import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/page_header.dart';

class ListenersPage extends StatelessWidget {
  const ListenersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.listeners'.tr, eyebrow: 'STREAM · ICECAST'),
      const Expanded(child: Center(child: Text('Listeners — TODO', style: TextStyle(color: Colors.white54)))),
    ]);
  }
}
