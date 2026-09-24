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

import '../pdf_preview_page.dart';
import 'package:flutter/material.dart';
import '../../models/nen_bouwdeel.dart';
import '../../models/nen_gebrek.dart';
import '../../models/nen_objectgegevens.dart';
import '../../services/database_service.dart';
import '../../services/nen2767_export_service.dart';
import '../../services/nen2767_pdf_export_service.dart';
import '../../services/nen2767_scoring_service.dart';
import 'nen_gebreken_list_page.dart';
import 'nen_historie_page.dart';

/// Entreepunt van de NEN 2767-conditiemetingsmodule voor één inspectie:
/// objectgegevens en de object > bouwdeel > element > locatie-boomstructuur.
class Nen2767OverviewPage extends StatefulWidget {
  final int inspectionId;

  const Nen2767OverviewPage({super.key, required this.inspectionId});

  @override
  State<Nen2767OverviewPage> createState() => _Nen2767OverviewPageState();
}

class _NodeRow {
  final NenBouwdeel node;
  final int depth;
  _NodeRow(this.node, this.depth);
}

class _Nen2767OverviewPageState extends State<Nen2767OverviewPage> {
  final _db = DatabaseService();
  bool _loading = true;
  NenObjectgegevens? _objectgegevens;
  List<NenBouwdeel> _bouwdelen = [];
  Map<int, List<NenGebrek>> _gebrekenPerBouwdeel = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    var obj = await _db.getNenObjectgegevens(widget.inspectionId);
    if (obj == null) {
      final id = await _db.insertNenObjectgegevens(
        NenObjectgegevens(inspectionId: widget.inspectionId),
      );
      obj = await _db.getNenObjectgegevens(widget.inspectionId) ??
          NenObjectgegevens(id: id, inspectionId: widget.inspectionId);
    }
    final bouwdelen = await _db.getNenBouwdelen(widget.inspectionId);
    final gebreken = await _db.getNenGebrekenVoorInspectie(widget.inspectionId);
    final grouped = <int, List<NenGebrek>>{};
    for (final g in gebreken) {
      grouped.putIfAbsent(g.bouwdeelId, () => []).add(g);
    }
    if (!mounted) return;
    setState(() {
      _objectgegevens = obj;
      _bouwdelen = bouwdelen;
      _gebrekenPerBouwdeel = grouped;
      _loading = false;
    });
  }

  List<_NodeRow> _flattenTree() {
    final byParent = <int?, List<NenBouwdeel>>{};
    for (final b in _bouwdelen) {
      byParent.putIfAbsent(b.parentId, () => []).add(b);
    }
    final rows = <_NodeRow>[];
    void visit(int? parentId, int depth) {
      for (final node in byParent[parentId] ?? const <NenBouwdeel>[]) {
        rows.add(_NodeRow(node, depth));
        visit(node.id, depth + 1);
      }
    }
    visit(null, 0);
    return rows;
  }

  /// Indicatieve conditiescore van een node: eigen gebreken geaggregeerd
  /// volgens NEN 2767, of - als de node zelf geen gebreken heeft maar
  /// onderliggende nodes wel - het (indicatieve, niet-officiële) gemiddelde
  /// van de kind-scores.
  int? _conditiescoreVoorNode(NenBouwdeel node) {
    final eigen = _gebrekenPerBouwdeel[node.id];
    if (eigen != null && eigen.isNotEmpty) {
      return Nen2767ScoringService.aggregeerConditiescore(eigen);
    }
    final children = _bouwdelen.where((b) => b.parentId == node.id).toList();
    if (children.isEmpty) return null;
    final scores = children
        .map(_conditiescoreVoorNode)
        .whereType<int>()
        .toList();
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
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

  Future<void> _editObjectgegevens() async {
    final obj = _objectgegevens;
    if (obj == null) return;
    final bouwjaarCtrl = TextEditingController(text: obj.bouwjaar);
    final functieCtrl = TextEditingController(text: obj.gebruiksfunctie);
    final objectcodeCtrl = TextEditingController(text: obj.objectcode);
    final opmerkingenCtrl = TextEditingController(text: obj.opmerkingen);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Objectgegevens'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bouwjaarCtrl,
                decoration: const InputDecoration(labelText: 'Bouwjaar'),
              ),
              TextField(
                controller: functieCtrl,
                decoration: const InputDecoration(labelText: 'Gebruiksfunctie'),
              ),
              TextField(
                controller: objectcodeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Objectcode',
                  helperText:
                      'Vrij te kiezen sleutel (bv. adres) om inspecties van'
                      ' hetzelfde object te koppelen voor historie',
                  helperMaxLines: 3,
                ),
              ),
              TextField(
                controller: opmerkingenCtrl,
                decoration: const InputDecoration(labelText: 'Opmerkingen'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _db.updateNenObjectgegevens(obj.copyWith(
        bouwjaar: bouwjaarCtrl.text.trim(),
        gebruiksfunctie: functieCtrl.text.trim(),
        objectcode: objectcodeCtrl.text.trim(),
        opmerkingen: opmerkingenCtrl.text.trim(),
      ));
      _loadData();
    }
  }

  Future<void> _addNode({int? parentId}) async {
    final naamCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bouwdeel/element toevoegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: naamCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Naam'),
            ),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code (optioneel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
    if (result == true && naamCtrl.text.trim().isNotEmpty) {
      await _db.insertNenBouwdeel(NenBouwdeel(
        inspectionId: widget.inspectionId,
        parentId: parentId,
        naam: naamCtrl.text.trim(),
        code: codeCtrl.text.trim(),
      ));
      _loadData();
    }
  }

  Future<void> _editNode(NenBouwdeel node) async {
    final naamCtrl = TextEditingController(text: node.naam);
    final codeCtrl = TextEditingController(text: node.code);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bouwdeel/element bewerken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: naamCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Naam'),
            ),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code (optioneel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _db.updateNenBouwdeel(node.copyWith(
        naam: naamCtrl.text.trim(),
        code: codeCtrl.text.trim(),
      ));
      _loadData();
    }
  }

  Future<void> _deleteNode(NenBouwdeel node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verwijderen'),
        content: Text(
          'Weet u zeker dat u "${node.naam}" wilt verwijderen, inclusief '
          'alle onderliggende bouwdelen en gebreken?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteNenBouwdeel(node.id!);
      _loadData();
    }
  }

  void _showRapportageOpties() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF-rapport'),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await Nen2767PdfExportService()
                    .generatePdf(widget.inspectionId);
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewPage(
                      path: path,
                      title: 'PDF-rapport',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel-export'),
              onTap: () async {
                Navigator.pop(ctx);
                await Nen2767ExportService()
                    .exportExcelAndShare(widget.inspectionId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('CSV-export'),
              onTap: () async {
                Navigator.pop(ctx);
                await Nen2767ExportService()
                    .exportCsvAndShare(widget.inspectionId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _flattenTree();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditiemeting NEN 2767'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historie',
            onPressed: _objectgegevens == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NenHistoriePage(
                          inspectionId: widget.inspectionId,
                          objectcode: _objectgegevens!.objectcode,
                        ),
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Rapportage',
            onPressed: _showRapportageOpties,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNode(),
        icon: const Icon(Icons.add),
        label: const Text('Bouwdeel'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Objectgegevens'),
                    subtitle: Text([
                      if (_objectgegevens?.bouwjaar.isNotEmpty == true)
                        'Bouwjaar ${_objectgegevens!.bouwjaar}',
                      if (_objectgegevens?.gebruiksfunctie.isNotEmpty == true)
                        _objectgegevens!.gebruiksfunctie,
                      if (_objectgegevens?.objectcode.isNotEmpty == true)
                        'Objectcode: ${_objectgegevens!.objectcode}',
                    ].join(' · ').ifEmptyThen('Nog niet ingevuld')),
                    trailing: const Icon(Icons.edit),
                    onTap: _editObjectgegevens,
                  ),
                ),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Nog geen bouwdelen. Voeg het eerste bouwdeel toe.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                for (final row in rows)
                  Padding(
                    padding: EdgeInsets.only(left: 16.0 * row.depth),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      child: ListTile(
                        leading: Icon(
                          row.depth == 0
                              ? Icons.apartment
                              : Icons.subdirectory_arrow_right,
                        ),
                        title: Text(row.node.naam),
                        subtitle: row.node.code.isNotEmpty
                            ? Text(row.node.code)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(builder: (context) {
                              final score = _conditiescoreVoorNode(row.node);
                              if (score == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _scoreColor(score),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'add':
                                    _addNode(parentId: row.node.id);
                                    break;
                                  case 'edit':
                                    _editNode(row.node);
                                    break;
                                  case 'delete':
                                    _deleteNode(row.node);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'add',
                                    child: Text('Subonderdeel toevoegen')),
                                PopupMenuItem(
                                    value: 'edit', child: Text('Bewerken')),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Verwijderen')),
                              ],
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NenGebrekenListPage(
                              inspectionId: widget.inspectionId,
                              bouwdeelId: row.node.id!,
                              bouwdeelNaam: row.node.naam,
                            ),
                          ),
                        ).then((_) => _loadData()),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

extension _EmptyOr on String {
  String ifEmptyThen(String fallback) => isEmpty ? fallback : this;
}
