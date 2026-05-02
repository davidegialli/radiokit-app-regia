import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/rk_button.dart';
import '../../shared/widgets/rk_card.dart';
import '../../shared/widgets/rk_status_chip.dart';
import 'activation_controller.dart';

class ActivationPage extends GetView<ActivationController> {
  const ActivationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // ── HERO halo: cerchio rosso pulsante con icona broadcast ───
              const _HeroHalo(),
              const SizedBox(height: 22),

              // ── Status chip "PRONTO · ATTIVAZIONE" ──────────────────────
              const Center(
                child: RkStatusChip(text: 'ATTIVAZIONE · CHIAVE LICENZA', active: false),
              ),
              const SizedBox(height: 18),

              // ── Titolo + subtitle ───────────────────────────────────────
              Text(
                'activation.title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'activation.subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.text3, height: 1.45),
                ),
              ),
              const SizedBox(height: 28),

              // ── Card chiave ─────────────────────────────────────────────
              RkCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CHIAVE',
                          style: TextStyle(
                            fontFamily: 'GeistMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: AppColors.text3,
                          ),
                        ),
                        Obx(() {
                          final ok = controller.isKeyValid;
                          final empty = controller.keyText.value.trim().isEmpty;
                          if (empty) return const SizedBox.shrink();
                          return Text(
                            ok ? '● VALIDA' : '○ INCOMPLETA',
                            style: TextStyle(
                              fontFamily: 'GeistMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: ok ? AppColors.autoDj : AppColors.text3,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      // No Obx qui: il TextField gestisce il suo testo da solo,
                      // non deve essere ri-buildato quando cambia keyText.
                      child: TextField(
                        onChanged: (v) => controller.keyText.value = v,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
                          LengthLimitingTextInputFormatter(24),
                          KeyAutoDashFormatter(),
                        ],
                        style: const TextStyle(
                          fontFamily: 'GeistMono',
                          fontSize: 16,
                          letterSpacing: 1.4,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'RK-XXXX-XXXX-XXXX-XXXX',
                          hintStyle: TextStyle(
                            fontFamily: 'GeistMono',
                            fontSize: 14,
                            color: AppColors.text4,
                            letterSpacing: 1.4,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Formato RK-, RKT-, RKR- o RKM-',
                      style: TextStyle(
                        fontFamily: 'GeistMono',
                        fontSize: 9,
                        color: AppColors.text3,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Obx(() {
                      final err = controller.error.value;
                      if (err == null || err.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, size: 16, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  err,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── CTA "Attiva" ────────────────────────────────────────────
              Obx(() => RkButton(
                fullWidth: true,
                size: RkBtnSize.lg,
                icon: controller.loading.value ? null : Icons.podcasts,
                onPressed: controller.loading.value || !controller.isKeyValid
                    ? null
                    : controller.activate,
                child: Text(controller.loading.value
                    ? 'common.loading'.tr
                    : 'activation.activate'.tr),
              )),
              const SizedBox(height: 18),

              // ── Footer hint ──────────────────────────────────────────────
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'La chiave si trova nella mail di benvenuto RadioKit.\nFunziona con account Diretta, Timer o Regia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 10,
                      color: AppColors.text3,
                      letterSpacing: 0.3,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HeroHalo: cerchio pulsante centrato con icona broadcast (riprende
// l'estetica del BroadcastHalo dello screen Stream).
// ─────────────────────────────────────────────────────────────────────────
class _HeroHalo extends StatefulWidget {
  const _HeroHalo();
  @override
  State<_HeroHalo> createState() => _HeroHaloState();
}

class _HeroHaloState extends State<_HeroHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132, height: 132,
      child: Stack(alignment: Alignment.center, children: [
        // 2 anelli pulsanti
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Transform.scale(
              scale: 1 + 0.30 * _ctrl.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.55 * (1 - _ctrl.value)),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final v = (_ctrl.value + 0.4) % 1.0;
            return Transform.scale(
              scale: 1 + 0.18 * v,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.4 * (1 - v)),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        // Disco centrale rosso
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.5),
              radius: 1.0,
              colors: [
                Color(0xFFEF8474),  // accent lighter
                Color(0xFFE6614F),  // accent
                Color(0xFFB94639),  // accent darker
              ],
              stops: [0, 0.65, 1],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.accent.withOpacity(0.45), blurRadius: 32),
            ],
          ),
          child: const Icon(Icons.podcasts, size: 42, color: Colors.white),
        ),
      ]),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Auto-formatter "smart paste":
/// - Typing manuale: NON tocca nulla — l'utente digita i "-" come vuole
/// - Paste di chiave intera senza trattini: 18 char → RK-…, 15 char → RKx-…
class KeyAutoDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('-', '');
    final oldRaw = oldValue.text.replaceAll('-', '');
    final isPaste = (raw.length - oldRaw.length).abs() > 1;
    if (!isPaste) return newValue;

    String? formatted;
    if (raw.length == 18 && raw.startsWith('RK')) {
      formatted = 'RK-${raw.substring(2, 6)}-${raw.substring(6, 10)}-${raw.substring(10, 14)}-${raw.substring(14, 18)}';
    } else if (raw.length == 15 &&
        (raw.startsWith('RKR') || raw.startsWith('RKT') || raw.startsWith('RKM'))) {
      formatted = '${raw.substring(0, 3)}-${raw.substring(3, 7)}-${raw.substring(7, 11)}-${raw.substring(11, 15)}';
    }
    if (formatted == null) return newValue;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
