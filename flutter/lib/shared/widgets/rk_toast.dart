import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

enum RkToastKind { info, success, warning, error }

class RkToast {
  static void show(String message, {RkToastKind kind = RkToastKind.info}) {
    Color bg;
    switch (kind) {
      case RkToastKind.success: bg = AppColors.autoDj; break;
      case RkToastKind.warning: bg = AppColors.warn; break;
      case RkToastKind.error:   bg = AppColors.accent; break;
      case RkToastKind.info:    bg = AppColors.bgElev; break;
    }
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
      ),
      backgroundColor: bg,
      borderRadius: 8,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      animationDuration: const Duration(milliseconds: 220),
    );
  }
}
