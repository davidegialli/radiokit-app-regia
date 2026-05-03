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

  const NowPlaying({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.state,
  });

  bool get isEmpty => title.isEmpty && artist.isEmpty;

  factory NowPlaying.fromJson(Map<String, dynamic> j) => NowPlaying(
    title:    (j['title']    ?? '').toString(),
    artist:   (j['artist']   ?? '').toString(),
    album:    (j['album']    ?? '').toString(),
    duration: (j['duration'] ?? '').toString(),
    state:    (j['state']    ?? '').toString(),
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
