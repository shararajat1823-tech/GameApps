import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Grand Prix — an original pseudo-3D Formula racing game. The circuit is built
/// from perspective-projected segments (curves + crests), with red/white kerbs,
/// an open-wheel car, oncoming field to pass, and a full racing HUD (gear,
/// speed, lap, position, lap times, DRS). Drawn with CustomPainter — no 3D
/// engine, no image assets, and no real-world F1 teams, liveries or logos.
class RacerScreen extends StatefulWidget {
  const RacerScreen({super.key});

  @override
  State<RacerScreen> createState() => _RacerScreenState();
}

// --- Tuning constants (world units) ---------------------------------------
const double _segLen = 200;
const int _segCount = 600;
const double _roadWidth = 2000;
const int _rumble = 3; // segments per kerb colour band
const double _camHeight = 1200;
const double _camDepth = 0.84;
const int _drawDistance = 160;
const double _trackLength = _segCount * _segLen;
const double _dt = 1 / 60;
const double _maxSpeed = _segLen / _dt; // one segment per frame
const double _centrifugal = 0.32;
const int _gridSize = 20; // cars in the field

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
  int sprite = 0; // 0 none, 1 tree, 2 grandstand, 3 billboard, 4 pole
  double spriteSide = 1; // -1 left, +1 right
  bool get dark => (index ~/ _rumble) % 2 == 0;
}

class _Car {
  _Car(this.z, this.offset, this.speed, this.color);
  double z;
  final double offset; // lateral -0.8..0.8 (fraction of road half-width)
  final double speed;
  final Color color;
}

class _RacerScreenState extends State<RacerScreen> {
  final List<_Seg> _segments = [];
  final List<_Car> _field = [];
  final Random _rng = Random();
  Timer? _timer;

  double _position = 0;
  double _playerX = 0;
  double _speed = 0;
  int _steer = 0;
  double _shake = 0;
  bool _started = false;

  // Racing state
  int _lap = 1;
  double _lapTimeSec = 0;
  double? _bestLapSec;
  int _racePos = _gridSize + 1;
  bool _drs = false;

