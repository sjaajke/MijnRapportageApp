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
import '../l10n/app_localizations.dart';
import '../models/report_template.dart';
import '../services/database_service.dart';
import 'report_template_detail_page.dart';

class ReportTemplatesPage extends StatefulWidget {
  const ReportTemplatesPage({super.key});

  @override
  State<ReportTemplatesPage> createState() => _ReportTemplatesPageState();
}

class _ReportTemplatesPageState extends State<ReportTemplatesPage> {
  final _db = DatabaseService();
  List<ReportTemplate> _templates = [];
  bool _loading = true;
  bool _importing = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = await _db.getReportTemplates();
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _loading = false;
    });
  }

  Future<void> _openTemplate(ReportTemplate? template) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportTemplateDetailPage(template: template),
      ),
    );
    if (result == true) await _load();
  }

  Future<void> _deleteTemplate(ReportTemplate template) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteReportTemplate),
        content: Text(l10n.deleteReportTemplateConfirm(template.rapporttitel)),
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
    await _db.deleteReportTemplate(template.id!);
    await _load();
  }

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
        final typeRapport = cell(row, 'TypeRapport');
        if (typeRapport.isEmpty) continue;

        final template = ReportTemplate(
          typeRapport: typeRapport,
          rapporttitel: cell(row, 'Rapporttitel'),
          subtitel: cell(row, 'Subtitel'),
          inleiding: cell(row, 'Inleiding'),
          tekstRapportVerklaring: cell(row, 'Eindbeoordeling'),
          visueleInspectieTitel: cell(row, 'Visuele inspectie Titel'),
          visueleInspectie: cell(row, 'Visuele inspectie'),
          visueleInspectieToelichting:
              cell(row, 'Visuele inspectie Toelichting'),
          metingenTitel: cell(row, 'Metingen en beproevingen Titel'),
          metingen: cell(row, 'Metingen en beproevingen'),
          metingenToelichting:
              cell(row, 'Metingen en beproevingen Toelichting'),
          aanvullendOnderzoekTitel: cell(row, 'Aanvullend onderzoek Titel'),
          aanvullendOnderzoek: cell(row, 'Aanvullend onderzoek'),
          aanvullendOnderzoekToelichting:
              cell(row, 'Toelichting Aanvullend Onderzoek'),
          lijst4Titel: cell(row, 'Lijst_4_Titel'),
          lijst4: cell(row, 'Lijst_4'),
          lijst4Toelichting: cell(row, 'Lijst_4_Toelichting'),
          vinklijstAfkeuringscriteria:
              cell(row, 'Vinklijst afkeuringscriteria'),
          inspectieUitgevoerdVolgens:
              cell(row, 'De inspectie is uitgevoerd volgens'),
          elektrischMaterieelGetoetst:
              cell(row, 'Het elektrisch materieel is getoets aan'),
          inleidingToelichting: cell(row, 'Toelichting'),
        );

        final wasInserted = await _db.upsertReportTemplateByType(template);
        if (wasInserted) { inserted++; } else { updated++; }
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
            '$inserted nieuwe template(s) toegevoegd\n$updated template(s) bijgewerkt'),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTexts),
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
              tooltip: 'Importeer Excel',
              onPressed: _pickAndImport,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTemplate(null),
        tooltip: l10n.addReportTemplate,
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
                  _templates.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noReportTemplates,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _templates.length,
                          itemBuilder: (context, index) {
                            final t = _templates[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(
                                  t.rapporttitel.isNotEmpty
                                      ? t.rapporttitel
                                      : t.typeRapport,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: t.typeRapport.isNotEmpty
                                    ? Text(
                                        t.typeRapport,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openTemplate(t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteTemplate(t),
                                    ),
                                  ],
                                ),
                                onTap: () => _openTemplate(t),
                              ),
                            );
                          },
                        ),
                  // Drop-overlay
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
                                  fontSize: 18, color: Colors.blue.shade800),
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
