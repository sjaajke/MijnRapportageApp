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
import '../models/measurement_group.dart';
import '../models/measurement_reading.dart';
import '../models/measurement_templates.dart';
import 'custom_dropdown.dart';

/// Shared "groep" and "meting" edit dialogs used both by the Meetgegevens
/// page and by the verdeler-scoped meetgegevens section.

class GroupEditResult {
  final String omschrijving;
  final String groepNummer;
  final String puntNummer;

  GroupEditResult(this.omschrijving, this.groepNummer, this.puntNummer);
}

class GroupEditDialog extends StatefulWidget {
  final MeasurementGroup? existing;

  const GroupEditDialog({super.key, this.existing});

  @override
  State<GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends State<GroupEditDialog> {
  late final TextEditingController _omschrijvingController;
  late final TextEditingController _groepController;
  late final TextEditingController _puntController;

  @override
  void initState() {
    super.initState();
    _omschrijvingController =
        TextEditingController(text: widget.existing?.omschrijving ?? '');
    _groepController = TextEditingController(text: widget.existing?.groepNummer ?? '');
    _puntController = TextEditingController(text: widget.existing?.puntNummer ?? '');
  }

  @override
  void dispose() {
    _omschrijvingController.dispose();
    _groepController.dispose();
    _puntController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Groep toevoegen' : 'Groep bewerken'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _omschrijvingController,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Omschrijving', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groepController,
                    decoration: const InputDecoration(
                        labelText: 'Groep (L)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _puntController,
                    decoration: const InputDecoration(
                        labelText: 'Punt (P)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            GroupEditResult(
              _omschrijvingController.text.trim(),
              _groepController.text.trim(),
              _puntController.text.trim(),
            ),
          ),
          child: const Text('Opslaan'),
        ),
      ],
    );
  }
}

class ReadingEditResult {
  final String puntNummer;
  final String metingType;
  final List<MeasurementValue> waarden;

  ReadingEditResult(this.puntNummer, this.metingType, this.waarden);
}

class _ValueRowControllers {
  final label = TextEditingController();
  final value = TextEditingController();
  final unit = TextEditingController();

  _ValueRowControllers({String label = '', String value = '', String unit = ''}) {
    this.label.text = label;
    this.value.text = value;
    this.unit.text = unit;
  }

  void dispose() {
    label.dispose();
    value.dispose();
    unit.dispose();
  }
}

class ReadingEditDialog extends StatefulWidget {
  final MeasurementReading? existing;

  const ReadingEditDialog({super.key, this.existing});

  @override
  State<ReadingEditDialog> createState() => _ReadingEditDialogState();
}

class _ReadingEditDialogState extends State<ReadingEditDialog> {
  static const _handmatig = 'Handmatig (vrije invoer)';

  late final TextEditingController _puntController;
  late final TextEditingController _typeController;
  final List<_ValueRowControllers> _rows = [];

  String _category = _handmatig;
  String? _subType;
  final Map<String, TextEditingController> _templateValues = {};
  final Map<String, String> _templateUnits = {};

  MeasurementTypeTemplate? get _template {
    for (final t in MeasurementTemplates.all) {
      if (t.category == _category) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _puntController = TextEditingController(text: widget.existing?.puntNummer ?? '');
    _typeController = TextEditingController(text: widget.existing?.metingType ?? '');
    final existingWaarden = widget.existing?.waarden ?? const [];

    final parsed = widget.existing != null
        ? MeasurementTemplates.parse(widget.existing!.metingType)
        : null;
    if (parsed != null) {
      final (template, subType) = parsed;
      _category = template.category;
      _subType = subType;
      _initTemplateControllers(template, existingWaarden);
    } else if (existingWaarden.isEmpty) {
      _rows.add(_ValueRowControllers());
    } else {
      for (final w in existingWaarden) {
        _rows.add(_ValueRowControllers(label: w.label, value: w.value, unit: w.unit));
      }
    }
  }

  void _initTemplateControllers(
      MeasurementTypeTemplate template, List<MeasurementValue> existingWaarden) {
    _disposeTemplateControllers();
    for (final field in template.fields) {
      final matches = existingWaarden.where((w) => w.label == field.label);
      final match = matches.isNotEmpty ? matches.first : null;
      _templateValues[field.label] = TextEditingController(text: match?.value ?? '');
      _templateUnits[field.label] =
          (match != null && field.unitOptions.contains(match.unit))
              ? match.unit
              : field.unitOptions.first;
    }
  }

  void _disposeTemplateControllers() {
    for (final c in _templateValues.values) {
      c.dispose();
    }
    _templateValues.clear();
    _templateUnits.clear();
  }

  @override
  void dispose() {
    _puntController.dispose();
    _typeController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    _disposeTemplateControllers();
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_ValueRowControllers()));

