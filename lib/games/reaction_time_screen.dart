import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Reflex test: wait for the screen to turn green, then tap as fast as you can.
class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

enum _Phase { idle, waiting, ready, early, result }

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  _Phase _phase = _Phase.idle;
  Timer? _goTimer;
  DateTime? _greenAt;
  int? _lastMs;
  int? _bestMs;
  final Random _rng = Random();

  @override
  void dispose() {
    _goTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.result:
      case _Phase.early:
        _startWaiting();
      case _Phase.waiting:
        // Tapped too early.
        _goTimer?.cancel();
        setState(() => _phase = _Phase.early);
      case _Phase.ready:
        final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
        setState(() {
          _lastMs = ms;
          if (_bestMs == null || ms < _bestMs!) _bestMs = ms;
          _phase = _Phase.result;
        });
    }
  }

  void _startWaiting() {
    setState(() => _phase = _Phase.waiting);
    final delay = 1200 + _rng.nextInt(3000); // 1.2s – 4.2s
    _goTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _greenAt = DateTime.now();
        _phase = _Phase.ready;
      });
    });
  }

  Color get _bg {
    switch (_phase) {
      case _Phase.ready:
        return const Color(0xFF2ECC71); // green: tap now
      case _Phase.waiting:
        return const Color(0xFFC0392B); // red: wait
      case _Phase.early:
        return const Color(0xFF8E44AD); // purple: too soon
      case _Phase.idle:
      case _Phase.result:
        return AppColors.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _bg,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _content(),
                    ),
                  ),
                ),
                if (_bestMs != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Best: $_bestMs ms',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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

  Widget _content() {
    final (title, subtitle) = switch (_phase) {
      _Phase.idle => ('Reaction Time', 'Tap anywhere to start'),
      _Phase.waiting => ('Wait for green…', "Don't tap yet!"),
      _Phase.ready => ('TAP!', 'Go go go'),
      _Phase.early => ('Too soon! 😅', 'Tap to try again'),
      _Phase.result => ('$_lastMs ms', 'Tap to try again'),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: _phase == _Phase.result ? 64 : 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
