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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/company_details.dart';
import '../models/general_data.dart';
import '../models/title_page.dart' as model;
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/photo_container.dart';
import 'general_data_page.dart';

class TitlePageScreen extends StatefulWidget {
  final int inspectionId;

  const TitlePageScreen({super.key, required this.inspectionId});

  @override
  State<TitlePageScreen> createState() => _TitlePageScreenState();
}

class _TitlePageScreenState extends State<TitlePageScreen> {
  final _db = DatabaseService();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _dateController = TextEditingController();
  final _dateEndController = TextEditingController();
  final _codeController = TextEditingController();
  final _projectController = TextEditingController();

  model.TitlePage? _titlePage;
  CompanyDetails? _companyDetails;
  GeneralData? _generalData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var tp = await _db.getTitlePage(widget.inspectionId);
    if (tp == null) {
      final d = await _db.getTitlePageLayoutDefaults();
      await _db.insertTitlePage(
        model.TitlePage(
          inspectionId: widget.inspectionId,
          inspectionDate: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          titleX: d?['title_x'] ?? 0.5,       titleY: d?['title_y'] ?? 0.15,
          titleW: d?['title_w'] ?? 0.80,       titleH: d?['title_h'] ?? 0.10,
          subtitleX: d?['subtitle_x'] ?? 0.5,  subtitleY: d?['subtitle_y'] ?? 0.26,
          subtitleW: d?['subtitle_w'] ?? 0.70,  subtitleH: d?['subtitle_h'] ?? 0.07,
          photoX: d?['photo_x'] ?? 0.5,        photoY: d?['photo_y'] ?? 0.50,
          photoW: d?['photo_w'] ?? 0.60,        photoH: d?['photo_h'] ?? 0.35,
          dateX: d?['date_x'] ?? 0.5,          dateY: d?['date_y'] ?? 0.78,
          dateW: d?['date_w'] ?? 0.70,          dateH: d?['date_h'] ?? 0.065,
          codeX: d?['code_x'] ?? 0.5,          codeY: d?['code_y'] ?? 0.86,
          codeW: d?['code_w'] ?? 0.70,          codeH: d?['code_h'] ?? 0.065,
          projectX: d?['project_x'] ?? 0.5,    projectY: d?['project_y'] ?? 0.93,
          projectW: d?['project_w'] ?? 0.70,    projectH: d?['project_h'] ?? 0.065,
          logoX: d?['logo_x'] ?? 0.82,         logoY: d?['logo_y'] ?? 0.07,
          logoW: d?['logo_w'] ?? 0.30,          logoH: d?['logo_h'] ?? 0.12,
          addressNameX: d?['address_name_x'] ?? 0.5,  addressNameY: d?['address_name_y'] ?? 0.72,
          addressNameW: d?['address_name_w'] ?? 0.70,  addressNameH: d?['address_name_h'] ?? 0.065,
        ),
      );
      tp = await _db.getTitlePage(widget.inspectionId);
    }

    if (tp != null) {
      _titleController.text = tp.title;
      _subtitleController.text = tp.subtitle;
      _dateController.text = tp.inspectionDate;
      _dateEndController.text = tp.inspectionDateEnd;
      _codeController.text = tp.identificationCode;
      _projectController.text = tp.projectNumber;
    }

    final companyDetails = await _db.getCompanyDetails();
    final generalData = await _db.getGeneralData(widget.inspectionId);

