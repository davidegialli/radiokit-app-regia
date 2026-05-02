class AppConstants {
  AppConstants._();

  static const String appName = 'RadioKit Regia';
  static const String appVersion = '0.1.0';

  // VPS RadioKit endpoint (stesso flow Timer/Diretta/Speaker)
  static const String apiBaseUrl = 'https://radiokit.io/api/regia';
  static const String wsBaseUrl  = 'wss://radiokit.io/api/regia/stream';

  // Sistema chiavi zero-config — prefisso prodotto Regia
  static const String keyPrefix = 'RKR-';
  static final RegExp keyRegex  = RegExp(r'^RKR-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');

  // OneSignal — riuso App ID Stereo 98 in fase iniziale,
  // poi App ID dedicato RadioKit Regia se separiamo
  static const String oneSignalAppId = '3e87897b-47fb-4389-9efe-9b99ecc6949d';

  // GetStorage keys
  static const String storageKeyLicense  = 'rkr_license_key';
  static const String storageKeyToken    = 'rkr_jwt';
  static const String storageKeyLocale   = 'rkr_locale';
  static const String storageKeyServices = 'rkr_services';
  static const String storageKeyRadioId  = 'rkr_radio_id';
  static const String storageKeyUserName = 'rkr_user_name';

  // Lingue supportate (allineate al sito stereo98 + radiokit.io)
  static const List<String> supportedLocales = ['it', 'en', 'fr', 'es'];
  static const String defaultLocale = 'it';
}
