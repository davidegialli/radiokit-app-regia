/// Schema condiviso dei comandi che la app Regia invia attraverso il VPS
/// verso i bridge in studio (Timer e/o Diretta).
///
/// Questo file è la **fonte di verità** del protocollo.
/// Quando estendiamo Timer/Diretta per accettare i comandi della Regia,
/// devono parsare lo stesso JSON shape.
///
/// Trasporto: WebSocket WSS verso VPS → VPS instrada al bridge giusto
/// in base al campo `target` e a quale bridge è online per radio_id.

enum CommandTarget {
  timer,    // RadioKit Timer Win
  diretta,  // RadioKit Diretta Win/Mac
  vps,      // gestito direttamente dal VPS (no bridge)
  any,      // qualsiasi bridge che lo supporti
}

enum CommandType {
  // ── Playout (Timer) ─────────────────────────────
  playlistSkip,           // skip brano corrente
  playlistNext,           // info prossimo brano
  playlistInsertJingle,   // insert jingle (mode: now|endtrack|fade)

  // ── Live mic (Diretta) ──────────────────────────
  liveStart,              // apri relay mic
  liveStop,               // chiudi relay mic
  micMute,                // mute on/off
  micVolume,              // 0..100

  // ── Stream URL (Timer) ──────────────────────────
  streamUrlStart,         // lancia diretta da URL esterno con titolo
  streamUrlStop,          // chiudi diretta URL
  streamUrlStatus,        // chiedi stato corrente

  // ── Monitor / metriche ─────────────────────────
  monitorStatus,          // bitrate, encoder, listener
  bridgeHeartbeat,        // bridge → VPS (vivo)

  // ── VPS-only ────────────────────────────────────
  pushSend,               // invia push OneSignal
  analyticsSnapshot,      // snapshot analytics
}

extension CommandTypeRouting on CommandType {
  /// Bridge predefinito che gestisce il comando.
  /// Il VPS può ridirigere se il preferito è offline e `any` è valido.
  CommandTarget get target {
    switch (this) {
      case CommandType.playlistSkip:
      case CommandType.playlistNext:
      case CommandType.playlistInsertJingle:
      case CommandType.streamUrlStart:
      case CommandType.streamUrlStop:
      case CommandType.streamUrlStatus:
      case CommandType.monitorStatus:
        return CommandTarget.timer;
      case CommandType.liveStart:
      case CommandType.liveStop:
      case CommandType.micMute:
      case CommandType.micVolume:
        return CommandTarget.diretta;
      case CommandType.bridgeHeartbeat:
        return CommandTarget.any;
      case CommandType.pushSend:
      case CommandType.analyticsSnapshot:
        return CommandTarget.vps;
    }
  }

  String get wireName {
    // snake_case su filo
    switch (this) {
      case CommandType.playlistSkip:         return 'playlist.skip';
      case CommandType.playlistNext:         return 'playlist.next';
      case CommandType.playlistInsertJingle: return 'playlist.insert_jingle';
      case CommandType.liveStart:            return 'live.start';
      case CommandType.liveStop:             return 'live.stop';
      case CommandType.micMute:              return 'mic.mute';
      case CommandType.micVolume:            return 'mic.volume';
      case CommandType.streamUrlStart:       return 'stream_url.start';
      case CommandType.streamUrlStop:        return 'stream_url.stop';
      case CommandType.streamUrlStatus:      return 'stream_url.status';
      case CommandType.monitorStatus:        return 'monitor.status';
      case CommandType.bridgeHeartbeat:      return 'bridge.heartbeat';
      case CommandType.pushSend:             return 'push.send';
      case CommandType.analyticsSnapshot:    return 'analytics.snapshot';
    }
  }
}

/// Modalità di avvio per insert jingle / lancio stream URL.
enum StartMode {
  now,        // taglia il brano corrente, stacco netto
  endtrack,   // aspetta la fine del brano corrente
  fade,       // cross-fade graduale 4s
}

extension StartModeWire on StartMode {
  String get wireName {
    switch (this) {
      case StartMode.now:      return 'now';
      case StartMode.endtrack: return 'endtrack';
      case StartMode.fade:     return 'fade';
    }
  }

  static StartMode fromWire(String s) {
    return StartMode.values.firstWhere(
      (e) => e.wireName == s,
      orElse: () => StartMode.endtrack,
    );
  }
}

/// Comando inviato dalla app Regia al VPS.
class RegiaCommand {
  final String id;             // UUID v4 — per ack/correlation
  final String radioId;        // tenant radio
  final CommandType type;
  final Map<String, dynamic> payload;
  final DateTime ts;

  RegiaCommand({
    required this.id,
    required this.radioId,
    required this.type,
    this.payload = const {},
    DateTime? ts,
  }) : ts = ts ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'id': id,
    'radio_id': radioId,
    'type': type.wireName,
    'target': type.target.name,
    'payload': payload,
    'ts': ts.toIso8601String(),
  };

  /// Helper per il caso d'uso più comune: lancio stream URL.
  static RegiaCommand streamUrlStart({
    required String id,
    required String radioId,
    required String url,
    required String title,
    String? host,
    int? durationMin,        // null = manuale
    StartMode startMode = StartMode.endtrack,
    bool autoFallback = true,
  }) {
    return RegiaCommand(
      id: id,
      radioId: radioId,
      type: CommandType.streamUrlStart,
      payload: {
        'url': url,
        'title': title,
        if (host != null) 'host': host,
        if (durationMin != null) 'duration_min': durationMin,
        'start_mode': startMode.wireName,
        'auto_fallback': autoFallback,
      },
    );
  }
}

/// Risposta dal bridge / VPS al comando.
class RegiaCommandAck {
  final String commandId;
  final bool ok;
  final String? error;
  final Map<String, dynamic> data;

  RegiaCommandAck({
    required this.commandId,
    required this.ok,
    this.error,
    this.data = const {},
  });

  factory RegiaCommandAck.fromJson(Map<String, dynamic> json) {
    return RegiaCommandAck(
      commandId: json['command_id'] as String,
      ok: json['ok'] as bool,
      error: json['error'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
