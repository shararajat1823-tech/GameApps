import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A pseudo-3D arcade racer (OutRun-style): the road is built from segments
/// projected into perspective, giving real curves, hills, and a sense of
/// speed — all drawn with CustomPainter, no 3D engine or image assets.
class RacerScreen extends StatefulWidget {
  const RacerScreen({super.key});

  @override
  State<RacerScreen> createState() => _RacerScreenState();
}

// --- Tuning constants (world units) ---------------------------------------
const double _segLen = 200;
const int _segCount = 600;
const double _roadWidth = 2000;
const int _rumble = 4; // segments per color band
const double _camHeight = 1200;
const double _camDepth = 0.84;
const int _drawDistance = 160;
const double _trackLength = _segCount * _segLen;
const double _dt = 1 / 60;
const double _maxSpeed = _segLen / _dt; // one segment per frame
const double _centrifugal = 0.32;

class _P {
  double wx = 0, wy = 0, wz = 0; // world
  double sx = 0, sy = 0, sw = 0, scale = 0; // screen
}

class _Seg {
  _Seg(this.index, this.curve, double y1, double y2) {
    p1 = _P()
      ..wz = index * _segLen
      ..wy = y1;
    p2 = _P()
      ..wz = (index + 1) * _segLen
      ..wy = y2;
  }
  final int index;
  final double curve;
  late _P p1;
  late _P p2;
  bool get dark => (index ~/ _rumble) % 2 == 0;
}

class _Car {
  _Car(this.z, this.offset, this.speed, this.color);
  double z;
  final double offset; // lateral -0.8..0.8 (fraction of road half-width)
  final double speed;
  final Color color;
  // transient screen placement for this frame
  double sx = 0, sy = 0, sw = 0;
  bool visible = false;
}

class _RacerScreenState extends State<RacerScreen> {
  final List<_Seg> _segments = [];
  final List<_Car> _traffic = [];
  final Random _rng = Random();
  Timer? _timer;

  double _position = 0; // along track
  double _playerX = 0; // -1..1 road edges (can exceed into grass)
  double _speed = 0;
  int _steer = 0; // -1 left, +1 right, 0 none
  int _score = 0;
  int _best = 0;
  double _shake = 0;
  bool _started = false;
  bool _crashed = false;

  @override
  void initState() {
    super.initState();
    _buildTrack();
    _buildTraffic();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _buildTrack() {
    _segments.clear();
    for (int i = 0; i < _segCount; i++) {
      // Smoothly varying curves and rolling hills.
      final curve = 2.6 * sin(i * 0.035) + 1.4 * sin(i * 0.0125);
      final y1 = 2600 * sin(i * 0.022);
      final y2 = 2600 * sin((i + 1) * 0.022);
      _segments.add(_Seg(i, curve, y1, y2));
    }
  }

  void _buildTraffic() {
    _traffic.clear();
    const colors = [
      Color(0xFF4FC3F7),
      Color(0xFFBA68C8),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFFFFFFF),
    ];
    for (int i = 0; i < 40; i++) {
      final z = _rng.nextDouble() * _trackLength;
      final offset = (_rng.nextDouble() * 1.6) - 0.8;
      final speed = _maxSpeed * (0.2 + _rng.nextDouble() * 0.25);
      _traffic.add(_Car(z, offset, speed, colors[_rng.nextInt(colors.length)]));
    }
  }

  void _start() {
    _position = 0;
    _playerX = 0;
    _speed = 0;
    _score = 0;
    _shake = 0;
    _crashed = false;
    _started = true;
    _buildTraffic();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    setState(() {});
  }

  _Seg _segAt(double z) => _segments[((z / _segLen).floor()) % _segCount];

  void _tick() {
    setState(() {
      final baseSeg = _segAt(_position);
      final speedPercent = _speed / _maxSpeed;
      final dx = _dt * 2.2 * speedPercent;

      if (_steer == -1) _playerX -= dx;
      if (_steer == 1) _playerX += dx;

      // Curve pushes you outward.
      _playerX -= dx * speedPercent * baseSeg.curve * _centrifugal;

      // Auto-accelerate; off-road slows you hard.
      _speed += _maxSpeed * 0.9 * _dt;
      final offRoad = _playerX.abs() > 1;
      if (offRoad && _speed > _maxSpeed * 0.35) {
        _speed -= _maxSpeed * 1.6 * _dt;
        _shake = 6;
      }
      _speed = _speed.clamp(0, _maxSpeed);
      _playerX = _playerX.clamp(-2.4, 2.4);

      _position = (_position + _speed * _dt) % _trackLength;

      // Move traffic forward along the track.
      for (final car in _traffic) {
        car.z = (car.z + car.speed * _dt) % _trackLength;
      }

      // Collision: a car just ahead of us, overlapping laterally.
      for (final car in _traffic) {
        var ahead = car.z - _position;
        if (ahead < 0) ahead += _trackLength;
        if (ahead < _segLen * 1.6) {
          if ((_playerX - car.offset).abs() < 0.7) {
            _speed = _maxSpeed * 0.18;
            _shake = 14;
            break;
          }
        }
      }

      if (_shake > 0) _shake -= 0.6;
      _score = (_position / _segLen).floor() + 0; // distance-based
      if (_score > _best) _best = _score;
    });
  }

