import 'regia_command.dart';

/// Stato di una diretta da URL stream esterno.
enum StreamHealth { idle, probing, ok, buffering, down }

extension StreamHealthWire on StreamHealth {
  String get wireName => name;
  static StreamHealth fromWire(String s) =>
      StreamHealth.values.firstWhere((e) => e.name == s, orElse: () => StreamHealth.idle);
}

class StreamLaunchSession {
  final String id;
  final String url;
  final String title;
  final String? host;
  final int? durationMin;
  final StartMode startMode;
  final bool autoFallback;

  // Stato runtime
  final DateTime? startedAt;
  final DateTime? endedAt;
  final StreamHealth health;
  final String? sourceCodec;
  final int? sourceBitrate;       // kbps
  final int bytesReceived;
  final String? error;

  const StreamLaunchSession({
    required this.id,
    required this.url,
    required this.title,
    this.host,
    this.durationMin,
    this.startMode = StartMode.endtrack,
    this.autoFallback = true,
    this.startedAt,
    this.endedAt,
    this.health = StreamHealth.idle,
    this.sourceCodec,
    this.sourceBitrate,
    this.bytesReceived = 0,
    this.error,
  });

  bool get isLive => startedAt != null && endedAt == null;

  Duration get elapsed {
    if (startedAt == null) return Duration.zero;
    final end = endedAt ?? DateTime.now().toUtc();
    return end.difference(startedAt!);
  }

  StreamLaunchSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    StreamHealth? health,
    String? sourceCodec,
    int? sourceBitrate,
    int? bytesReceived,
    String? error,
  }) {
    return StreamLaunchSession(
      id: id, url: url, title: title, host: host,
      durationMin: durationMin, startMode: startMode, autoFallback: autoFallback,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      health: health ?? this.health,
      sourceCodec: sourceCodec ?? this.sourceCodec,
      sourceBitrate: sourceBitrate ?? this.sourceBitrate,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      error: error ?? this.error,
    );
  }

  factory StreamLaunchSession.fromJson(Map<String, dynamic> j) {
    return StreamLaunchSession(
      id: j['id'] as String,
      url: j['url'] as String,
      title: j['title'] as String,
      host: j['host'] as String?,
      durationMin: j['duration_min'] as int?,
      startMode: StartModeWire.fromWire(j['start_mode'] as String? ?? 'endtrack'),
      autoFallback: j['auto_fallback'] as bool? ?? true,
      startedAt: j['started_at'] != null ? DateTime.parse(j['started_at']) : null,
      endedAt: j['ended_at']   != null ? DateTime.parse(j['ended_at'])   : null,
      health: StreamHealthWire.fromWire(j['health'] as String? ?? 'idle'),
      sourceCodec: j['source_codec'] as String?,
      sourceBitrate: j['source_bitrate'] as int?,
      bytesReceived: j['bytes_received'] as int? ?? 0,
      error: j['error'] as String?,
    );
  }
}
