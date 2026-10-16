import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_session.dart';
import 'game_provider.dart';

enum LiveRole { none, host, viewer }

class LiveState {
  final LiveRole role;
  final String? roomCode;
  final bool isConnected;
  final GameSession? viewerSession;
  final String? error;
  final bool scoresHidden;

  /// Odadan son veri alındığı an — izleyiciye "bayat mı" bilgisi için.
  final DateTime? lastSync;

  /// Manuel yenileme sürerken true.
  final bool isRefreshing;

  const LiveState({
    this.role = LiveRole.none,
    this.roomCode,
    this.isConnected = false,
    this.viewerSession,
    this.error,
    this.scoresHidden = false,
    this.lastSync,
    this.isRefreshing = false,
  });

  bool get isActive => role != LiveRole.none;

  LiveState copyWith({
    LiveRole? role,
    String? roomCode,
    bool? isConnected,
    GameSession? viewerSession,
    String? error,
    bool? scoresHidden,
    DateTime? lastSync,
    bool? isRefreshing,
    bool clearError = false,
    bool clearAll = false,
  }) {
    if (clearAll) return const LiveState();
    return LiveState(
      role: role ?? this.role,
      roomCode: roomCode ?? this.roomCode,
      isConnected: isConnected ?? this.isConnected,
      viewerSession: viewerSession ?? this.viewerSession,
      error: clearError ? null : (error ?? this.error),
      scoresHidden: scoresHidden ?? this.scoresHidden,
      lastSync: lastSync ?? this.lastSync,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class LiveRoomNotifier extends StateNotifier<LiveState> with WidgetsBindingObserver {
  LiveRoomNotifier(this._prefs, this._ref) : super(const LiveState()) {
    WidgetsBinding.instance.addObserver(this);
    _restoreRoom();
  }

  final SharedPreferences _prefs;
  final Ref _ref;

  /// Host'un o anki yerel oturumu — yeniden bağlanmada tek doğru kaynak.
  GameSession? get _localSession => _ref.read(gameSessionProvider);

  /// Host yayınını yerel duruma göre tazeler (kill/resume/reconnect sonrası
  /// Firebase geride kalmış olabilir).
  void _resyncHost() {
    final session = _localSession;
    if (session != null) pushUpdate(session);
  }

  static const _kRoomCode = 'live_room_code';
  static const _kRoomRole = 'live_room_role';

  DatabaseReference? _roomRef;
  StreamSubscription<DatabaseEvent>? _sub;
  StreamSubscription<DatabaseEvent>? _connSub;
  Timer? _retryTimer;
  bool _disposed = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  DatabaseReference _dbRef(String path) => FirebaseDatabase.instance.ref(path);

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // Firebase Maps (LinkedHashMap<Object?,Object?>) → Map<String,dynamic>
  static dynamic _convert(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), _convert(e.value))),
      );
    }
    if (v is List) return v.map(_convert).toList();
    return v;
  }

  // ─────────────────────────────────────────────────────────
  // Kalıcılık: uygulama öldürülüp açılırsa oda kaybolmasın.
  // Host tarafında _roomRef null kalınca yayın tamamen duruyordu.
  // ─────────────────────────────────────────────────────────

  void _persistRoom(String code, LiveRole role) {
    _prefs.setString(_kRoomCode, code);
    _prefs.setString(_kRoomRole, role.name);
  }

  void _clearPersistedRoom() {
    _prefs.remove(_kRoomCode);
    _prefs.remove(_kRoomRole);
  }

  Future<void> _restoreRoom() async {
    final code = _prefs.getString(_kRoomCode);
    final roleName = _prefs.getString(_kRoomRole);
    if (code == null || roleName == null) return;
    if (!_firebaseReady) return;

    final role = LiveRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => LiveRole.none,
    );
    if (role == LiveRole.none) {
      _clearPersistedRoom();
      return;
    }

    final ref = _dbRef('rooms/$code');
    DataSnapshot snap;
    try {
      snap = await ref.get();
    } catch (_) {
      return; // ağ yok; bir sonraki resume'da tekrar denenir
    }

    if (!snap.exists || snap.value == null) {
      _clearPersistedRoom();
      return;
    }

    final data = _convert(snap.value) as Map<String, dynamic>;
    if (data['isActive'] != true) {
      _clearPersistedRoom();
      return;
    }

    _roomRef = ref;

    if (role == LiveRole.host) {
      // Yerelde oyun kalmadıysa oda hayalet — kapat, geri yükleme.
      if (_localSession == null) {
        try {
          await ref.update({'isActive': false});
        } catch (_) {}
        _roomRef = null;
        _clearPersistedRoom();
        return;
      }
      state = state.copyWith(
        role: LiveRole.host,
        roomCode: code,
        isConnected: true,
        scoresHidden: data['scoresHidden'] == true,
        lastSync: DateTime.now(),
      );
      _watchConnection();
      _resyncHost();
      return;
    }

    GameSession? session;
    try {
      session = GameSession.fromJson(data);
    } catch (_) {}
    state = state.copyWith(
      role: LiveRole.viewer,
      roomCode: code,
      isConnected: true,
      viewerSession: session,
      scoresHidden: data['scoresHidden'] == true,
      lastSync: DateTime.now(),
    );
    _attachViewerListener();
    _watchConnection();
  }

  // ─────────────────────────────────────────────────────────
  // Host
  // ─────────────────────────────────────────────────────────

  /// Oda açar, 6 haneli kodu döner (hata olursa null).
  Future<String?> createRoom(GameSession session) async {
    if (!_firebaseReady) {
      state = state.copyWith(error: 'Firebase bağlantısı yok');
      return null;
    }

    final code = _generateCode();
    try {
      _roomRef = _dbRef('rooms/$code');
      await _roomRef!.set({
        ...session.toJson(),
        'isActive': true,
        'scoresHidden': state.scoresHidden,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      _roomRef = null;
      state = state.copyWith(error: 'Oda oluşturulamadı: $e');
      return null;
    }

    _persistRoom(code, LiveRole.host);
    state = state.copyWith(
      role: LiveRole.host,
      roomCode: code,
      isConnected: true,
      lastSync: DateTime.now(),
      clearError: true,
    );
    _watchConnection();
    return code;
  }

  /// Güncel oturumu Firebase'e yazar (sadece host).
  /// Hata yutulmaz: bayrak düşer, resume/yeniden bağlanmada tekrar denenir.
  Future<void> pushUpdate(GameSession session, {bool? scoresHidden}) async {
    if (!_firebaseReady) return;
    if (state.role != LiveRole.host) return;

    // Uygulama öldürülmüşse ref kaybolmuş olabilir — koddan geri kur.
    _roomRef ??= state.roomCode != null ? _dbRef('rooms/${state.roomCode}') : null;
    if (_roomRef == null) return;

    try {
      await _roomRef!.update({
        ...session.toJson(),
        'isActive': true,
        'scoresHidden': scoresHidden ?? state.scoresHidden,
        'lastUpdated': ServerValue.timestamp,
      });
      if (!_disposed) {
        state = state.copyWith(isConnected: true, lastSync: DateTime.now());
      }
    } catch (_) {
      if (!_disposed) state = state.copyWith(isConnected: false);
    }
  }

  /// Sadece gizleme bayrağını yazar.
  Future<void> pushHidden(bool hidden) async {
    state = state.copyWith(scoresHidden: hidden);
    if (!_firebaseReady) return;
    if (state.role != LiveRole.host) return;
    _roomRef ??= state.roomCode != null ? _dbRef('rooms/${state.roomCode}') : null;
    if (_roomRef == null) return;
    try {
      await _roomRef!.update({
        'scoresHidden': hidden,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  // Viewer
  // ─────────────────────────────────────────────────────────

  /// Odaya izleyici olarak katılır. Hata metni döner, başarıda null.
  Future<String?> joinRoom(String code) async {
    if (!_firebaseReady) return 'Firebase bu platformda kullanılamıyor';

    final ref = _dbRef('rooms/$code');
    DataSnapshot snap;
    try {
      snap = await ref.get();
    } catch (_) {
      return 'Bağlantı hatası';
    }

    if (!snap.exists || snap.value == null) return 'Oda bulunamadı';

    final data = _convert(snap.value) as Map<String, dynamic>;
    if (data['isActive'] != true) return 'Bu oda artık aktif değil';

    GameSession initialSession;
    try {
      initialSession = GameSession.fromJson(data);
    } catch (_) {
      return 'Oda verisi okunamadı';
    }

    _roomRef = ref;
    _persistRoom(code, LiveRole.viewer);
    state = state.copyWith(
      role: LiveRole.viewer,
      roomCode: code,
      isConnected: true,
      viewerSession: initialSession,
      scoresHidden: data['scoresHidden'] == true,
      lastSync: DateTime.now(),
      clearError: true,
    );

    _attachViewerListener();
    _watchConnection();
    return null;
  }

  /// Dinleyiciyi kurar. onError olmadığı için stream sessizce ölüyordu —
  /// artık hata gelirse geri çekilerek yeniden bağlanıyor.
  void _attachViewerListener() {
    if (_roomRef == null) return;
    _sub?.cancel();

    // Çevrimdışıyken de son veri elde kalsın.
    try {
      _roomRef!.keepSynced(true);
    } catch (_) {}

    _sub = _roomRef!.onValue.listen(
      (event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return;
        try {
          final json = _convert(event.snapshot.value) as Map<String, dynamic>;
          if (json['isActive'] != true) {
            leaveRoom();
            return;
          }
          final updated = GameSession.fromJson(json);
          state = state.copyWith(
            viewerSession: updated,
            scoresHidden: json['scoresHidden'] == true,
            isConnected: true,
            lastSync: DateTime.now(),
            isRefreshing: false,
            clearError: true,
          );
        } catch (_) {}
      },
      onError: (Object _) {
        if (_disposed) return;
        state = state.copyWith(isConnected: false);
        _scheduleReattach();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReattach() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      if (_disposed || state.role != LiveRole.viewer) return;
      _attachViewerListener();
      refresh();
    });
  }

  /// Bağlantı durumunu izler; yeniden bağlanınca bekleyen yazımı gönderir.
  void _watchConnection() {
    _connSub?.cancel();
    if (!_firebaseReady) return;
    try {
      _connSub = FirebaseDatabase.instance.ref('.info/connected').onValue.listen((e) {
        if (_disposed) return;
        final online = e.snapshot.value == true;
        state = state.copyWith(isConnected: online);
        if (!online) return;
        // Tekrar çevrimiçi: izleyici veriyi çeksin, host yayını tazelesin.
        if (state.role == LiveRole.viewer) {
          refresh();
        } else if (state.role == LiveRole.host) {
          _resyncHost();
        }
      });
    } catch (_) {}
  }

  /// Odayı tek seferlik yeniden okur — yenile butonu ve resume bunu çağırır.
  Future<void> refresh() async {
    if (!_firebaseReady) return;
    final code = state.roomCode;
    if (code == null) return;

    _roomRef ??= _dbRef('rooms/$code');
    if (state.role == LiveRole.viewer) {
      state = state.copyWith(isRefreshing: true);
    }

    DataSnapshot snap;
    try {
      snap = await _roomRef!.get();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(isRefreshing: false, isConnected: false);
      }
      return;
    }

    if (_disposed) return;

    if (!snap.exists || snap.value == null) {
      state = state.copyWith(isRefreshing: false);
      return;
    }

    final data = _convert(snap.value) as Map<String, dynamic>;
    if (data['isActive'] != true) {
      await leaveRoom();
      return;
    }

    if (state.role == LiveRole.viewer) {
      GameSession? session;
      try {
        session = GameSession.fromJson(data);
      } catch (_) {}
      state = state.copyWith(
        viewerSession: session,
        scoresHidden: data['scoresHidden'] == true,
        isConnected: true,
        lastSync: DateTime.now(),
        isRefreshing: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(isConnected: true, lastSync: DateTime.now());
    }
  }

  /// Odayı kapatır / terk eder.
  Future<void> leaveRoom() async {
    if (_firebaseReady && state.role == LiveRole.host && _roomRef != null) {
      try {
        await _roomRef!.update({'isActive': false});
      } catch (_) {}
    }
    if (_roomRef != null) {
      try {
        _roomRef!.keepSynced(false);
      } catch (_) {}
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _sub?.cancel();
    _sub = null;
    _connSub?.cancel();
    _connSub = null;
    _roomRef = null;
    _clearPersistedRoom();
    if (!_disposed) state = const LiveState();
  }

  // ─────────────────────────────────────────────────────────
  // Lifecycle: telefon kilitlenip açıldığında soket kopuyor.
  // Resume'da dinleyiciyi tazeleyip veriyi zorla çekiyoruz.
  // ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!this.state.isActive) return;
    _watchConnection();
    if (this.state.role == LiveRole.viewer) {
      _attachViewerListener();
      refresh();
    } else {
      _resyncHost();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _sub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

final liveProvider = StateNotifierProvider<LiveRoomNotifier, LiveState>(
  (ref) => LiveRoomNotifier(ref.watch(sharedPreferencesProvider), ref),
);
