import 'package:flutter/material.dart';

import '../theme.dart';

/// A classic concentration game: flip two cards, keep them if they match.
class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryCard {
  _MemoryCard(this.emoji);
  final String emoji;
  bool faceUp = false;
  bool matched = false;
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  static const List<String> _emojis = [
    '🍎', '🚀', '🌟', '🎵', '🐱', '🌈', '⚽', '🍩',
  ];

  late List<_MemoryCard> _cards;
  int? _firstIndex;
  bool _busy = false;
  int _moves = 0;
  int _matches = 0;

  bool get _won => _matches == _emojis.length;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final deck = [..._emojis, ..._emojis].map(_MemoryCard.new).toList()
      ..shuffle();
    _cards = deck;
    _firstIndex = null;
    _busy = false;
    _moves = 0;
    _matches = 0;
  }

  Future<void> _onTap(int index) async {
    if (_busy) return;
    final card = _cards[index];
    if (card.faceUp || card.matched) return;

    setState(() => card.faceUp = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _moves++;
    final first = _cards[_firstIndex!];

    if (first.emoji == card.emoji) {
      setState(() {
        first.matched = true;
        card.matched = true;
        _matches++;
        _firstIndex = null;
      });
    } else {
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        first.faceUp = false;
        card.faceUp = false;
        _firstIndex = null;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _topBar(context),
                const SizedBox(height: 8),
                _statsBar(),
                const SizedBox(height: 16),
                Expanded(child: Center(child: _grid())),
                const SizedBox(height: 16),
                if (_won)
                  Text(
                    'Solved in $_moves moves! 🎉',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => setState(_setup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _won ? 'Play Again' : 'Shuffle / Restart',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Memory Match',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('Moves', '$_moves'),
        _stat('Pairs', '$_matches / ${_emojis.length}'),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return SizedBox(
          width: side,
          height: side,
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < _cards.length; i++) _cardView(i),
            ],
          ),
        );
      },
    );
  }

  Widget _cardView(int index) {
    final card = _cards[index];
    final revealed = card.faceUp || card.matched;
    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: revealed
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gold, Color(0xFFD9A441)],
                ),
          color: revealed
              ? (card.matched
                  ? AppColors.blue.withValues(alpha: 0.55)
                  : AppColors.blue)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            revealed ? card.emoji : '?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: revealed ? Colors.white : AppColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}
