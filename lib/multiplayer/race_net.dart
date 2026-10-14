import 'dart:async';
import 'dart:math';

/// One racer's live state, shared with the room.
class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    required this.carColor,
    this.position = 0,
    this.lateralX = 0,
    this.speed = 0,
    this.lap = 1,
    this.ready = false,
    this.finished = false,
  });

  final String id;
  final String name;
  final int carColor; // ARGB
  double position; // along the track
  double lateralX; // -2.4..2.4
  double speed;
  int lap;
  bool ready;
  bool finished;
}

/// The shared state of a race room.
class RoomState {
  RoomState({
    required this.code,
    required this.hostId,
    required this.players,
    this.started = false,
  });

  final String code;
  final String hostId;
  final Map<String, PlayerState> players;
  bool started;
}

/// Networking contract for multiplayer racing. A Firebase-backed implementation
/// will replace the local stub once the backend is configured — the lobby and
/// race UI depend only on this interface, so nothing above it has to change.
abstract class RaceNet {
  String get myId;
  bool get isHost;
  RoomState? get room;

  /// Emits whenever anyone in the room changes (joins, readies, moves).
  Stream<RoomState> get updates;

  Future<void> createRoom(String name);
  Future<void> joinRoom(String code, String name);
  Future<void> setReady(bool ready);
  Future<void> startRace();

  /// Push my car state to the room (called frequently while racing).
  void sendState(double position, double lateralX, double speed, int lap);

  Future<void> leave();
}

/// A single-device stub so the lobby/race UI works before the online backend
/// is wired in. It holds one real player (you); remote players appear once the
/// Firebase implementation is connected.
class LocalRaceNet implements RaceNet {
  final _controller = StreamController<RoomState>.broadcast();
  final _rng = Random();
  RoomState? _room;

  @override
  final String myId = 'you';

  @override
  bool get isHost => _room?.hostId == myId;

  @override
  RoomState? get room => _room;

  @override
  Stream<RoomState> get updates => _controller.stream;

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  void _emit() {
    if (_room != null) _controller.add(_room!);
  }

  @override
  Future<void> createRoom(String name) async {
    final me = PlayerState(id: myId, name: name, carColor: 0xFF1E6CE0);
    _room = RoomState(code: _genCode(), hostId: myId, players: {myId: me});
    _emit();
  }

  @override
  Future<void> joinRoom(String code, String name) async {
    final me = PlayerState(id: myId, name: name, carColor: 0xFF2EC4B6);
    // Offline stub: no real host, so we stand in as host of this code.
    _room = RoomState(code: code, hostId: myId, players: {myId: me});
    _emit();
  }

  @override
  Future<void> setReady(bool ready) async {
    _room?.players[myId]?.ready = ready;
    _emit();
  }

  @override
  Future<void> startRace() async {
    _room?.started = true;
    _emit();
  }

  @override
  void sendState(double position, double lateralX, double speed, int lap) {
    final me = _room?.players[myId];
    if (me != null) {
      me
        ..position = position
        ..lateralX = lateralX
        ..speed = speed
        ..lap = lap;
    }
  }

  @override
  Future<void> leave() async {
    _room = null;
    await _controller.close();
  }
}
