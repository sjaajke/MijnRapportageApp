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
import '../models/checklist_template.dart';
import '../services/checklist_template_export_service.dart';
import '../services/database_service.dart';
import 'checklist_template_detail_page.dart';

/// Settings page for managing reusable checklist templates ("Standaard
/// checklijsten") that can be loaded into any inspection's checklists.
class StandardChecklistsPage extends StatefulWidget {
  const StandardChecklistsPage({super.key});

  @override
  State<StandardChecklistsPage> createState() =>
      _StandardChecklistsPageState();
}

class _StandardChecklistsPageState extends State<StandardChecklistsPage> {
  final _db = DatabaseService();
  final _exportService = ChecklistTemplateExportService();
  List<ChecklistTemplate> _templates = [];
  bool _loading = true;
  bool _importing = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getChecklistTemplates();
    if (mounted) {
      setState(() {
        _templates = list;
        _loading = false;
      });
    }
  }

  Future<void> _createTemplate() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe standaard checklijst'),
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

    final id = await _db.insertChecklistTemplate(ChecklistTemplate(
      name: name,
      sortOrder: _templates.length,
    ));
    await _load();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistTemplateDetailPage(templateId: id),
      ),
    );
    _load();
  }

  Future<void> _deleteTemplate(ChecklistTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Standaard checklijst verwijderen'),
        content:
            Text('Weet u zeker dat u "${template.name}" wilt verwijderen?'),
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
    if (confirmed == true && template.id != null) {
      await _db.deleteChecklistTemplate(template.id!);
      await _load();
    }
  }

  Future<void> _reorderTemplates(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final template = _templates.removeAt(oldIndex);
      _templates.insert(newIndex, template);
    });
    await _db.updateChecklistTemplateOrder(
      _templates.map((t) => t.id!).toList(),
    );
  }

  Future<void> _exportExcel() async {
    if (_templates.isEmpty) return;
    setState(() => _exporting = true);
    try {
      await _exportService.exportExcelAndShare();
    } catch (e) {
      _showError('Exporteren mislukt: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport() async {
    const xlsxType = XTypeGroup(
      label: 'Excel',
      extensions: ['xlsx'],
      uniformTypeIdentifiers: ['org.openxmlformats.spreadsheetml.sheet'],
    );
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;

    setState(() => _importing = true);
    try {
      final result = await _exportService.importExcel(file.path);
      await _load();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import voltooid'),
          content: Text(
              '${result.inserted} nieuwe checklijst(en) toegevoegd\n'
              '${result.updated} checklijst(en) bijgewerkt'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Importeren mislukt: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _openTemplate(ChecklistTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistTemplateDetailPage(templateId: template.id!),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standaard checklijsten'),
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
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Importeren uit Excel',
              onPressed: _pickAndImport,
            ),
          if (_exporting)
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
              icon: const Icon(Icons.ios_share),
              tooltip: 'Exporteren naar Excel',
              onPressed: _templates.isEmpty ? null : _exportExcel,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Standaard checklijst toevoegen',
            onPressed: _createTemplate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _templates.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createTemplate,
              tooltip: 'Standaard checklijst toevoegen',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nog geen standaard checklijsten aangemaakt.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Maak hier herbruikbare checklijsten die u bij elke\n'
              'inspectie kunt inladen bij Checklijsten.',
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
                  onPressed: _createTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('Standaard checklijst toevoegen'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickAndImport,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Importeren uit Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _templates.length,
      onReorder: _reorderTemplates,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          key: ValueKey(template.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.fact_check_outlined,
                color: Color(0xFF1976D2), size: 32),
            title: Text(
              template.name.isNotEmpty ? template.name : '(naamloos)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              template.items.isEmpty
                  ? 'Geen items'
                  : '${template.items.length} item(s)',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteTemplate(template),
                ),
                const Icon(Icons.chevron_right),
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            onTap: () => _openTemplate(template),
          ),
        );
      },
    );
  }
}
