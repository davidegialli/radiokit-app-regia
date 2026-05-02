import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Card scura con bordo hairline — equivalente a `<Card padded>` del prototipo.
class RkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  const RkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? AppColors.bgElev : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: child,
    );
  }
}
