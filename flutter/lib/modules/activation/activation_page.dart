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
                  LengthLimitingTextInputFormatter(19),
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
