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

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/defect_annotation.dart';
import 'defect_annotation_painter.dart';

enum AnnotationShape { rectangle, arrow, doubleArrow }

/// True for any shape drawn as a line between two points (as opposed to a
/// rectangle): single-headed and double-headed ("kop-staart") arrows.
bool _isArrowShape(String shape) => shape == 'arrow' || shape == 'double_arrow';

class DefectPhotoAnnotator extends StatefulWidget {
  final String photoPath;
  final List<DefectAnnotation> annotations;
  final bool editMode;
  final int? selectedIndex;
  final AnnotationShape activeShape;
  final ValueChanged<int?>? onSelectionChanged;
  final void Function(DefectAnnotation annotation)? onAnnotationUpdated;
  final void Function(Offset start, Offset end, String shape)? onNewAnnotation;

  const DefectPhotoAnnotator({
    super.key,
    required this.photoPath,
    required this.annotations,
    this.editMode = false,
    this.selectedIndex,
    this.activeShape = AnnotationShape.rectangle,
    this.onSelectionChanged,
    this.onAnnotationUpdated,
    this.onNewAnnotation,
  });

  @override
  State<DefectPhotoAnnotator> createState() => _DefectPhotoAnnotatorState();
}

enum _GestureMode { none, drawing, moving, resizing }

class _DefectPhotoAnnotatorState extends State<DefectPhotoAnnotator> {
  ui.Image? _image;
  Size _imageSize = Size.zero;

  // Updated every build from LayoutBuilder — used by all gesture handlers.
  Size _displaySize = Size.zero;

  _GestureMode _gestureMode = _GestureMode.none;
  String? _resizeHandle;

  // Drawing state (display coords)
  Offset? _drawStart;
  Offset? _drawEnd;