    setState(() {
      _titlePage = tp;
      _companyDetails = companyDetails;
      _generalData = generalData;
      _loading = false;
    });
  }

  Future<void> _autoSave() async {
    if (_titlePage == null) return;
    final updated = _titlePage!.copyWith(
      title: _titleController.text,
      subtitle: _subtitleController.text,
      inspectionDate: _dateController.text,
      inspectionDateEnd: _dateEndController.text,
      identificationCode: _codeController.text,
      projectNumber: _projectController.text,
    );
    await _db.updateTitlePage(updated);
    _titlePage = updated;
  }

  Future<void> _saveLayout(model.TitlePage updated) async {
    await _db.updateTitlePage(updated);
    setState(() => _titlePage = updated);
  }

  @override
  void dispose() {
    _autoSave();
    _titleController.dispose();
    _subtitleController.dispose();
    _dateController.dispose();
    _dateEndController.dispose();
    _codeController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.titlePageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titlePageTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Draggable + resizable A4 preview ──────────────
            _TitlePagePreview(
              titlePage: _titlePage!,
              titleText: _titleController.text,
              subtitleText: _subtitleController.text,
              onLayoutChanged: _saveLayout,
              effectiveLogoPath: _titlePage?.logoTitelpaginaPath ?? _companyDetails?.logoTitelpaginaPath,
              sciosLogoPath: _companyDetails?.logoSciosPath,
              addressNameText: _generalData?.inspectionAddressName ?? '',
              locked: _titlePage!.layoutLocked,
              onToggleLock: () => _saveLayout(
                  _titlePage!.copyWith(layoutLocked: !_titlePage!.layoutLocked)),
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text(
                  'Positie & afmetingen (voorbeeldpagina)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                children: [
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Titel',
                    cx: _titlePage!.titleX, cy: _titlePage!.titleY,
                    w: _titlePage!.titleW, h: _titlePage!.titleH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        titleX: cx, titleY: cy, titleW: w, titleH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Subtitel',
                    cx: _titlePage!.subtitleX, cy: _titlePage!.subtitleY,
                    w: _titlePage!.subtitleW, h: _titlePage!.subtitleH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        subtitleX: cx, subtitleY: cy, subtitleW: w, subtitleH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Foto',
                    cx: _titlePage!.photoX, cy: _titlePage!.photoY,
                    w: _titlePage!.photoW, h: _titlePage!.photoH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        photoX: cx, photoY: cy, photoW: w, photoH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Inspectiedatum',
                    cx: _titlePage!.dateX, cy: _titlePage!.dateY,
                    w: _titlePage!.dateW, h: _titlePage!.dateH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        dateX: cx, dateY: cy, dateW: w, dateH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Identificatiecode',
                    cx: _titlePage!.codeX, cy: _titlePage!.codeY,
                    w: _titlePage!.codeW, h: _titlePage!.codeH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        codeX: cx, codeY: cy, codeW: w, codeH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Projectnummer',
                    cx: _titlePage!.projectX, cy: _titlePage!.projectY,
                    w: _titlePage!.projectW, h: _titlePage!.projectH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        projectX: cx, projectY: cy, projectW: w, projectH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Inspectieadres',
                    cx: _titlePage!.addressNameX, cy: _titlePage!.addressNameY,
                    w: _titlePage!.addressNameW, h: _titlePage!.addressNameH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        addressNameX: cx, addressNameY: cy, addressNameW: w, addressNameH: h)),
                  ),
                  _PositionSizeRow(
                    locked: _titlePage!.layoutLocked,
                    label: 'Logo (SCIOS)',
                    cx: _titlePage!.logoX, cy: _titlePage!.logoY,
                    w: _titlePage!.logoW, h: _titlePage!.logoH,
                    onChanged: (cx, cy, w, h) => _saveLayout(_titlePage!.copyWith(
                        logoX: cx, logoY: cy, logoW: w, logoH: h)),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _titlePage == null ? null : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _db.saveTitlePageLayoutDefaults(_titlePage!);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Lay-out opgeslagen als standaard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Sla op als standaard'),
              ),
            ),
            const SizedBox(height: 12),

            // ── Form fields ────────────────────────────────────
            CustomTextField(
              label: l10n.titleLabel,
              controller: _titleController,
              onChanged: (_) {
                _autoSave();
                setState(() {});
              },
            ),
            CustomTextField(
              label: l10n.subtitleLabel,
              controller: _subtitleController,
              onChanged: (_) => _autoSave(),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: PhotoContainer(
                    photoPath: _titlePage?.photoPath,
                    label: l10n.addPhoto,
                    aspectRatio: 4 / 3,
                    onPhotoSelected: (path) {
                      setState(() {
                        _titlePage = _titlePage!.copyWith(photoPath: path);
                      });
                      _autoSave();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: l10n.inspectionDate,
                              controller: _dateController,
                              onChanged: (_) => _autoSave(),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _dateController.text =
                                      DateFormat('dd-MM-yyyy').format(date);
                                  _autoSave();
                                }
                              },
                              onClear: () {
                                setState(() => _dateController.clear());
                                _autoSave();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              label: l10n.inspectionDateEnd,
                              controller: _dateEndController,
                              onChanged: (_) => _autoSave(),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _dateEndController.text =
                                      DateFormat('dd-MM-yyyy').format(date);
                                  _autoSave();
                                }
                              },
                              onClear: () {
                                setState(() => _dateEndController.clear());
                                _autoSave();
                              },
                            ),
                          ),
                        ],
                      ),
                      _TextColorRow(
                        label: l10n.inspectionDate.isNotEmpty
                            ? (_titlePage!.inspectionDateEnd.isNotEmpty
                                ? 'Tekstkleur Inspectieperiode'
                                : 'Tekstkleur Inspectiedatum')
                            : 'Tekstkleur Datum',
                        isWhite: _titlePage!.dateColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(dateColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                      CustomTextField(
                        label: l10n.identificationCode,
                        controller: _codeController,
                        onChanged: (_) => _autoSave(),
                      ),
                      _TextColorRow(
                        label: 'Tekstkleur Identificatiecode',
                        isWhite: _titlePage!.codeColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(codeColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                      CustomTextField(
                        label: l10n.projectNumber,
                        controller: _projectController,
                        onChanged: (_) => _autoSave(),
                      ),
                      _TextColorRow(
                        label: 'Tekstkleur Projectnummer',
                        isWhite: _titlePage!.projectColorWhite,
                        onChanged: (val) async {
                          final updated = _titlePage!.copyWith(projectColorWhite: val);
                          await _db.updateTitlePage(updated);
                          setState(() => _titlePage = updated);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_companyDetails?.logoSciosPath != null &&
                File(_companyDetails!.logoSciosPath!).existsSync()) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Logo SCIOS tonen in PDF'),
                value: _titlePage!.showSciosLogo,
                onChanged: (val) async {
                  final updated = _titlePage!.copyWith(showSciosLogo: val);
                  await _db.updateTitlePage(updated);
                  setState(() => _titlePage = updated);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _autoSave();
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => GeneralDataPage(
                        inspectionId: widget.inspectionId),
                  ),
                );
              },
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Numeric position/size editor (top-left coordinate + size, in % of A4) ────

class _PositionSizeRow extends StatefulWidget {
  /// Current position (center, fraction 0-1) and size (fraction 0-1).
  final String label;
  final double cx, cy, w, h;
  final bool locked;
  final void Function(double cx, double cy, double w, double h) onChanged;

  const _PositionSizeRow({
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.onChanged,
    this.locked = false,
  });

  @override
  State<_PositionSizeRow> createState() => _PositionSizeRowState();
}

class _PositionSizeRowState extends State<_PositionSizeRow> {
  late final TextEditingController _xCtrl, _yCtrl, _wCtrl, _hCtrl;

  @override
  void initState() {
    super.initState();
    _xCtrl = TextEditingController(text: _fmt(_left(widget.cx, widget.w)));
    _yCtrl = TextEditingController(text: _fmt(_top(widget.cy, widget.h)));
    _wCtrl = TextEditingController(text: _fmt(widget.w * 100));
    _hCtrl = TextEditingController(text: _fmt(widget.h * 100));
  }

  @override
  void didUpdateWidget(_PositionSizeRow old) {
    super.didUpdateWidget(old);
    if (widget.cx != old.cx || widget.w != old.w) {
      _xCtrl.text = _fmt(_left(widget.cx, widget.w));
      _wCtrl.text = _fmt(widget.w * 100);
    }
    if (widget.cy != old.cy || widget.h != old.h) {
      _yCtrl.text = _fmt(_top(widget.cy, widget.h));
      _hCtrl.text = _fmt(widget.h * 100);
    }
  }

  double _left(double cx, double w) => (cx - w / 2) * 100;
  double _top(double cy, double h) => (cy - h / 2) * 100;
  String _fmt(double v) => v.toStringAsFixed(1);

  void _apply() {
    final left = double.tryParse(_xCtrl.text.replaceAll(',', '.'));
    final top = double.tryParse(_yCtrl.text.replaceAll(',', '.'));
    final wPct = double.tryParse(_wCtrl.text.replaceAll(',', '.'));
    final hPct = double.tryParse(_hCtrl.text.replaceAll(',', '.'));
    if (left == null || top == null || wPct == null || hPct == null) return;

    final w = (wPct / 100).clamp(0.02, 1.0);
    final h = (hPct / 100).clamp(0.02, 1.0);
    final cx = ((left / 100) + w / 2).clamp(0.0, 1.0);
    final cy = ((top / 100) + h / 2).clamp(0.0, 1.0);
    widget.onChanged(cx, cy, w, h);
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _yCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 12,
                    color: widget.locked ? Colors.grey.shade400 : Colors.grey)),
          ),
          Expanded(child: _numField('X %', _xCtrl)),
          const SizedBox(width: 6),
          Expanded(child: _numField('Y %', _yCtrl)),
          const SizedBox(width: 6),
          Expanded(child: _numField('B %', _wCtrl)),
          const SizedBox(width: 6),
          Expanded(child: _numField('H %', _hCtrl)),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      enabled: !widget.locked,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => _apply(),
    );
  }
}

