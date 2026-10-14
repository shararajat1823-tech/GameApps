import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A calm, endless game: soft bubbles drift upward and you tap to pop them.
/// No timer, no losing — just relaxing.
class BubblePopScreen extends StatefulWidget {
  const BubblePopScreen({super.key});

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _Bubble {
  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final Color color;
}

class _BubblePopScreenState extends State<BubblePopScreen> {
  static const List<Color> _palette = [
    Color(0xFF7FB2F0), // soft blue
    Color(0xFFF2C14E), // gold
    Color(0xFF9AD0C2), // mint
    Color(0xFFE6A6C7), // pink
    Color(0xFFB7A7E0), // lavender
  ];

  final List<_Bubble> _bubbles = [];
  final Random _rng = Random();
  Timer? _timer;
  Size _area = Size.zero;
  int _popped = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_area == Size.zero) return;
    setState(() {
      for (final b in _bubbles) {
        b.y -= b.speed;
      }
      _bubbles.removeWhere((b) => b.y + b.size < 0);

      // Occasionally spawn a new bubble from the bottom.
      if (_bubbles.length < 14 && _rng.nextDouble() < 0.18) {
        final size = 44 + _rng.nextDouble() * 46;
        _bubbles.add(
          _Bubble(
            x: _rng.nextDouble() * (_area.width - size),
            y: _area.height,
            size: size,
            speed: 1.2 + _rng.nextDouble() * 1.8,
            color: _palette[_rng.nextInt(_palette.length)],
          ),
        );
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    final p = details.localPosition;
    // Pop the top-most bubble under the finger.
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      final center = Offset(b.x + b.size / 2, b.y + b.size / 2);
      if ((p - center).distance <= b.size / 2) {
        setState(() {
          _bubbles.removeAt(i);
          _popped++;
        });
        break;
      }
    }
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _area = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _onTapDown,
                      child: Stack(
                        children: [
                          for (final b in _bubbles)
                            Positioned(
                              left: b.x,
                              top: b.y,
                              child: _bubbleView(b),
                            ),
                          if (_bubbles.isEmpty)
                            const Center(
                              child: Text(
                                'Tap the bubbles to pop them…',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleView(_Bubble b) {
    return Container(
      width: b.size,
      height: b.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            b.color.withValues(alpha: 0.75),
            b.color.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.45, 1.0],
          center: const Alignment(-0.3, -0.3),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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
            'Bubble Pop',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            'Popped: $_popped',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
