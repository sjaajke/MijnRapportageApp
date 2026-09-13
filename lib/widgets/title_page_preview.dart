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

// Shared draggable/resizable A4 title-page preview, used both by the
// per-inspection titelpagina editor and by the Bedrijfsgegevens page
// (where it edits the global layout defaults).

import 'dart:io';

import 'package:flutter/material.dart';
import '../models/title_page.dart' as model;

// ── Numeric position/size editor (top-left coordinate + size, in % of A4) ────

class PositionSizeRow extends StatefulWidget {
  /// Current position (center, fraction 0-1) and size (fraction 0-1).
  final String label;
  final double cx, cy, w, h;
  final bool locked;
  final void Function(double cx, double cy, double w, double h) onChanged;

  const PositionSizeRow({
    super.key,
    required this.label,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.onChanged,
    this.locked = false,
  });

  @override
  State<PositionSizeRow> createState() => _PositionSizeRowState();
}

class _PositionSizeRowState extends State<PositionSizeRow> {
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
  void didUpdateWidget(PositionSizeRow old) {
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

class TitlePagePreview extends StatefulWidget {
  final model.TitlePage titlePage;
  final String titleText;
  final String subtitleText;
  final String? effectiveLogoPath;
  final String? sciosLogoPath;
  final String addressNameText;
  final bool locked;
  final VoidCallback onToggleLock;
  final Future<void> Function(model.TitlePage updated) onLayoutChanged;

  const TitlePagePreview({
    super.key,
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
  State<TitlePagePreview> createState() => _TitlePagePreviewState();
}

class _TitlePagePreviewState extends State<TitlePagePreview> {
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
  void didUpdateWidget(TitlePagePreview old) {
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                      DraggableResizableItem(
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
                        DraggableResizableItem(
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

class DraggableResizableItem extends StatelessWidget {
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

  const DraggableResizableItem({
    super.key,
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

// ── Box widgets (fill their parent, sized by DraggableResizableItem) ────────

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