// ── Draggable + resizable A4 preview ────────────────────────────────────────

class _TitlePagePreview extends StatefulWidget {
  final model.TitlePage titlePage;
  final String titleText;
  final String subtitleText;
  final String? effectiveLogoPath;
  final String? sciosLogoPath;
  final String addressNameText;
  final bool locked;
  final VoidCallback onToggleLock;
  final Future<void> Function(model.TitlePage updated) onLayoutChanged;

  const _TitlePagePreview({
    required this.titlePage,
    required this.titleText,
    required this.subtitleText,
    required this.onLayoutChanged,
    required this.locked,
    required this.onToggleLock,
    this.effectiveLogoPath,
    this.sciosLogoPath,
    this.addressNameText = '',
  });

  @override
  State<_TitlePagePreview> createState() => _TitlePagePreviewState();
}

class _TitlePagePreviewState extends State<_TitlePagePreview> {
  // Position (center, fraction) and size (fraction) for each element.
  late double _titleX,    _titleY,    _titleW,    _titleH;
  late double _subtitleX, _subtitleY, _subtitleW, _subtitleH;
  late double _photoX,    _photoY,    _photoW,    _photoH;
  late double _dateX,  _dateY,  _dateW,  _dateH;
  late double _codeX,  _codeY,  _codeW,  _codeH;
  late double _projX,  _projY,  _projW,  _projH;
  late double _addrX,  _addrY,  _addrW,  _addrH;
  late double _logoX,  _logoY,  _logoW,  _logoH;

