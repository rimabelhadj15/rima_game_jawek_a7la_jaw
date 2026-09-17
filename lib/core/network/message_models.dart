import 'dart:convert';

enum MessageType {
  join, // client -> host: {name}
  joinAck, // host -> client: {playerId}
  playerList, // host -> all: {players: [{id,name}]}
  startGame, // host -> all: {}
  stateUpdate, // host -> all: full ChkobaState json
  playCard, // client -> host: {card: {...}, chosenCaptureCardIds: [...]?}
  error, // host -> client: {message}
  playerDisconnected, // host -> all: {playerId}
  playerReconnected, // host -> all: {playerId}
}

class NetworkMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  const NetworkMessage(this.type, this.data);

  String encode() => jsonEncode({'type': type.name, 'data': data});

  static NetworkMessage decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final type = MessageType.values.firstWhere((t) => t.name == json['type']);
    return NetworkMessage(type, Map<String, dynamic>.from(json['data'] as Map));
  }
}