  @override
  void initState() {
    super.initState();
    _buildTrack();
    _buildField();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _buildTrack() {
    _segments.clear();
    for (int i = 0; i < _segCount; i++) {
      final curve = 2.6 * sin(i * 0.035) + 1.4 * sin(i * 0.0125);
      final y1 = 2600 * sin(i * 0.022);
      final y2 = 2600 * sin((i + 1) * 0.022);
      final seg = _Seg(i, curve, y1, y2);
      // Scatter roadside scenery for depth and a sense of speed.
      if (i % 6 == 0) {
        seg.spriteSide = _rng.nextBool() ? -1 : 1;
        final r = _rng.nextDouble();
        if (r < 0.55) {
          seg.sprite = 1; // tree
        } else if (r < 0.72) {
          seg.sprite = 4; // pole
        } else if (r < 0.9) {
          seg.sprite = 3; // billboard
        } else {
          seg.sprite = 2; // grandstand
        }
      }
      _segments.add(seg);
    }
  }

  void _buildField() {
    _field.clear();
    // Original team colours (not tied to any real team).
    const colors = [
      Color(0xFF2EC4B6),
      Color(0xFFE71D36),
      Color(0xFFFF9F1C),
      Color(0xFF8338EC),
      Color(0xFF06D6A0),
      Color(0xFFEDEDED),
    ];
    for (int i = 0; i < _gridSize; i++) {
      final z = (i + 1) * (_trackLength / (_gridSize + 2));
      final offset = (_rng.nextDouble() * 1.4) - 0.7;
      final speed = _maxSpeed * (0.45 + _rng.nextDouble() * 0.22);
      _field.add(_Car(z, offset, speed, colors[i % colors.length]));
    }
  }

  void _start() {
    _position = 0;
    _playerX = 0;
    _speed = 0;
    _shake = 0;
    _lap = 1;
    _lapTimeSec = 0;
    _bestLapSec = null;
    _racePos = _gridSize + 1;
    _started = true;
    _buildField();
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
      _playerX -= dx * speedPercent * baseSeg.curve * _centrifugal;

      // DRS: on a straight at speed you get a top-end boost.
      _drs = baseSeg.curve.abs() < 0.7 && speedPercent > 0.55;
      final targetMax = _drs ? _maxSpeed * 1.08 : _maxSpeed;

      _speed += _maxSpeed * 0.95 * _dt;
      final offRoad = _playerX.abs() > 1;
      if (offRoad && _speed > _maxSpeed * 0.35) {
        _speed -= _maxSpeed * 1.7 * _dt;
        _shake = 6;
      }
      _speed = _speed.clamp(0, targetMax);
      _playerX = _playerX.clamp(-2.4, 2.4);

      final prev = _position;
      _position = (prev + _speed * _dt) % _trackLength;
      if (_position < prev) {
        // Completed a lap.
        if (_lapTimeSec > 1 &&
            (_bestLapSec == null || _lapTimeSec < _bestLapSec!)) {
          _bestLapSec = _lapTimeSec;
        }
        _lap++;
        _lapTimeSec = 0;
      }
      _lapTimeSec += _dt;

      for (final car in _field) {
        car.z = (car.z + car.speed * _dt) % _trackLength;
      }

      // Collision with a car just ahead.
      for (final car in _field) {
        var ahead = car.z - _position;
        if (ahead < 0) ahead += _trackLength;
        if (ahead < _segLen * 1.6 && (_playerX - car.offset).abs() < 0.7) {
          _speed = _maxSpeed * 0.2;
          _shake = 14;
          break;
        }
      }

      // Race position = 1 + cars ahead within the front half of the lap.
      int ahead = 0;
      for (final car in _field) {
        final g = ((car.z - _position + _trackLength * 1.5) % _trackLength) -
            _trackLength * 0.5;
        if (g > 0) ahead++;
      }
      _racePos = (ahead + 1).clamp(1, _gridSize + 1);

      if (_shake > 0) _shake -= 0.6;
    });
  }

  void _setSteer(Offset local, double width) {
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
        color: const Color(0xFF0A1A2F),
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
                      onPointerDown: (e) => _setSteer(e.localPosition, size.width),
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
                              field: _field,
                              position: _position,
                              playerX: _playerX,
                              shake: _shake,
                              steer: _steer,
                              drs: _drs,
                              speedPercent: _speed / _maxSpeed,
                            ),
                          ),
                          _hud(),
                          if (!_started) _overlay(),
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

  // ---- HUD ----------------------------------------------------------------

  String _fmt(double? sec) {
    if (sec == null) return '--.---';
    return sec.toStringAsFixed(3);
  }

  int get _gear => _started ? (1 + (_speed / _maxSpeed * 7)).round().clamp(1, 8) : 1;

  Widget _hud() {
    final kmh = (_speed / _maxSpeed * 340).round();
    return Stack(
      children: [
        // Top-left: lap + position.
        Positioned(
          left: 14,
          top: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pill('LAP  $_lap', AppColors.gold),
              const SizedBox(height: 8),
              _pill('P$_racePos', Colors.white, big: true),
            ],
          ),
        ),
        // Top-right: lap times.
        Positioned(
          right: 14,
          top: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _timeRow('LAP', _fmt(_lapTimeSec), Colors.white),
              const SizedBox(height: 6),
              _timeRow('BEST', _fmt(_bestLapSec), AppColors.gold),
            ],
          ),
        ),
        // DRS indicator.
        if (_drs)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DRS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        // Bottom-right: gear + speed.
        Positioned(
          right: 16,
          bottom: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  const Text('GEAR',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('$_gear',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                ],
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$kmh',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                  const Text('km/h',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color, {bool big = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 6 : 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: big ? 26 : 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _timeRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('$label ',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [])),
        ],
      ),
    );
  }

  Widget _overlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Tap to start\nHold left / right to steer',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
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
            'Grand Prix',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.w800,
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
    required this.field,
    required this.position,
    required this.playerX,
    required this.shake,
    required this.steer,
    required this.drs,
    required this.speedPercent,
  });

  final List<_Seg> segments;
  final List<_Car> field;
  final double position;
  final double playerX;
  final double shake;
  final int steer;
  final bool drs;
  final double speedPercent;

  // Circuit colours.
  static const _grassLight = Color(0xFF3BA55D);
  static const _grassDark = Color(0xFF2F9150);
  static const _roadLight = Color(0xFF44474E);
  static const _roadDark = Color(0xFF3C3F46);
  static const _kerbLight = Color(0xFFF2F2F2);
  static const _kerbDark = Color(0xFFE63946);
  static const _line = Color(0xFFEDEDED);

  void _project(_P p, double camX, double camY, double camZ, Size size) {
    final dz = p.wz - camZ;
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
    if (shake > 0) canvas.translate((rnd.nextDouble() - 0.5) * shake, 0);

    _paintSky(canvas, size);

    final baseIndex = (position / _segLen).floor() % _segCount;
    final baseSeg = segments[baseIndex];
    final percent = (position % _segLen) / _segLen;
    final camY = _camHeight + _lerp(baseSeg.p1.wy, baseSeg.p2.wy, percent);

    double x = 0;
    double dx = -(baseSeg.curve * percent);
    double maxy = size.height;
    final visible = <int>{};
    // Scenery to draw after the road: (screenX, groundY, scale, type).
    final scenery = <(double, double, double, int)>[];

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
      if (seg.sprite != 0) {
        final sScale = seg.p1.scale;
        final sx = seg.p1.sx +
            sScale * (seg.spriteSide * _roadWidth * 1.25) * size.width / 2;
        scenery.add((sx, seg.p1.sy, sScale, seg.sprite));
      }
      visible.add(idx);
      maxy = seg.p2.sy;
    }

    // Draw scenery far-to-near so nearer objects overlap distant ones.
    scenery.sort((a, b) => a.$3.compareTo(b.$3));
    for (final s in scenery) {
      _drawScenery(canvas, size, s.$1, s.$2, s.$3, s.$4);
    }

    for (final car in field) {
      final carIdx = ((car.z / _segLen).floor()) % _segCount;
      if (!visible.contains(carIdx)) continue;
      final seg = segments[carIdx];
      if (seg.p1.sw <= 2) continue;
      final cx = seg.p1.sx + car.offset * seg.p1.sw;
      final cw = seg.p1.sw * 0.5;
      if (cw < 3) continue;
      _drawFieldCar(canvas, cx, seg.p1.sy, cw, car.color);
    }

    _drawPlayerCar(canvas, size);

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        stops: const [0.74, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);

    // Speed lines streaking outward when travelling fast.
    if (speedPercent > 0.6) {
      final rnd2 = Random(7);
      final alpha = ((speedPercent - 0.6) / 0.4).clamp(0.0, 1.0) * 0.5;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 2;
      final cx = size.width / 2;
      final cy = size.height * 0.62;
      for (int i = 0; i < 12; i++) {
        final ang = rnd2.nextDouble() * 2 * pi;
        final r0 = size.width * (0.5 + rnd2.nextDouble() * 0.2);
        final r1 = r0 + size.width * 0.18;
        canvas.drawLine(
          Offset(cx + cos(ang) * r0, cy + sin(ang) * r0),
          Offset(cx + cos(ang) * r1, cy + sin(ang) * r1),
          paint,
        );
      }
    }

    canvas.restore();
  }

  void _paintSky(Canvas canvas, Size size) {
    final horizon = size.height * 0.5;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C6FB5), Color(0xFF6FB7E8), Color(0xFFBFE3F5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizon));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizon), sky);

    // Distant hill silhouette along the horizon.
    final hills = Path()..moveTo(0, horizon);
    for (double hx = 0; hx <= size.width; hx += size.width / 6) {
      hills.quadraticBezierTo(
        hx + size.width / 12,
        horizon - 34 - 14 * sin(hx * 0.9),
        hx + size.width / 6,
        horizon,
      );
    }
    hills
      ..lineTo(size.width, horizon)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF2B6E45));

    // A few soft clouds.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.75);
    void puff(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx, cy), r, cloud);
    puff(size.width * 0.2, horizon * 0.4, 16);
    puff(size.width * 0.26, horizon * 0.4, 22);
    puff(size.width * 0.32, horizon * 0.42, 15);
    puff(size.width * 0.72, horizon * 0.28, 14);
    puff(size.width * 0.78, horizon * 0.3, 20);
    puff(size.width * 0.84, horizon * 0.31, 13);
  }

  void _renderSegment(Canvas c, Size size, _Seg seg) {
    final p1 = seg.p1;
    final p2 = seg.p2;
    final grass = seg.dark ? _grassDark : _grassLight;
    final road = seg.dark ? _roadDark : _roadLight;
    final kerb = seg.dark ? _kerbDark : _kerbLight;

    c.drawRect(Rect.fromLTRB(0, p2.sy, size.width, p1.sy), Paint()..color = grass);

    _poly(c, road, p1.sx - p1.sw, p1.sy, p1.sx + p1.sw, p1.sy, p2.sx + p2.sw,
        p2.sy, p2.sx - p2.sw, p2.sy);

    final r1 = p1.sw * 0.16;
    final r2 = p2.sw * 0.16;
    _poly(c, kerb, p1.sx - p1.sw - r1, p1.sy, p1.sx - p1.sw, p1.sy,
        p2.sx - p2.sw, p2.sy, p2.sx - p2.sw - r2, p2.sy);
    _poly(c, kerb, p1.sx + p1.sw + r1, p1.sy, p1.sx + p1.sw, p1.sy,
        p2.sx + p2.sw, p2.sy, p2.sx + p2.sw + r2, p2.sy);

    // Dashed centre line on light bands.
    if (!seg.dark) {
      final l1 = p1.sw * 0.02;
      final l2 = p2.sw * 0.02;
      _poly(c, _line, p1.sx - l1, p1.sy, p1.sx + l1, p1.sy, p2.sx + l2, p2.sy,
          p2.sx - l2, p2.sy);
    }
  }

  void _drawFieldCar(Canvas c, double x, double y, double w, Color color) {
    final bodyW = w * 0.34;
    final bodyH = w * 0.78;
    final top = y - bodyH;
    final tyre = Paint()..color = const Color(0xFF15151A);

    // Rear tyres.
    final tW = w * 0.22;
    final tH = bodyH * 0.5;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - w * 0.5, y - tH, tW, tH), Radius.circular(tW * 0.3)),
        tyre);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + w * 0.5 - tW, y - tH, tW, tH),
            Radius.circular(tW * 0.3)),
        tyre);

    // Body.
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x - bodyW / 2, top, bodyW, bodyH), Radius.circular(w * 0.08)),
      Paint()..color = color,
    );
    // Rear wing.
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x - w * 0.42, top - w * 0.06, w * 0.84, w * 0.1),
          Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFF1F1F27),
    );
  }

  void _drawScenery(
      Canvas c, Size size, double x, double groundY, double scale, int type) {
    final unit = scale * size.width / 2; // world unit -> pixels
    if (unit <= 0 || unit * 200 < 1.5) return; // too far to matter
    switch (type) {
      case 1:
        _tree(c, x, groundY, unit);
      case 2:
        _grandstand(c, x, groundY, unit);
      case 3:
        _billboard(c, x, groundY, unit);
      case 4:
        _pole(c, x, groundY, unit);
    }
  }

  void _tree(Canvas c, double x, double groundY, double u) {
    final trunkW = 150 * u;
    final trunkH = 700 * u;
    c.drawRect(
      Rect.fromLTWH(x - trunkW / 2, groundY - trunkH, trunkW, trunkH),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    final r = 780 * u;
    final cy = groundY - trunkH - r * 0.7;
    final leaf = Paint()..color = const Color(0xFF2E7D32);
    final leafHi = Paint()..color = const Color(0xFF43A047);
    c.drawCircle(Offset(x - r * 0.5, cy + r * 0.2), r * 0.7, leaf);
    c.drawCircle(Offset(x + r * 0.5, cy + r * 0.2), r * 0.7, leaf);
    c.drawCircle(Offset(x, cy - r * 0.25), r * 0.8, leafHi);
  }

  void _pole(Canvas c, double x, double groundY, double u) {
    final w = 90 * u;
    final h = 2600 * u;
    c.drawRect(Rect.fromLTWH(x - w / 2, groundY - h, w, h),
        Paint()..color = const Color(0xFFBFC4CC));
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x - w * 2, groundY - h, w * 4, w * 1.4),
          Radius.circular(w * 0.4)),
      Paint()..color = const Color(0xFF8A9099),
    );
  }

  void _billboard(Canvas c, double x, double groundY, double u) {
    final postH = 1200 * u;
    final post = Paint()..color = const Color(0xFF9AA0A8);
    c.drawRect(Rect.fromLTWH(x - 520 * u, groundY - postH, 120 * u, postH), post);
    c.drawRect(Rect.fromLTWH(x + 400 * u, groundY - postH, 120 * u, postH), post);
    final panelW = 2600 * u;
    final panelH = 1300 * u;
    final top = groundY - postH - panelH * 0.75;
    final panel = Rect.fromCenter(
        center: Offset(x, top + panelH / 2), width: panelW, height: panelH);
    c.drawRRect(
      RRect.fromRectAndRadius(panel, Radius.circular(60 * u)),
      Paint()..color = const Color(0xFF1E6CE0),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(panel.deflate(70 * u), Radius.circular(40 * u)),
      Paint()..color = const Color(0xFF0B2E73),
    );
    if (panelW > 60) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'GP',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: panelH * 0.55,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(x - tp.width / 2, top + panelH * 0.2));
    }
  }

  void _grandstand(Canvas c, double x, double groundY, double u) {
    final w = 5200 * u;
    final h = 1500 * u;
    final rect = Rect.fromLTWH(x - w / 2, groundY - h, w, h);
    c.drawRect(rect, Paint()..color = const Color(0xFF55606E));
    // Crowd stripes.
    const crowd = [Color(0xFFE63946), Color(0xFFF1FAEE), Color(0xFF457B9D)];
    final rows = 5;
    for (int i = 0; i < rows; i++) {
      final ry = groundY - h + (h / rows) * i;
      c.drawRect(
        Rect.fromLTWH(x - w / 2, ry, w, h / rows * 0.7),
        Paint()..color = crowd[i % crowd.length].withValues(alpha: 0.85),
      );
    }
    // Roof.
    c.drawRect(
      Rect.fromLTWH(x - w / 2 - 120 * u, groundY - h - 260 * u, w + 240 * u, 300 * u),
      Paint()..color = const Color(0xFF2B3240),
    );
  }

  void _drawPlayerCar(Canvas canvas, Size size) {
    final w = size.width * 0.42;
    final cx = size.width / 2 + steer * w * 0.06;
    final baseY = size.height - 16;

    final bodyW = w * 0.3;
    final bodyH = w * 0.62;
    final bodyTop = baseY - bodyH;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, baseY), width: w * 1.0, height: bodyH * 0.22),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final tyrePaint = Paint()..color = const Color(0xFF17171C);
    final tyreW = w * 0.2;
    final tyreH = bodyH * 0.62;

    // Front tyres (slightly forward/smaller, drawn first/behind).
    final fTyreW = tyreW * 0.82;
    final fTyreH = tyreH * 0.8;
    final fy = baseY - bodyH * 0.72;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.44, fy - fTyreH, fTyreW, fTyreH),
            Radius.circular(fTyreW * 0.3)),
        tyrePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + w * 0.44 - fTyreW, fy - fTyreH, fTyreW, fTyreH),
            Radius.circular(fTyreW * 0.3)),
        tyrePaint);

    // Front wing.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.4, baseY - bodyH * 0.14, w * 0.8, bodyH * 0.1),
          Radius.circular(w * 0.02)),
      Paint()..color = const Color(0xFF1C1C24),
    );

    // Rear tyres.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.5, baseY - tyreH, tyreW, tyreH),
            Radius.circular(tyreW * 0.28)),
        tyrePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + w * 0.5 - tyreW, baseY - tyreH, tyreW, tyreH),
            Radius.circular(tyreW * 0.28)),
        tyrePaint);

    // Body (nose to engine cover) — original blue/gold livery.
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E6CE0), Color(0xFF0B2E73)],
        ).createShader(bodyRect.outerRect),
    );
    // Gold centre stripe.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyW * 0.12, bodyTop, bodyW * 0.24, bodyH),
          Radius.circular(w * 0.02)),
      Paint()..color = AppColors.gold.withValues(alpha: 0.9),
    );

    // Cockpit + halo.
    canvas.drawCircle(Offset(cx, bodyTop + bodyH * 0.42), bodyW * 0.26,
        Paint()..color = const Color(0xFF101017));
    final halo = Paint()
      ..color = const Color(0xFF0B0B10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(cx, bodyTop + bodyH * 0.5), radius: bodyW * 0.34),
        pi,
        pi,
        false,
        halo);

    // Rear wing with endplates.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.36, bodyTop - w * 0.02, w * 0.72, w * 0.07),
          Radius.circular(w * 0.015)),
      Paint()..color = const Color(0xFF1A1A22),
    );
    // DRS flap glows green when open.
    if (drs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.3, bodyTop - w * 0.02, w * 0.6, w * 0.02),
            Radius.circular(w * 0.01)),
        Paint()..color = const Color(0xFF00E676),
      );
    }

    // Rear light.
    canvas.drawCircle(
      Offset(cx, baseY - bodyH * 0.04),
      w * 0.03,
      Paint()
        ..color = const Color(0xFFFF3B3B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Car number.
    final tp = TextPainter(
      text: TextSpan(
        text: '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: bodyW * 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, bodyTop + bodyH * 0.6));
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}
