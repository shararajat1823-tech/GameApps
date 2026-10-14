import 'package:flutter/material.dart';

import 'games/bubble_pop_screen.dart';
import 'games/memory_match_screen.dart';
import 'games/reaction_time_screen.dart';
import 'theme.dart';

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// null = "coming soon" (card is disabled).
  final WidgetBuilder? builder;

  bool get locked => builder == null;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<_GameEntry> get _games => [
        _GameEntry(
          title: 'Memory Match',
          subtitle: 'Flip cards and find the pairs',
          icon: Icons.style,
          builder: (_) => const MemoryMatchScreen(),
        ),
        _GameEntry(
          title: 'Bubble Pop',
          subtitle: 'Tap floating bubbles — calm & satisfying',
          icon: Icons.bubble_chart,
          builder: (_) => const BubblePopScreen(),
        ),
        _GameEntry(
          title: 'Reaction Time',
          subtitle: 'Wait for green, then tap fast',
          icon: Icons.bolt,
          builder: (_) => const ReactionTimeScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _Header(),
              const SizedBox(height: 10),
              for (final game in _games) ...[
                _GameCard(game: game),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              Text(
                'More games coming soon',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
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
        const Text(
          'FREE GAMES',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Pick a game and play',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final _GameEntry game;

  @override
  Widget build(BuildContext context) {
    final locked = game.locked;
    return Material(
      color: locked
          ? AppColors.blue.withValues(alpha: 0.4)
          : AppColors.blue,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: locked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: game.builder!),
                ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold
                      .withValues(alpha: locked ? 0.4 : 1.0),
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, color: AppColors.dark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      locked ? 'Coming soon' : game.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
