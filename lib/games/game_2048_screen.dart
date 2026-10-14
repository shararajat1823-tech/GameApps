import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 2048: swipe to slide tiles; equal tiles merge. Reach 2048.
class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int _n = 4;
  late List<List<int>> _grid;
  int _score = 0;
  int _best = 0;
  bool _gameOver = false;
  final Random _rng = Random();

  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(_n, (_) => List.filled(_n, 0));
    _score = 0;
    _gameOver = false;
    _spawn();
    _spawn();
  }

  void _spawn() {
    final empty = <Point<int>>[];
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        if (_grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[_rng.nextInt(empty.length)];
    _grid[cell.x][cell.y] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  /// Collapse one line toward index 0, merging equal neighbors once.
  List<int> _collapse(List<int> line) {
    final tiles = line.where((v) => v != 0).toList();
    final result = <int>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        result.add(merged);
        _score += merged;
        i++;
      } else {
        result.add(tiles[i]);
      }
    }
    while (result.length < _n) {
      result.add(0);
    }
    return result;
  }

  void _move(_Dir dir) {
    if (_gameOver) return;
    final before = _grid.map((r) => r.toList()).toList();

    List<List<int>> lines;
    switch (dir) {
      case _Dir.left:
        lines = [for (int r = 0; r < _n; r++) _grid[r].toList()];
      case _Dir.right:
        lines = [for (int r = 0; r < _n; r++) _grid[r].reversed.toList()];
      case _Dir.up:
        lines = [
          for (int c = 0; c < _n; c++) [for (int r = 0; r < _n; r++) _grid[r][c]]
        ];
      case _Dir.down:
        lines = [
          for (int c = 0; c < _n; c++)
            [for (int r = _n - 1; r >= 0; r--) _grid[r][c]]
        ];
    }

    final collapsed = lines.map(_collapse).toList();

    for (int i = 0; i < _n; i++) {
      final line = collapsed[i];
      switch (dir) {
        case _Dir.left:
          _grid[i] = line;
        case _Dir.right:
          _grid[i] = line.reversed.toList();
        case _Dir.up:
          for (int r = 0; r < _n; r++) {
            _grid[r][i] = line[r];
          }
        case _Dir.down:
          for (int r = 0; r < _n; r++) {
            _grid[_n - 1 - r][i] = line[r];
          }
      }
    }

    final changed = !_sameGrid(before, _grid);
    if (changed) {
      _spawn();
      if (_score > _best) _best = _score;
      if (!_anyMovesLeft()) _gameOver = true;
    }
    setState(() {});
  }

  bool _sameGrid(List<List<int>> a, List<List<int>> b) {
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  bool _anyMovesLeft() {
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        if (_grid[r][c] == 0) return true;
        if (c + 1 < _n && _grid[r][c] == _grid[r][c + 1]) return true;
        if (r + 1 < _n && _grid[r][c] == _grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  void _onPanEnd(DragEndDetails _) {
    if (_drag.distance < 18) {
      _drag = Offset.zero;
      return;
    }
    if (_drag.dx.abs() > _drag.dy.abs()) {
      _move(_drag.dx > 0 ? _Dir.right : _Dir.left);
    } else {
      _move(_drag.dy > 0 ? _Dir.down : _Dir.up);
    }
    _drag = Offset.zero;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chip('SCORE', '$_score'),
                    _chip('BEST', '$_best'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanStart: (_) => _drag = Offset.zero,
                      onPanUpdate: (d) => _drag += d.delta,
                      onPanEnd: _onPanEnd,
                      child: _board(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_gameOver)
                  const Text(
                    'No moves left — Game Over',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => setState(_reset),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Swipe to move the tiles',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
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
          child: Column(
            children: [
              for (int r = 0; r < _n; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (int c = 0; c < _n; c++)
                        Expanded(child: _tile(_grid[r][c])),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(int value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _tileColor(value),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : '$value',
            style: TextStyle(
              color: value <= 4 ? AppColors.dark : Colors.white,
              fontSize: value >= 1024 ? 22 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0:
        return AppColors.dark.withValues(alpha: 0.45);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      default:
        return const Color(0xFFEDC22E);
    }
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.gold.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
            '2048',
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

enum _Dir { left, right, up, down }
