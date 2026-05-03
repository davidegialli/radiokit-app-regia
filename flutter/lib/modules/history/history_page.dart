import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/page_header.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      PageHeader(title: 'tab.history'.tr, eyebrow: 'ULTIMI BRANI', onBack: () => Get.back()),
      Expanded(child: ComingSoon(
        icon: Icons.history,
        title: 'soon.title'.tr,
        description: 'soon.historyDesc'.tr,
        features: [
          'soon.historyF1'.tr,
          'soon.historyF2'.tr,
          'soon.historyF3'.tr,
        ],
      )),
    ])));
  }
}