  // Minimum sizes (fraction of canvas).
  static const double _minW = 0.10;
  static const double _minH = 0.04;

  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _syncFromWidget(widget.titlePage);
  }

  @override
  void didUpdateWidget(_TitlePagePreview old) {
    super.didUpdateWidget(old);
    final tp = widget.titlePage;
    final op = old.titlePage;
    if (tp.titleX != op.titleX || tp.titleY != op.titleY ||
        tp.titleW != op.titleW || tp.titleH != op.titleH) {
      _titleX = tp.titleX; _titleY = tp.titleY;
      _titleW = tp.titleW; _titleH = tp.titleH;
    }
    if (tp.subtitleX != op.subtitleX || tp.subtitleY != op.subtitleY ||
        tp.subtitleW != op.subtitleW || tp.subtitleH != op.subtitleH) {
      _subtitleX = tp.subtitleX; _subtitleY = tp.subtitleY;
      _subtitleW = tp.subtitleW; _subtitleH = tp.subtitleH;
    }
    if (tp.dateX != op.dateX || tp.dateY != op.dateY ||
        tp.dateW != op.dateW || tp.dateH != op.dateH) {
      _dateX = tp.dateX; _dateY = tp.dateY;
      _dateW = tp.dateW; _dateH = tp.dateH;
    }
    if (tp.codeX != op.codeX || tp.codeY != op.codeY ||
        tp.codeW != op.codeW || tp.codeH != op.codeH) {
      _codeX = tp.codeX; _codeY = tp.codeY;
      _codeW = tp.codeW; _codeH = tp.codeH;
    }
    if (tp.projectX != op.projectX || tp.projectY != op.projectY ||
        tp.projectW != op.projectW || tp.projectH != op.projectH) {
      _projX = tp.projectX; _projY = tp.projectY;
      _projW = tp.projectW; _projH = tp.projectH;
    }
    if (tp.photoX != op.photoX || tp.photoY != op.photoY ||
        tp.photoW != op.photoW || tp.photoH != op.photoH) {
      _photoX = tp.photoX; _photoY = tp.photoY;
      _photoW = tp.photoW; _photoH = tp.photoH;
    }
    if (tp.addressNameX != op.addressNameX || tp.addressNameY != op.addressNameY ||
        tp.addressNameW != op.addressNameW || tp.addressNameH != op.addressNameH) {
      _addrX = tp.addressNameX; _addrY = tp.addressNameY;
      _addrW = tp.addressNameW; _addrH = tp.addressNameH;
    }
    if (tp.logoX != op.logoX || tp.logoY != op.logoY ||
        tp.logoW != op.logoW || tp.logoH != op.logoH) {
      _logoX = tp.logoX; _logoY = tp.logoY;
      _logoW = tp.logoW; _logoH = tp.logoH;
    }
  }

  void _syncFromWidget(model.TitlePage tp) {
    _titleX    = tp.titleX;    _titleY    = tp.titleY;
    _titleW    = tp.titleW;    _titleH    = tp.titleH;
    _subtitleX = tp.subtitleX; _subtitleY = tp.subtitleY;
    _subtitleW = tp.subtitleW; _subtitleH = tp.subtitleH;
    _dateX  = tp.dateX;  _dateY  = tp.dateY;
    _dateW  = tp.dateW;  _dateH  = tp.dateH;
    _codeX  = tp.codeX;  _codeY  = tp.codeY;
    _codeW  = tp.codeW;  _codeH  = tp.codeH;
    _projX  = tp.projectX; _projY = tp.projectY;
    _projW  = tp.projectW; _projH = tp.projectH;
    _photoX = tp.photoX; _photoY = tp.photoY;
    _photoW = tp.photoW; _photoH = tp.photoH;
    _addrX  = tp.addressNameX; _addrY = tp.addressNameY;
    _addrW  = tp.addressNameW; _addrH = tp.addressNameH;
    _logoX  = tp.logoX; _logoY = tp.logoY;
    _logoW  = tp.logoW; _logoH = tp.logoH;
  }

  // ── Clamp helpers ──────────────────────────────────────────
  double _cx(double cx, double w) => cx.clamp(w / 2, 1.0 - w / 2);
  double _cy(double cy, double h) => cy.clamp(h / 2, 1.0 - h / 2);
  double _cw(double w) => w.clamp(_minW, 0.98);
  double _ch(double h) => h.clamp(_minH, 0.98);

  // ── Save helpers ───────────────────────────────────────────
  void _saveTitle() => widget.onLayoutChanged(widget.titlePage.copyWith(
      titleX: _titleX, titleY: _titleY, titleW: _titleW, titleH: _titleH));
  void _saveSubtitle() => widget.onLayoutChanged(widget.titlePage.copyWith(
      subtitleX: _subtitleX, subtitleY: _subtitleY, subtitleW: _subtitleW, subtitleH: _subtitleH));
  void _saveDate()  => widget.onLayoutChanged(widget.titlePage.copyWith(
      dateX: _dateX, dateY: _dateY, dateW: _dateW, dateH: _dateH));
  void _saveCode()  => widget.onLayoutChanged(widget.titlePage.copyWith(
      codeX: _codeX, codeY: _codeY, codeW: _codeW, codeH: _codeH));
  void _saveProj()  => widget.onLayoutChanged(widget.titlePage.copyWith(
      projectX: _projX, projectY: _projY, projectW: _projW, projectH: _projH));
  void _savePhoto() => widget.onLayoutChanged(widget.titlePage.copyWith(
      photoX: _photoX, photoY: _photoY, photoW: _photoW, photoH: _photoH));
  void _saveAddr()  => widget.onLayoutChanged(widget.titlePage.copyWith(
      addressNameX: _addrX, addressNameY: _addrY, addressNameW: _addrW, addressNameH: _addrH));
  void _saveLogo()  => widget.onLayoutChanged(widget.titlePage.copyWith(
      logoX: _logoX, logoY: _logoY, logoW: _logoW, logoH: _logoH));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.locked
                          ? 'Voorbeeldweergave — vergrendeld'
                          : 'Voorbeeldweergave — sleep en vergroot/verklein blokken',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(widget.locked ? Icons.lock : Icons.lock_open,
                        size: 20, color: colorScheme.primary),
                    tooltip: widget.locked
                        ? 'Ontgrendel velden'
                        : 'Vergrendel velden',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onToggleLock,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
            const SizedBox(height: 8),
            // A4 ratio (1 : √2)
            AspectRatio(
              aspectRatio: 1 / 1.4142,
              child: LayoutBuilder(builder: (context, box) {
                final cw = box.maxWidth;
                final ch = box.maxHeight;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // ── Logo as full-canvas background ────
                      Positioned.fill(
                        child: _LogoBox(photoPath: widget.effectiveLogoPath),
                      ),
                      // ── Title ──────────────────────────────
                      _DraggableResizableItem(
                        cx: _titleX, cy: _titleY,
                        iw: _titleW, ih: _titleH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _titleX = _cx(_titleX + dx / cw, _titleW);
                          _titleY = _cy(_titleY + dy / ch, _titleH);
                        }),
                        onMoveEnd: _saveTitle,
                        onResize: (dw, dh) => setState(() {
                          _titleW = _cw(_titleW + dw / cw);
                          _titleH = _ch(_titleH + dh / ch);
                          _titleX = _cx(_titleX, _titleW);
                          _titleY = _cy(_titleY, _titleH);
                        }),
                        onResizeEnd: _saveTitle,
                        child: _TitleBox(
                          text: widget.titleText.isEmpty ? 'Titel' : widget.titleText,
                        ),
                      ),
                      // ── Subtitle ───────────────────────────
                      _DraggableResizableItem(
                        cx: _subtitleX, cy: _subtitleY,
                        iw: _subtitleW, ih: _subtitleH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _subtitleX = _cx(_subtitleX + dx / cw, _subtitleW);
                          _subtitleY = _cy(_subtitleY + dy / ch, _subtitleH);
                        }),
                        onMoveEnd: _saveSubtitle,
                        onResize: (dw, dh) => setState(() {
                          _subtitleW = _cw(_subtitleW + dw / cw);
                          _subtitleH = _ch(_subtitleH + dh / ch);
                          _subtitleX = _cx(_subtitleX, _subtitleW);
                          _subtitleY = _cy(_subtitleY, _subtitleH);
                        }),
                        onResizeEnd: _saveSubtitle,
                        child: _SubtitleBox(
                          text: widget.subtitleText.isEmpty ? 'Subtitel' : widget.subtitleText,
                        ),
                      ),
                      // ── Date ───────────────────────────────
                      _DraggableResizableItem(
                        cx: _dateX, cy: _dateY,
                        iw: _dateW, ih: _dateH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _dateX = _cx(_dateX + dx / cw, _dateW);
                          _dateY = _cy(_dateY + dy / ch, _dateH);
                        }),
                        onMoveEnd: _saveDate,
                        onResize: (dw, dh) => setState(() {
                          _dateW = _cw(_dateW + dw / cw);
                          _dateH = _ch(_dateH + dh / ch);
                          _dateX = _cx(_dateX, _dateW);
                          _dateY = _cy(_dateY, _dateH);
                        }),
                        onResizeEnd: _saveDate,
                        child: _FieldBox(
                          label: widget.titlePage.inspectionDate.isNotEmpty &&
                                  widget.titlePage.inspectionDateEnd.isNotEmpty
                              ? 'Inspectieperiode'
                              : 'Inspectiedatum',
                          value: widget.titlePage.inspectionDateEnd.isNotEmpty
                              ? '${widget.titlePage.inspectionDate} t/m ${widget.titlePage.inspectionDateEnd}'
                              : widget.titlePage.inspectionDate,
                          color: Colors.green,
                        ),
                      ),
                      // ── Identification code ─────────────────
                      _DraggableResizableItem(
                        cx: _codeX, cy: _codeY,
                        iw: _codeW, ih: _codeH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _codeX = _cx(_codeX + dx / cw, _codeW);
                          _codeY = _cy(_codeY + dy / ch, _codeH);
                        }),
                        onMoveEnd: _saveCode,
                        onResize: (dw, dh) => setState(() {
                          _codeW = _cw(_codeW + dw / cw);
                          _codeH = _ch(_codeH + dh / ch);
                          _codeX = _cx(_codeX, _codeW);
                          _codeY = _cy(_codeY, _codeH);
                        }),
                        onResizeEnd: _saveCode,
                        child: _FieldBox(
                          label: 'Identificatiecode',
                          value: widget.titlePage.identificationCode,
                          color: Colors.orange,
                        ),
                      ),
                      // ── Project number ─────────────────────
                      _DraggableResizableItem(
                        cx: _projX, cy: _projY,
                        iw: _projW, ih: _projH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _projX = _cx(_projX + dx / cw, _projW);
                          _projY = _cy(_projY + dy / ch, _projH);
                        }),
                        onMoveEnd: _saveProj,
                        onResize: (dw, dh) => setState(() {
                          _projW = _cw(_projW + dw / cw);
                          _projH = _ch(_projH + dh / ch);
                          _projX = _cx(_projX, _projW);
                          _projY = _cy(_projY, _projH);
                        }),
                        onResizeEnd: _saveProj,
                        child: _FieldBox(
                          label: 'Projectnummer',
                          value: widget.titlePage.projectNumber,
                          color: Colors.purple,
                        ),
                      ),
                      // ── Photo (draggable) ──────────────────
                      _DraggableResizableItem(
                        cx: _photoX, cy: _photoY,
                        iw: _photoW, ih: _photoH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _photoX = _cx(_photoX + dx / cw, _photoW);
                          _photoY = _cy(_photoY + dy / ch, _photoH);
                        }),
                        onMoveEnd: _savePhoto,
                        onResize: (dw, dh) => setState(() {
                          _photoW = _cw(_photoW + dw / cw);
                          _photoH = _ch(_photoH + dh / ch);
                          _photoX = _cx(_photoX, _photoW);
                          _photoY = _cy(_photoY, _photoH);
                        }),
                        onResizeEnd: _savePhoto,
                        child: _PhotoBox(photoPath: widget.titlePage.photoPath),
                      ),
                      // ── Inspectieadres Naam ────────────────
                      _DraggableResizableItem(
                        cx: _addrX, cy: _addrY,
                        iw: _addrW, ih: _addrH,
                        cw: cw, ch: ch,
                        locked: widget.locked,
                        onMove: (dx, dy) => setState(() {
                          _addrX = _cx(_addrX + dx / cw, _addrW);
                          _addrY = _cy(_addrY + dy / ch, _addrH);
                        }),
                        onMoveEnd: _saveAddr,
                        onResize: (dw, dh) => setState(() {
                          _addrW = _cw(_addrW + dw / cw);
                          _addrH = _ch(_addrH + dh / ch);
                          _addrX = _cx(_addrX, _addrW);
                          _addrY = _cy(_addrY, _addrH);
                        }),
                        onResizeEnd: _saveAddr,
                        child: _FieldBox(
                          label: 'Inspectieadres',
                          value: widget.addressNameText,
                          color: Colors.teal,
                        ),
                      ),
                      // ── SCIOS logo ─────────────────────────────
                      if (widget.sciosLogoPath != null)
                        _DraggableResizableItem(
                          cx: _logoX, cy: _logoY,
                          iw: _logoW, ih: _logoH,
                          cw: cw, ch: ch,
                          locked: widget.locked,
                          onMove: (dx, dy) => setState(() {
                            _logoX = _cx(_logoX + dx / cw, _logoW);
                            _logoY = _cy(_logoY + dy / ch, _logoH);
                          }),
                          onMoveEnd: _saveLogo,
                          onResize: (dw, dh) => setState(() {
                            _logoW = _cw(_logoW + dw / cw);
                            _logoH = _ch(_logoH + dh / ch);
                            _logoX = _cx(_logoX, _logoW);
                            _logoY = _cy(_logoY, _logoH);
                          }),
                          onResizeEnd: _saveLogo,
                          child: _SciosLogoBox(logoPath: widget.sciosLogoPath),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.open_with, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('Verplaatsen', style: _hintStyle(context)),
                const SizedBox(width: 12),
                Icon(Icons.open_in_full, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('Hoek = formaat aanpassen', style: _hintStyle(context)),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _hintStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey.shade600);
}

