// Copyright (C) 2026 Jay Smeekes
//
// This file is part of MijnRapportage.
//
// MijnRapportage is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// MijnRapportage is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with MijnRapportage. If not, see <https://www.gnu.org/licenses/>.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/defect_annotation.dart';

/// Builds the filled arrowhead triangle at [to], pointing away from [from].
Path _arrowHeadPath(Offset from, Offset to) {
  const headLength = 16.0;
  const headAngle = 0.5; // radians
  final angle = (to - from).direction;
  final p1 = to -
      Offset(headLength * math.cos(angle - headAngle),
          headLength * math.sin(angle - headAngle));
  final p2 = to -
      Offset(headLength * math.cos(angle + headAngle),
          headLength * math.sin(angle + headAngle));
  return Path()
    ..moveTo(to.dx, to.dy)
    ..lineTo(p1.dx, p1.dy)
    ..lineTo(p2.dx, p2.dy)
    ..close();
}

class DefectAnnotationPainter extends CustomPainter {
  final List<DefectAnnotation> annotations;
  final Size imageSize; // kept for API compat, not used for painting
  final int? selectedIndex;
  final bool showHandles;

  DefectAnnotationPainter({
    required this.annotations,
    required this.imageSize,
    this.selectedIndex,
    this.showHandles = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];
      final color = DefectAnnotation.getColorForClassification(annotation.color);
      final isSelected = i == selectedIndex;

      if (annotation.shape == 'arrow' || annotation.shape == 'double_arrow') {
        _paintArrow(canvas, annotation, size, color, isSelected);
      } else {
        _paintRect(canvas, annotation, size, color, isSelected);
      }
    }
  }

  void _paintRect(Canvas canvas, DefectAnnotation annotation, Size size,
      Color color, bool isSelected) {
    // Use display coords (size = canvas size = displaySize)
    final rect = annotation.getDisplayRect(size);

    // Draw filled rectangle with transparency
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    canvas.drawRect(rect, borderPaint);

    _drawLabel(canvas, annotation, rect, color);

    // Draw resize handles for selected annotation
    if (isSelected && showHandles) {
      _drawHandle(canvas, rect.topLeft, color);
      _drawHandle(canvas, rect.topRight, color);
      _drawHandle(canvas, rect.bottomLeft, color);
      _drawHandle(canvas, rect.bottomRight, color);
    }
  }

  void _paintArrow(Canvas canvas, DefectAnnotation annotation, Size size,
      Color color, bool isSelected) {
    final start = annotation.getStartOffset(size);
    final end = annotation.getEndOffset(size);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, linePaint);

    // Arrowhead(s): a filled triangle at the end point, and also at the
    // start point for a double-headed ("kop-staart") arrow.
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(_arrowHeadPath(start, end), headPaint);
    if (annotation.shape == 'double_arrow') {
      canvas.drawPath(_arrowHeadPath(end, start), headPaint);
    }

    _drawLabel(canvas, annotation, Rect.fromPoints(start, end), color);

    if (isSelected && showHandles) {
      _drawHandle(canvas, start, color);
      _drawHandle(canvas, end, color);
    }
  }

  void _drawLabel(
      Canvas canvas, DefectAnnotation annotation, Rect boundingRect, Color color) {
    final labelText = annotation.label.isNotEmpty
        ? '${annotation.orderNumber}. ${annotation.label}'
        : '${annotation.orderNumber}';

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(
        maxWidth: boundingRect.width > 20 ? boundingRect.width - 4 : 100);

    final labelBgRect = Rect.fromLTWH(
      boundingRect.left,
      boundingRect.top - textPainter.height - 4,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    // Adjust if label would go above the image
    final adjustedLabelBg = labelBgRect.top < 0
        ? labelBgRect.translate(0, -labelBgRect.top + boundingRect.height + 4)
        : labelBgRect;

    final labelBgPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(adjustedLabelBg, const Radius.circular(2)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(adjustedLabelBg.left + 4, adjustedLabelBg.top + 2),
    );
  }

  void _drawHandle(Canvas canvas, Offset center, Color color) {
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 6, bgPaint);
    canvas.drawCircle(center, 6, borderPaint);
  }

  @override
  bool shouldRepaint(covariant DefectAnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        selectedIndex != oldDelegate.selectedIndex ||
        showHandles != oldDelegate.showHandles;
  }
}
