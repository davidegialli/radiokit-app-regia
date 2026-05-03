import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/page_header.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.library'.tr, eyebrow: 'PARLATO · JINGLE'),
      Expanded(child: ComingSoon(
        icon: Icons.library_music_outlined,
        title: 'soon.title'.tr,
        description: 'soon.libraryDesc'.tr,
        features: [
          'soon.libraryF1'.tr,
          'soon.libraryF2'.tr,
          'soon.libraryF3'.tr,
        ],
      )),
    ]);
  }
}
