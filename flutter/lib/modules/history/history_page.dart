import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/page_header.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      PageHeader(title: 'tab.history'.tr, eyebrow: 'ULTIMI BRANI', onBack: () => Get.back()),
      const Expanded(child: Center(child: Text('Storico — TODO', style: TextStyle(color: Colors.white54)))),
    ])));
  }
}