// ── Draggable + resizable item ───────────────────────────────────────────────

class _DraggableResizableItem extends StatelessWidget {
  /// Center position as fraction of canvas.
  final double cx, cy;
  /// Size as fraction of canvas.
  final double iw, ih;
  /// Canvas pixel dimensions.
  final double cw, ch;
  final void Function(double dx, double dy) onMove;
  final VoidCallback onMoveEnd;
  final void Function(double dw, double dh) onResize;
  final VoidCallback onResizeEnd;
  final bool locked;
  final Widget child;

  const _DraggableResizableItem({
    required this.cx, required this.cy,
    required this.iw, required this.ih,
    required this.cw, required this.ch,
    required this.onMove, required this.onMoveEnd,
    required this.onResize, required this.onResizeEnd,
    required this.child,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final pw = iw * cw;
    final ph = ih * ch;
    const handleSize = 18.0;

    return Positioned(
      left: cx * cw - pw / 2,
      top:  cy * ch - ph / 2,
      child: SizedBox(
        width: pw,
        height: ph,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main drag area ──────────────────────────────
            Positioned.fill(
              child: locked
                  ? child
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (d) => onMove(d.delta.dx, d.delta.dy),
                      onPanEnd: (_) => onMoveEnd(),
                      child: child,
                    ),
            ),
            // ── Resize handle (bottom-right corner) ────────
            if (!locked)
              Positioned(
                right: -handleSize / 2,
                bottom: -handleSize / 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) => onResize(d.delta.dx, d.delta.dy),
                  onPanEnd: (_) => onResizeEnd(),
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blueGrey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.open_in_full,
                      size: 11,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Box widgets (fill their parent, sized by _DraggableResizableItem) ────────

class _TitleBox extends StatelessWidget {
  final String text;
  const _TitleBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (box.maxHeight * 0.28).clamp(7.0, 18.0),
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      );
    });
  }
}

