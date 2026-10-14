import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The classic 15-puzzle: slide numbered tiles into order 1..15.
class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({super.key});

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  static const int _n = 4;
  static const int _blank = 0;

  // tiles[i] holds the number at position i (row*_n + col); 0 is the blank.
  late List<int> _tiles;
  int _moves = 0;
  final Random _rng = Random();

  bool get _solved {
    for (int i = 0; i < _n * _n - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    _tiles = [for (int i = 1; i < _n * _n; i++) i, _blank];
    // Shuffle by making many random legal moves (guarantees solvability).
    int blankPos = _n * _n - 1;
    for (int k = 0; k < 400; k++) {
      final neighbors = _neighborsOf(blankPos);
      final pick = neighbors[_rng.nextInt(neighbors.length)];
      _tiles[blankPos] = _tiles[pick];
      _tiles[pick] = _blank;
      blankPos = pick;
    }
    _moves = 0;
  }

  List<int> _neighborsOf(int pos) {
    final r = pos ~/ _n;
    final c = pos % _n;
    final result = <int>[];
    if (r > 0) result.add(pos - _n);
    if (r < _n - 1) result.add(pos + _n);
    if (c > 0) result.add(pos - 1);
    if (c < _n - 1) result.add(pos + 1);
    return result;
  }

  void _tap(int pos) {
    if (_solved) return;
    final blankPos = _tiles.indexOf(_blank);
    if (_neighborsOf(pos).contains(blankPos)) {
      setState(() {
        _tiles[blankPos] = _tiles[pos];
        _tiles[pos] = _blank;
        _moves++;
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
                Text(
                  'Moves: $_moves',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: Center(child: _board())),
                const SizedBox(height: 12),
                if (_solved)
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
                    onPressed: () => setState(_shuffle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _solved ? 'Play Again' : 'Shuffle',
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

  Widget _board() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Container(
          width: side,
          height: side,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.count(
            crossAxisCount: _n,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < _tiles.length; i++) _tileView(i),
            ],
          ),
        );
      },
    );
  }

  Widget _tileView(int pos) {
    final value = _tiles[pos];
    if (value == _blank) {
      return const SizedBox.shrink();
    }
    final correct = value == pos + 1;
    return GestureDetector(
      onTap: () => _tap(pos),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: correct
                ? const [Color(0xFF9AD0C2), Color(0xFF5FB49C)]
                : const [AppColors.gold, Color(0xFFD9A441)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '$value',
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 30,
              fontWeight: FontWeight.w800,
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
            'Sliding Puzzle',
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
}
