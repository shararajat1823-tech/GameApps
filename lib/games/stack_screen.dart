import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Stack: a block slides back and forth — tap to drop it on the tower.
/// Any part hanging over the edge is sliced off, so precision matters.
/// It speeds up as you climb.
class StackScreen extends StatefulWidget {
  const StackScreen({super.key});

  @override
  State<StackScreen> createState() => _StackScreenState();
}

class _Block {
  _Block(this.left, this.width, this.color);
  double left; // 0..1 (fraction of width)
  double width; // 0..1
  final Color color;
}

class _StackScreenState extends State<StackScreen> {
  static const double _blockHeight = 34;
  static const double _startWidth = 0.6;

  final List<_Block> _tower = [];
  late _Block _active;
  double _speed = 0.012;
  int _dir = 1;
  int _score = 0;
  int _best = 0;
  bool _gameOver = false;
  bool _started = false;
  Timer? _timer;

  Color _colorFor(int index) {
    // Cycle hues for a rainbow tower.
    final hue = (200 + index * 24) % 360;
    return HSVColor.fromAHSV(1, hue.toDouble(), 0.55, 0.95).toColor();
  }

  void _start() {
    _timer?.cancel();
    _tower.clear();
    _tower.add(_Block(0.2, _startWidth, _colorFor(0)));
    _active = _Block(0.0, _startWidth, _colorFor(1));
    _speed = 0.016;
    _dir = 1;
    _score = 0;
    _gameOver = false;
    _started = true;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_gameOver) return;
    setState(() {
      _active.left += _dir * _speed;
      if (_active.left <= 0) {
        _active.left = 0;
        _dir = 1;
      } else if (_active.left + _active.width >= 1) {
        _active.left = 1 - _active.width;
        _dir = -1;
      }
    });
  }

  void _drop() {
    if (!_started || _gameOver) return;
    final prev = _tower.last;
    final overlapLeft =
        _active.left > prev.left ? _active.left : prev.left;
    final activeRight = _active.left + _active.width;
    final prevRight = prev.left + prev.width;
    final overlapRight = activeRight < prevRight ? activeRight : prevRight;
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 0) {
      _endGame();
      return;
    }

    _tower.add(_Block(overlapLeft, overlap, _active.color));
    _score++;
    if (_score > _best) _best = _score;
    _speed = (_speed + 0.0014).clamp(0.016, 0.045);

    // New active block starts from an edge, same trimmed width.
    final startLeft = _dir == 1 ? 0.0 : 1 - overlap;
    _active = _Block(startLeft, overlap, _colorFor(_tower.length));
    setState(() {});
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _gameOver = true;
      _started = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackground,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _started ? _drop : _start,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final anchorY = h * 0.30;
                      return Stack(
                        children: [
                          // Placed blocks.
                          for (int j = 0; j < _tower.length; j++)
                            _blockWidget(_tower[j], w,
                                anchorY + (_tower.length - j) * _blockHeight),
                          // Active moving block.
                          if (_started)
                            _blockWidget(_active, w, anchorY),
                          if (!_started)
                            Center(
                              child: Text(
                                _gameOver
                                    ? 'Tower fell!\nTap to play again'
                                    : 'Tap to drop the blocks\nStack them as high as you can',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockWidget(_Block b, double areaWidth, double top) {
    return Positioned(
      top: top,
      left: b.left * areaWidth,
      child: Container(
        width: b.width * areaWidth,
        height: _blockHeight,
        decoration: BoxDecoration(
          color: b.color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: b.color.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Text(
            'Stack',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            'Height: $_score    Best: $_best',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
