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
import '../models/checklist.dart';
import '../models/checklist_item_entry.dart';
import '../models/checklist_template.dart';
import '../services/database_service.dart';
import 'checklist_detail_page.dart';

/// Below this content width the page shows the checklists list full-screen
/// and pushes the detail as a separate route; at or above it, a split view
/// shows the list on the left and the selected checklist's detail on the
/// right.
const _splitBreakpoint = 800.0;

class ChecklistsListPage extends StatefulWidget {
  final int inspectionId;

  const ChecklistsListPage({super.key, required this.inspectionId});

  @override
  State<ChecklistsListPage> createState() => _ChecklistsListPageState();
}

class _ChecklistsListPageState extends State<ChecklistsListPage> {
  final _db = DatabaseService();
  List<Checklist> _checklists = [];
  bool _loading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getChecklists(widget.inspectionId);
    if (mounted) {
      setState(() {
        _checklists = list;
        _loading = false;
        if (_selectedId != null &&
            !_checklists.any((c) => c.id == _selectedId)) {
          _selectedId = null;
        }
      });
    }
  }

  Future<void> _createChecklist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe checklijst'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Naam', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Aanmaken')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    if (!mounted) return;

    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final id = await _db.insertChecklist(Checklist(
      inspectionId: widget.inspectionId,
      name: name,
      sortOrder: _checklists.length,
    ));
    if (!mounted) return;
    if (isSplit) {
      await _load();
      if (!mounted) return;
      setState(() => _selectedId = id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistDetailPage(
          inspectionId: widget.inspectionId,
          checklistId: id,
        ),
      ),
    );
    _load();
  }

  Future<void> _loadFromTemplate() async {
    final templates = await _db.getChecklistTemplates();
    if (!mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nog geen standaard checklijsten. Maak deze aan bij Instellingen > Standaard checklijsten.'),
        ),
      );
      return;
    }

    final selected = await showDialog<ChecklistTemplate>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Standaard checklijst laden'),
        children: templates
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined,
                        size: 20, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name.isNotEmpty ? t.name : '(naamloos)'),
                          Text(
                            t.items.isEmpty
                                ? 'Geen items'
                                : '${t.items.length} item(s)',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    if (!mounted) return;

    final isSplit = MediaQuery.sizeOf(context).width >= _splitBreakpoint;
    final items = [
      for (var i = 0; i < selected.items.length; i++)
        ChecklistItemEntry(id: i + 1, label: selected.items[i]),
    ];
    final id = await _db.insertChecklist(Checklist(
      inspectionId: widget.inspectionId,
      name: selected.name,
      items: items,
      sortOrder: _checklists.length,
    ));
    if (!mounted) return;
    if (isSplit) {
      await _load();
      if (!mounted) return;
      setState(() => _selectedId = id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistDetailPage(
          inspectionId: widget.inspectionId,
          checklistId: id,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteChecklist(Checklist checklist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Checklijst verwijderen'),
        content:
            Text('Weet u zeker dat u "${checklist.name}" wilt verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && checklist.id != null) {
      if (_selectedId == checklist.id) {
        setState(() => _selectedId = null);
      }
      await _db.deleteChecklist(checklist.id!);
      await _load();
    }
  }

  Future<void> _reorderChecklists(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final checklist = _checklists.removeAt(oldIndex);
      _checklists.insert(newIndex, checklist);
    });
    await _db.updateChecklistOrder(
      _checklists.map((c) => c.id!).toList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen checklijsten aangemaakt.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Maak eigen checklijsten met vrij in te vullen items,\n'
              'te beantwoorden met Ja, Nee of N.v.t.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _createChecklist,
                  icon: const Icon(Icons.add),
                  label: const Text('Checklijst toevoegen'),
                ),
                OutlinedButton.icon(
                  onPressed: _loadFromTemplate,
                  icon: const Icon(Icons.library_add_outlined),
                  label: const Text('Standaard checklijst laden'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, {required bool isSplit}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_checklists.isEmpty) {
      return _buildEmpty();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _checklists.length,
      onReorder: _reorderChecklists,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final checklist = _checklists[index];
        final total = checklist.items.length;
        final answered =
            checklist.items.where((i) => i.value != 'N.v.t.').length;
        final isActive = isSplit && checklist.id == _selectedId;
        return Card(
          key: ValueKey(checklist.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isActive
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.4)
              : null,
          child: ListTile(
            leading: const Icon(Icons.checklist,
                color: Color(0xFF1976D2), size: 32),
            title: Text(
              checklist.name.isNotEmpty ? checklist.name : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              total == 0 ? 'Geen items' : '$answered/$total ingevuld',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteChecklist(checklist),
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
                setState(() => _selectedId = checklist.id);
                return;
              }
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChecklistDetailPage(
                    inspectionId: widget.inspectionId,
                    checklistId: checklist.id!,
                  ),
                ),
              );
              _load();
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
          'Selecteer een checklijst om de details te bekijken.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ChecklistDetailView(
      key: ValueKey(selectedId),
      inspectionId: widget.inspectionId,
      checklistId: selectedId,
      onNotFound: () => setState(() => _selectedId = null),
      onChecklistUpdated: (updated) {
        setState(() {
          final idx = _checklists.indexWhere((c) => c.id == updated.id);
          if (idx >= 0) _checklists[idx] = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklijsten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: 'Standaard checklijst laden',
            onPressed: _loadFromTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Checklijst toevoegen',
            onPressed: _createChecklist,
          ),
        ],
      ),
      body: LayoutBuilder(
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
                child: _buildDetailPane(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
