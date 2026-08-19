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
import '../../data/nen2767_seed_data.dart';
import '../../models/nen_elementcode.dart';
import '../../models/nen_gebrek.dart';
import '../../models/nen_gebrek_foto.dart';
import '../../models/nen_gebrek_referentie.dart';
import '../../services/database_service.dart';
import '../../services/nen2767_scoring_service.dart';
import '../../services/photo_service.dart';

/// Registratie van één NEN 2767-gebrek. Eerst wordt de installatiecode en
/// daarna de elementcode van dit specifieke gebrek gekozen; op basis daarvan
/// kan een gebrek uit de officiële lijst gekozen worden (met ernst volgens
/// NEN 2767-2). Omvang (%) en intensiteit worden door de inspecteur
/// vastgelegd; de conditiescore wordt live berekend volgens de officiële
/// methodiek.
class NenGebrekDetailPage extends StatefulWidget {
  final int gebrekId;
  final int inspectionId;

  const NenGebrekDetailPage({
    super.key,
    required this.gebrekId,
    required this.inspectionId,
  });

  @override
  State<NenGebrekDetailPage> createState() => _NenGebrekDetailPageState();
}

int _lijstnrCompare(String a, String b) {
  final ra = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(a);
  final rb = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(b);
  if (ra == null || rb == null) return a.compareTo(b);
  final letterCompare = ra.group(1)!.compareTo(rb.group(1)!);
  if (letterCompare != 0) return letterCompare;
  return int.parse(ra.group(2)!).compareTo(int.parse(rb.group(2)!));
}

class _NenGebrekDetailPageState extends State<NenGebrekDetailPage> {
  final _db = DatabaseService();
  bool _loading = true;
  NenGebrek? _gebrek;
  List<NenGebrekFoto> _fotos = [];
  List<NenGebrekReferentie> _gebrekenlijst = [];

