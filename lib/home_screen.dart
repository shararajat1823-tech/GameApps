import 'package:flutter/material.dart';

import 'games/dodge_screen.dart';
import 'games/flip_screen.dart';
import 'games/racer_screen.dart';
import 'games/stack_screen.dart';
import 'multiplayer/lobby_screen.dart';
import 'theme.dart';

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final WidgetBuilder builder;
}

const List<_GameEntry> _games = [
  _GameEntry(
    title: 'Race Online',
    subtitle: 'Create a room, invite up to 6 friends, race together. (preview)',
    icon: Icons.groups,
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
    builder: _buildMultiplayer,
  ),
  _GameEntry(
    title: 'Grand Prix',
    subtitle: 'Formula racing — carve the circuit, chase the fastest lap.',
    icon: Icons.sports_score,
    gradient: [Color(0xFF00C6FB), Color(0xFF005BEA)],
    builder: _buildRacer,
  ),
  _GameEntry(
    title: 'Stack',
    subtitle: 'Drop blocks dead-center — or lose the overhang. Speeds up fast.',
    icon: Icons.layers,
    gradient: [Color(0xFFFFA63D), Color(0xFFE8431F)],
    builder: _buildStack,
  ),
  _GameEntry(
    title: 'Flip',
    subtitle: 'Flip gravity to dodge the bars. One touch kills you.',
    icon: Icons.flip_camera_android,
    gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    builder: _buildFlip,
  ),
  _GameEntry(
    title: 'Dodge',
    subtitle: 'Drag through a storm of hazards. One hit = dead.',
    icon: Icons.warning_amber_rounded,
    gradient: [Color(0xFFFF416C), Color(0xFFB00020)],
    builder: _buildDodge,
  ),
];

Widget _buildMultiplayer(BuildContext _) => const MultiplayerScreen();
Widget _buildRacer(BuildContext _) => const RacerScreen();
Widget _buildStack(BuildContext _) => const StackScreen();
Widget _buildFlip(BuildContext _) => const FlipScreen();
Widget _buildDodge(BuildContext _) => const DodgeScreen();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const _Header(),
              const SizedBox(height: 22),
              for (final game in _games) ...[
                _GameCard(game: game),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFE08A), AppColors.gold, Color(0xFFE8431F)],
          ).createShader(bounds),
          child: const Text(
            'ARCADE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        Text(
          'Fast. Brutal. One shot.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({required this.game});

  final _GameEntry game;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: game.builder),
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: game.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: game.gradient.last.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
