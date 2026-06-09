import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper su GetStorage per le preferenze persistenti.
/// Stesse chiavi tra Diretta / Timer / Regia per coerenza.
class StorageService extends GetxService {
  final _box = GetStorage();

  static StorageService get to => Get.find<StorageService>();

  // ── Licenza / token ─────────────────────────────
  String? get licenseKey => _box.read<String>(AppConstants.storageKeyLicense);
  set licenseKey(String? v) => v == null
      ? _box.remove(AppConstants.storageKeyLicense)
      : _box.write(AppConstants.storageKeyLicense, v);

  String? get jwt => _box.read<String>(AppConstants.storageKeyToken);
  set jwt(String? v) => v == null
      ? _box.remove(AppConstants.storageKeyToken)
      : _box.write(AppConstants.storageKeyToken, v);

  String? get radioId => _box.read<String>(AppConstants.storageKeyRadioId);
  set radioId(String? v) => v == null
      ? _box.remove(AppConstants.storageKeyRadioId)
      : _box.write(AppConstants.storageKeyRadioId, v);

  String? get userName => _box.read<String>(AppConstants.storageKeyUserName);
  set userName(String? v) => v == null
      ? _box.remove(AppConstants.storageKeyUserName)
      : _box.write(AppConstants.storageKeyUserName, v);

  // ── Scadenza prova (trial) ──────────────────────
  String? get licenseExpires => _box.read<String>(AppConstants.storageKeyLicenseExpires);
  set licenseExpires(String? v) => (v == null || v.isEmpty)
      ? _box.remove(AppConstants.storageKeyLicenseExpires)
      : _box.write(AppConstants.storageKeyLicenseExpires, v);

  /// True se la prova è scaduta in base all'ultimo `expires_at` noto.
  /// FAIL-OPEN: senza data nota o non parsabile → NON bloccare (no brick).
  bool get isTrialExpired {
    final s = licenseExpires;
    if (s == null || s.isEmpty) return false;
    // Server format MySQL "Y-m-d H:i:s" → ISO con 'T'.
    final d = DateTime.tryParse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));
    if (d == null) return false;
    return DateTime.now().isAfter(d);
  }

  // ── Servizi abilitati per chiave ─────────────────
  List<String> get services {
    final raw = _box.read<List>(AppConstants.storageKeyServices) ?? const [];
    return raw.cast<String>();
  }
  set services(List<String> v) => _box.write(AppConstants.storageKeyServices, v);

  bool hasService(String flag) => services.contains(flag);

  // ── Locale ──────────────────────────────────────
  String get locale => _box.read<String>(AppConstants.storageKeyLocale) ?? AppConstants.defaultLocale;
  set locale(String v) => _box.write(AppConstants.storageKeyLocale, v);

  bool get isAuthenticated => jwt != null && jwt!.isNotEmpty;

  void logout() {
    licenseKey = null;
    jwt = null;
    services = const [];
    radioId = null;
    userName = null;
    licenseExpires = null;
  }

  // ── Generic key/value (per dati di feature specifiche) ──────────────
  T? read<T>(String key) => _box.read<T>(key);
  void write(String key, dynamic value) => _box.write(key, value);
  void remove(String key) => _box.remove(key);
}
