import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

/// Schermata di blocco quando la prova gratuita (trial) è scaduta.
/// L'utente può reinserire una chiave valida (rinnovata) → torna all'attivazione.
class TrialExpiredPage extends StatelessWidget {
  const TrialExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.lock_clock, size: 40, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                Text(
                  'trial.expired.title'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 12),
                Text(
                  'trial.expired.msg'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.text2),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      // Reinserisci chiave: logout + torna all'attivazione.
                      StorageService.to.logout();
                      Get.offAllNamed(AppRoutes.activation);
                    },
                    child: Text('trial.expired.cta'.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'trial.expired.contact'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.text3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