  void _setSteerFromPointer(Offset local, double width) {
    if (!_started) {
      _start();
      return;
    }
    _steer = local.dx < width / 2 ? -1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1A1030),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) =>
                          _setSteerFromPointer(e.localPosition, size.width),
                      onPointerMove: (e) {
                        if (_started) {
                          _steer = e.localPosition.dx < size.width / 2 ? -1 : 1;
                        }
                      },
                      onPointerUp: (_) => _steer = 0,
                      onPointerCancel: (_) => _steer = 0,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: _RoadPainter(
                              segments: _segments,
                              traffic: _traffic,
                              position: _position,
                              playerX: _playerX,
                              speed: _speed,
                              shake: _shake,
                              steer: _steer,
                            ),
                          ),
                          if (!_started) _overlay(),
                          _speedHud(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _controlsHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          _crashed ? 'Tap to race again' : 'Tap to start\nLeft / right side to steer',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _speedHud() {
    final kmh = (_speed / _maxSpeed * 260).round();
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$kmh',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Text(
            'km/h',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _controlsHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        'Hold left half = steer left   •   right half = steer right',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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
            'Neon Racer',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            'Dist: $_score    Best: $_best',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.segments,
    required this.traffic,
    required this.position,
    required this.playerX,
    required this.speed,
    required this.shake,
    required this.steer,
  });

  final List<_Seg> segments;
  final List<_Car> traffic;
  final double position;
  final double playerX;
  final double speed;
  final double shake;
  final int steer;

  // Colors
  static const _grassLight = Color(0xFF2A2140);
  static const _grassDark = Color(0xFF241B38);
  static const _roadLight = Color(0xFF3C3C48);
  static const _roadDark = Color(0xFF34343F);
  static const _rumbleLight = Color(0xFFECECF4);
  static const _rumbleDark = Color(0xFFD23A5A);
  static const _lane = Color(0xFFE6E6EE);

  void _project(_P p, double camX, double camY, double camZ, Size size) {
    final dz = (p.wz - camZ);
    p.scale = _camDepth / dz;
    p.sx = size.width / 2 + p.scale * (p.wx - camX) * size.width / 2;
    p.sy = size.height / 2 - p.scale * (p.wy - camY) * size.height / 2;
    p.sw = p.scale * _roadWidth * size.width / 2;
  }

  void _poly(Canvas c, Color color, double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4) {
    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(x4, y4)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(1);
    canvas.save();
    if (shake > 0) {
      canvas.translate((rnd.nextDouble() - 0.5) * shake, 0);
    }

    _paintSky(canvas, size);

    final baseIndex = (position / _segLen).floor() % _segCount;
    final baseSeg = segments[baseIndex];
    final percent = (position % _segLen) / _segLen;
    final camY = _camHeight + _lerp(baseSeg.p1.wy, baseSeg.p2.wy, percent);

    double x = 0;
    double dx = -(baseSeg.curve * percent);
    double maxy = size.height;

    final visibleByIndex = <int>{};

    for (int n = 0; n < _drawDistance; n++) {
      final idx = (baseIndex + n) % _segCount;
      final seg = segments[idx];
      final looped = idx < baseIndex;
      final camZ = position - (looped ? _trackLength : 0);

      _project(seg.p1, playerX * _roadWidth - x, camY, camZ, size);
      _project(seg.p2, playerX * _roadWidth - x - dx, camY, camZ, size);

      x += dx;
      dx += seg.curve;

      if ((seg.p1.wz - camZ) <= _camDepth || seg.p2.sy >= maxy) continue;

      _renderSegment(canvas, size, seg);
      visibleByIndex.add(idx);
      maxy = seg.p2.sy;
    }

    // Traffic — draw each visible car using its segment's projection.
    for (final car in traffic) {
      final carIdx = ((car.z / _segLen).floor()) % _segCount;
      if (!visibleByIndex.contains(carIdx)) continue;
      final seg = segments[carIdx];
      if (seg.p1.sw <= 0) continue;
      final cx = seg.p1.sx + car.offset * seg.p1.sw;
      final cy = seg.p1.sy;
      final cw = seg.p1.sw * 0.55;
      if (cw < 2) continue;
      _drawTrafficCar(canvas, cx, cy, cw, car.color);
    }

    _drawPlayerCar(canvas, size);

    // Vignette for depth.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
        stops: const [0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);

    canvas.restore();
  }

  void _paintSky(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241A4D), Color(0xFF7A3B8F), Color(0xFFF0754B)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.62));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.62), sky);

    // Sun.
    final sunY = size.height * 0.42;
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE08A), const Color(0xFFFFB04A).withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, sunY), radius: size.width * 0.28));
    canvas.drawCircle(Offset(size.width / 2, sunY), size.width * 0.28, sunPaint);
    canvas.drawCircle(Offset(size.width / 2, sunY), size.width * 0.14,
        Paint()..color = const Color(0xFFFFE6A0));
  }

  void _renderSegment(Canvas c, Size size, _Seg seg) {
    final p1 = seg.p1;
    final p2 = seg.p2;
    final grass = seg.dark ? _grassDark : _grassLight;
    final road = seg.dark ? _roadDark : _roadLight;
    final rumble = seg.dark ? _rumbleDark : _rumbleLight;

    // Grass band.
    c.drawRect(
      Rect.fromLTRB(0, p2.sy, size.width, p1.sy),
      Paint()..color = grass,
    );

    // Road.
    _poly(c, road, p1.sx - p1.sw, p1.sy, p1.sx + p1.sw, p1.sy, p2.sx + p2.sw,
        p2.sy, p2.sx - p2.sw, p2.sy);

    // Rumble strips.
    final r1 = p1.sw * 0.14;
    final r2 = p2.sw * 0.14;
    _poly(c, rumble, p1.sx - p1.sw - r1, p1.sy, p1.sx - p1.sw, p1.sy,
        p2.sx - p2.sw, p2.sy, p2.sx - p2.sw - r2, p2.sy);
    _poly(c, rumble, p1.sx + p1.sw + r1, p1.sy, p1.sx + p1.sw, p1.sy,
        p2.sx + p2.sw, p2.sy, p2.sx + p2.sw + r2, p2.sy);

    // Lane markers (only on light bands) — two dividers for 3 lanes.
    if (!seg.dark) {
      final l1 = p1.sw * 0.025;
      final l2 = p2.sw * 0.025;
      for (final frac in const [-0.34, 0.34]) {
        final c1 = p1.sx + frac * p1.sw;
        final c2 = p2.sx + frac * p2.sw;
        _poly(c, _lane, c1 - l1, p1.sy, c1 + l1, p1.sy, c2 + l2, p2.sy,
            c2 - l2, p2.sy);
      }
    }
  }

  void _drawTrafficCar(Canvas c, double x, double y, double w, Color color) {
    final h = w * 0.7;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - w / 2, y - h, w, h),
      Radius.circular(w * 0.15),
    );
    c.drawRRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.35));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2, y - h - 2, w, h),
        Radius.circular(w * 0.15),
      ),
      Paint()..color = color,
    );
    // windshield
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w * 0.32, y - h * 0.9, w * 0.64, h * 0.4),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
  }

  void _drawPlayerCar(Canvas canvas, Size size) {
    final cw = size.width * 0.26;
    final ch = cw * 0.62;
    final cx = size.width / 2 + steer * cw * 0.12;
    final cy = size.height - ch * 0.6 - 10;

    // Shadow / glow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + ch * 0.45), width: cw * 1.1, height: ch * 0.5),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Body.
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch),
      Radius.circular(ch * 0.3),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF5E62), Color(0xFFB00020)],
        ).createShader(bodyRect.outerRect),
    );

    // Rear window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy - ch * 0.18), width: cw * 0.66, height: ch * 0.34),
        Radius.circular(ch * 0.15),
      ),
      Paint()..color = const Color(0xFF14121F),
    );

    // Spoiler.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy - ch * 0.48), width: cw * 0.92, height: ch * 0.12),
        Radius.circular(ch * 0.06),
      ),
      Paint()..color = const Color(0xFF2A2730),
    );

    // Taillights with glow.
    for (final s in const [-1, 1]) {
      final lx = cx + s * cw * 0.33;
      final ly = cy + ch * 0.26;
      canvas.drawCircle(
        Offset(lx, ly),
        cw * 0.08,
        Paint()
          ..color = const Color(0xFFFF3B3B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly), width: cw * 0.16, height: ch * 0.12),
          Radius.circular(ch * 0.04),
        ),
        Paint()..color = const Color(0xFFFF6B6B),
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}
