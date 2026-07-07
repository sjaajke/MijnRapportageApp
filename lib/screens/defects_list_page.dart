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
import '../l10n/app_localizations.dart';
import '../models/defect.dart';
import '../services/database_service.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboards_list_page.dart';
import 'solar_installations_list_page.dart';
import 'defect_detail_page.dart';
import 'herstel_page.dart';

/// Below this content width the page shows the defect list full-screen and
/// pushes the detail as a separate route; at or above it, a split view shows
/// the list on the left and the selected defect's detail on the right.
const _splitBreakpoint = 800.0;

class DefectsListPage extends StatefulWidget {
  final int inspectionId;

  const DefectsListPage({super.key, required this.inspectionId});

  @override
  State<DefectsListPage> createState() => _DefectsListPageState();
}

class _DefectsListPageState extends State<DefectsListPage> {
  final _db = DatabaseService();
  List<Defect> _defects = [];
  Map<int, bool> _herstelStatus = {};
  bool _loading = true;
  bool _selectionMode = false;
  Set<int> _selectedIds = {};
  int? _selectedDefectId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _db.getDefects(widget.inspectionId);
    final statusMap = <int, bool>{};
    for (final d in items) {
      if (d.id != null) {
        final herstel = await _db.getHerstel(d.id!);
        statusMap[d.id!] = herstel?.isHersteld ?? false;
      }
    }
    setState(() {
      _defects = items;
      _herstelStatus = statusMap;
      _loading = false;
      if (_selectedDefectId != null &&
          !_defects.any((d) => d.id == _selectedDefectId)) {
        _selectedDefectId = null;
      }
    });
  }

  Future<void> _create() async {
    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final id = await _db.insertDefect(
      Defect(inspectionId: widget.inspectionId),
    );
    if (!mounted) return;
    if (isSplit) {
      await _loadData();
      if (!mounted) return;
      setState(() => _selectedDefectId = id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DefectDetailPage(defectId: id, inspectionId: widget.inspectionId),
      ),
    );
    _loadData();
  }

  Future<void> _deleteAll() async {
    if (_defects.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllDefects),
        content: Text(l10n.deleteAllDefectsConfirm),
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
    if (confirmed == true) {
      await _db.deleteAllDefects(widget.inspectionId);
      setState(() => _selectedDefectId = null);
      _loadData();
    }
  }

  void _enterSelectionMode([int? initialId]) {
    setState(() {
      _selectionMode = true;
      _selectedDefectId = null;
      if (initialId != null) _selectedIds.add(initialId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllRecords() {
    setState(() {
      _selectedIds = _defects.map((d) => d.id!).toSet();
    });
  }

  void _deselectAllRecords() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: Text(l10n.deleteSelectedConfirm),
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
    if (confirmed == true) {
      if (_selectedDefectId != null &&
          _selectedIds.contains(_selectedDefectId)) {
        _selectedDefectId = null;
      }
      await _db.deleteDefects(_selectedIds.toList());
      _exitSelectionMode();
      _loadData();
    }
  }

  Future<void> _delete(Defect defect) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDefect),
        content: Text(l10n.deleteDefectConfirm),
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
    if (confirmed == true) {
      if (_selectedDefectId == defect.id) {
        setState(() => _selectedDefectId = null);
      }
      await _db.deleteDefect(defect.id!);
      _loadData();
    }
  }

  Color _classificationColor(String classification) {
    switch (classification) {
      case 'Rd':
        return Colors.red;
      case 'Or':
        return Colors.orange;
      case 'Ge':
        return Colors.yellow.shade700;
      case 'Bl':
        return Colors.blue;
      case 'Pa':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildList(BuildContext context, {required bool isSplit}) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_defects.isEmpty) {
      return Center(
        child: Text(
          l10n.noDefects,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _defects.length,
      itemBuilder: (context, index) {
        final defect = _defects[index];
        final isSelected = _selectedIds.contains(defect.id);
        final isActive = isSplit && !_selectionMode && defect.id == _selectedDefectId;
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          color: isSelected || isActive
              ? Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.4)
              : null,
          child: ListTile(
            leading: _selectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(defect.id!),
                  )
                : CircleAvatar(
                    backgroundColor: _classificationColor(
                      defect.classification,
                    ),
                    radius: 16,
                    child: Text(
                      defect.classification,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            title: Text(
              defect.locationFull.isNotEmpty
                  ? defect.locationFull
                  : l10n.defectNumber(defect.id!),
            ),
            subtitle: defect.description.isNotEmpty
                ? Text(
                    defect.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: _selectionMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_herstelStatus[defect.id] == true)
                        Tooltip(
                          message: 'Hersteld',
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HerstelPage(
                                  defectId: defect.id!,
                                  inspectionId: widget.inspectionId,
                                  defectLabel: defect.locationFull.isNotEmpty
                                      ? defect.locationFull
                                      : 'Gebrek #${defect.id}',
                                ),
                              ),
                            ).then((_) => _loadData()),
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade400,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 13,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Hersteld',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _delete(defect),
                      ),
                      if (isSplit) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ],
                  ),
            onTap: () async {
              if (_selectionMode) {
                _toggleSelection(defect.id!);
                return;
              }
              if (isSplit) {
                setState(() => _selectedDefectId = defect.id);
                return;
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DefectDetailPage(
                    defectId: defect.id!,
                    inspectionId: widget.inspectionId,
                  ),
                ),
              );
              _loadData();
            },
            onLongPress: _selectionMode ? null : () => _enterSelectionMode(defect.id),
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final selectedId = _selectedDefectId;
    if (selectedId == null) {
      return const Center(
        child: Text(
          'Selecteer een gebrek om de details te bekijken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return DefectDetailView(
      key: ValueKey(selectedId),
      defectId: selectedId,
      inspectionId: widget.inspectionId,
      onSimilarCreated: (newId) {
        _loadData();
        setState(() => _selectedDefectId = newId);
      },
      onSavedAndClose: () => setState(() => _selectedDefectId = null),
      onNotFound: () => setState(() => _selectedDefectId = null),
      onDefectUpdated: (updated) {
        setState(() {
          final idx = _defects.indexWhere((d) => d.id == updated.id);
          if (idx >= 0) _defects[idx] = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(
          _selectionMode
              ? l10n.selectedCount(_selectedIds.length)
              : l10n.defectsTitle,
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: l10n.selectAll,
                  onPressed: _selectAllRecords,
                ),
                IconButton(
                  icon: const Icon(Icons.deselect),
                  tooltip: l10n.deselectAll,
                  onPressed: _deselectAllRecords,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteSelected,
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              ]
            : [
                if (_defects.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    tooltip: l10n.selectDefects,
                    onPressed: _enterSelectionMode,
                  ),
                if (_defects.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: l10n.deleteAllDefects,
                    onPressed: _deleteAll,
                  ),
              ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: Text(l10n.newDefect),
            ),
      body: Column(
        children: [
          _NavBar(inspectionId: widget.inspectionId),
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

class _NavBar extends StatelessWidget {
  final int inspectionId;
  const _NavBar({required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _btn(
              context,
              Icons.list_outlined,
              'Inspecties',
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              ),
            ),
            _btn(
              context,
              Icons.home_outlined,
              'Inspectie',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InspectionMenuPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.electrical_services,
              'Verdelers',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SwitchboardsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.solar_power,
              'Zonnestroom',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SolarInstallationsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
            _btn(
              context,
              Icons.warning_amber,
              'Gebreken',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DefectsListPage(inspectionId: inspectionId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
    );
  }
}