  final _omschrijvingCtrl = TextEditingController();
  final _locatieCtrl = TextEditingController();
  final _toelichtingCtrl = TextEditingController();
  final _inspecteurCtrl = TextEditingController();
  String _ernst = 'G';
  String _intensiteit = 'Begin';
  double _omvang = 0;
  DateTime _geinspecteerdOp = DateTime.now();
  int? _gebrekReferentieId;
  String? _installatiecode;
  NenElementcode? _elementcode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _omschrijvingCtrl.dispose();
    _locatieCtrl.dispose();
    _toelichtingCtrl.dispose();
    _inspecteurCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final gebrek = await _db.getNenGebrek(widget.gebrekId);
    final fotos = await _db.getNenGebrekFotos(widget.gebrekId);
    NenElementcode? elementcode;
    List<NenGebrekReferentie> lijst = [];
    if (gebrek?.elementcodeId != null) {
      elementcode = await _db.getNenElementcode(gebrek!.elementcodeId!);
      if (elementcode != null) {
        lijst = await _db
            .getNenGebrekenlijstVoorElementcode(elementcode.elementcode);
      }
    }
    if (!mounted) return;
    setState(() {
      _gebrek = gebrek;
      _fotos = fotos;
      _elementcode = elementcode;
      _installatiecode = elementcode?.nen2767Lijstnr;
      _gebrekenlijst = lijst;
      if (gebrek != null) {
        _omschrijvingCtrl.text = gebrek.gebrekOmschrijving;
        _locatieCtrl.text = gebrek.locatieDetail;
        _toelichtingCtrl.text = gebrek.toelichting;
        _inspecteurCtrl.text = gebrek.inspecteur;
        _ernst = gebrek.ernst;
        _intensiteit = gebrek.intensiteit;
        _omvang = gebrek.omvangPercentage;
        _gebrekReferentieId = gebrek.gebrekReferentieId;
        _geinspecteerdOp =
            DateTime.tryParse(gebrek.geinspecteerdOp) ?? DateTime.now();
      }
      _loading = false;
    });
  }

  int get _conditiescore => Nen2767ScoringService.gebrekScore(
        ernst: _ernst,
        intensiteit: _intensiteit,
        omvangPercentage: _omvang,
      );

  Future<void> _save() async {
    final gebrek = _gebrek;
    if (gebrek == null) return;
    final updated = gebrek.copyWith(
      elementcodeId: _elementcode?.id,
      clearElementcodeId: _elementcode == null,
      gebrekOmschrijving: _omschrijvingCtrl.text.trim(),
      locatieDetail: _locatieCtrl.text.trim(),
      toelichting: _toelichtingCtrl.text.trim(),
      inspecteur: _inspecteurCtrl.text.trim(),
      ernst: _ernst,
      intensiteit: _intensiteit,
      omvangPercentage: _omvang,
      conditiescore: _conditiescore,
      geinspecteerdOp: _geinspecteerdOp.toIso8601String(),
      gebrekReferentieId: _gebrekReferentieId,
      clearGebrekReferentieId: _gebrekReferentieId == null,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _db.updateNenGebrek(updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickInstallatiecode() async {
    final codes = await _db.getNenLijstnrs();
    codes.sort(_lijstnrCompare);
    if (!mounted) return;
    var filter = '';
    final gekozen = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = filter.isEmpty
              ? codes
              : codes
                  .where((c) =>
                      c.toLowerCase().contains(filter) ||
                      (nen2767LijstTitels[c] ?? '')
                          .toLowerCase()
                          .contains(filter))
                  .toList();
          return AlertDialog(
            title: const Text('Kies installatiecode'),
            content: SizedBox(
              width: 420,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Zoeken...',
                    ),
                    onChanged: (v) =>
                        setDialogState(() => filter = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final code = filtered[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(code,
                                style: const TextStyle(fontSize: 10)),
                          ),
                          title: Text(nen2767LijstTitels[code] ?? code),
                          onTap: () => Navigator.pop(ctx, code),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuleren'),
              ),
            ],
          );
        },
      ),
    );
    if (gekozen != null && gekozen != _installatiecode) {
      setState(() {
        _installatiecode = gekozen;
        _elementcode = null;
        _gebrekenlijst = [];
        _gebrekReferentieId = null;
      });
    }
  }

  Future<void> _pickElementcode() async {
    if (_installatiecode == null) return;
    final all = await _db.getNenElementcodes(nen2767Lijstnr: _installatiecode);
    if (!mounted) return;
    var filter = '';
    final gekozen = await showDialog<NenElementcode>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = filter.isEmpty
              ? all
              : all
                  .where((e) =>
                      e.omschrijving.toLowerCase().contains(filter) ||
                      e.elementcode.contains(filter))
                  .toList();
          return AlertDialog(
            title: const Text('Kies elementcode'),
            content: SizedBox(
              width: 420,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Zoeken...',
                    ),
                    onChanged: (v) =>
                        setDialogState(() => filter = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(e.elementbenaming.isNotEmpty
                              ? e.elementbenaming
                              : e.omschrijving),
                          subtitle: Text(
                              '${e.elementcode} · ${e.hoofdgroep} > ${e.groep}'),
                          onTap: () => Navigator.pop(ctx, e),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuleren'),
              ),
            ],
          );
        },
      ),
    );
    if (gekozen != null) {
      final lijst =
          await _db.getNenGebrekenlijstVoorElementcode(gekozen.elementcode);
      if (!mounted) return;
      setState(() {
        _elementcode = gekozen;
        _gebrekenlijst = lijst;
        _gebrekReferentieId = null;
      });
    }
  }

  /// Toont de gebreken uit de officiële NEN 2767-2 lijst voor de gekozen
  /// elementcode, gegroepeerd in drie kolommen naar ernst (Gering/Serieus/
  /// Ernstig) — de ernst volgt uit de gekozen gebrek-kolom, niet uit een
  /// losse keuze.
  Future<void> _pickGebrekUitLijst() async {
    final gering =
        _gebrekenlijst.where((g) => g.ernstDefault == 'G').toList();
    final serieus =
        _gebrekenlijst.where((g) => g.ernstDefault == 'S').toList();
    final ernstig =
        _gebrekenlijst.where((g) => g.ernstDefault == 'E').toList();

    final gekozen = await showDialog<NenGebrekReferentie>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 1000,
          height: 560,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Selectie gebrek',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Nihil'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                if (_elementcode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_elementcode!.elementcode} · ${_elementcode!.elementbenaming}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ErnstKolom(
                          titel: 'Gering',
                          kleur: Colors.green,
                          items: gering,
                          onKies: (g) => Navigator.pop(ctx, g),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ErnstKolom(
                          titel: 'Serieus',
                          kleur: Colors.orange,
                          items: serieus,
                          onKies: (g) => Navigator.pop(ctx, g),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ErnstKolom(
                          titel: 'Ernstig',
                          kleur: Colors.red,
                          items: ernstig,
                          onKies: (g) => Navigator.pop(ctx, g),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (gekozen != null) {
      setState(() {
        _gebrekReferentieId = gekozen.id;
        _omschrijvingCtrl.text = gekozen.gebrekOmschrijving;
        if (gekozen.ernstDefault.isNotEmpty) _ernst = gekozen.ernstDefault;
        if (NenGebrek.intensiteiten.contains(gekozen.suggestieIntensiteit)) {
          _intensiteit = gekozen.suggestieIntensiteit;
        }
      });
    }
  }

  Future<void> _addFoto() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService()
                    .takePhoto(inspectionId: widget.inspectionId);
                if (path != null) await _saveFoto(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService()
                    .pickFromGallery(inspectionId: widget.inspectionId);
                if (path != null) await _saveFoto(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFoto(String path) async {
    await _db.insertNenGebrekFoto(NenGebrekFoto(
      gebrekId: widget.gebrekId,
      fotoPath: path,
      volgorde: _fotos.length,
      createdAt: DateTime.now().toIso8601String(),
    ));
    final fotos = await _db.getNenGebrekFotos(widget.gebrekId);
    if (!mounted) return;
    setState(() => _fotos = fotos);
  }

  Future<void> _deleteFoto(NenGebrekFoto foto) async {
    await _db.deleteNenGebrekFoto(foto.id!);
    final fotos = await _db.getNenGebrekFotos(widget.gebrekId);
    if (!mounted) return;
    setState(() => _fotos = fotos);
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _geinspecteerdOp,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _geinspecteerdOp = picked);
  }

  Color _scoreColor(int score) {
    switch (score) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _gebrek == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gebrek'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: _scoreColor(_conditiescore),
                  child: Text(
                    '$_conditiescore',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Conditiescore', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('1. Installatiecode',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            icon: const Icon(Icons.category_outlined),
            label: Text(
              _installatiecode == null
                  ? 'Kies installatiecode'
                  : '$_installatiecode · ${nen2767LijstTitels[_installatiecode] ?? ''}',
            ),
            onPressed: _pickInstallatiecode,
          ),
          const SizedBox(height: 16),
          const Text('2. Elementcode',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            icon: const Icon(Icons.list_alt_outlined),
            label: Text(
              _elementcode == null
                  ? 'Kies elementcode'
                  : '${_elementcode!.elementcode} · ${_elementcode!.elementbenaming}',
            ),
            onPressed: _installatiecode == null ? null : _pickElementcode,
          ),
          const SizedBox(height: 16),
          if (_gebrekenlijst.isNotEmpty) ...[
            const Text('3. Gebrek en ernst (NEN 2767-2)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Kies gebrek uit officiële lijst'),
              onPressed: _pickGebrekUitLijst,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _omschrijvingCtrl,
            decoration: const InputDecoration(
              labelText: 'Gebrek-omschrijving',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ernst', style: TextStyle(fontWeight: FontWeight.w600)),
          SegmentedButton<String>(
            segments: NenGebrek.ernstNiveaus
                .map((e) => ButtonSegment(
                    value: e, label: Text(NenGebrek.ernstLabels[e] ?? e)))
                .toList(),
            selected: {_ernst},
            onSelectionChanged: (v) => setState(() => _ernst = v.first),
          ),
          const SizedBox(height: 16),
          const Text('Intensiteit', style: TextStyle(fontWeight: FontWeight.w600)),
          SegmentedButton<String>(
            segments: NenGebrek.intensiteiten
                .map((i) => ButtonSegment(value: i, label: Text(i)))
                .toList(),
            selected: {_intensiteit},
            onSelectionChanged: (v) => setState(() => _intensiteit = v.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Omvang', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_omvang.toStringAsFixed(0)}%'),
            ],
          ),
          Slider(
            value: _omvang,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_omvang.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _omvang = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locatieCtrl,
            decoration: const InputDecoration(
              labelText: 'Exacte locatie',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _toelichtingCtrl,
            decoration: const InputDecoration(
              labelText: 'Toelichting / opmerkingen',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inspecteurCtrl,
            decoration: const InputDecoration(
              labelText: 'Inspecteur',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(DateFormat('dd-MM-yyyy').format(_geinspecteerdOp)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickDatum,
          ),
          const SizedBox(height: 16),
          const Text("Foto's", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final foto in _fotos)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(foto.fotoPath),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _deleteFoto(foto),
                      ),
                    ),
                  ],
                ),
              InkWell(
                onTap: _addFoto,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eén ernst-kolom (Gering/Serieus/Ernstig) in de gebrek-selectiedialoog:
/// toont de gebreken uit de officiële lijst die tot die ernstklasse behoren.
class _ErnstKolom extends StatelessWidget {
  final String titel;
  final Color kleur;
  final List<NenGebrekReferentie> items;
  final ValueChanged<NenGebrekReferentie> onKies;

  const _ErnstKolom({
    required this.titel,
    required this.kleur,
    required this.items,
    required this.onKies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titel,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: kleur),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Geen gebreken in deze klasse',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (context, i) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.add_circle,
                            color: Colors.green.shade600),
                        title: Text(item.gebrekOmschrijving,
                            style: const TextStyle(fontSize: 13)),
                        onTap: () => onKies(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
