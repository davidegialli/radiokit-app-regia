class AppConstants {
  AppConstants._();

  static const String appName = 'RadioKit Regia';
  static const String appVersion = '0.1.0';

  // VPS RadioKit endpoint — single front-controller, action-dispatched
  // (stesso pattern di /api/timer/)
  static const String apiBaseUrl = 'https://radiokit.io/api/regia/';
  static const String wsBaseUrl  = 'wss://radiokit.io/api/regia/stream';

  // Sistema chiavi: accetta RK-, RKR-, RKT-, RKM-
  // (il VPS valida che la chiave sia abilitata per Regia)
  static const String keyPrefix = 'RKR-';
  static final RegExp keyRegex  = RegExp(
    r'^(RK-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}|RK[RTM]-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4})$'
  );

  // OneSignal — App ID dedicato RadioKit Regia (da creare in dashboard).
  // Placeholder finché non viene creata l'app dedicata.
  static const String oneSignalAppId = '00000000-0000-0000-0000-000000000000';

  // GetStorage keys
  static const String storageKeyLicense  = 'rkr_license_key';
  static const String storageKeyToken    = 'rkr_jwt';
  static const String storageKeyLocale   = 'rkr_locale';
  static const String storageKeyServices = 'rkr_services';
  static const String storageKeyRadioId  = 'rkr_radio_id';
  static const String storageKeyUserName = 'rkr_user_name';
  static const String storageKeyLicenseExpires = 'rkr_license_expires'; // ISO/MySQL datetime

  // Lingue supportate (allineate al sito radiokit.io)
  static const List<String> supportedLocales = ['it', 'en', 'fr', 'es'];
  static const String defaultLocale = 'it';
}
