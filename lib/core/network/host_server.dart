import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'message_models.dart';

class HostServer {
  HttpServer? _server;
  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, String> playerNames = {};
  final _uuid = const Uuid();

  void Function(String playerId, NetworkMessage msg)? onMessage;
  void Function(String playerId)? onDisconnect;
  void Function()? onPlayersChanged;

  static const int port = 4040;

  List<String> get connectedPlayerIds => _clients.keys.toList();

  /// Returns local IPv4 addresses so the host can tell others what to type,
  /// as a fallback if they can't auto-discover the host.
  Future<List<String>> localIPv4Addresses() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return interfaces.expand((i) => i.addresses).map((a) => a.address).toList();
  }

  Future<void> start() async {
    final handler = webSocketHandler((WebSocketChannel channel, String? protocol) {
      String? playerId;

      channel.stream.listen(
        (raw) {
          final msg = NetworkMessage.decode(raw as String);
          if (msg.type == MessageType.join) {
            playerId = _uuid.v4();
            playerNames[playerId!] = msg.data['name'] as String? ?? 'Player';
            _clients[playerId!] = channel;
            channel.sink.add(NetworkMessage(MessageType.joinAck, {'playerId': playerId}).encode());
            onPlayersChanged?.call();
          } else if (playerId != null) {
            onMessage?.call(playerId!, msg);
          }
        },
        onDone: () {
          if (playerId != null) {
            _clients.remove(playerId);
            onDisconnect?.call(playerId!);
            onPlayersChanged?.call();
          }
        },
        onError: (_) {
          if (playerId != null) {
            _clients.remove(playerId);
            onDisconnect?.call(playerId!);
            onPlayersChanged?.call();
          }
        },
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  void sendTo(String playerId, NetworkMessage msg) {
    _clients[playerId]?.sink.add(msg.encode());
  }

  void broadcast(NetworkMessage msg) {
    for (final channel in _clients.values) {
      channel.sink.add(msg.encode());
    }
  }

  Future<void> stop() async {
    for (final c in _clients.values) {
      await c.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
  }
}
