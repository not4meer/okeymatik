import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_session.dart';

enum LiveRole { none, host, viewer }

class LiveState {
  final LiveRole role;
  final String? roomCode;
  final bool isConnected;
  final GameSession? viewerSession;
  final String? error;
  final bool scoresHidden;

  const LiveState({
    this.role = LiveRole.none,
    this.roomCode,
    this.isConnected = false,
    this.viewerSession,
    this.error,
    this.scoresHidden = false,
  });

  bool get isActive => role != LiveRole.none;

  LiveState copyWith({
    LiveRole? role,
    String? roomCode,
    bool? isConnected,
    GameSession? viewerSession,
    String? error,
    bool? scoresHidden,
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
    );
  }
}

class LiveRoomNotifier extends StateNotifier<LiveState> {
  LiveRoomNotifier() : super(const LiveState());

  DatabaseReference? _roomRef;
  StreamSubscription<DatabaseEvent>? _sub;

  static const _dbUrl =
      'https://okeymatik-1d379-default-rtdb.europe-west1.firebasedatabase.app';

  static FirebaseDatabase? _dbInstance;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  DatabaseReference _ref(String path) {
    _dbInstance ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _dbUrl,
    );
    return _dbInstance!.ref(path);
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // Deep-converts Firebase Maps (LinkedHashMap<Object?,Object?>) to Map<String,dynamic>
  static dynamic _convert(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), _convert(e.value))),
      );
    }
    if (v is List) return v.map(_convert).toList();
    return v;
  }

  /// Creates a room, returns the 6-digit code or null on error.
  Future<String?> createRoom(GameSession session) async {
    if (!_firebaseReady) {
      state = state.copyWith(error: 'Firebase bağlantısı yok');
      return null;
    }

    final code = _generateCode();
    try {
      _roomRef = _ref('rooms/$code');
      final data = {
        ...session.toJson(),
        'isActive': true,
        'lastUpdated': ServerValue.timestamp,
      };
      await _roomRef!.set(data);
    } catch (e) {
      _roomRef = null;
      state = state.copyWith(error: 'Oda oluşturulamadı: $e');
      return null;
    }

    state = state.copyWith(
      role: LiveRole.host,
      roomCode: code,
      isConnected: true,
    );
    return code;
  }

  /// Pushes updated session to Firebase (host only).
  Future<void> pushUpdate(GameSession session, {bool? scoresHidden}) async {
    if (!_firebaseReady) return;
    if (state.role != LiveRole.host || _roomRef == null) return;
    try {
      await _roomRef!.update({
        ...session.toJson(),
        'scoresHidden': scoresHidden ?? state.scoresHidden,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  /// Pushes only the hidden flag (no full session update needed).
  Future<void> pushHidden(bool hidden) async {
    if (!_firebaseReady) return;
    if (state.role != LiveRole.host || _roomRef == null) return;
    try {
      await _roomRef!.update({'scoresHidden': hidden});
    } catch (_) {}
    state = state.copyWith(scoresHidden: hidden);
  }

  /// Joins a room as viewer. Returns error string, or null on success.
  Future<String?> joinRoom(String code) async {
    if (!_firebaseReady) return 'Firebase bu platformda kullanılamıyor';

    final ref = _ref('rooms/$code');
    DatabaseEvent snap;
    try {
      snap = await ref.once();
    } catch (_) {
      return 'Bağlantı hatası';
    }

    if (!snap.snapshot.exists || snap.snapshot.value == null) {
      return 'Oda bulunamadı';
    }

    final raw = _convert(snap.snapshot.value);
    final data = raw as Map<String, dynamic>;

    if (data['isActive'] != true) return 'Bu oda artık aktif değil';

    GameSession initialSession;
    try {
      initialSession = GameSession.fromJson(data);
    } catch (_) {
      return 'Oda verisi okunamadı';
    }

    _roomRef = ref;
    state = state.copyWith(
      role: LiveRole.viewer,
      roomCode: code,
      isConnected: true,
      viewerSession: initialSession,
    );

    _sub = ref.onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return;
      try {
        final json = _convert(event.snapshot.value) as Map<String, dynamic>;
        if (json['isActive'] != true) {
          leaveRoom();
          return;
        }
        final updated = GameSession.fromJson(json);
        final hidden = json['scoresHidden'] == true;
        state = state.copyWith(viewerSession: updated, scoresHidden: hidden);
      } catch (_) {}
    });

    return null;
  }

  /// Closes/leaves the room.
  Future<void> leaveRoom() async {
    if (_firebaseReady && state.role == LiveRole.host && _roomRef != null) {
      try {
        await _roomRef!.update({'isActive': false});
      } catch (_) {}
    }
    _sub?.cancel();
    _sub = null;
    _roomRef = null;
    state = const LiveState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final liveProvider = StateNotifierProvider<LiveRoomNotifier, LiveState>(
  (ref) => LiveRoomNotifier(),
);
