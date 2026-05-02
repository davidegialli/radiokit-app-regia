import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../services/ws_service.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

/// Decide al boot dove mandare l'utente:
///   - chiave salvata + token valido → /shell
///   - altrimenti → /activation
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final storage = StorageService.to;
    if (storage.isAuthenticated) {
      // Fire-and-forget: il routing non aspetta il VPS.
      // Se il WS non si connette in 5s, l'app entra comunque in modalità degraded.
      WsService.to.connect().timeout(const Duration(seconds: 5),
        onTimeout: () { /* degraded mode */ });
      Get.offAllNamed(AppRoutes.shell);
    } else {
      Get.offAllNamed(AppRoutes.activation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
      ),
    );
  }
}
