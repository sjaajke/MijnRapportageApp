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
import '../models/switchboard.dart';
import '../services/database_service.dart';
import 'home_page.dart';
import 'inspection_menu_page.dart';
import 'switchboard_detail_page.dart';
import 'solar_installations_list_page.dart';
import 'noodverlichting_list_page.dart';
import 'defects_list_page.dart';

/// Below this content width the page shows the switchboard list full-screen
/// and pushes the detail as a separate route; at or above it, a split view
/// shows the list on the left and the selected switchboard's detail on the
/// right.
const _splitBreakpoint = 800.0;

class SwitchboardsListPage extends StatefulWidget {
  final int inspectionId;

  const SwitchboardsListPage({super.key, required this.inspectionId});

  @override
  State<SwitchboardsListPage> createState() => _SwitchboardsListPageState();
}

class _SwitchboardsListPageState extends State<SwitchboardsListPage> {
  final _db = DatabaseService();
  List<Switchboard> _switchboards = [];
  bool _loading = true;
  int? _selectedSwitchboardId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _db.getSwitchboards(widget.inspectionId);
    setState(() {
      _switchboards = items;
      _loading = false;
      if (_selectedSwitchboardId != null &&
          !_switchboards.any((sb) => sb.id == _selectedSwitchboardId)) {
        _selectedSwitchboardId = null;
      }
    });
  }

  Future<void> _createSwitchboard() async {
    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final id = await _db.insertSwitchboard(
      Switchboard(
        inspectionId: widget.inspectionId,
        sortOrder: _switchboards.length,
      ),
    );
    if (!mounted) return;
    if (isSplit) {
      await _loadData();
      if (!mounted) return;
      setState(() => _selectedSwitchboardId = id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwitchboardDetailPage(
          switchboardId: id,
          inspectionId: widget.inspectionId,
        ),
      ),
    );
    _loadData();
  }

  Future<void> _deleteSwitchboard(Switchboard sb) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSwitchboard),
        content: Text(l10n.deleteSwitchboardConfirm),
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
      if (_selectedSwitchboardId == sb.id) {
        setState(() => _selectedSwitchboardId = null);
      }
      await _db.deleteSwitchboard(sb.id!);
      _loadData();
    }
  }

  Future<void> _reorderSwitchboards(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final sb = _switchboards.removeAt(oldIndex);
      _switchboards.insert(newIndex, sb);
    });
    await _db.updateSwitchboardOrder(
      _switchboards.map((sb) => sb.id!).toList(),
    );
  }

  Widget _buildList(BuildContext context, {required bool isSplit}) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_switchboards.isEmpty) {
      return Center(
        child: Text(
          l10n.noSwitchboards,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _switchboards.length,
      onReorder: _reorderSwitchboards,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final sb = _switchboards[index];
        final isActive = isSplit && sb.id == _selectedSwitchboardId;
        return Card(
          key: ValueKey(sb.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.4)
              : null,
          child: ListTile(
            leading: const Icon(Icons.lan,
                color: Color(0xFF1976D2)),
            title: Text(
              sb.name.isNotEmpty ? sb.name : l10n.switchboardNumber(sb.id!),
            ),
            subtitle:
                sb.locationFull.isNotEmpty ? Text(sb.locationFull) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteSwitchboard(sb),
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
                setState(() => _selectedSwitchboardId = sb.id);
                return;
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SwitchboardDetailPage(
                    switchboardId: sb.id!,
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
    final selectedId = _selectedSwitchboardId;
    if (selectedId == null) {
      return const Center(
        child: Text(
          'Selecteer een verdeler om de details te bekijken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SwitchboardDetailView(
      key: ValueKey(selectedId),
      switchboardId: selectedId,
      inspectionId: widget.inspectionId,
      onSavedAndClose: () => setState(() => _selectedSwitchboardId = null),
      onNotFound: () => setState(() => _selectedSwitchboardId = null),
      onSwitchboardUpdated: (updated) {
        setState(() {
          final idx = _switchboards.indexWhere((sb) => sb.id == updated.id);
          if (idx >= 0) _switchboards[idx] = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.switchboardsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSwitchboard,
        icon: const Icon(Icons.add),
        label: Text(l10n.newSwitchboard),
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
            _btn(context, Icons.list_outlined, 'Inspecties',
                () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                      builder: (_) => HomePage()), (route) => false)),
            _btn(context, Icons.home_outlined, 'Inspectie',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InspectionMenuPage(inspectionId: inspectionId)))),
            _btn(context, Icons.lan, 'Verdelers',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SwitchboardsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.solar_power, 'Zonnestroom',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SolarInstallationsListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.emergency, 'Noodverlichting',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NoodverlichtingListPage(inspectionId: inspectionId)))),
            _btn(context, Icons.warning_amber, 'Gebreken',
                () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DefectsListPage(inspectionId: inspectionId)))),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1976D2)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2))),
          ],
        ),
      ),
    );
  }
}
