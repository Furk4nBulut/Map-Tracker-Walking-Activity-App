import 'package:flutter/material.dart';

class Constants {
  // Spacing
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double textLg = 20.0;
  static const double textBase = 16.0;
  static const double textSm = 14.0;
  static const double textXs = 12.0;

  // Colors
  static const Color kykPrimary = Color(0xFF416FDF);
  static const Color kykGray800 = Color(0xFF23272F);
  static const Color kykGray700 = Color(0xFF2D323C);
  static const Color kykGray600 = Color(0xFF4B5563);
  static const Color kykGray500 = Color(0xFF6B7280);
  static const Color kykGray400 = Color(0xFF9CA3AF);
  static const Color kykGray300 = Color(0xFFD1D5DB);
  static const Color kykGray200 = Color(0xFFE5E7EB);
  static const Color kykGray100 = Color(0xFFF3F4F6);
  static const Color kykGray50 = Color(0xFFFAFAFA);
  static const Color kykGray900 = Color(0xFF111827);
  static const Color white = Colors.white;
  static const Color kykSuccess = Color(0xFF22C55E);
}


const OPENWEATHER_API_KEY = 'd6143ca52fdfb839fb639b667daea1f0';


const basarsoft_color = Color(0xFF02205C);
const basarsoft_color_light = Color(0xFF00A5FF);

void showErrorSnackbar(BuildContext context, String userMessage, {String? debugMessage, String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(userMessage),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Colors.white,
            )
          : null,
    ),
  );
  assert(() {
    if (debugMessage != null) debugPrint('DEBUG ERROR: ' + debugMessage);
    return true;
  }());
}