import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/page_header.dart';

/// Stub On Air. TODO: now playing card, queue, skip, insert jingle modal,
/// toggle Live/AutoDJ, controlli volume mic via WS verso Diretta bridge.
class OnAirPage extends StatelessWidget {
  const OnAirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(title: 'tab.onAir'.tr, eyebrow: 'header.live'.tr),
      const Expanded(child: Center(child: Text('On Air — TODO', style: TextStyle(color: Colors.white54)))),
    ]);
  }
}
