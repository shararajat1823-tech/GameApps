import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Flip: your glowing runner is pulled by gravity to the floor. Tap to flip
/// gravity and stick to the ceiling instead — dodge the bars coming at you.
class FlipScreen extends StatefulWidget {
  const FlipScreen({super.key});

  @override
  State<FlipScreen> createState() => _FlipScreenState();
}

class _Bar {
  _Bar({required this.x, required this.fromTop, required this.height});
  double x;
  final bool fromTop;
  final double height; // fraction of play area height
  bool passed = false;
}

class _FlipScreenState extends State<FlipScreen> {
  static const double _dotRadius = 14;
  static const double _dotXFrac = 0.28;
  static const double _barWidth = 26;

  final List<_Bar> _bars = [];
  final Random _rng = Random();
  Timer? _timer;
  Size _area = Size.zero;

  double _dotY = 0; // px from top
  double _vel = 0;
  int _gravity = 1; // 1 = down, -1 = up
  double _speed = 3.2;
  double _sinceSpawn = 0;
  int _score = 0;
  int _best = 0;
  bool _started = false;
  bool _gameOver = false;

  void _start() {
    _timer?.cancel();
    _bars.clear();
    _dotY = _area.height - _dotRadius;
    _vel = 0;
    _gravity = 1;
    _speed = 4.4;
    _sinceSpawn = 0;
    _score = 0;
    _started = true;
    _gameOver = false;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTap() {
    if (!_started || _gameOver) {
      _start();
      return;
    }
    _gravity = -_gravity; // flip
  }

  void _tick() {
    if (_area == Size.zero) return;
    final h = _area.height;
    final w = _area.width;

    setState(() {
      // Physics.
      _vel += _gravity * 0.9;
      _dotY += _vel;
      final floor = h - _dotRadius;
      const ceiling = _dotRadius;
      if (_dotY >= floor) {
        _dotY = floor;
        _vel = 0;
      } else if (_dotY <= ceiling) {
        _dotY = ceiling;
        _vel = 0;
      }

      // Move bars.
      for (final b in _bars) {
        b.x -= _speed;
      }
      _bars.removeWhere((b) => b.x + _barWidth < 0);

      // Spawn.
      _sinceSpawn += _speed;
      if (_sinceSpawn > 185) {
        _sinceSpawn = 0;
        _bars.add(
          _Bar(
            x: w,
            fromTop: _rng.nextBool(),
            height: 0.46 + _rng.nextDouble() * 0.18,
          ),
        );
      }

      // Score + collision.
      final dotX = w * _dotXFrac;
      for (final b in _bars) {
        if (!b.passed && b.x + _barWidth < dotX) {
          b.passed = true;
          _score++;
        }
        final hitX = (b.x - _barWidth / 2 < dotX + _dotRadius) &&
            (b.x + _barWidth > dotX - _dotRadius);
        if (hitX) {
          final barPx = b.height * h;
          if (b.fromTop && _dotY - _dotRadius < barPx) {
            _endGame();
          } else if (!b.fromTop && _dotY + _dotRadius > h - barPx) {
            _endGame();
          }
        }
      }

      _speed = (_speed + 0.004).clamp(4.4, 9.5);
    });
  }

  void _endGame() {
    _timer?.cancel();
    if (_score > _best) _best = _score;
    _started = false;
    _gameOver = true;
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
                  onTap: _onTap,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _area = Size(constraints.maxWidth, constraints.maxHeight);
                      if (!_started && !_gameOver && _dotY == 0) {
                        _dotY = _area.height - _dotRadius;
                      }
                      return Stack(
                        children: [
                          for (final b in _bars) _barWidget(b),
                          _dotWidget(),
                          if (!_started)
                            Center(
                              child: Text(
                                _gameOver
                                    ? 'Crashed!  Score: $_score\nTap to try again'
                                    : 'Tap to flip gravity\nDodge the bars',
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

  Widget _dotWidget() {
    return Positioned(
      left: _area.width * _dotXFrac - _dotRadius,
      top: _dotY - _dotRadius,
      child: Container(
        width: _dotRadius * 2,
        height: _dotRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.8),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _barWidget(_Bar b) {
    final barPx = b.height * _area.height;
    return Positioned(
      left: b.x - _barWidth / 2,
      top: b.fromTop ? 0 : null,
      bottom: b.fromTop ? null : 0,
      child: Container(
        width: _barWidth,
        height: barPx,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
              blurRadius: 10,
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
            'Flip',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            'Score: $_score    Best: $_best',
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
