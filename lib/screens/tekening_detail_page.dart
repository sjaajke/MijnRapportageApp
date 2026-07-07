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
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/defect.dart';
import '../models/tekening.dart';
import '../models/tekening_pin.dart';
import '../services/database_service.dart';

class TekeningDetailPage extends StatefulWidget {
  final Tekening tekening;

  const TekeningDetailPage({super.key, required this.tekening});

  @override
  State<TekeningDetailPage> createState() => _TekeningDetailPageState();
}

class _TekeningDetailPageState extends State<TekeningDetailPage> {
  final _db = DatabaseService();
  final _transformController = TransformationController();

  Uint8List? _imageBytes;
  Size _naturalSize = Size.zero;

  List<TekeningPin> _pins = [];
  int? _selectedPinIndex;
  bool _addMode = false;
  String _selectedKleur = 'Gr';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final bytes = await _loadImage();
      final pins = await _db.getTekeningPins(widget.tekening.id!);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _pins = pins;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kan bestand niet laden: $e';
          _loading = false;
        });
      }
    }
  }

  Future<Uint8List> _loadImage() async {
    final path = widget.tekening.bestandPad;
    if (widget.tekening.bestandType == 'pdf') {
      return await _renderPdf(path);
    } else {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _naturalSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      return bytes;
    }
  }

  Future<Uint8List> _renderPdf(String path) async {
    final doc = await PdfDocument.openFile(path);
    final page = await doc.getPage(1);
    const scale = 2.0;
    final image = await page.render(
      width: page.width * scale,
      height: page.height * scale,
      format: PdfPageImageFormat.png,
    );
    _naturalSize = Size(page.width * scale, page.height * scale);
    await page.close();
    await doc.close();
    if (image == null) throw Exception('PDF rendering mislukt');
    return image.bytes;
  }

  Future<void> _reloadPins() async {
    final pins = await _db.getTekeningPins(widget.tekening.id!);
    if (mounted) setState(() => _pins = pins);
  }

  Size _calcDisplaySize(BoxConstraints constraints) {
    final viewW = constraints.maxWidth;
    final viewH = constraints.maxHeight;
    if (_naturalSize == Size.zero || viewW == 0 || viewH == 0) {
      return Size(viewW == 0 ? 400 : viewW, viewH == 0 ? 400 : viewH);
    }
    final scaleX = viewW / _naturalSize.width;
    final scaleY = viewH / _naturalSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    return Size(_naturalSize.width * scale, _naturalSize.height * scale);
  }

  void _handleTap(Offset localPos, Size displaySize) {
    // Hit-test against existing pins (18px touch radius)
    for (var i = _pins.length - 1; i >= 0; i--) {
      final pin = _pins[i];
      final pinPos = Offset(
        pin.x * displaySize.width,
        pin.y * displaySize.height,
      );
      if ((localPos - pinPos).distance <= 18) {
        if (_addMode) {
          _showPinDialog(existingIndex: i);
        } else {
          setState(() =>
              _selectedPinIndex = _selectedPinIndex == i ? null : i);
        }
        return;
      }
    }
    if (_addMode) {
      final x = (localPos.dx / displaySize.width).clamp(0.0, 1.0);
      final y = (localPos.dy / displaySize.height).clamp(0.0, 1.0);
      _showPinDialog(newX: x, newY: y);
    } else {
      setState(() => _selectedPinIndex = null);
    }
  }

  Future<void> _showPinDialog({int? existingIndex, double? newX, double? newY}) async {
    final existing = existingIndex != null ? _pins[existingIndex] : null;
    final nextNum = _pins.isEmpty
        ? 1
        : _pins.map((p) => p.volgnummer).reduce((a, b) => a > b ? a : b) + 1;

    final result = await showDialog<TekeningPin>(
      context: context,
      builder: (ctx) => _PinConfigDialog(
        inspectionId: widget.tekening.inspectionId,
        tekeningId: widget.tekening.id!,
        existing: existing,
        newX: newX ?? existing?.x ?? 0.5,
        newY: newY ?? existing?.y ?? 0.5,
        defaultKleur: existing?.kleur ?? _selectedKleur,
        nextVolgnummer: existing?.volgnummer ?? nextNum,
      ),
    );
    if (result == null || !mounted) return;

    if (result.id != null) {
      await _db.updateTekeningPin(result);
    } else {
      await _db.insertTekeningPin(result);
    }
    setState(() => _selectedKleur = result.kleur);
    await _reloadPins();
  }

  Future<void> _deletePin(int index) async {
    final pin = _pins[index];
    if (pin.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pin verwijderen'),
        content: Text('Pin ${pin.volgnummer} verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteTekeningPin(pin.id!);
      if (mounted) {
        setState(() {
          if (_selectedPinIndex == index) _selectedPinIndex = null;
        });
      }
      await _reloadPins();
    }
  }

  List<Widget> _buildPins(Size displaySize) {
    return _pins.asMap().entries.map((entry) {
      final index = entry.key;
      final pin = entry.value;
      final isSelected = _selectedPinIndex == index;
      final color = TekeningPin.getColor(pin.kleur);
      final size = isSelected ? 16.0 : 14.0;
      return Positioned(
        left: pin.x * displaySize.width - size / 2,
        top: pin.y * displaySize.height - size / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.55)
                    : Colors.black38,
                blurRadius: isSelected ? 4 : 2,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${pin.volgnummer}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSelected ? 7 : 6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final naam = widget.tekening.naam.isNotEmpty
        ? widget.tekening.naam
        : 'Tekening';
    return Scaffold(
      appBar: AppBar(
        title: Text(naam),
        actions: [
          if (_selectedPinIndex != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Pin verwijderen',
              onPressed: () => _deletePin(_selectedPinIndex!),
            ),
          IconButton(
            icon: Icon(
                _addMode ? Icons.pan_tool_outlined : Icons.add_location_alt),
            tooltip: _addMode ? 'Navigatiemodus' : 'Pin toevoegen',
            onPressed: () => setState(() {
              _addMode = !_addMode;
              if (_addMode) _selectedPinIndex = null;
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(children: [
                  _buildModeBar(),
                  Expanded(child: _buildDrawingArea()),
                  if (_pins.isNotEmpty) _buildPinList(),
                ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBar() {
    return Container(
      color: _addMode
          ? const Color(0xFF1976D2).withValues(alpha: 0.08)
          : Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Icon(
            _addMode ? Icons.add_location_alt : Icons.touch_app,
            size: 17,
            color: _addMode
                ? const Color(0xFF1976D2)
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _addMode
                  ? 'Tik op de tekening om een pin te plaatsen'
                  : 'Navigatiemodus — tik op een pin om te selecteren',
              style: TextStyle(
                fontSize: 12,
                color: _addMode
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          if (_addMode) ...[
            const SizedBox(width: 4),
            ..._buildKleurPicker(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildKleurPicker() {
    return TekeningPin.kleurNamen.keys.map((kleur) {
      final isSelected = kleur == _selectedKleur;
      return GestureDetector(
        onTap: () => setState(() => _selectedKleur = kleur),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          width: isSelected ? 24 : 20,
          height: isSelected ? 24 : 20,
          decoration: BoxDecoration(
            color: TekeningPin.getColor(kleur),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black87 : Colors.white,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: isSelected ? 3 : 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDrawingArea() {
    if (_imageBytes == null) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final displaySize = _calcDisplaySize(constraints);
      return InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.3,
        maxScale: 10.0,
        boundaryMargin: const EdgeInsets.all(80),
        child: Center(
          child: SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: GestureDetector(
              onTapUp: (d) => _handleTap(d.localPosition, displaySize),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.memory(
                    _imageBytes!,
                    width: displaySize.width,
                    height: displaySize.height,
                    fit: BoxFit.fill,
                  ),
                  ..._buildPins(displaySize),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPinList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Pins (${_pins.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pins.length,
              itemBuilder: (_, index) {
                final pin = _pins[index];
                final color = TekeningPin.getColor(pin.kleur);
                final isSelected = _selectedPinIndex == index;
                return InkWell(
                  onTap: () => setState(() =>
                      _selectedPinIndex = isSelected ? null : index),
                  child: Container(
                    color: isSelected
                        ? color.withValues(alpha: 0.08)
                        : null,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: color,
                          child: Text(
                            '${pin.volgnummer}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pin.typeLabel,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                _pinDescription(pin),
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () =>
                              _showPinDialog(existingIndex: index),
                          tooltip: 'Bewerken',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () => _deletePin(index),
                          tooltip: 'Verwijderen',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _pinDescription(TekeningPin pin) {
    switch (pin.type) {
      case 'meting':
        if (pin.metingType == 'Zi+Zs') {
          final parts = pin.metingWaarde.split('|');
          final zi = parts.isNotEmpty ? parts[0] : '';
          final zs = parts.length > 1 ? parts[1] : '';
          return 'Zi: $zi Ω / Zs: $zs Ω';
        }
        if (pin.metingType.isNotEmpty) {
          return '${pin.metingType}: ${pin.metingWaarde} ${pin.metingEenheid}';
        }
        return pin.label.isNotEmpty ? pin.label : '(geen waarde)';
      case 'constatering':
        return pin.label.isNotEmpty
            ? pin.label
            : '(constatering gekoppeld)';
      default:
        return pin.label.isNotEmpty ? pin.label : '(geen label)';
    }
  }
}

// ── Pin configuratie dialoog ────────────────────────────────────────────────

class _PinConfigDialog extends StatefulWidget {
  final int inspectionId;
  final int tekeningId;
  final TekeningPin? existing;
  final double newX;
  final double newY;
  final String defaultKleur;
  final int nextVolgnummer;

  const _PinConfigDialog({
    required this.inspectionId,
    required this.tekeningId,
    required this.existing,
    required this.newX,
    required this.newY,
    required this.defaultKleur,
    required this.nextVolgnummer,
  });

  @override
  State<_PinConfigDialog> createState() => _PinConfigDialogState();
}

class _PinConfigDialogState extends State<_PinConfigDialog> {
  List<Defect> _defects = [];
  bool _defectsLoading = true;

  late String _kleur;
  late String _type;
  int? _defectId;
  late String _metingType;
  final _waardeCtrl = TextEditingController();
  final _waarde2Ctrl = TextEditingController(); // Zs-waarde bij Zi+Zs
  final _eenheidCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _kleur = ex?.kleur ?? widget.defaultKleur;
    _type = ex?.type ?? 'notitie';
    _defectId = ex?.defectId;
    _metingType =
        (ex?.metingType.isNotEmpty ?? false) ? ex!.metingType : 'Zi';
    if (_metingType == 'Zi+Zs') {
      final parts = (ex?.metingWaarde ?? '').split('|');
      _waardeCtrl.text = parts.isNotEmpty ? parts[0] : '';
      _waarde2Ctrl.text = parts.length > 1 ? parts[1] : '';
    } else {
      _waardeCtrl.text = ex?.metingWaarde ?? '';
    }
    _eenheidCtrl.text =
        (ex?.metingEenheid.isNotEmpty ?? false) ? ex!.metingEenheid : 'Ω';
    _labelCtrl.text = ex?.label ?? '';
    _loadDefects();
  }

  @override
  void dispose() {
    _waardeCtrl.dispose();
    _waarde2Ctrl.dispose();
    _eenheidCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefects() async {
    final list = await DatabaseService().getDefects(widget.inspectionId);
    if (mounted) {
      setState(() {
        _defects = list;
        _defectsLoading = false;
      });
    }
  }

  TekeningPin _buildPin() => TekeningPin(
        id: widget.existing?.id,
        tekeningId: widget.tekeningId,
        x: widget.newX,
        y: widget.newY,
        kleur: _kleur,
        type: _type,
        defectId: _type == 'constatering' ? _defectId : null,
        metingType: _type == 'meting' ? _metingType : '',
        metingWaarde: _type == 'meting'
            ? (_metingType == 'Zi+Zs'
                ? '${_waardeCtrl.text.trim()}|${_waarde2Ctrl.text.trim()}'
                : _waardeCtrl.text.trim())
            : '',
        metingEenheid: _type == 'meting'
            ? (_metingType == 'Overig' ? _eenheidCtrl.text.trim() : 'Ω')
            : 'Ω',
        label: _labelCtrl.text.trim(),
        volgnummer:
            widget.existing?.volgnummer ?? widget.nextVolgnummer,
      );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Nieuwe pin' : 'Pin bewerken'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKleurSection(),
            const SizedBox(height: 14),
            _buildTypeSection(),
            const SizedBox(height: 12),
            _buildTypeFields(),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _buildPin()),
          child: Text(isNew ? 'Plaatsen' : 'Opslaan'),
        ),
      ],
    );
  }

  Widget _buildKleurSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kleur',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: TekeningPin.kleurNamen.entries.map((entry) {
            final isSelected = entry.key == _kleur;
            return GestureDetector(
              onTap: () => setState(() => _kleur = entry.key),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isSelected ? 36 : 30,
                    height: isSelected ? 36 : 30,
                    decoration: BoxDecoration(
                      color: TekeningPin.getColor(entry.key),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.black87
                            : Colors.white,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: isSelected ? 4 : 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _typeChip('notitie', 'Notitie', Icons.notes),
            _typeChip(
                'constatering', 'Constatering', Icons.warning_amber),
            _typeChip(
                'meting', 'Meetwaarde', Icons.electrical_services),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _type = value),
      selectedColor: const Color(0xFF1976D2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTypeFields() {
    switch (_type) {
      case 'constatering':
        return _buildConstateringFields();
      case 'meting':
        return _buildMetingFields();
      default:
        return _buildNotitieFields();
    }
  }

  Widget _buildNotitieFields() {
    return TextField(
      controller: _labelCtrl,
      decoration: const InputDecoration(
        labelText: 'Omschrijving (optioneel)',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLines: 2,
    );
  }

  Widget _buildConstateringFields() {
    if (_defectsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_defects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Text(
          'Geen constateringen gevonden. Voeg eerst een constatering toe via het inspectie-menu.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }
    if (_defectId != null &&
        !_defects.any((d) => d.id == _defectId)) {
      _defectId = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _defectId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Selecteer constatering',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('— Geen koppeling —',
                  style: TextStyle(color: Colors.grey)),
            ),
            ..._defects.map((d) {
              final desc = d.description.isNotEmpty
                  ? d.description
                  : d.location;
              final truncated = desc.length > 55
                  ? '${desc.substring(0, 55)}…'
                  : desc;
              return DropdownMenuItem<int?>(
                value: d.id,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _defectColor(d.classification),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                        child: Text(truncated,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) => setState(() => _defectId = val),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _labelCtrl,
          decoration: const InputDecoration(
            labelText: 'Extra toelichting (optioneel)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildMetingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meettype',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: ['Zi', 'Zs', 'Zi en Zs', 'Overig'].map((t) {
            final key = t == 'Zi en Zs' ? 'Zi+Zs' : t;
            final isSelected = _metingType == key;
            return ChoiceChip(
              label: Text(t),
              selected: isSelected,
              onSelected: (_) => setState(() => _metingType = key),
              selectedColor: const Color(0xFF1976D2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        if (_metingType == 'Zi+Zs') ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _waardeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zi waarde',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'Ω',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _waarde2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Zs waarde',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'Ω',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
            ],
          ),
        ] else
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _waardeCtrl,
                  decoration: InputDecoration(
                    labelText: _metingType == 'Overig'
                        ? 'Waarde'
                        : '$_metingType waarde',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixText: _metingType != 'Overig' ? 'Ω' : null,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
              if (_metingType == 'Overig') ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _eenheidCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Eenheid',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _labelCtrl,
          decoration: const InputDecoration(
            labelText: 'Toelichting (optioneel)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Color _defectColor(String classification) {
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
        return Colors.grey;
    }
  }
}
