import 'package:flutter/material.dart';

import '../games/racer_screen.dart';
import '../theme.dart';
import 'race_net.dart';

const int _maxPlayers = 6;

/// Entry screen for multiplayer: enter a name, then create or join a room.
class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _openLobby(bool host) {
    final name = _nameCtrl.text.trim().isEmpty ? 'Player' : _nameCtrl.text.trim();
    final net = LocalRaceNet();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (host) {
      net.createRoom(name);
    } else {
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a room code to join')),
        );
        return;
      }
      net.joinRoom(code, name);
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomLobbyScreen(net: net)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Race Online',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Race up to $_maxPlayers friends. Create a room and share the '
                  'code, or join with a code.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                _label('YOUR NAME'),
                _field(_nameCtrl, 'e.g. Rajat', TextCapitalization.words),
                const SizedBox(height: 28),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLobby(true),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or join',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                ]),
                const SizedBox(height: 20),
                _label('ROOM CODE'),
                _field(_codeCtrl, 'e.g. 7KQP', TextCapitalization.characters),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => _openLobby(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.gold, width: 2),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Join Room'),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Online play needs the backend connected. Until then this is '
                    'a preview of the lobby — you can look around, but friends '
                    "can't join live yet.",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _field(TextEditingController c, String hint, TextCapitalization cap) {
    return TextField(
      controller: c,
      textCapitalization: cap,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: AppColors.blue.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Room lobby: shows the code, the connected players, a Ready toggle, and
/// (for the host) a Start button once everyone is ready.
class RoomLobbyScreen extends StatelessWidget {
  const RoomLobbyScreen({super.key, required this.net});

  final RaceNet net;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: StreamBuilder<RoomState>(
            stream: net.updates,
            initialData: net.room,
            builder: (context, snapshot) {
              final room = snapshot.data;
              if (room == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final players = room.players.values.toList();
              final me = room.players[net.myId];
              final allReady =
                  players.isNotEmpty && players.every((p) => p.ready);

              return Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            net.leave();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Text('Lobby',
                            style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Text('ROOM CODE',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  letterSpacing: 2)),
                          Text(room.code,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6)),
                          Text('Share this code with friends',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('PLAYERS  ${players.length}/$_maxPlayers',
                        style: TextStyle(
                            color: AppColors.gold.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: players.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _playerTile(players[i], room.hostId),
                      ),
                    ),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => net.setReady(!(me?.ready ?? false)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (me?.ready ?? false) ? AppColors.blue : AppColors.gold,
                          foregroundColor:
                              (me?.ready ?? false) ? Colors.white : AppColors.dark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text((me?.ready ?? false) ? 'Not Ready' : "I'm Ready",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (net.isHost) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: allReady
                              ? () => _startRace(context)
                              : null,
                          icon: const Icon(Icons.flag),
                          label: const Text('Start Race'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _startRace(BuildContext context) {
    // Until live sync is connected, the race runs locally (solo). The synced
    // multiplayer race slots in here once the backend is wired up.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live sync coming once the backend is connected — '
            'running a solo race for now.'),
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RacerScreen()),
    );
  }

  Widget _playerTile(PlayerState p, String hostId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(p.carColor),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Text(p.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          if (p.id == hostId) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: AppColors.gold, size: 18),
          ],
          const Spacer(),
          Text(p.ready ? 'READY' : 'waiting',
              style: TextStyle(
                  color: p.ready ? const Color(0xFF00E676) : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
