import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../modules/home/home_page.dart';
import '../../modules/on_air/on_air_page.dart';
import '../../modules/stream_url/stream_url_page.dart';
import '../../modules/stream_url/stream_url_binding.dart';
import '../../modules/listeners/listeners_page.dart';
import '../../modules/library/library_page.dart';

/// Indice tab corrente, esposto in modo che altre pagine (es. Home con
/// shortcut "Vai in onda") possano cambiare tab senza un secondo navigator.
final RxInt shellTabIndex = 0.obs;

/// Shell principale: header + body tab + bottom nav 5 voci.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    StreamUrlBinding().dependencies();
    _pages = const [
      HomePage(),
      OnAirPage(),
      StreamUrlPage(),
      ListenersPage(),
      LibraryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _pages[shellTabIndex.value]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shellTabIndex.value,
        onTap: (v) => shellTabIndex.value = v,
        backgroundColor: AppColors.bgElev,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined),         activeIcon: const Icon(Icons.home),         label: 'tab.home'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.play_circle_outline),  activeIcon: const Icon(Icons.play_circle),  label: 'tab.onAir'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.podcasts_outlined),    activeIcon: const Icon(Icons.podcasts),     label: 'tab.stream'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.people_outline),       activeIcon: const Icon(Icons.people),       label: 'tab.listeners'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.library_music_outlined),activeIcon: const Icon(Icons.library_music),label: 'tab.library'.tr),
        ],
      ),
    ));
  }
}