class _SubtitleBox extends StatelessWidget {
  final String text;
  const _SubtitleBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200, width: 1.0),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (box.maxHeight * 0.30).clamp(7.0, 14.0),
            fontWeight: FontWeight.normal,
            color: Colors.blue.shade700,
          ),
        ),
      );
    });
  }
}

class _PhotoBox extends StatelessWidget {
  final String? photoPath;
  const _PhotoBox({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasPhoto
            ? Image.file(File(photoPath!), fit: BoxFit.cover,
                width: box.maxWidth, height: box.maxHeight)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: (box.maxHeight * 0.3).clamp(12.0, 48.0),
                      color: Colors.grey.shade500),
                  Text(
                    'Foto',
                    style: TextStyle(
                      fontSize: (box.maxHeight * 0.12).clamp(7.0, 14.0),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

class _LogoBox extends StatelessWidget {
  final String? photoPath;
  const _LogoBox({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          border: Border.all(color: Colors.teal.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasPhoto
            ? Image.file(File(photoPath!), fit: BoxFit.contain,
                width: box.maxWidth, height: box.maxHeight)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business,
                      size: (box.maxHeight * 0.3).clamp(12.0, 40.0),
                      color: Colors.teal.shade400),
                  Text(
                    'Logo',
                    style: TextStyle(
                      fontSize: (box.maxHeight * 0.15).clamp(7.0, 13.0),
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

class _SciosLogoBox extends StatelessWidget {
  final String? logoPath;
  const _SciosLogoBox({required this.logoPath});

  @override
  Widget build(BuildContext context) {
    final hasFile = logoPath != null && File(logoPath!).existsSync();
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasFile
            ? Image.file(File(logoPath!), fit: BoxFit.contain,
                width: box.maxWidth, height: box.maxHeight)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined,
                      size: (box.maxHeight * 0.3).clamp(12.0, 40.0),
                      color: Colors.blue.shade400),
                  Text(
                    'SCIOS',
                    style: TextStyle(
                      fontSize: (box.maxHeight * 0.15).clamp(7.0, 13.0),
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final String value;
  final MaterialColor color;

  const _FieldBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? label : '$label: $value';
    return LayoutBuilder(builder: (_, box) {
      return Container(
        decoration: BoxDecoration(
          color: color.shade50,
          border: Border.all(color: color.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: (box.maxHeight * 0.38).clamp(7.0, 14.0),
            color: color.shade900,
          ),
        ),
      );
    });
  }
}

// ── Text colour toggle (black / white) for PDF fields ────────────────────────

class _TextColorRow extends StatelessWidget {
  final String label;
  final bool isWhite;
  final ValueChanged<bool> onChanged;

  const _TextColorRow({
    required this.label,
    required this.isWhite,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade700)),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Zwart'),
                icon: Icon(Icons.circle, size: 12, color: Colors.black),
              ),
              ButtonSegment(
                value: true,
                label: Text('Wit'),
                icon: Icon(Icons.circle_outlined, size: 12),
              ),
            ],
            selected: {isWhite},
            onSelectionChanged: (s) => onChanged(s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
