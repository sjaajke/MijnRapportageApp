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
import '../services/database_service.dart';
import 'measurement_dialogs.dart';

/// Embeddable "meetgegevens" list (groepen + metingen) scoped to a single
/// verdeler, reusing the same group/meting dialogs as the Meetgegevens page.
class SwitchboardMeasurementsSection extends StatefulWidget {
  final int inspectionId;
  final int switchboardId;

  const SwitchboardMeasurementsSection({
    super.key,
    required this.inspectionId,
    required this.switchboardId,
  });

  @override
  State<SwitchboardMeasurementsSection> createState() =>
      _SwitchboardMeasurementsSectionState();
}

class _SwitchboardMeasurementsSectionState
    extends State<SwitchboardMeasurementsSection> {
  final _db = DatabaseService();

  List<MeasurementGroup> _groups = [];
  final Map<int, List<MeasurementReading>> _readingsByGroup = {};
  final Set<int> _expandedGroupIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups =
        await _db.getMeasurementGroupsForSwitchboard(widget.switchboardId);
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
  }

  Future<void> _addGroup() async {
    final result = await showDialog<GroupEditResult>(
      context: context,
      builder: (_) => const GroupEditDialog(),
    );
    if (result == null) return;
    await _db.insertMeasurementGroup(MeasurementGroup(
      inspectionId: widget.inspectionId,
      switchboardId: widget.switchboardId,
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
    await _db.insertMeasurementReading(MeasurementReading(
      groupId: group.id!,
      puntNummer: result.puntNummer,
      metingType: result.metingType,
      waarden: result.waarden,
      volgorde: (_readingsByGroup[group.id] ?? const []).length,
    ));
    _expandedGroupIds.add(group.id!);
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
    await _db.insertMeasurementReading(MeasurementReading(
      groupId: reading.groupId,
      puntNummer: reading.puntNummer,
      metingType: reading.metingType,
      waarden: reading.waarden,
      volgorde: (_readingsByGroup[reading.groupId] ?? const []).length,
    ));
    _expandedGroupIds.add(reading.groupId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in _groups) _buildGroupCard(group),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Groep toevoegen'),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(MeasurementGroup group) {
    final readings = _readingsByGroup[group.id] ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: PageStorageKey('switchboard_measurement_group_${group.id}'),
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
  }
}
