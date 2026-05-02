import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_routes.dart';
import '../../shared/widgets/page_header.dart';

/// Stub Home / Dashboard.
/// TODO: KPI listener live, status bridge, now playing card,
/// shortcut "Vai in onda da URL", anteprime push recenti.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(
        title: 'tab.home'.tr,
        eyebrow: 'header.regia'.tr,
        actions: [
          HeaderIconButton(icon: Icons.notifications_none, onTap: () => Get.toNamed(AppRoutes.push), dot: true),
          HeaderIconButton(icon: Icons.person_outline,     onTap: () => Get.toNamed(AppRoutes.account)),
        ],
      ),
      const Expanded(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Dashboard — TODO', style: TextStyle(color: Colors.white54)),
          ),
        ),
      ),
    ]);
  }
}
