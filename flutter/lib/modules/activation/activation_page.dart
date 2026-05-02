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
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                  LengthLimitingTextInputFormatter(24),  // RK-XXXX-XXXX-XXXX-XXXX = 22 (max prodotti)
                  KeyAutoDashFormatter(),                // auto-insert "-" ogni 4 char dopo prefisso
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

/// Auto-insert "-" every 4 chars after the product prefix.
/// Supports RK- (Diretta, 5 groups), RKR- (Regia), RKT- (Timer), RKM- (Speaker).
/// Esempio: digiti "RKRKRFEH3M" → diventa "RK-RKRF-EH3M"
class KeyAutoDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('-', '');

    // Determina lunghezza prefisso (RK | RKR | RKT | RKM)
    String prefix;
    if (raw.length >= 3 && (raw.startsWith('RKR') || raw.startsWith('RKT') || raw.startsWith('RKM'))) {
      prefix = raw.substring(0, 3);
    } else if (raw.length >= 2 && raw.startsWith('RK')) {
      prefix = raw.substring(0, 2);
    } else {
      // Non c'è ancora un prefisso valido: lascia passare l'input senza dash
      return newValue;
    }

    final rest = raw.substring(prefix.length);
    final buf = StringBuffer(prefix);
    for (var i = 0; i < rest.length; i++) {
      if (i % 4 == 0) buf.write('-');
      buf.write(rest[i]);
    }
    final formatted = buf.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
