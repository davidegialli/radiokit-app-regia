import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../modules/home/home_page.dart';
import '../../modules/on_air/on_air_page.dart';
import '../../modules/stream_url/stream_url_page.dart';
import '../../modules/stream_url/stream_url_binding.dart';
import '../../modules/listeners/listeners_page.dart';
import '../../modules/listeners/listeners_controller.dart';
import '../../modules/library/library_page.dart';
import '../../core/services/status_service.dart';

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
        onTap: (v) {
          shellTabIndex.value = v;
          // Force-refresh dei dati piu' rilevanti per la tab che si apre,
          // cosi' i KPI sono freschi all'apertura senza aspettare il
          // prossimo tick di polling.
          _refreshOnTabOpen(v);
        },
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
          BottomNavigationBarItem(icon: const Icon(Icons.mic_none),             activeIcon: const Icon(Icons.mic),          label: 'tab.library'.tr),
        ],
      ),
    ));
  }

  /// Force-refresh dei dati pertinenti quando l'utente cambia tab.
  /// Best-effort: niente await/blocking, gli errori vengono ignorati
  /// (il polling normale recupera al prossimo tick).
  void _refreshOnTabOpen(int tabIndex) {
    // 0=Home, 1=OnAir, 2=Stream, 3=Listeners, 4=Library
    // Tutti tranne Library mostrano dati live → refresh status + listeners.
    if (tabIndex == 4) return;
    try { StatusService.to.refresh(); } catch (_) {}
    if (tabIndex == 0 || tabIndex == 2 || tabIndex == 3) {
      // Home / Diretta / Streaming hanno KPI ascoltatori
      try {
        if (Get.isRegistered<ListenersController>()) {
          ListenersController.to.loadStreams(silent: true);
        }
      } catch (_) {}
    }
  }
}
