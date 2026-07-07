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
import 'package:desktop_drop/desktop_drop.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../models/rapport_constatering.dart';
import '../services/database_service.dart';

class RapportConstateringenPage extends StatefulWidget {
  const RapportConstateringenPage({super.key});

  @override
  State<RapportConstateringenPage> createState() =>
      _RapportConstateringenPageState();
}

class _RapportConstateringenPageState
    extends State<RapportConstateringenPage> {
  final _db = DatabaseService();
  List<RapportConstatering> _items = [];
  bool _loading = true;
  bool _importing = false;
  bool _dragging = false;
  bool _searchActive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getRapportConstateringen();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  // ── Kwalificatie helpers ───────────────────────────────────────────────────

  static const _kwalificatieOptions = ['Ge', 'Or', 'Bl', 'Er', 'NO'];

  String _kwalificatieLabel(String k) {
    switch (k) {
      case 'Er':
        return 'Ernstig';
      case 'Or':
        return 'Serieus';
      case 'Ge':
        return 'Gering';
      case 'Bl':
        return 'Opmerking';
      case 'NO':
        return 'Nader onderzoek';
      default:
        return k;
    }
  }

  Color _kwalificatieColor(String k) {
    switch (k) {
      case 'Er':
        return Colors.red;
      case 'Or':
        return Colors.orange;
      case 'Ge':
        return Colors.amber;
      case 'Bl':
        return Colors.blue;
      case 'NO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ── Grouped list helpers ───────────────────────────────────────────────────

  List<RapportConstatering> get _filtered {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((c) {
      return c.groep.toLowerCase().contains(q) ||
          c.beschrijving.toLowerCase().contains(q) ||
          c.tekst.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<RapportConstatering>> _grouped(
      List<RapportConstatering> items) {
    final map = <String, List<RapportConstatering>>{};
    for (final item in items) {
      (map[item.groep.isEmpty ? '—' : item.groep] ??= []).add(item);
    }
    return map;
  }

  // ── Add / Edit dialog ──────────────────────────────────────────────────────

  Future<void> _newGroep() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe groep'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Groepnaam',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Aanmaken'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _openEditDialog(null, initialGroep: name);
  }

  Future<void> _openEditDialog(RapportConstatering? existing,
      {String? initialGroep}) async {
    // Collect distinct existing groups for autocomplete
    final existingGroups =
        _items.map((c) => c.groep).toSet().toList()..sort();

    final groepCtrl = TextEditingController(
        text: existing?.groep ?? initialGroep ?? '');
    final beschrijvingCtrl =
        TextEditingController(text: existing?.beschrijving ?? '');
    final tekstCtrl = TextEditingController(text: existing?.tekst ?? '');
    final normCtrl = TextEditingController(text: existing?.norm ?? '');
    final toelichtingCtrl =
        TextEditingController(text: existing?.toelichting ?? '');
    String kwalificatie = existing?.kwalificatie ?? 'Ge';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null
              ? 'Nieuwe constatering'
              : 'Constatering bewerken'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Groep: free text + suffix icon to pick an existing group
                  TextField(
                    controller: groepCtrl,
                    decoration: InputDecoration(
                      labelText: 'Groep',
                      border: const OutlineInputBorder(),
                      suffixIcon: existingGroups.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.arrow_drop_down),
                              tooltip: 'Kies bestaande groep',
                              onPressed: () async {
                                final picked = await showDialog<String>(
                                  context: ctx,
                                  builder: (ctx2) => SimpleDialog(
                                    title: const Text('Kies groep'),
                                    children: existingGroups
                                        .map((g) => SimpleDialogOption(
                                              onPressed: () =>
                                                  Navigator.pop(ctx2, g),
                                              child: Text(g),
                                            ))
                                        .toList(),
                                  ),
                                );
                                if (picked != null) {
                                  groepCtrl.text = picked;
                                }
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: beschrijvingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Beschrijving',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tekstCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tekst',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Kwalificatie',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButton<String>(
                      value: kwalificatie,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _kwalificatieOptions
                          .map((k) => DropdownMenuItem(
                                value: k,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: _kwalificatieColor(k),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text('$k — ${_kwalificatieLabel(k)}'),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => kwalificatie = v ?? 'Ge'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: normCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Norm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: toelichtingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Toelichting',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final item = RapportConstatering(
      id: existing?.id,
      groep: groepCtrl.text.trim(),
      beschrijving: beschrijvingCtrl.text.trim(),
      tekst: tekstCtrl.text.trim(),
      kwalificatie: kwalificatie,
      norm: normCtrl.text.trim(),
      toelichting: toelichtingCtrl.text.trim(),
    );

    if (existing == null) {
      await _db.insertRapportConstatering(item);
    } else {
      await _db.updateRapportConstatering(item);
    }
    await _load();
  }

  Future<void> _delete(RapportConstatering item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verwijderen'),
        content: Text(
            'Wil je "${item.beschrijving}" verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteRapportConstatering(item.id!);
    await _load();
  }

  // ── Excel import ───────────────────────────────────────────────────────────

  Future<void> _pickAndImport() async {
    const xlsxType = XTypeGroup(label: 'Excel', extensions: ['xlsx']);
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;
    await _runImport(file.path);
  }

  Future<void> _runImport(String path) async {
    if (!path.toLowerCase().endsWith('.xlsx')) {
      _showError('Selecteer een .xlsx-bestand.');
      return;
    }
    setState(() => _importing = true);
    try {
      final bytes = File(path).readAsBytesSync();
      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook.sheets.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) {
        _showImportResult(0, 0);
        return;
      }

      // Build header → column-index map from row 0
      final headers = <String, int>{};
      for (int c = 0; c < rows[0].length; c++) {
        final h = rows[0][c]?.value?.toString().trim() ?? '';
        if (h.isNotEmpty) headers[h] = c;
      }

      String cell(List<Data?> row, String col) {
        final idx = headers[col];
        if (idx == null || idx >= row.length) return '';
        return row[idx]?.value?.toString().trim() ?? '';
      }

      int inserted = 0;
      int updated = 0;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final beschrijving = cell(row, 'Beschrijving');
        if (beschrijving.isEmpty) continue;

        final item = RapportConstatering(
          groep: cell(row, 'Groep'),
          beschrijving: beschrijving,
          tekst: cell(row, 'Tekst'),
          kwalificatie: cell(row, 'Kwalificatie').isEmpty
              ? 'Ge'
              : cell(row, 'Kwalificatie'),
          norm: cell(row, 'Norm'),
          toelichting: cell(row, 'Toelichting'),
        );

        final wasInserted = await _db.upsertRapportConstatering(item);
        if (wasInserted) {
          inserted++;
        } else {
          updated++;
        }
      }

      await _load();
      if (mounted) _showImportResult(inserted, updated);
    } catch (e) {
      _showError('Import mislukt: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showImportResult(int inserted, int updated) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import voltooid'),
        content: Text(
            '$inserted nieuwe constatering(en) toegevoegd\n$updated constatering(en) bijgewerkt'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _grouped(filtered);
    final sortedGroups = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Zoeken...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Rapport constateringen'),
        actions: [
          if (_searchActive)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _searchActive = false;
                _searchQuery = '';
              }),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Zoeken',
              onPressed: () => setState(() => _searchActive = true),
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Nieuwe groep',
              onPressed: _newGroep,
            ),
            if (_importing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Importeer Excel',
                onPressed: _pickAndImport,
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(null),
        tooltip: 'Nieuwe constatering',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (detail) {
                setState(() => _dragging = false);
                if (detail.files.isNotEmpty) {
                  _runImport(detail.files.first.path);
                }
              },
              child: Stack(
                children: [
                  filtered.isEmpty
                      ? Center(
                          child: Text(
                            _items.isEmpty
                                ? 'Geen constateringen.\nVoeg er een toe of importeer een Excel-bestand.'
                                : 'Geen resultaten voor "$_searchQuery".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: sortedGroups.fold<int>(
                              0, (sum, g) => sum + 1 + grouped[g]!.length),
                          itemBuilder: (ctx, index) {
                            // Build a flat index → widget mapping
                            int cursor = 0;
                            for (final group in sortedGroups) {
                              if (index == cursor) {
                                return _GroupHeader(
                                  title: group,
                                  count: grouped[group]!.length,
                                  onAdd: () => _openEditDialog(null,
                                      initialGroep:
                                          group == '—' ? '' : group),
                                );
                              }
                              cursor++;
                              final groupItems = grouped[group]!;
                              if (index < cursor + groupItems.length) {
                                final item = groupItems[index - cursor];
                                return _ConstateringTile(
                                  item: item,
                                  kwalificatieColor:
                                      _kwalificatieColor(item.kwalificatie),
                                  kwalificatieLabel:
                                      _kwalificatieLabel(item.kwalificatie),
                                  onEdit: () => _openEditDialog(item),
                                  onDelete: () => _delete(item),
                                );
                              }
                              cursor += groupItems.length;
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                  if (_dragging)
                    Container(
                      color: Colors.blue.withValues(alpha: 0.15),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.upload_file,
                                size: 64, color: Colors.blue),
                            const SizedBox(height: 12),
                            Text(
                              'Laat het bestand los om te importeren',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onAdd;

  const _GroupHeader({
    required this.title,
    required this.count,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAdd != null)
            IconButton(
              icon: Icon(Icons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              tooltip: 'Constatering toevoegen aan groep',
              onPressed: onAdd,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
        ],
      ),
    );
  }
}

class _ConstateringTile extends StatelessWidget {
  final RapportConstatering item;
  final Color kwalificatieColor;
  final String kwalificatieLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConstateringTile({
    required this.item,
    required this.kwalificatieColor,
    required this.kwalificatieLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Tooltip(
        message: kwalificatieLabel,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: kwalificatieColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      title: Text(
        item.beschrijving,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: item.tekst.isNotEmpty
          ? Text(
              item.tekst,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