  // Move/resize state
  Offset? _moveStartNorm; // normalized (0-1) position where drag started
  DefectAnnotation? _moveOriginal; // annotation snapshot at drag start
  DefectAnnotation? _draggingAnnotation; // live local state during drag

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant DefectPhotoAnnotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final file = File(widget.photoPath);
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = frame.image;
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
  }

  Size _getDisplaySize(BoxConstraints constraints) {
    if (_imageSize == Size.zero) return constraints.biggest;
    final w = constraints.biggest;
    final sx = _imageSize.width / w.width;
    final sy = _imageSize.height / w.height;
    final s = sx > sy ? sx : sy;
    return Size(_imageSize.width / s, _imageSize.height / s);
  }

  // ── Hit testing in display coordinates ────────────────────────────────────

  /// Returns which resize handle the display-coord [pos] hits, or null.
  /// Uses a 22 dp radius so handles are easy to grab.
  String? _hitTestHandle(DefectAnnotation a, Offset pos) {
    const r = 22.0;
    if (_isArrowShape(a.shape)) {
      final start = a.getStartOffset(_displaySize);
      final end = a.getEndOffset(_displaySize);
      if ((pos - start).distance <= r) return 'start';
      if ((pos - end).distance <= r) return 'end';
      return null;
    }
    final rect = a.getDisplayRect(_displaySize);
    if ((pos - rect.topLeft).distance <= r) return 'tl';
    if ((pos - rect.topRight).distance <= r) return 'tr';
    if ((pos - rect.bottomLeft).distance <= r) return 'bl';
    if ((pos - rect.bottomRight).distance <= r) return 'br';
    return null;
  }

  /// Returns true if display-coord [pos] is inside (or near) annotation [a].
  bool _hitTestBody(DefectAnnotation a, Offset pos) {
    if (_isArrowShape(a.shape)) {
      final start = a.getStartOffset(_displaySize);
      final end = a.getEndOffset(_displaySize);
      return _distanceToSegment(pos, start, end) <= 14.0;
    }
    return a.getDisplayRect(_displaySize).inflate(8).contains(pos);
  }

  /// Shortest distance from point [p] to the line segment [a]-[b].
  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSq == 0) return (p - a).distance;
    var t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lengthSq;
    t = t.clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).distance;
  }

  // ── Effective annotation list (merges live drag state) ────────────────────

  List<DefectAnnotation> get _effectiveAnnotations {
    if (_draggingAnnotation == null || widget.selectedIndex == null) {
      return widget.annotations;
    }
    final list = List<DefectAnnotation>.from(widget.annotations);
    final idx = widget.selectedIndex!;
    if (idx < list.length) list[idx] = _draggingAnnotation!;
    return list;
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _handlePanStart(DragStartDetails details) {
    if (!widget.editMode || _displaySize == Size.zero) return;
    final pos = details.localPosition;

    // 1. Check resize handles on the currently selected annotation.
    if (widget.selectedIndex != null &&
        widget.selectedIndex! < widget.annotations.length) {
      final sel = widget.annotations[widget.selectedIndex!];
      final handle = _hitTestHandle(sel, pos);
      if (handle != null) {
        setState(() {
          _gestureMode = _GestureMode.resizing;
          _resizeHandle = handle;
          _moveOriginal = sel;
        });
        return;
      }
    }

    // 2. Check annotation bodies (topmost first).
    for (var i = widget.annotations.length - 1; i >= 0; i--) {
      if (_hitTestBody(widget.annotations[i], pos)) {
        widget.onSelectionChanged?.call(i);
        setState(() {
          _gestureMode = _GestureMode.moving;
          _moveStartNorm = Offset(
            pos.dx / _displaySize.width,
            pos.dy / _displaySize.height,
          );
          _moveOriginal = widget.annotations[i];
        });
        return;
      }
    }

    // 3. Start drawing a new annotation.
    widget.onSelectionChanged?.call(null);
    setState(() {
      _gestureMode = _GestureMode.drawing;
      _drawStart = pos;
      _drawEnd = pos;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.editMode || _displaySize == Size.zero) return;
    final pos = details.localPosition;

    switch (_gestureMode) {
      case _GestureMode.drawing:
        setState(() => _drawEnd = pos);

      case _GestureMode.moving:
        if (_moveStartNorm != null && _moveOriginal != null) {
          final nx = pos.dx / _displaySize.width;
          final ny = pos.dy / _displaySize.height;
          final dx = nx - _moveStartNorm!.dx;
          final dy = ny - _moveStartNorm!.dy;
          double newX, newY;
          if (_isArrowShape(_moveOriginal!.shape)) {
            newX = (_moveOriginal!.x + dx).clamp(0.0, 1.0);
            newY = (_moveOriginal!.y + dy).clamp(0.0, 1.0);
          } else {
            newX =
                (_moveOriginal!.x + dx).clamp(0.0, 1.0 - _moveOriginal!.width);
            newY = (_moveOriginal!.y + dy)
                .clamp(0.0, 1.0 - _moveOriginal!.height);
          }
          setState(() {
            _draggingAnnotation = _moveOriginal!.copyWith(x: newX, y: newY);
          });
        }

      case _GestureMode.resizing:
        if (_moveOriginal != null && _resizeHandle != null) {
          _applyResize(pos);
        }

      case _GestureMode.none:
        break;
    }
  }

  void _applyResize(Offset pos) {
    final orig = _moveOriginal!;
    final nx = (pos.dx / _displaySize.width).clamp(0.0, 1.0);
    final ny = (pos.dy / _displaySize.height).clamp(0.0, 1.0);

    if (_isArrowShape(orig.shape)) {
      if (_resizeHandle == 'start') {
        final endX = orig.x + orig.width;
        final endY = orig.y + orig.height;
        setState(() {
          _draggingAnnotation = orig.copyWith(
              x: nx, y: ny, width: endX - nx, height: endY - ny);
        });
      } else if (_resizeHandle == 'end') {
        setState(() {
          _draggingAnnotation =
              orig.copyWith(width: nx - orig.x, height: ny - orig.y);
        });
      }
      return;
    }

    double newX = orig.x, newY = orig.y, newW = orig.width, newH = orig.height;
    const minSize = 0.02;

    switch (_resizeHandle) {
      case 'tl':
        newW = (orig.x + orig.width - nx).clamp(minSize, 1.0);
        newH = (orig.y + orig.height - ny).clamp(minSize, 1.0);
        newX = (orig.x + orig.width - newW).clamp(0.0, 1.0);
        newY = (orig.y + orig.height - newH).clamp(0.0, 1.0);
      case 'tr':
        newW = (nx - orig.x).clamp(minSize, 1.0 - orig.x);
        newH = (orig.y + orig.height - ny).clamp(minSize, 1.0);
        newY = (orig.y + orig.height - newH).clamp(0.0, 1.0);
      case 'bl':
        newW = (orig.x + orig.width - nx).clamp(minSize, 1.0);
        newX = (orig.x + orig.width - newW).clamp(0.0, 1.0);
        newH = (ny - orig.y).clamp(minSize, 1.0 - orig.y);
      case 'br':
        newW = (nx - orig.x).clamp(minSize, 1.0 - orig.x);
        newH = (ny - orig.y).clamp(minSize, 1.0 - orig.y);
    }

    setState(() {
      _draggingAnnotation =
          orig.copyWith(x: newX, y: newY, width: newW, height: newH);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.editMode) return;

    if (_gestureMode == _GestureMode.drawing &&
        _drawStart != null &&
        _drawEnd != null) {
      // Convert display coords → normalized
      final x1 = (_drawStart!.dx / _displaySize.width).clamp(0.0, 1.0);
      final y1 = (_drawStart!.dy / _displaySize.height).clamp(0.0, 1.0);
      final x2 = (_drawEnd!.dx / _displaySize.width).clamp(0.0, 1.0);
      final y2 = (_drawEnd!.dy / _displaySize.height).clamp(0.0, 1.0);

      if (widget.activeShape != AnnotationShape.rectangle) {
        final start = Offset(x1, y1);
        final end = Offset(x2, y2);
        if ((end - start).distance > 0.02) {
          final shapeStr = widget.activeShape == AnnotationShape.doubleArrow
              ? 'double_arrow'
              : 'arrow';
          widget.onNewAnnotation?.call(start, end, shapeStr);
        }
      } else {
        final left = x1 < x2 ? x1 : x2;
        final top = y1 < y2 ? y1 : y2;
        final w = (x1 - x2).abs();
        final h = (y1 - y2).abs();

        if (w > 0.02 && h > 0.02) {
          widget.onNewAnnotation
              ?.call(Offset(left, top), Offset(left + w, top + h), 'rect');
        }
      }
    } else if (_draggingAnnotation != null) {
      // Single DB write at the end of the drag (not per-frame).
      widget.onAnnotationUpdated?.call(_draggingAnnotation!);
    }

    setState(() {
      _gestureMode = _GestureMode.none;
      _drawStart = null;
      _drawEnd = null;
      _moveStartNorm = null;
      _moveOriginal = null;
      _resizeHandle = null;
      _draggingAnnotation = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      _displaySize = _getDisplaySize(constraints);

      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        // Disable pan/scale while editing so they don't compete with the
        // inner GestureDetector's drag recognizer.
        panEnabled: !widget.editMode,
        scaleEnabled: !widget.editMode,
        child: Center(
          child: SizedBox(
            width: _displaySize.width,
            height: _displaySize.height,
            child: GestureDetector(
              onPanStart: widget.editMode ? _handlePanStart : null,
              onPanUpdate: widget.editMode ? _handlePanUpdate : null,
              onPanEnd: widget.editMode ? _handlePanEnd : null,
              onTapUp: widget.editMode
                  ? (d) {
                      for (var i = widget.annotations.length - 1;
                          i >= 0;
                          i--) {
                        if (_hitTestBody(
                            widget.annotations[i], d.localPosition)) {
                          widget.onSelectionChanged?.call(i);
                          return;
                        }
                      }
                      widget.onSelectionChanged?.call(null);
                    }
                  : null,
              child: CustomPaint(
                foregroundPainter: DefectAnnotationPainter(
                  annotations: _effectiveAnnotations,
                  imageSize: _imageSize,
                  selectedIndex: widget.selectedIndex,
                  showHandles: widget.editMode,
                ),
                child: Stack(
                  children: [
                    Image.file(
                      File(widget.photoPath),
                      fit: BoxFit.contain,
                      width: _displaySize.width,
                      height: _displaySize.height,
                    ),
                    if (_gestureMode == _GestureMode.drawing &&
                        _drawStart != null &&
                        _drawEnd != null)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DrawingPreviewPainter(
                            start: _drawStart!,
                            current: _drawEnd!,
                            shape: widget.activeShape,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Builds the filled arrowhead triangle at [to], pointing away from [from].
Path _arrowHeadPath(Offset from, Offset to) {
  const headLength = 16.0;
  const headAngle = 0.5;
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

// ── Drawing preview painter (display coords) ──────────────────────────────

class _DrawingPreviewPainter extends CustomPainter {
  final Offset start;
  final Offset current;
  final AnnotationShape shape;

  _DrawingPreviewPainter({
    required this.start,
    required this.current,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shape != AnnotationShape.rectangle) {
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, current, paint);

      final headPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawPath(_arrowHeadPath(start, current), headPaint);
      if (shape == AnnotationShape.doubleArrow) {
        canvas.drawPath(_arrowHeadPath(current, start), headPaint);
      }
      return;
    }

    final rect = Rect.fromPoints(start, current);

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _DrawingPreviewPainter old) =>
      start != old.start || current != old.current || shape != old.shape;
}
