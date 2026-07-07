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

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../models/measurement_group.dart';
import '../models/measurement_reading.dart';
import '../services/database_service.dart';
import '../services/measurement_import_service.dart';
import '../widgets/measurement_dialogs.dart';

class MeetgegevensPage extends StatefulWidget {
  final int inspectionId;

  const MeetgegevensPage({super.key, required this.inspectionId});

  @override
  State<MeetgegevensPage> createState() => _MeetgegevensPageState();
}

class _MeetgegevensPageState extends State<MeetgegevensPage> {
  final _db = DatabaseService();
  final _importService = MeasurementImportService();

  List<MeasurementGroup> _groups = [];
  final Map<int, List<MeasurementReading>> _readingsByGroup = {};
  final Set<int> _expandedGroupIds = {};
  final Map<int, GlobalKey> _readingKeys = {};
  bool _loading = true;
  bool _importing = false;
  int? _scrollToReadingId;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
  }

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner) setState(() => _loading = true);
    final groups = await _db.getMeasurementGroups(widget.inspectionId);
    final readingsByGroup = <int, List<MeasurementReading>>{};
    for (final group in groups) {
      if (group.id != null) {
        readingsByGroup[group.id!] = await _db.getMeasurementReadings(group.id!);
      }
    }
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _readingsByGroup
        ..clear()
        ..addAll(readingsByGroup);
      _loading = false;
    });
    if (_scrollToReadingId != null) {
      final targetId = _scrollToReadingId;
      _scrollToReadingId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _readingKeys[targetId];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  GlobalKey _readingKey(int id) => _readingKeys.putIfAbsent(id, () => GlobalKey());

  Future<void> _pickAndImport() async {
    const typeGroup = XTypeGroup(
      label: 'Excel meetgegevens',
      extensions: ['xlsx', 'xls'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    setState(() => _importing = true);
    try {
      final count = await _importService.importFile(file.path, widget.inspectionId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count groep(en) geïmporteerd uit ${file.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import mislukt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _addGroup() async {
    final result = await showDialog<GroupEditResult>(
      context: context,
      builder: (_) => const GroupEditDialog(),
    );
    if (result == null) return;
    await _db.insertMeasurementGroup(MeasurementGroup(
      inspectionId: widget.inspectionId,
      bronBestand: 'Handmatig',
      label: 'Handmatig ingevoerd',
      groepNummer: result.groepNummer,
      puntNummer: result.puntNummer,
      omschrijving: result.omschrijving,
      volgorde: _groups.length,
    ));
    await _load();
  }

  Future<void> _editGroup(MeasurementGroup group) async {
    final result = await showDialog<GroupEditResult>(
      context: context,
      builder: (_) => GroupEditDialog(existing: group),
    );
    if (result == null) return;
    await _db.updateMeasurementGroup(group.copyWith(
      omschrijving: result.omschrijving,
      groepNummer: result.groepNummer,
      puntNummer: result.puntNummer,
    ));
    await _load();
  }

  Future<void> _deleteGroup(MeasurementGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Groep verwijderen'),
        content: Text(
            'Weet u zeker dat u "${group.omschrijving}" en alle bijbehorende metingen wilt verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && group.id != null) {
      await _db.deleteMeasurementGroup(group.id!);
      await _load();
    }
  }

  Future<void> _addReading(MeasurementGroup group) async {
    if (group.id == null) return;
    final result = await showDialog<ReadingEditResult>(
      context: context,
      builder: (_) => const ReadingEditDialog(),
    );
    if (result == null) return;
    final newId = await _db.insertMeasurementReading(MeasurementReading(
      groupId: group.id!,
      puntNummer: result.puntNummer,
      metingType: result.metingType,
      waarden: result.waarden,
      volgorde: (_readingsByGroup[group.id] ?? const []).length,
    ));
    _expandedGroupIds.add(group.id!);
    _scrollToReadingId = newId;
    await _load();
  }

  Future<void> _editReading(MeasurementReading reading) async {
    final result = await showDialog<ReadingEditResult>(
      context: context,
      builder: (_) => ReadingEditDialog(existing: reading),
    );
    if (result == null) return;
    await _db.updateMeasurementReading(reading.copyWith(
      puntNummer: result.puntNummer,
      metingType: result.metingType,
      waarden: result.waarden,
    ));
    await _load();
  }

  Future<void> _deleteReading(MeasurementReading reading) async {
    if (reading.id == null) return;
    await _db.deleteMeasurementReading(reading.id!);
    await _load();
  }

  Future<void> _duplicateReading(MeasurementReading reading) async {
    final newId = await _db.insertMeasurementReading(MeasurementReading(
      groupId: reading.groupId,
      puntNummer: reading.puntNummer,
      metingType: reading.metingType,
      waarden: reading.waarden,
      volgorde: (_readingsByGroup[reading.groupId] ?? const []).length,
    ));
    _expandedGroupIds.add(reading.groupId);
    _scrollToReadingId = newId;
    await _load();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alles verwijderen'),
        content: const Text(
            'Weet u zeker dat u alle meetgegevens van deze inspectie wilt verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteMeasurementGroupsForInspection(widget.inspectionId);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetgegevens'),
        actions: [
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
              tooltip: 'Excel-bestand importeren',
              onPressed: _pickAndImport,
            ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Groep handmatig toevoegen',
            onPressed: _addGroup,
          ),
          if (_groups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Alles verwijderen',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen meetgegevens.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Importeer een Excel-export (.xlsx of .xls) van uw meetinstrument, '
              'of voer een groep handmatig in.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickAndImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('Excel-bestand importeren'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addGroup,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Groep handmatig toevoegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: _groups.length,
      itemBuilder: (_, index) {
        final group = _groups[index];
        final readings = _readingsByGroup[group.id] ?? [];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            key: PageStorageKey('measurement_group_${group.id}'),
            initiallyExpanded:
                group.id != null && _expandedGroupIds.contains(group.id),
            onExpansionChanged: (expanded) {
              if (group.id == null) return;
              if (expanded) {
                _expandedGroupIds.add(group.id!);
              } else {
                _expandedGroupIds.remove(group.id!);
              }
            },
            leading: const Icon(Icons.electrical_services, color: Color(0xFF1976D2)),
            title: Text(
              group.omschrijving.isNotEmpty ? group.omschrijving : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${group.label} · L${group.groepNummer} P${group.puntNummer} · '
              '${readings.length} meting(en)',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editGroup(group);
                if (value == 'delete') _deleteGroup(group);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Bewerken'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ],
            ),
            children: [
              for (final reading in readings)
                ListTile(
                  key: reading.id != null ? _readingKey(reading.id!) : null,
                  dense: true,
                  leading: Text(
                    '#${reading.puntNummer}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  title: Text(reading.metingType, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(reading.displayText, style: const TextStyle(fontSize: 12)),
                  onTap: () => _editReading(reading),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_copy, size: 18),
                        tooltip: 'Meting dupliceren',
                        onPressed: () => _duplicateReading(reading),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Meting verwijderen',
                        onPressed: () => _deleteReading(reading),
                      ),
                    ],
                  ),
                ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.add, color: Color(0xFF1976D2)),
                title: const Text('Meting toevoegen',
                    style: TextStyle(color: Color(0xFF1976D2), fontSize: 13)),
                onTap: () => _addReading(group),
              ),
            ],
          ),
        );
      },
    );
  }
}