  void _removeRow(int index) => setState(() {
        _rows[index].dispose();
        _rows.removeAt(index);
      });

  void _onCategoryChanged(String? value) {
    if (value == null) return;
    setState(() {
      _category = value;
      final template = _template;
      if (template != null) {
        _subType = template.subTypes.first;
        _initTemplateControllers(template, const []);
      } else {
        _subType = null;
        _disposeTemplateControllers();
      }
    });
  }

  String get _subTypeLabel {
    switch (_category) {
      case 'RCD':
        return 'Nominale lekstroom';
      case 'Zi/Zs':
      case 'Zi/Zs 3 fase':
        return 'Zekering';
      default:
        return 'Spanning';
    }
  }

  void _save() {
    final template = _template;
    if (template != null && _subType != null) {
      final waarden = template.fields
          .map((field) => MeasurementValue(
                label: field.label,
                value: _templateValues[field.label]?.text.trim() ?? '',
                unit: _templateUnits[field.label] ?? field.unitOptions.first,
              ))
          .toList();
      Navigator.pop(
        context,
        ReadingEditResult(
          _puntController.text.trim(),
          '${template.category} $_subType',
          waarden,
        ),
      );
      return;
    }

    final waarden = _rows
        .where((row) => row.label.text.trim().isNotEmpty)
        .map((row) => MeasurementValue(
              label: row.label.text.trim(),
              value: row.value.text.trim(),
              unit: row.unit.text.trim(),
            ))
        .toList();
    Navigator.pop(
      context,
      ReadingEditResult(
        _puntController.text.trim(),
        _typeController.text.trim(),
        waarden,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final template = _template;
    return AlertDialog(
      title: Text(isNew ? 'Meting toevoegen' : 'Meting bewerken'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _puntController,
                      autofocus: true,
                      decoration: const InputDecoration(
                          labelText: 'Puntnummer', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomDropdown(
                      label: 'Meting type',
                      value: _category,
                      items: [
                        for (final t in MeasurementTemplates.all) t.category,
                        _handmatig,
                      ],
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                ],
              ),
              if (template != null) ...[
                const SizedBox(height: 6),
                CustomDropdown(
                  label: _subTypeLabel,
                  value: _subType,
                  items: template.subTypes,
                  onChanged: (v) => setState(() => _subType = v),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Waarden', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                for (final field in template.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(field.label, style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _templateValues[field.label],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: const InputDecoration(
                                labelText: 'Waarde',
                                isDense: true,
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: field.unitOptions.length > 1
                              ? DropdownButtonFormField<String>(
                                  initialValue: _templateUnits[field.label],
                                  isDense: true,
                                  decoration: const InputDecoration(
                                      isDense: true, border: OutlineInputBorder()),
                                  items: field.unitOptions
                                      .map((u) =>
                                          DropdownMenuItem(value: u, child: Text(u)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _templateUnits[field.label] = v);
                                    }
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(
                                    field.unitOptions.first,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                      labelText: 'Meting type (vrije tekst)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Waarden', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _rows[i].label,
                            decoration: const InputDecoration(
                                labelText: 'Label',
                                isDense: true,
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _rows[i].value,
                            decoration: const InputDecoration(
                                labelText: 'Waarde',
                                isDense: true,
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _rows[i].unit,
                            decoration: const InputDecoration(
                                labelText: 'Eenheid',
                                isDense: true,
                                border: OutlineInputBorder()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: _rows.length > 1 ? () => _removeRow(i) : null,
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Waarde toevoegen'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren')),
        TextButton(onPressed: _save, child: const Text('Opslaan')),
      ],
    );
  }
}
