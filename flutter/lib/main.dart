import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/constants/app_constants.dart';
import 'core/i18n/translations.dart';
import 'core/routing/app_pages.dart';
import 'core/routing/app_routes.dart';
import 'core/services/api_service.dart';
import 'core/services/status_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/ws_service.dart';
import 'core/theme/app_theme.dart';
import 'modules/listeners/listeners_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // DI services
  Get.put(StorageService(), permanent: true);
  Get.put(ApiService(),     permanent: true);
  Get.put(WsService(),      permanent: true);
  Get.put(StatusService(),  permanent: true);
  // ListenersController permanente: polla listener_stats in background
  // (ogni 30s) cosi' i KPI ascoltatori sono freschi anche su Home/Diretta
  // senza bisogno di aprire la tab Streaming.
  Get.put(ListenersController(), permanent: true);

  runApp(const RadioKitRegiaApp());
}

class RadioKitRegiaApp extends StatelessWidget {
  const RadioKitRegiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = StorageService.to.locale;
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      translations: AppTranslations(),
      locale: _localeFor(saved),
      fallbackLocale: const Locale('it', 'IT'),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }

  Locale _localeFor(String code) {
    switch (code) {
      case 'en': return const Locale('en', 'US');
      case 'fr': return const Locale('fr', 'FR');
      case 'es': return const Locale('es', 'ES');
      case 'it':
      default:   return const Locale('it', 'IT');
    }
  }
}
