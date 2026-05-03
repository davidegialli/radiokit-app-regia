import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Placeholder coerente per le tab non ancora implementate.
/// Mostra icona, titolo, descrizione e una lista bullet di cosa sara' disponibile.
class ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const ComingSoon({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.features = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: Icon(icon, size: 32, color: AppColors.text3),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text, letterSpacing: -0.2)),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.5)),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5, right: 8),
                        child: Icon(Icons.circle, size: 4, color: AppColors.accent),
                      ),
                      Expanded(child: Text(f,
                        style: const TextStyle(fontSize: 11, color: AppColors.text2, height: 1.5))),
                    ]),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
