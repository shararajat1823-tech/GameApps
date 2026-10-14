import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Dodge: drag to move your core along the bottom and survive an accelerating
/// rain of hazards. One hit ends the run. It gets faster and denser — fast.
class DodgeScreen extends StatefulWidget {
  const DodgeScreen({super.key});

  @override
  State<DodgeScreen> createState() => _DodgeScreenState();
}

class _Hazard {
  _Hazard({required this.x, required this.y, required this.size, required this.vy});
  double x;
  double y;
  final double size;
  final double vy;
}

class _DodgeScreenState extends State<DodgeScreen> {
  static const double _coreRadius = 16;

  final List<_Hazard> _hazards = [];
  final Random _rng = Random();
  Timer? _timer;
  Size _area = Size.zero;

  double _coreX = 0;
  double _speed = 6;
  double _sinceSpawn = 0;
  double _spawnGap = 26;
  int _ticks = 0;
  int _score = 0;
  int _best = 0;
  bool _started = false;
  bool _gameOver = false;

  double get _coreY => _area.height - _coreRadius - 12;

  void _start() {
    _timer?.cancel();
    _hazards.clear();
    _coreX = _area.width / 2;
    _speed = 6;
    _sinceSpawn = 0;
    _spawnGap = 26;
    _ticks = 0;
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

  void _steer(Offset p) {
    if (_area == Size.zero) return;
    setState(() {
      _coreX = p.dx.clamp(_coreRadius, _area.width - _coreRadius);
    });
  }

  void _tick() {
    if (_area == Size.zero) return;
    setState(() {
      _ticks++;
      if (_ticks % 6 == 0) _score++; // survival score

      for (final hz in _hazards) {
        hz.y += hz.vy;
      }
      _hazards.removeWhere((hz) => hz.y - hz.size > _area.height);

      _sinceSpawn += 1;
      if (_sinceSpawn >= _spawnGap) {
        _sinceSpawn = 0;
        final size = 14 + _rng.nextDouble() * 22;
        _hazards.add(
          _Hazard(
            x: size + _rng.nextDouble() * (_area.width - size * 2),
            y: -size,
            size: size,
            vy: _speed * (0.8 + _rng.nextDouble() * 0.5),
          ),
        );
      }

      // Collision.
      final core = Offset(_coreX, _coreY);
      for (final hz in _hazards) {
        if ((Offset(hz.x, hz.y) - core).distance < hz.size / 2 + _coreRadius) {
          _endGame();
          break;
        }
      }

      // Ramp up — harsh.
      _speed = (_speed + 0.01).clamp(6, 16);
      _spawnGap = (_spawnGap - 0.03).clamp(9, 26);
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
                  onTapDown: (d) {
                    if (!_started) {
                      _start();
                    } else {
                      _steer(d.localPosition);
                    }
                  },
                  onPanStart: (d) => _steer(d.localPosition),
                  onPanUpdate: (d) => _steer(d.localPosition),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _area = Size(constraints.maxWidth, constraints.maxHeight);
                      if (_coreX == 0) _coreX = _area.width / 2;
                      return Stack(
                        children: [
                          for (final hz in _hazards) _hazardWidget(hz),
                          _coreWidget(),
                          if (!_started)
                            Center(
                              child: Text(
                                _gameOver
                                    ? 'Hit!  Score: $_score\nTap to try again'
                                    : 'Drag to move\nSurvive the falling hazards',
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

  Widget _coreWidget() {
    return Positioned(
      left: _coreX - _coreRadius,
      top: _coreY - _coreRadius,
      child: Container(
        width: _coreRadius * 2,
        height: _coreRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.8),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _hazardWidget(_Hazard hz) {
    return Positioned(
      left: hz.x - hz.size / 2,
      top: hz.y - hz.size / 2,
      child: Transform.rotate(
        angle: hz.y * 0.03,
        child: Container(
          width: hz.size,
          height: hz.size,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B3B),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
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
            'Dodge',
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
