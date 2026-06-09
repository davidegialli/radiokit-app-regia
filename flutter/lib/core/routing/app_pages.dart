import 'package:get/get.dart';

import '../../modules/activation/activation_page.dart';
import '../../modules/activation/activation_binding.dart';
import '../../modules/account/account_page.dart';
import '../../modules/push/push_page.dart';
import '../../modules/history/history_page.dart';
import '../../modules/trial/trial_expired_page.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';
import 'splash_page.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.activation,
      page: () => const ActivationPage(),
      binding: ActivationBinding(),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const AppShell(),
    ),
    GetPage(
      name: AppRoutes.trialExpired,
      page: () => const TrialExpiredPage(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountPage(),
    ),
    GetPage(
      name: AppRoutes.push,
      page: () => const PushPage(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryPage(),
    ),
  ];
}
