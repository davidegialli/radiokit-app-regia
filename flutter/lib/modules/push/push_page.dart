import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/page_header.dart';

class PushPage extends StatelessWidget {
  const PushPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [
      PageHeader(title: 'push.title'.tr, eyebrow: 'ONESIGNAL', onBack: () => Get.back()),
      const Expanded(child: Center(child: Text('Push — TODO', style: TextStyle(color: Colors.white54)))),
    ])));
  }
}
