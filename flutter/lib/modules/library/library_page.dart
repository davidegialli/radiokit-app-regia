import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/page_header.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.library'.tr, eyebrow: 'JINGLES · BRANI'),
      const Expanded(child: Center(child: Text('Library — TODO', style: TextStyle(color: Colors.white54)))),
    ]);
  }
}
