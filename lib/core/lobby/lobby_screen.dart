import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/common_button.dart';
import '../../games/chkoba/providers/chkoba_provider.dart';
import '../../games/chkoba/ui/game_table_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style, size: 72, color: AppTheme.gold),
                const SizedBox(height: 16),
                const Text('Chkoba', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Tunisian card games, offline, over hotspot', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 48),
                CommonButton(
                  label: 'Host a Game',
                  icon: Icons.wifi_tethering,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostLobbyScreen())),
                ),
                const SizedBox(height: 16),
                CommonButton(
                  label: 'Join a Game',
                  icon: Icons.wifi,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinLobbyScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  final _nameController = TextEditingController(text: 'Host');
  bool _hosting = false;
  bool _starting = false;
  String? _hostIp;
  String? _startError;

  Future<void> _startHosting() async {
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final manager = ref.read(gameManagerProvider);
      final ip = await manager.startHosting(
        _nameController.text.trim().isEmpty ? 'Host' : _nameController.text.trim(),
      );
      setState(() {
        _hosting = true;
        _hostIp = ip;
        _starting = false;
      });
    } catch (e) {
      setState(() {
        _starting = false;
        _startError = 'Could not start server: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Host a Game')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hosting) ...[
              const Text('1. Turn on your phone Hotspot in Settings first.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              if (_startError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_startError!, style: const TextStyle(color: Colors.redAccent)),
                ),
              _starting
                  ? const Center(child: CircularProgressIndicator())
                  : CommonButton(label: 'Start Server', onPressed: _startHosting),
            ] else ...[
              Card(
                color: Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tell other players to Join using this address:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      SelectableText(_hostIp ?? '...', style: const TextStyle(fontSize: 20, color: AppTheme.gold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Players (${players.length}/4)', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: Icon(players[i].isHost ? Icons.star : Icons.person, color: AppTheme.gold),
                    title: Text(players[i].name, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              CommonButton(
                label: 'Start Game',
                onPressed: players.length >= 2
                    ? () {
                        ref.read(gameManagerProvider).startGame();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameTableScreen()));
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController(text: '192.168.43.1');
  bool _connecting = false;
  bool _joined = false;

  Future<void> _join() async {
    setState(() => _connecting = true);
    final manager = ref.read(gameManagerProvider);
    await manager.joinGame(_ipController.text.trim(), _nameController.text.trim().isEmpty ? 'Player' : _nameController.text.trim());
    setState(() {
      _connecting = false;
      _joined = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chkobaStateProvider, (prev, next) {
      if (next != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameTableScreen()));
      }
    });
    final players = ref.watch(playersProvider);
    final error = ref.watch(lastErrorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join a Game')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_joined) ...[
              const Text('Connect to the host\'s hotspot in WiFi settings first, then enter the address they gave you.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'Host address', border: OutlineInputBorder()),
              ),
              if (error != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error, style: const TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(height: 20),
              _connecting
                  ? const Center(child: CircularProgressIndicator())
                  : CommonButton(label: 'Connect', onPressed: _join),
            ] else ...[
              const Text('Waiting for host to start the game...', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: Icon(players[i].isHost ? Icons.star : Icons.person, color: AppTheme.gold),
                    title: Text(players[i].name, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
