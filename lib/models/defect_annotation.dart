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

import 'dart:ui';

class DefectAnnotation {
  final int? id;
  final int defectId;
  final int photoNumber; // 1 or 2
  final double x; // percentage 0.0-1.0
  final double y; // percentage 0.0-1.0
  final double width; // percentage 0.0-1.0
  final double height; // percentage 0.0-1.0
  final String label;
  final String color; // classification color code: Rd, Or, Ge, Bl, Pa
  final int orderNumber;
  final String shape; // 'rect' or 'arrow'

  DefectAnnotation({
    this.id,
    required this.defectId,
    required this.photoNumber,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.1,
    this.height = 0.1,
    this.label = '',
    this.color = 'Ge',
    this.orderNumber = 1,
    this.shape = 'rect',
  });

  Rect getRect(Size imageSize) => Rect.fromLTWH(
        x * imageSize.width,
        y * imageSize.height,
        width * imageSize.width,
        height * imageSize.height,
      );

  /// Returns the annotation rect in display (canvas) coordinates.
  Rect getDisplayRect(Size displaySize) => Rect.fromLTWH(
        x * displaySize.width,
        y * displaySize.height,
        width * displaySize.width,
        height * displaySize.height,
      );

  /// For 'arrow' shapes: the start point in display (canvas) coordinates.
  Offset getStartOffset(Size displaySize) => Offset(
        x * displaySize.width,
        y * displaySize.height,
      );

  /// For 'arrow' shapes: the end point in display (canvas) coordinates.
  Offset getEndOffset(Size displaySize) => Offset(
        (x + width) * displaySize.width,
        (y + height) * displaySize.height,
      );

  static Color getColorForClassification(String classification) {
    switch (classification) {
      case 'Rd':
        return const Color(0xFFE53935);
      case 'Or':
        return const Color(0xFFFF9800);
      case 'Ge':
        return const Color(0xFFFDD835);
      case 'Bl':
        return const Color(0xFF1E88E5);
      case 'Pa':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFFFDD835);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'defect_id': defectId,
      'photo_number': photoNumber,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'label': label,
      'color': color,
      'order_number': orderNumber,
      'shape': shape,
    };
  }

  factory DefectAnnotation.fromMap(Map<String, dynamic> map) {
    return DefectAnnotation(
      id: map['id'] as int?,
      defectId: map['defect_id'] as int,
      photoNumber: map['photo_number'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      label: map['label'] as String? ?? '',
      color: map['color'] as String? ?? 'Ge',
      orderNumber: map['order_number'] as int? ?? 1,
      shape: map['shape'] as String? ?? 'rect',
    );
  }

  DefectAnnotation copyWith({
    int? id,
    int? defectId,
    int? photoNumber,
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    String? color,
    int? orderNumber,
    String? shape,
  }) {
    return DefectAnnotation(
      id: id ?? this.id,
      defectId: defectId ?? this.defectId,
      photoNumber: photoNumber ?? this.photoNumber,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
      color: color ?? this.color,
      orderNumber: orderNumber ?? this.orderNumber,
      shape: shape ?? this.shape,
    );
  }
}
