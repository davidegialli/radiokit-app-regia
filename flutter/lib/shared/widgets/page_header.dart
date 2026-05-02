import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgElev,
        border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            _IconBtn(icon: Icons.arrow_back_ios_new, onTap: onBack!),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    style: const TextStyle(
                      fontFamily: 'GeistMono',
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Icon(icon, size: 14, color: AppColors.text2),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  const HeaderIconButton({super.key, required this.icon, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, size: 16, color: AppColors.text2),
            if (dot)
              const Positioned(
                top: 5, right: 5,
                child: SizedBox(
                  width: 6, height: 6,
                  child: DecoratedBox(decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
