import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message_models.dart';

class GameClient {
  WebSocketChannel? _channel;
  final _controller = StreamController<NetworkMessage>.broadcast();
  String? myPlayerId;

  Stream<NetworkMessage> get messages => _controller.stream;

  Future<void> connect(String hostIp, String playerName, {int port = 4040}) async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$hostIp:$port'));
    _channel!.stream.listen(
      (raw) {
        final msg = NetworkMessage.decode(raw as String);
        if (msg.type == MessageType.joinAck) {
          myPlayerId = msg.data['playerId'] as String;
        }
        _controller.add(msg);
      },
      onDone: () => _controller.add(const NetworkMessage(MessageType.error, {'message': 'Disconnected from host'})),
      onError: (_) => _controller.add(const NetworkMessage(MessageType.error, {'message': 'Connection error'})),
    );
    send(NetworkMessage(MessageType.join, {'name': playerName}));
  }

  void send(NetworkMessage msg) {
    _channel?.sink.add(msg.encode());
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
