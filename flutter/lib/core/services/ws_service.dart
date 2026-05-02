import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';
import '../../data/models/regia_command.dart';
import 'storage_service.dart';

/// WebSocket persistente verso il VPS per:
///  - inviare comandi al bridge (Timer / Diretta)
///  - ricevere stato realtime (listener, now playing, salute stream)
///  - ricevere ack/result dei comandi
class WsService extends GetxService {
  static WsService get to => Get.find<WsService>();

  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;

  final connected = false.obs;
  final lastEvent = Rxn<Map<String, dynamic>>();

  /// Stream di tutti i messaggi inbound (typed dispatch lo fanno i controller).
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> connect() async {
    final t = StorageService.to.jwt;
    if (t == null) return;
    await disconnect();

    final uri = Uri.parse('${AppConstants.wsBaseUrl}?token=$t');
    _ch = WebSocketChannel.connect(uri);

    _sub = _ch!.stream.listen(
      (data) {
        try {
          final m = jsonDecode(data as String) as Map<String, dynamic>;
          lastEvent.value = m;
          _events.add(m);
        } catch (_) {}
      },
      onError: (_) => connected.value = false,
      onDone: () => connected.value = false,
    );

    connected.value = true;
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'type': 'ping'});
    });
  }

  Future<void> disconnect() async {
    _heartbeat?.cancel();
    await _sub?.cancel();
    await _ch?.sink.close();
    _ch = null;
    _sub = null;
    connected.value = false;
  }

  void send(RegiaCommand cmd) => _send(cmd.toJson());

  void _send(Map<String, dynamic> m) {
    if (_ch == null) return;
    _ch!.sink.add(jsonEncode(m));
  }

  /// Filtra eventi per tipo (es. ack di un comando specifico, push listener).
  Stream<Map<String, dynamic>> filter(bool Function(Map<String, dynamic>) pred) {
    return events.where(pred);
  }

  /// Aspetta l'ack di un comando con un id specifico.
  Future<RegiaCommandAck> waitAck(String commandId, {Duration timeout = const Duration(seconds: 8)}) {
    return events
        .where((m) => m['type'] == 'ack' && m['command_id'] == commandId)
        .map((m) => RegiaCommandAck.fromJson(m))
        .first
        .timeout(timeout);
  }

  @override
  void onClose() {
    disconnect();
    _events.close();
    super.onClose();
  }
}
