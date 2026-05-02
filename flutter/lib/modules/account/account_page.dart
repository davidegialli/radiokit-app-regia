import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/ws_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/rk_button.dart';
import '../../shared/widgets/rk_card.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.to;
    return Scaffold(body: SafeArea(child: Column(children: [
      PageHeader(title: 'account.title'.tr, eyebrow: 'CONDUTTORE', onBack: () => Get.back()),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(storage.userName ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(storage.licenseKey ?? '—', style: const TextStyle(fontFamily: 'GeistMono', fontSize: 11, color: AppColors.text3)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('account.language'.tr, style: const TextStyle(fontSize: 13, color: AppColors.text2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: AppConstants.supportedLocales.map((code) {
              final selected = Get.locale?.languageCode == code;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) {
                  storage.locale = code;
                  Get.updateLocale(_localeFor(code));
                },
                label: Text(code.toUpperCase(), style: const TextStyle(fontFamily: 'GeistMono', fontSize: 12)),
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surface2,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.text2),
              );
            }).toList()),
          ])),
          const SizedBox(height: 16),
          RkButton(
            fullWidth: true,
            variant: RkBtnVariant.outlined,
            onPressed: () {
              storage.logout();
              WsService.to.disconnect();
              Get.offAllNamed(AppRoutes.activation);
            },
            child: Text('account.logout'.tr),
          ),
        ]),
      )),
    ])));
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
