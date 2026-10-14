import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Simon: watch the growing color sequence, then repeat it from memory.
class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  static const List<Color> _colors = [
    Color(0xFF2ECC71), // green
    Color(0xFFE74C3C), // red
    Color(0xFFF1C40F), // yellow
    Color(0xFF3498DB), // blue
  ];

  final List<int> _sequence = [];
  final Random _rng = Random();
  int _playerIndex = 0;
  int? _active;
  bool _inputLocked = true;
  bool _started = false;
  bool _gameOver = false;
  int _best = 0;

  int get _level => _sequence.length;

  Future<void> _startGame() async {
    setState(() {
      _sequence.clear();
      _playerIndex = 0;
      _gameOver = false;
      _started = true;
    });
    await _addAndPlay();
  }

  Future<void> _addAndPlay() async {
    _sequence.add(_rng.nextInt(4));
    _playerIndex = 0;
    await _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() => _inputLocked = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    for (final pad in _sequence) {
      if (!mounted) return;
      setState(() => _active = pad);
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() => _active = null);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() => _inputLocked = false);
  }

  Future<void> _onPad(int pad) async {
    if (_inputLocked || _gameOver || !_started) return;

    // Quick visual feedback for the press.
    setState(() => _active = pad);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _active = null);

    if (pad != _sequence[_playerIndex]) {
      setState(() {
        _gameOver = true;
        _inputLocked = true;
        if (_level - 1 > _best) _best = _level - 1;
      });
      return;
    }

    _playerIndex++;
    if (_playerIndex == _sequence.length) {
      if (_level > _best) _best = _level;
      setState(() => _inputLocked = true);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _addAndPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status;
    if (!_started) {
      status = 'Watch, then repeat the pattern';
    } else if (_gameOver) {
      status = 'Game Over — you reached level ${_level - 1}';
    } else if (_inputLocked) {
      status = 'Watch…';
    } else {
      status = 'Your turn — level $_level';
    }

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
                    _chip('LEVEL', '$_level'),
                    _chip('BEST', '$_best'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: Center(child: _pads())),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _inputLocked && _started && !_gameOver
                        ? null
                        : _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.dark,
                      disabledBackgroundColor:
                          AppColors.gold.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      !_started
                          ? 'Start'
                          : (_gameOver ? 'Play Again' : 'Restart'),
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

  Widget _pads() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return SizedBox(
          width: side,
          height: side,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < 4; i++) _pad(i),
            ],
          ),
        );
      },
    );
  }

  Widget _pad(int index) {
    final isActive = _active == index;
    return GestureDetector(
      onTap: () => _onPad(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _colors[index].withValues(alpha: isActive ? 1.0 : 0.45),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _colors[index].withValues(alpha: 0.8),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
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
            'Simon',
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
