import 'package:flutter/material.dart';

/// Palette derivata dal prototipo design HTML/React.
/// Le sorgenti usano OKLCH; qui sono i corrispondenti sRGB.
/// Mantenere allineate con `design/styles.css`.
class AppColors {
  AppColors._();

  // Background scale
  static const Color bg        = Color(0xFF1F2126); // oklch(0.16 0.005 260)
  static const Color bgElev    = Color(0xFF272A2F); // oklch(0.20)
  static const Color surface   = Color(0xFF2D3036); // oklch(0.23)
  static const Color surface2  = Color(0xFF353941); // oklch(0.27)
  static const Color hairline  = Color(0xFF42464E); // oklch(0.32)
  static const Color hairlineSoft = Color(0xFF393D45); // oklch(0.28)

  // Text scale
  static const Color text  = Color(0xFFF1F2F4); // oklch(0.96)
  static const Color text2 = Color(0xFFC2C5C9); // oklch(0.78)
  static const Color text3 = Color(0xFF888C92); // oklch(0.58)
  static const Color text4 = Color(0xFF5E6168); // oklch(0.42)

  // Stati
  static const Color accent     = Color(0xFFE6614F); // ON AIR red
  static const Color accentSoft = Color(0x29E6614F); // alpha .16
  static const Color autoDj     = Color(0xFF5FC594); // green
  static const Color autoDjSoft = Color(0x295FC594);
  static const Color warn       = Color(0xFFE3B85A); // amber
  static const Color warnSoft   = Color(0x29E3B85A);
  static const Color info       = Color(0xFF6BB1E0); // push blue

  // Brand Stereo 98 (per quando si usa profilo radio Stereo 98)
  static const Color brandPink  = Color(0xFFD61F7A);
  static const Color brandCyan  = Color(0xFF5BC4F2);
}
