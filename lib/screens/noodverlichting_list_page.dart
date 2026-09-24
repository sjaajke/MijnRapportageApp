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
import '../widgets/inspection_nav_bar.dart';
import '../models/noodverlichting_installation.dart';
import '../services/database_service.dart';
import '../services/noodverlichting_export_service.dart';
import 'noodverlichting_detail_page.dart';
import 'noodverlichting_import_log_page.dart';

/// Below this content width the page shows the noodverlichting list
/// full-screen and pushes the detail as a separate route; at or above it, a
/// split view shows the list on the left and the selected installation's
/// detail on the right.
const _splitBreakpoint = 800.0;

class NoodverlichtingListPage extends StatefulWidget {
  final int inspectionId;

  const NoodverlichtingListPage({super.key, required this.inspectionId});

  @override
  State<NoodverlichtingListPage> createState() =>
      _NoodverlichtingListPageState();
}

class _NoodverlichtingListPageState extends State<NoodverlichtingListPage> {
  final _db = DatabaseService();
  List<NoodverlichtingInstallation> _installations = [];
  bool _loading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _db.getNoodverlichtingInstallations(widget.inspectionId);
    setState(() {
      _installations = items;
      _loading = false;
      if (_selectedId != null &&
          !_installations.any((i) => i.id == _selectedId)) {
        _selectedId = null;
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'R':
        return Colors.red;
      case 'O':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Future<void> _createInstallation() async {
    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final id = await _db.insertNoodverlichtingInstallation(
      NoodverlichtingInstallation(
        inspectionId: widget.inspectionId,
        sortOrder: _installations.length,
      ),
    );
    if (!mounted) return;
    if (isSplit) {
      await _loadData();
      if (!mounted) return;
      setState(() => _selectedId = id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoodverlichtingDetailPage(
          installationId: id,
          inspectionId: widget.inspectionId,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _copyInstallation(NoodverlichtingInstallation item) async {
    await _db.insertNoodverlichtingInstallation(
      NoodverlichtingInstallation(
        inspectionId: item.inspectionId,
        componentNr: item.componentNr,
        name: item.name,
        nameCode: item.nameCode,
        location: item.location,
        locationA: item.locationA,
        locationB: item.locationB,
        merk: item.merk,
        lichtbron: item.lichtbron,
        accuType: item.accuType,
        typeNoodverlichting: item.typeNoodverlichting,
        typeSteker: item.typeSteker,
        hoogte: item.hoogte,
        functie: item.functie,
        montage: item.montage,
        chemieVanDeAccu: item.chemieVanDeAccu,
        typeInstallatie: item.typeInstallatie,
        installatieOnderdeel: item.installatieOnderdeel,
        componentFunctie: item.componentFunctie,
        jaarVanAanleg: item.jaarVanAanleg,
        inspectieDatum: item.inspectieDatum,
        inspectieInterval: item.inspectieInterval,
        photoAccuPath: item.photoAccuPath,
        photoStekkerAansluitingPath: item.photoStekkerAansluitingPath,
        photoAfbeeldingPath: item.photoAfbeeldingPath,
        photoTypePlaatjePath: item.photoTypePlaatjePath,
        photoGebruiktPictogramPath: item.photoGebruiktPictogramPath,
        photoAfbeeldingDetailPath: item.photoAfbeeldingDetailPath,
        status: item.status,
        opmerkingOptie: item.opmerkingOptie,
        opmerking: item.opmerking,
        sortOrder: _installations.length,
      ),
    );
    _loadData();
  }

  Future<void> _deleteInstallation(NoodverlichtingInstallation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Noodverlichting verwijderen'),
        content: const Text(
            'Weet je zeker dat je deze noodverlichting wilt verwijderen?'),
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
      if (_selectedId == item.id) {
        setState(() => _selectedId = null);
      }
      await _db.deleteNoodverlichtingInstallation(item.id!);
      _loadData();
    }
  }

  Future<void> _deleteAllInstallations() async {
    if (_installations.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alle noodverlichting verwijderen'),
        content: Text(
          'Weet je zeker dat je alle ${_installations.length} '
          'noodverlichting(en) in deze inspectie wilt verwijderen? Dit kan '
          'niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Alles verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _selectedId = null);
    await _db.deleteAllNoodverlichtingInstallations(widget.inspectionId);
    _loadData();
  }

  Future<void> _reorderInstallations(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _installations.removeAt(oldIndex);
      _installations.insert(newIndex, item);
    });
    await _db.updateNoodverlichtingInstallationOrder(
      _installations.map((i) => i.id!).toList(),
    );
  }

  Future<void> _exportExcel() async {
    if (_installations.isEmpty) return;
    try {
      await NoodverlichtingExportService()
          .exportExcelAndShare(widget.inspectionId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exporteren mislukt: $e')),
      );
    }
  }

  Future<void> _importExcel() async {
    const xlsxType = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
      uniformTypeIdentifiers: ['org.openxmlformats.spreadsheetml.sheet'],
    );
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;
    try {
      final imported = await NoodverlichtingExportService()
          .importExcel(file.path, widget.inspectionId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported noodverlichting(en) geïmporteerd.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importeren mislukt: $e')),
      );
    }
  }

  Future<void> _openImportLog() async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoodverlichtingImportLogPage(inspectionId: widget.inspectionId),
      ),
    );
    if (imported == true) _loadData();
  }

  Widget _buildList(BuildContext context, {required bool isSplit}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_installations.isEmpty) {
      return const Center(
        child: Text(
          'Nog geen noodverlichting toegevoegd.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _installations.length,
      onReorder: _reorderInstallations,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final item = _installations[index];
        final isActive = isSplit && item.id == _selectedId;
        return Card(
          key: ValueKey(item.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isActive
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.4)
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(item.status),
              child: const Icon(Icons.emergency, color: Colors.white, size: 20),
            ),
            title: Text(
              item.name.isNotEmpty ? item.name : 'Noodverlichting #${item.id}',
            ),
            subtitle:
                item.locationFull.isNotEmpty ? Text(item.locationFull) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Noodverlichting kopiëren',
                  onPressed: () => _copyInstallation(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteInstallation(item),
                ),
                if (isSplit) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            onTap: () async {
              if (isSplit) {
                setState(() => _selectedId = item.id);
                return;
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoodverlichtingDetailPage(
                    installationId: item.id!,
                    inspectionId: widget.inspectionId,
                  ),
                ),
              );
              _loadData();
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final selectedId = _selectedId;
    if (selectedId == null) {
      return const Center(
        child: Text(
          'Selecteer een noodverlichting om de details te bekijken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return NoodverlichtingDetailView(
      key: ValueKey(selectedId),
      installationId: selectedId,
      inspectionId: widget.inspectionId,
      onSavedAndClose: () => setState(() => _selectedId = null),
      onNotFound: () => setState(() => _selectedId = null),
      onInstallationUpdated: (updated) {
        setState(() {
          final idx = _installations.indexWhere((i) => i.id == updated.id);
          if (idx >= 0) _installations[idx] = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noodverlichting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Importeren uit Inspectora',
            onPressed: _openImportLog,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Importeren uit Excel',
            onPressed: _importExcel,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporteren naar Excel',
            onPressed: _installations.isEmpty ? null : _exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Alle noodverlichting verwijderen',
            onPressed: _installations.isEmpty ? null : _deleteAllInstallations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInstallation,
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe noodverlichting'),
      ),
      body: Column(
        children: [
          InspectionNavBar(inspectionId: widget.inspectionId, current: NavSection.noodverlichting),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSplit = constraints.maxWidth >= _splitBreakpoint;
                if (!isSplit) {
                  return _buildList(context, isSplit: false);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 380,
                      child: _buildList(context, isSplit: true),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDetailPane(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
