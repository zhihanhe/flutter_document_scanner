
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';

@Deprecated('这个方式不可行，会导致整个页面被遮住')
/// 线中间整体拖动的部分
class BorderCropMidPainter extends CustomPainter {
  /// Create a painter for the given [Area].
  const BorderCropMidPainter({
    required this.area,
    required this.colorBorderArea,
    required this.widthBorderArea,
  });

  /// 4个角的四周位置
  final Area area;

  /// Color of the border covering the clipping mask
  ///
  /// Can be modified from [CropPhotoDocumentStyle.colorBorderArea]
  final Color colorBorderArea;

  /// Width of the border covering the clipping mask
  ///
  /// Can be modified from [CropPhotoDocumentStyle.widthBorderArea]
  final double widthBorderArea;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = widthBorderArea
      ..color = colorBorderArea;
    

    const double borderRadiusRadius = 20;
    final Rect rect = Rect.fromCenter(center: Offset((area.topLeft.x + area.bottomLeft.x)/2, (area.topLeft.y + area.bottomLeft.y)/2), width: 20, height: 40);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadiusRadius));

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}