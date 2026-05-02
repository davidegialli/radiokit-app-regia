import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/rk_button.dart';
import 'activation_controller.dart';

class ActivationPage extends GetView<ActivationController> {
  const ActivationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.podcasts, size: 56, color: AppColors.accent),
              const SizedBox(height: 24),
              Text('activation.title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 8),
              Text('activation.subtitle'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.text3)),
              const SizedBox(height: 32),
              Obx(() => TextField(
                onChanged: (v) => controller.keyText.value = v,
                keyboardType: TextInputType.visiblePassword,  // mostra lettere+simboli insieme, no autocorrect
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                  LengthLimitingTextInputFormatter(24),  // RK-XXXX-XXXX-XXXX-XXXX = 22 (max prodotti)
                  KeyAutoDashFormatter(),                // auto-insert "-" su paste
                ],
                style: const TextStyle(fontFamily: 'GeistMono', fontSize: 16, letterSpacing: 1.5),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'activation.keyLabel'.tr,
                  hintText: 'activation.keyHint'.tr,
                  errorText: controller.error.value,
                ),
              )),
              const SizedBox(height: 24),
              Obx(() => RkButton(
                fullWidth: true,
                size: RkBtnSize.lg,
                onPressed: controller.loading.value || !controller.isKeyValid ? null : controller.activate,
                child: Text(controller.loading.value ? 'common.loading'.tr : 'activation.activate'.tr),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Auto-formatter "smart paste":
/// - Se l'utente digita carattere per carattere, NON tocca nulla — l'utente
///   mette i "-" come preferisce (oppure li copia da email).
/// - Se l'utente INCOLLA una chiave intera senza trattini (es. da clipboard),
///   il formatter la riconosce dal numero di caratteri grezzi e inserisce i "-"
///   nei punti giusti:
///     * 18 char raw  → RK-XXXX-XXXX-XXXX-XXXX (Diretta, 5 gruppi)
///     * 15 char raw  → RKx-XXXX-XXXX-XXXX     (Regia/Timer/Speaker, 4 gruppi)
class KeyAutoDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('-', '');

    // Determina se è un paste (input cresciuto di più di 1 char in un colpo)
    final oldRaw   = oldValue.text.replaceAll('-', '');
    final isPaste  = (raw.length - oldRaw.length).abs() > 1;
    if (!isPaste) {
      // Typing manuale → lascia tutto com'è (l'utente mette il dash dove vuole)
      return newValue;
    }

    // Paste: prova a riconoscere il formato e auto-formatta
    String? formatted;
    if (raw.length == 18 && raw.startsWith('RK')) {
      // Diretta: RK + 16 char → RK-XXXX-XXXX-XXXX-XXXX
      formatted = 'RK-${raw.substring(2, 6)}-${raw.substring(6, 10)}-${raw.substring(10, 14)}-${raw.substring(14, 18)}';
    } else if (raw.length == 15 &&
        (raw.startsWith('RKR') || raw.startsWith('RKT') || raw.startsWith('RKM'))) {
      // Regia/Timer/Speaker: RKx + 12 char → RKx-XXXX-XXXX-XXXX
      formatted = '${raw.substring(0, 3)}-${raw.substring(3, 7)}-${raw.substring(7, 11)}-${raw.substring(11, 15)}';
    }

    if (formatted != null) {
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}
