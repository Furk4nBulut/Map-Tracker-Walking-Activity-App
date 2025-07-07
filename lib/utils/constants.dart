import 'package:flutter/material.dart';

// Colors
const kBackgroundColor = Color(0xFFD2FFF4);
const kPrimaryColor = Color(0xFF2D5D70);
const kSecondaryColor = Color(0xFF265DAB);


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