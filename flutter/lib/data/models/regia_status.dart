/// Stato sintetico della regia, single source of truth per la UI.
/// Mappato 1:1 con `app_state` ritornato da `/api/regia/?action=status`.
enum RegiaAppState { unknown, offline, idle, requested, scheduled, live, error }

extension RegiaAppStateWire on RegiaAppState {
  String get wireName => name;
  static RegiaAppState fromWire(String? s) {
    switch (s) {
      case 'offline':   return RegiaAppState.offline;
      case 'idle':      return RegiaAppState.idle;
      case 'requested': return RegiaAppState.requested;
      case 'scheduled': return RegiaAppState.scheduled;
      case 'live':      return RegiaAppState.live;
      case 'error':     return RegiaAppState.error;
      default:          return RegiaAppState.unknown;
    }
  }
}

class NowPlaying {
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String state;
  final int posMs;
  final int lenMs;
  final int timeLeftSec;

  const NowPlaying({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.state,
    this.posMs = 0,
    this.lenMs = 0,
    this.timeLeftSec = 0,
  });

  bool get isEmpty => title.isEmpty && artist.isEmpty;

  /// Progress 0.0..1.0 — valido solo se lenMs > 0.
  double get progress {
    if (lenMs <= 0) return 0.0;
    final p = posMs / lenMs;
    if (p < 0) return 0.0;
    if (p > 1) return 1.0;
    return p;
  }

  String fmtPos() => _fmtMs(posMs);
  String fmtLen() => _fmtMs(lenMs);

  static String _fmtMs(int ms) {
    final s = (ms ~/ 1000);
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2,'0')}:${ss.toString().padLeft(2,'0')}';
  }

  factory NowPlaying.fromJson(Map<String, dynamic> j) => NowPlaying(
    title:       (j['title']    ?? '').toString(),
    artist:      (j['artist']   ?? '').toString(),
    album:       (j['album']    ?? '').toString(),
    duration:    (j['duration'] ?? '').toString(),
    state:       (j['state']    ?? '').toString(),
    posMs:       j['pos_ms']      is int ? j['pos_ms']      as int : 0,
    lenMs:       j['len_ms']      is int ? j['len_ms']      as int : 0,
    timeLeftSec: j['time_left_s'] is int ? j['time_left_s'] as int : 0,
  );
}

/// Snapshot completo restituito da `/status`.
class RegiaStatus {
  final RegiaAppState appState;
  final List<String> bridgesOnline;
  final int? bridgeAgeSec;
  final NowPlaying? nowPlaying;
  final int? listeners;
  final bool relayActive;
  final bool live;
  final Map<String, dynamic>? session; // sessione stream URL attiva (raw)
  final DateTime? serverTime;

  const RegiaStatus({
    required this.appState,
    required this.bridgesOnline,
    this.bridgeAgeSec,
    this.nowPlaying,
    this.listeners,
    this.relayActive = false,
    this.live = false,
    this.session,
    this.serverTime,
  });

  factory RegiaStatus.fromJson(Map<String, dynamic> j) {
    final np = j['now_playing'];
    return RegiaStatus(
      appState:      RegiaAppStateWire.fromWire(j['app_state'] as String?),
      bridgesOnline: ((j['bridges_online'] as List?)?.cast<String>()) ?? const [],
      bridgeAgeSec:  j['bridge_age_sec'] is int ? j['bridge_age_sec'] as int : null,
      nowPlaying:    np is Map ? NowPlaying.fromJson(Map<String, dynamic>.from(np)) : null,
      listeners:     j['listeners'] is int ? j['listeners'] as int : null,
      relayActive:   j['relay_active'] == true,
      live:          j['live'] == true,
      session:       j['session'] is Map ? Map<String, dynamic>.from(j['session']) : null,
      serverTime:    j['server_time'] is String ? DateTime.tryParse(j['server_time']) : null,
    );
  }

  static const RegiaStatus unknown = RegiaStatus(
    appState: RegiaAppState.unknown,
    bridgesOnline: [],
  );
}

/// Esito polling /cmd_result?id=X
enum CmdStatus { pending, picked, done, failed, notFound }

class CmdResult {
  final String commandId;
  final CmdStatus status;
  final Map<String, dynamic>? result;
  final String? error;

  const CmdResult({
    required this.commandId,
    required this.status,
    this.result,
    this.error,
  });

  factory CmdResult.fromJson(Map<String, dynamic> j) {
    final s = (j['status'] ?? '').toString();
    final cs = switch (s) {
      'pending' => CmdStatus.pending,
      'picked'  => CmdStatus.picked,
      'done'    => CmdStatus.done,
      'failed'  => CmdStatus.failed,
      _         => CmdStatus.pending,
    };
    return CmdResult(
      commandId: (j['command_id'] ?? '').toString(),
      status:    cs,
      result:    j['result'] is Map ? Map<String, dynamic>.from(j['result']) : null,
      error:     j['error'] as String?,
    );
  }
}
