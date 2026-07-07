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

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/defect_annotation.dart';
import '../services/database_service.dart';
import '../widgets/defect_photo_annotator.dart';

class DefectAnnotationScreen extends StatefulWidget {
  final int defectId;
  final int photoNumber;
  final String photoPath;
  final String classification;

  const DefectAnnotationScreen({
    super.key,
    required this.defectId,
    required this.photoNumber,
    required this.photoPath,
    required this.classification,
  });

  @override
  State<DefectAnnotationScreen> createState() => _DefectAnnotationScreenState();
}

class _DefectAnnotationScreenState extends State<DefectAnnotationScreen> {
  final _db = DatabaseService();
  List<DefectAnnotation> _annotations = [];
  bool _editMode = true;
  int? _selectedIndex;
  bool _loading = true;
  AnnotationShape _activeShape = AnnotationShape.rectangle;

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  Future<void> _loadAnnotations() async {
    final annotations =
        await _db.getAnnotations(widget.defectId, widget.photoNumber);
    setState(() {
      _annotations = annotations;
      _loading = false;
    });
  }

  Future<void> _addAnnotation(Offset start, Offset end, String shape) async {
    final nextNumber = await _db.getNextAnnotationNumber(widget.defectId);
    final annotation = DefectAnnotation(
      defectId: widget.defectId,
      photoNumber: widget.photoNumber,
      x: start.dx,
      y: start.dy,
      width: end.dx - start.dx,
      height: end.dy - start.dy,
      label: '',
      color: widget.classification,
      orderNumber: nextNumber,
      shape: shape,
    );
    final id = await _db.insertAnnotation(annotation);
    await _loadAnnotations();
    // Select the new annotation
    final newIndex = _annotations.indexWhere((a) => a.id == id);
    setState(() {
      _selectedIndex = newIndex >= 0 ? newIndex : null;
    });
    if (newIndex >= 0) {
      _showLabelDialog(newIndex);
    }
  }

  Future<void> _updateAnnotation(DefectAnnotation annotation) async {
    await _db.updateAnnotation(annotation);
    await _loadAnnotations();
  }

  Future<void> _deleteAnnotation(int index) async {
    final annotation = _annotations[index];
    if (annotation.id == null) return;
    await _db.deleteAnnotation(annotation.id!, widget.defectId);
    setState(() {
      _selectedIndex = null;
    });
    await _loadAnnotations();
  }

  Future<void> _showLabelDialog(int index) async {
    final annotation = _annotations[index];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _LabelDialog(
        orderNumber: annotation.orderNumber,
        initialLabel: annotation.label,
      ),
    );

    if (result != null) {
      final updated = annotation.copyWith(label: result);
      await _updateAnnotation(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final classColor =
        DefectAnnotation.getColorForClassification(widget.classification);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.annotationsPhotoTitle(widget.photoNumber)),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.visibility : Icons.edit),
            tooltip: _editMode ? l10n.viewMode : l10n.editMode,
            onPressed: () {
              setState(() {
                _editMode = !_editMode;
                if (!_editMode) _selectedIndex = null;
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Instructions bar
                if (_editMode)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: classColor.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedIndex != null
                                ? l10n.dragToMove
                                : (_activeShape == AnnotationShape.rectangle
                                    ? l10n.drawRectangle
                                    : l10n.drawArrow),
                            style: TextStyle(
                              fontSize: 13,
                              color: classColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        SegmentedButton<AnnotationShape>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: [
                            ButtonSegment(
                              value: AnnotationShape.rectangle,
                              icon: const Icon(Icons.crop_square, size: 18),
                              tooltip: l10n.rectangleTool,
                            ),
                            ButtonSegment(
                              value: AnnotationShape.arrow,
                              icon: const Icon(Icons.north_east, size: 18),
                              tooltip: l10n.arrowTool,
                            ),
                            ButtonSegment(
                              value: AnnotationShape.doubleArrow,
                              icon: const Icon(Icons.compare_arrows, size: 18),
                              tooltip: l10n.doubleArrowTool,
                            ),
                          ],
                          selected: {_activeShape},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _activeShape = selection.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                // Photo with annotations
                Expanded(
                  child: DefectPhotoAnnotator(
                    photoPath: widget.photoPath,
                    annotations: _annotations,
                    editMode: _editMode,
                    selectedIndex: _selectedIndex,
                    activeShape: _activeShape,
                    onSelectionChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onAnnotationUpdated: (annotation) {
                      _updateAnnotation(annotation);
                    },
                    onNewAnnotation: (start, end, shape) {
                      _addAnnotation(start, end, shape);
                    },
                  ),
                ),
                // Annotation list
                if (_annotations.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _annotations.length,
                      itemBuilder: (context, index) {
                        final annotation = _annotations[index];
                        final color =
                            DefectAnnotation.getColorForClassification(
                                annotation.color);
                        final isSelected = index == _selectedIndex;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: color.withValues(alpha: 0.08),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: color,
                            child: Text(
                              '${annotation.orderNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            annotation.label.isNotEmpty
                                ? annotation.label
                                : l10n.noLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: annotation.label.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: annotation.label.isEmpty
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          trailing: _editMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () =>
                                          _showLabelDialog(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      onPressed: () =>
                                          _confirmDeleteAnnotation(index),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmDeleteAnnotation(int index) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAnnotation),
        content: Text(l10n.deleteAnnotationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAnnotation(index);
    }
  }
}

class _LabelDialog extends StatefulWidget {
  final int orderNumber;
  final String initialLabel;

  const _LabelDialog({
    required this.orderNumber,
    required this.initialLabel,
  });

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.annotationNumber(widget.orderNumber)),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: l10n.label,
          hintText: l10n.defectDescriptionHint,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
