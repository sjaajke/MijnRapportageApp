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

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/standard.dart';
import '../services/database_service.dart';
import '../services/standards_export_service.dart';

class StandardsPage extends StatefulWidget {
  const StandardsPage({super.key});

  @override
  State<StandardsPage> createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage> {
  int _selectedIndex = 0;

  static const _categoryKeys = [
    'system',
    'protection',
    'karakteristiek',
    'protection_class',
    'cable',
    'cable_length',
    'cable_type',
    'main_switch',
    'main_switch_poles',
    'location',
    'location_a',
    'location_b',
    'aarding',
    'inspection_reason',
    'inverter',
    'panel',
  ];

  List<String> _categoryLabels(AppLocalizations l10n) => [
    l10n.catSystem,
    l10n.catProtection,
    l10n.catKarakteristiek,
    l10n.catProtectionClass,
    l10n.catCable,
    l10n.catCableLength,
    l10n.catCableType,
    l10n.catMainSwitch,
    l10n.catMainSwitchPoles,
    l10n.catLocation,
    l10n.catLocationA,
    l10n.catLocationB,
    l10n.catAarding,
    l10n.catInspectionReason,
    l10n.catInverter,
    l10n.catPanel,
  ];

  bool _exporting = false;
  bool _importing = false;
  bool _dragging = false;

  final _listKeys =
      List.generate(_categoryKeys.length, (_) => GlobalKey<_StandardsListState>());

  Future<void> _exportToExcel(AppLocalizations l10n, List<String> labels) async {
    setState(() => _exporting = true);
    try {
      await StandardsExportService()
          .exportExcelAndShare(_categoryKeys, labels);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAllCategories(AppLocalizations l10n) async {
    final db = DatabaseService();
    final count = await db.getStandardsCount();
    if (count == 0) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllStandardsEverywhereTitle),
        content: Text(l10n.deleteAllStandardsEverywhereConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await db.deleteAllStandardsEverywhere();
    for (final key in _listKeys) {
      key.currentState?.reload();
    }
  }

  Future<void> _pickAndImport(AppLocalizations l10n) async {
    const xlsxType = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
      uniformTypeIdentifiers: ['org.openxmlformats.spreadsheetml.sheet'],
    );
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;
    await _runImport(l10n, file.path);
  }

  Future<void> _runImport(AppLocalizations l10n, String path) async {
    if (!path.toLowerCase().endsWith('.xlsx')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectXlsxFile)),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final result = await StandardsExportService().importExcel(path);
      for (final key in _listKeys) {
        key.currentState?.reload();
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importComplete),
            content: Text(l10n.importResult(
                result.inserted, result.updated, result.skipped)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = _categoryLabels(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.standards),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.deleteAllStandardsEverywhere,
            onPressed: () => _deleteAllCategories(l10n),
          ),
          IconButton(
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            tooltip: l10n.importFromExcel,
            onPressed: _importing ? null : () => _pickAndImport(l10n),
          ),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_chart_outlined),
            tooltip: l10n.exportToExcel,
            onPressed: _exporting ? null : () => _exportToExcel(l10n, labels),
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (detail) {
          setState(() => _dragging = false);
          if (detail.files.isNotEmpty) {
            _runImport(l10n, detail.files.first.path);
          }
        },
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: ListView.builder(
                    itemCount: _categoryKeys.length,
                    itemBuilder: (context, index) {
                      final selected = index == _selectedIndex;
                      return ListTile(
                        title: Text(labels[index]),
                        selected: selected,
                        selectedTileColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(
                      _categoryKeys.length,
                      (i) => _StandardsList(
                        key: _listKeys[i],
                        category: _categoryKeys[i],
                        label: labels[i],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_dragging)
              Container(
                color: Colors.blue.withValues(alpha: 0.15),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload_file, size: 64, color: Colors.blue),
                      const SizedBox(height: 12),
                      Text(
                        l10n.dropXlsxHere,
                        style: TextStyle(fontSize: 18, color: Colors.blue.shade800),
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

class _StandardsList extends StatefulWidget {
  final String category;
  final String label;

  const _StandardsList({super.key, required this.category, required this.label});

  @override
  State<_StandardsList> createState() => _StandardsListState();
}

class _StandardsListState extends State<_StandardsList>
    with AutomaticKeepAliveClientMixin {
  final _db = DatabaseService();
  List<Standard> _standards = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await _db.getStandards(widget.category);
    if (!mounted) return;
    setState(() {
      _standards = items;
      _loading = false;
    });
  }

  void reload() => _loadData();

  Future<void> _addStandard() async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController();
    final displayController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addCategory(widget.label)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayController,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );

    if (result == true && valueController.text.isNotEmpty) {
      await _db.insertStandard(Standard(
        category: widget.category,
        value: valueController.text,
        displayName: displayController.text.isNotEmpty
            ? displayController.text
            : valueController.text,
      ));
      _loadData();
    }
  }

  Future<void> _editStandard(Standard standard) async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController(text: standard.value);
    final displayController =
        TextEditingController(text: standard.displayName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editCategory(widget.label)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: l10n.value,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayController,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true && valueController.text.isNotEmpty) {
      await _db.updateStandard(Standard(
        id: standard.id,
        category: standard.category,
        value: valueController.text,
        displayName: displayController.text.isNotEmpty
            ? displayController.text
            : valueController.text,
      ));
      _loadData();
    }
  }

  Future<void> _deleteAllStandards() async {
    final l10n = AppLocalizations.of(context);
    if (_standards.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllStandardsTitle(widget.label)),
        content:
            Text(l10n.deleteAllStandardsConfirm(_standards.length, widget.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteAllStandards(widget.category);
    _loadData();
  }

  Future<void> _deleteStandard(Standard standard) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteItemConfirm(standard.displayName)),
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
      await _db.deleteStandard(standard.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _standards.isEmpty
              ? Center(child: Text(l10n.noItems))
              : ListView.builder(
                  itemCount: _standards.length,
                  itemBuilder: (context, index) {
                    final standard = _standards[index];
                    return ListTile(
                      title: Text(standard.displayName),
                      subtitle: Text(l10n.valuePrefix(standard.value)),
                      onTap: () => _editStandard(standard),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editStandard(standard),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteStandard(standard),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _addStandard,
                icon: const Icon(Icons.add),
                label: Text(l10n.add),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _standards.isEmpty ? null : _deleteAllStandards,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.deleteAllStandards),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
