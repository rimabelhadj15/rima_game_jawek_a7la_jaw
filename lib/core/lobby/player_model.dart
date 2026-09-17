class Player {
  final String id;
  final String name;
  final bool isHost;
  bool connected;

  Player({required this.id, required this.name, this.isHost = false, this.connected = true});
}
