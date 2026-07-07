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
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/general_data.dart';
import '../models/inspection.dart';
import '../models/title_page.dart' as tp;
import '../services/database_service.dart';
import '../services/xml_export_service.dart';
import '../services/xml_import_service.dart';
import '../services/pdf_export_service.dart';
import 'title_page.dart';
import 'inspection_menu_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = DatabaseService();
  List<Inspection> _inspections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _loading = true);
    final inspections = await _db.getInspections();
    setState(() {
      _inspections = inspections;
      _loading = false;
    });
  }

  Future<void> _importZip() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'ZIP', extensions: ['zip']),
      ],
    );
    if (file == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = await file.readAsBytes();
      final newId = await XmlImportService().importFromZip(bytes);
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InspectionMenuPage(inspectionId: newId),
        ),
      );
      _loadInspections();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importeren mislukt: $e')),
      );
    }
  }

  Future<void> _createInspection() async {
    final id = await _db.createInspection();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TitlePageScreen(inspectionId: id),
      ),
    );
    _loadInspections();
  }

  Future<void> _exportXml(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final path = await XmlExportService().exportInspection(inspection.id!);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.xmlExported(path))),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e))),
      );
    }
  }

  Future<void> _exportPdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService().generatePdf(inspection.id!);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    try {
      await Share.shareXFiles([XFile(path)], text: l10n.shareText);
    } catch (_) {}
  }

  Future<void> _exportConstateriungPdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService()
          .generateConstateriungPdf(inspection.id!);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    try {
      await Share.shareXFiles([XFile(path)], text: l10n.shareText);
    } catch (_) {}
  }

  Future<void> _exportSwitchboardConstateriungPdf(
      Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService()
          .generateSwitchboardsConstateriungPdf(inspection.id!);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    try {
      await Share.shareXFiles([XFile(path)], text: l10n.shareText);
    } catch (_) {}
  }

  Future<void> _exportHerstelPdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService().generateHerstelPdf(inspection.id!);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    try {
      await Share.shareXFiles([XFile(path)], text: l10n.shareText);
    } catch (_) {}
  }

  Future<void> _generateSamplePdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService().generateSamplePdf();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.samplePdfFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    try {
      await Share.shareXFiles([XFile(path)], text: l10n.shareSampleText);
    } catch (_) {}
  }

  Future<void> _exportZip(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String pdfPath;
    String xmlPath;
    try {
      pdfPath = await PdfExportService().generatePdf(inspection.id!);
      xmlPath = await XmlExportService().exportInspection(inspection.id!);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);

    // Build ZIP in memory
    final archive = Archive();
    for (final filePath in [pdfPath, xmlPath]) {
      final bytes = await File(filePath).readAsBytes();
      archive.addFile(ArchiveFile(p.basename(filePath), bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ZIP aanmaken mislukt')),
      );
      return;
    }

    // Suggested filename from TitlePage
    final titlePage = await _db.getTitlePage(inspection.id!);
    final safeName = (titlePage?.title.isNotEmpty == true)
        ? titlePage!.title.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        : 'inspectie_${inspection.id}';

    // Let user choose save location
    final location = await getSaveLocation(
      suggestedName: '$safeName.zip',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'ZIP', extensions: ['zip']),
      ],
    );
    if (location == null || !mounted) return;

    await File(location.path).writeAsBytes(zipBytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Geëxporteerd naar ${location.path}')),
    );
  }

  Future<void> _duplicateInspection(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _db.duplicateInspection(inspection.id!,
          titleSuffix: l10n.copySuffix);
      if (!mounted) return;
      Navigator.pop(context);
      _loadInspections();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.duplicateInspectionFailed}: $e')),
      );
    }
  }

  Future<void> _copySections(Inspection source) async {
    final targets = _inspections.where((i) => i.id != source.id).toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Er is geen andere inspectie om naar over te nemen'),
        ),
      );
      return;
    }
    final copied = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _CopySectionsDialog(source: source, targets: targets, db: _db),
    );
    if (copied == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onderdelen overgenomen')),
      );
    }
  }

  Future<void> _deleteInspection(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInspection),
        content: Text(l10n.deleteInspectionConfirm),
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
      await _db.deleteInspection(inspection.id!);
      _loadInspections();
    }
  }

  void _toggleLanguage() {
    final current = AppLocalizations.of(context).locale.languageCode;
    final next = current == 'nl' ? const Locale('en') : const Locale('nl');
    InspectieApp.setLocale(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNl = l10n.locale.languageCode == 'nl';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inspections),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'ZIP importeren',
            onPressed: _importZip,
          ),
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              isNl ? 'EN' : 'NL',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInspection,
        icon: const Icon(Icons.add),
        label: Text(l10n.newInspection),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _inspections.isEmpty
              ? Center(
                  child: Text(
                    l10n.noInspections,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInspections,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _inspections.length,
                    itemBuilder: (context, index) {
                      return _InspectionTile(
                        inspection: _inspections[index],
                        db: _db,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InspectionMenuPage(
                                inspectionId: _inspections[index].id!,
                              ),
                            ),
                          );
                          _loadInspections();
                        },
                        onExportXml: () => _exportXml(_inspections[index]),
                        onExportPdf: () => _exportPdf(_inspections[index]),
                        onExportConstateriungPdf: () =>
                            _exportConstateriungPdf(_inspections[index]),
                        onExportSwitchboardConstateriungPdf: () =>
                            _exportSwitchboardConstateriungPdf(
                                _inspections[index]),
                        onExportHerstelPdf: () =>
                            _exportHerstelPdf(_inspections[index]),
                        onExportZip: () => _exportZip(_inspections[index]),
                        onSamplePdf: () =>
                            _generateSamplePdf(_inspections[index]),
                        onCopySections: () =>
                            _copySections(_inspections[index]),
                        onDuplicate: () =>
                            _duplicateInspection(_inspections[index]),
                        onDelete: () => _deleteInspection(_inspections[index]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  final Inspection inspection;
  final DatabaseService db;
  final VoidCallback onTap;
  final VoidCallback onExportXml;
  final VoidCallback onExportPdf;
  final VoidCallback onExportConstateriungPdf;
  final VoidCallback onExportSwitchboardConstateriungPdf;
  final VoidCallback onExportHerstelPdf;
  final VoidCallback onExportZip;
  final VoidCallback onSamplePdf;
  final VoidCallback onCopySections;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _InspectionTile({
    required this.inspection,
    required this.db,
    required this.onTap,
    required this.onExportXml,
    required this.onExportPdf,
    required this.onExportConstateriungPdf,
    required this.onExportSwitchboardConstateriungPdf,
    required this.onExportHerstelPdf,
    required this.onExportZip,
    required this.onSamplePdf,
    required this.onCopySections,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        db.getTitlePage(inspection.id!),
        db.getGeneralData(inspection.id!),
      ]),
      builder: (context, snapshot) {
        final titlePage = snapshot.data?[0] as tp.TitlePage?;
        final generalData = snapshot.data?[1] as GeneralData?;
        final title = (titlePage?.title.isNotEmpty == true)
            ? titlePage!.title
            : l10n.inspectionNumber(inspection.id!);
        final date = titlePage?.inspectionDate ?? '';
        final projectNumber = titlePage?.projectNumber ?? '';
        final objectnaam = generalData?.inspectionAddressName ?? '';

        String statusLabel;
        Color statusColor;
        switch (inspection.status) {
          case 'completed':
            statusLabel = l10n.statusCompleted;
            statusColor = Colors.green;
            break;
          case 'exported':
            statusLabel = l10n.statusExported;
            statusColor = Colors.blue;
            break;
          default:
            statusLabel = l10n.statusDraft;
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (projectNumber.isNotEmpty)
                  Text(
                    projectNumber,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (objectnaam.isNotEmpty)
                  Text(
                    objectnaam,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            subtitle: Row(
              children: [
                if (date.isNotEmpty) ...[
                  Text(date, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'zip':
                    onExportZip();
                    break;
                  case 'xml':
                    onExportXml();
                    break;
                  case 'pdf':
                    onExportPdf();
                    break;
                  case 'pdf_constatering':
                    onExportConstateriungPdf();
                    break;
                  case 'pdf_schakelv':
                    onExportSwitchboardConstateriungPdf();
                    break;
                  case 'pdf_herstel':
                    onExportHerstelPdf();
                    break;
                  case 'sample_pdf':
                    onSamplePdf();
                    break;
                  case 'copy_sections':
                    onCopySections();
                    break;
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'zip',
                  child: Row(
                    children: [
                      Icon(Icons.folder_zip_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Exporteren als ZIP'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'xml',
                  child: Row(
                    children: [
                      const Icon(Icons.code, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.exportXml),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.generatePdf),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf_constatering',
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.generateConstateriungPdf),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf_schakelv',
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.generateSwitchboardConstateriungPdf,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf_herstel',
                  child: Row(
                    children: [
                      const Icon(Icons.build_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.generateHerstelPdf),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sample_pdf',
                  child: Row(
                    children: [
                      const Icon(Icons.description,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(l10n.samplePdf),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_sections',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 20),
                      SizedBox(width: 8),
                      Text('Onderdelen overnemen'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_all_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.duplicateInspection),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.delete,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

class _CopySectionsDialog extends StatefulWidget {
  final Inspection source;
  final List<Inspection> targets;
  final DatabaseService db;

  const _CopySectionsDialog({
    required this.source,
    required this.targets,
    required this.db,
  });

  @override
  State<_CopySectionsDialog> createState() => _CopySectionsDialogState();
}

class _CopySectionsDialogState extends State<_CopySectionsDialog> {
  bool _loading = true;
  bool _busy = false;
  int? _targetId;
  final Map<int, String> _labels = {};

  bool _copySwitchboards = true;
  bool _copySolar = true;
  bool _copyDefects = true;

  int _switchboardCount = 0;
  int _solarCount = 0;
  int _defectCount = 0;

  bool _targetCountsLoading = false;
  int _targetSwitchboardCount = 0;
  int _targetSolarCount = 0;
  int _targetDefectCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sourceId = widget.source.id!;
    final results = await Future.wait([
      widget.db.getSwitchboards(sourceId),
      widget.db.getSolarInstallations(sourceId),
      widget.db.getDefects(sourceId),
      ...widget.targets.map((i) => widget.db.getTitlePage(i.id!)),
    ]);
    if (!mounted) return;
    setState(() {
      _switchboardCount = (results[0] as List).length;
      _solarCount = (results[1] as List).length;
      _defectCount = (results[2] as List).length;
      for (var i = 0; i < widget.targets.length; i++) {
        final titlePage = results[3 + i] as tp.TitlePage?;
        final label = (titlePage?.title.isNotEmpty == true)
            ? titlePage!.title
            : 'Inspectie #${widget.targets[i].id}';
        _labels[widget.targets[i].id!] = label;
      }
      _targetId = widget.targets.first.id;
      _loading = false;
    });
    await _loadTargetCounts();
  }

  Future<void> _loadTargetCounts() async {
    final targetId = _targetId;
    if (targetId == null) return;
    setState(() => _targetCountsLoading = true);
    final results = await Future.wait([
      widget.db.getSwitchboards(targetId),
      widget.db.getSolarInstallations(targetId),
      widget.db.getDefects(targetId),
    ]);
    // The selected target may have changed again while this was loading.
    if (!mounted || _targetId != targetId) return;
    setState(() {
      _targetSwitchboardCount = (results[0] as List).length;
      _targetSolarCount = (results[1] as List).length;
      _targetDefectCount = (results[2] as List).length;
      _targetCountsLoading = false;
    });
  }

  String _targetCountSubtitle(int targetCount) {
    if (_targetCountsLoading) return 'Doel heeft al: ...';
    return 'Doel heeft al: $targetCount';
  }

  bool get _canConfirm =>
      !_busy &&
      _targetId != null &&
      (_copySwitchboards || _copySolar || _copyDefects);

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() => _busy = true);
    final sourceId = widget.source.id!;
    final targetId = _targetId!;
    try {
      if (_copySwitchboards) {
        await widget.db.copySwitchboardsToInspection(sourceId, targetId);
      }
      if (_copySolar) {
        await widget.db.copySolarInstallationsToInspection(
            sourceId, targetId);
      }
      if (_copyDefects) {
        await widget.db.copyDefectsToInspection(sourceId, targetId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Overnemen mislukt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Onderdelen overnemen'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Over te nemen naar:'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    initialValue: _targetId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: widget.targets
                        .map((i) => DropdownMenuItem<int>(
                              value: i.id,
                              child: Text(
                                _labels[i.id] ?? 'Inspectie #${i.id}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (v) {
                            setState(() => _targetId = v);
                            _loadTargetCounts();
                          },
                  ),
                  const SizedBox(height: 16),
                  const Text('Onderdelen:'),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Verdelers ($_switchboardCount)'),
                    subtitle: Text(_targetCountSubtitle(_targetSwitchboardCount)),
                    value: _copySwitchboards,
                    onChanged: _busy || _switchboardCount == 0
                        ? null
                        : (v) =>
                            setState(() => _copySwitchboards = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Zonnestroom ($_solarCount)'),
                    subtitle: Text(_targetCountSubtitle(_targetSolarCount)),
                    value: _copySolar,
                    onChanged: _busy || _solarCount == 0
                        ? null
                        : (v) => setState(() => _copySolar = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Constateringen ($_defectCount)'),
                    subtitle: Text(_targetCountSubtitle(_targetDefectCount)),
                    value: _copyDefects,
                    onChanged: _busy || _defectCount == 0
                        ? null
                        : (v) => setState(() => _copyDefects = v ?? false),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: _canConfirm ? _confirm : null,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Overnemen'),
        ),
      ],
    );
  }
}
