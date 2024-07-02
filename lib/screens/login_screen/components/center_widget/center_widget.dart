import 'dart:ui';

import 'package:flutter/material.dart';

import 'center_widget_clipper.dart';
import 'center_widget_painter.dart';

class CenterWidget extends StatelessWidget {
  final Size size;

  const CenterWidget({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = size.width;
    final height = size.height;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    return Stack(
      children: [
        CustomPaint(
          painter: CenterWidgetPainter(path: path),
        ),
        ClipPath(
          clipper: CenterWidgetClipper(path: path),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
            ),
          ),
        ),
      ],
    );
  }
}
