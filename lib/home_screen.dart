import 'package:flutter/material.dart';

import 'games/bubble_pop_screen.dart';
import 'games/game_2048_screen.dart';
import 'games/memory_match_screen.dart';
import 'games/reaction_time_screen.dart';
import 'games/simon_screen.dart';
import 'games/sliding_puzzle_screen.dart';
import 'theme.dart';

enum _Category {
  brain('Brain', Icons.psychology),
  reflex('Reflex', Icons.bolt),
  calm('Calm', Icons.self_improvement);

  const _Category(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.category,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final _Category category;
  final WidgetBuilder builder;
}

const List<_GameEntry> _games = [
  _GameEntry(
    title: 'Memory Match',
    subtitle: 'Find the pairs',
    icon: Icons.style,
    gradient: [Color(0xFF8E7CF0), Color(0xFF5B4BC4)],
    category: _Category.brain,
    builder: _buildMemory,
  ),
  _GameEntry(
    title: '2048',
    subtitle: 'Swipe & merge tiles',
    icon: Icons.grid_view,
    gradient: [Color(0xFFF6A14E), Color(0xFFE8702A)],
    category: _Category.brain,
    builder: _build2048,
  ),
  _GameEntry(
    title: 'Sliding Puzzle',
    subtitle: 'Order 1 to 15',
    icon: Icons.extension,
    gradient: [Color(0xFF4ECDC4), Color(0xFF2BA89F)],
    category: _Category.brain,
    builder: _buildSliding,
  ),
  _GameEntry(
    title: 'Simon',
    subtitle: 'Repeat the colors',
    icon: Icons.palette,
    gradient: [Color(0xFFEE6FA0), Color(0xFFD64D86)],
    category: _Category.brain,
    builder: _buildSimon,
  ),
  _GameEntry(
    title: 'Reaction Time',
    subtitle: 'Tap on green, fast',
    icon: Icons.bolt,
    gradient: [Color(0xFFFF6B6B), Color(0xFFE63946)],
    category: _Category.reflex,
    builder: _buildReaction,
  ),
  _GameEntry(
    title: 'Bubble Pop',
    subtitle: 'Calm & satisfying',
    icon: Icons.bubble_chart,
    gradient: [Color(0xFF56CCF2), Color(0xFF2D9CDB)],
    category: _Category.calm,
    builder: _buildBubble,
  ),
];

// Top-level builders (so the entry list can be `const`).
Widget _buildMemory(BuildContext _) => const MemoryMatchScreen();
Widget _build2048(BuildContext _) => const Game2048Screen();
Widget _buildSliding(BuildContext _) => const SlidingPuzzleScreen();
Widget _buildSimon(BuildContext _) => const SimonScreen();
Widget _buildReaction(BuildContext _) => const ReactionTimeScreen();
Widget _buildBubble(BuildContext _) => const BubblePopScreen();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const _Header(),
              const SizedBox(height: 18),
              for (final category in _Category.values) ...[
                _SectionHeader(category: category),
                const SizedBox(height: 12),
                _GamesGrid(
                  games: _games
                      .where((g) => g.category == category)
                      .toList(),
                ),
                const SizedBox(height: 22),
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
            colors: [Color(0xFFFFE08A), AppColors.gold, Color(0xFFD9A441)],
          ).createShader(bounds),
          child: const Text(
            'FREE GAMES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Text(
          'Reflex • Brain • Calm — pick one and play',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(category.icon, color: AppColors.gold, size: 22),
        const SizedBox(width: 8),
        Text(
          category.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GamesGrid extends StatelessWidget {
  const _GamesGrid({required this.games});

  final List<_GameEntry> games;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final g in games) _GameTile(game: g)],
    );
  }
}

class _GameTile extends StatefulWidget {
  const _GameTile({required this.game});

  final _GameEntry game;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: game.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: game.gradient.last.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                game.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
