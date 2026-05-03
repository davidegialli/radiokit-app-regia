import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/page_header.dart';

class PushPage extends StatelessWidget {
  const PushPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      PageHeader(title: 'push.title'.tr, eyebrow: 'ONESIGNAL', onBack: () => Get.back()),
      Expanded(child: ComingSoon(
        icon: Icons.notifications_active_outlined,
        title: 'soon.title'.tr,
        description: 'soon.pushDesc'.tr,
        features: [
          'soon.pushF1'.tr,
          'soon.pushF2'.tr,
          'soon.pushF3'.tr,
        ],
      )),
    ])));
  }
}
