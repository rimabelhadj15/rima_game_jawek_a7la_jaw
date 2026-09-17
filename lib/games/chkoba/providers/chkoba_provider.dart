import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/lobby/player_model.dart';
import '../../../core/network/host_server.dart';
import '../../../core/network/game_client.dart';
import '../../../core/network/message_models.dart';
import '../models/card_model.dart';
import '../models/chkoba_state.dart';
import '../logic/rules_engine.dart';

class PlayersNotifier extends StateNotifier<List<Player>> {
  PlayersNotifier() : super([]);

  void setFromNetwork(List<Map<String, dynamic>> players, {required String hostId}) {
    state = players
        .map((p) => Player(id: p['id'] as String, name: p['name'] as String, isHost: p['id'] == hostId))
        .toList();
  }

  void addLocal(Player p) {
    state = [...state, p];
  }
}

class ChkobaNotifier extends StateNotifier<ChkobaState?> {
  ChkobaNotifier() : super(null);

  void setState(ChkobaState newState) {
    state = newState;
  }

  void clear() {
    state = null;
  }
}

final playersProvider = StateNotifierProvider<PlayersNotifier, List<Player>>((ref) => PlayersNotifier());

final chkobaStateProvider = StateNotifierProvider<ChkobaNotifier, ChkobaState?>((ref) => ChkobaNotifier());

final lastErrorProvider = StateProvider<String?>((ref) => null);

/// Handles both the "I am the host" and "I am a client" roles behind one API,
/// so the UI layer doesn't need to know which one it's talking to.
class GameManager {
  final Ref ref;
  GameManager(this.ref);

  bool isHost = false;
  String myPlayerId = '';
  String myName = '';

  HostServer? _host;
  GameClient? _client;

  Future<String> startHosting(String hostName) async {
    isHost = true;
    myName = hostName;
    myPlayerId = 'host';
    _host = HostServer();
    _host!.onPlayersChanged = _broadcastPlayerListFromHost;
    _host!.onMessage = _handleIncomingMove;
    _host!.onDisconnect = (_) => _broadcastPlayerListFromHost();
    await _host!.start();
    ref.read(playersProvider.notifier).state = [Player(id: myPlayerId, name: myName, isHost: true)];
    final ips = await _host!.localIPv4Addresses();
    return ips.isNotEmpty ? ips.first : 'unknown';
  }

  void _broadcastPlayerListFromHost() {
    if (_host == null) return;
    final players = [
      {'id': myPlayerId, 'name': myName},
      ..._host!.playerNames.entries.map((e) => {'id': e.key, 'name': e.value}),
    ];
    _host!.broadcast(NetworkMessage(MessageType.playerList, {'players': players}));
    ref.read(playersProvider.notifier).setFromNetwork(List<Map<String, dynamic>>.from(players), hostId: myPlayerId);
  }

  void _handleIncomingMove(String playerId, NetworkMessage msg) {
    if (msg.type != MessageType.playCard) return;
    final current = ref.read(chkobaStateProvider);
    if (current == null) return;

    final card = GameCard.fromJson(Map<String, dynamic>.from(msg.data['card']));
    final rawIds = msg.data['chosenCaptureCardIds'];
    final captureIds = rawIds != null ? List<String>.from(rawIds) : null;

    final result = ChkobaEngine.playCard(current, playerId, card, chosenCaptureCardIds: captureIds);
    if (result.error != null) {
      if (playerId == myPlayerId) {
        ref.read(lastErrorProvider.notifier).state = result.error;
      } else {
        _host!.sendTo(playerId, NetworkMessage(MessageType.error, {'message': result.error}));
      }
      return;
    }
    ref.read(chkobaStateProvider.notifier).setState(result.state);
    _host!.broadcast(NetworkMessage(MessageType.stateUpdate, result.state.toJson()));
  }

  void startGame() {
    final players = ref.read(playersProvider);
    final ids = players.map((p) => p.id).toList();
    final names = {for (final p in players) p.id: p.name};
    final newState = ChkobaEngine.newGame(ids, names);
    ref.read(chkobaStateProvider.notifier).setState(newState);
    _host!.broadcast(NetworkMessage(MessageType.stateUpdate, newState.toJson()));
  }

  Future<void> joinGame(String hostIp, String name) async {
    isHost = false;
    myName = name;
    _client = GameClient();
    _client!.messages.listen(_handleClientMessage);
    await _client!.connect(hostIp, name);
  }

  void _handleClientMessage(NetworkMessage msg) {
    switch (msg.type) {
      case MessageType.joinAck:
        myPlayerId = msg.data['playerId'] as String;
        break;
      case MessageType.playerList:
        final players = List<Map<String, dynamic>>.from(
          (msg.data['players'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
        final hostId = players.isNotEmpty ? players.first['id'] as String : '';
        ref.read(playersProvider.notifier).setFromNetwork(players, hostId: hostId);
        break;
      case MessageType.stateUpdate:
        ref.read(chkobaStateProvider.notifier).setState(ChkobaState.fromJson(msg.data));
        break;
      case MessageType.error:
        ref.read(lastErrorProvider.notifier).state = msg.data['message'] as String?;
        break;
      default:
        break;
    }
  }

  void playCard(GameCard card, {List<String>? chosenCaptureCardIds}) {
    final payload = {
      'card': card.toJson(),
      'chosenCaptureCardIds': chosenCaptureCardIds,
    };
    if (isHost) {
      _handleIncomingMove(myPlayerId, NetworkMessage(MessageType.playCard, payload));
    } else {
      _client!.send(NetworkMessage(MessageType.playCard, payload));
    }
  }

  void dispose() {
    _host?.stop();
    _client?.disconnect();
  }
}

final gameManagerProvider = Provider<GameManager>((ref) => GameManager(ref));
