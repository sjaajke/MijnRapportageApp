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
import 'dart:math' as math;
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/general_data.dart';
import '../models/inspection.dart';
import '../models/title_page.dart' as tp;
import '../models/switchboard.dart';
import '../models/defect.dart';
import '../models/solar_installation.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../services/xml_export_service.dart';
import '../services/xml_import_service.dart';
import '../services/pdf_export_service.dart';
import 'handleiding_page.dart';
import 'privacy_screen.dart';
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
  String? _loadError;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadInspections();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
  }

  Future<void> _loadInspections() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final inspections = await _db.getInspections();
      if (!mounted) return;
      setState(() {
        _inspections = inspections;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Database openen mislukt: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importZip() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'ZIP',
          extensions: ['zip'],
          uniformTypeIdentifiers: [
            'public.zip-archive',
            'com.pkware.zip-archive',
          ],
        ),
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
    final int id;
    try {
      id = await _db.createInspection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aanmaken mislukt: $e')),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionMenuPage(inspectionId: id),
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

  Future<void> _exportNoodverlichtingPdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path =
          await PdfExportService().generateNoodverlichtingPdf(inspection.id!);
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

  Future<void> _exportNoodverlichtingInternPdf(Inspection inspection) async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String path;
    try {
      path = await PdfExportService()
          .generateNoodverlichtingInternPdf(inspection.id!);
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

    final exportsDir = await PhotoService().getExportsDir();
    final zipPath = p.join(exportsDir, '$safeName.zip');
    await File(zipPath).writeAsBytes(zipBytes);

    if (!mounted) return;
    try {
      await Share.shareXFiles([XFile(zipPath)], text: l10n.shareText);
    } catch (_) {}
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

  Future<void> _copySections(Inspection target) async {
    final sources = _inspections.where((i) => i.id != target.id).toList();
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Er is geen andere inspectie om onderdelen van over te nemen'),
        ),
      );
      return;
    }
    final summary = await showDialog<String>(
      context: context,
      builder: (_) =>
          _CopySectionsDialog(target: target, sources: sources, db: _db),
    );
    if (summary != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(summary)),
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

  Future<void> _copyError(String error) async {
    await Clipboard.setData(ClipboardData(text: error));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foutmelding gekopieerd')),
    );
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
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.inspections),
            if (_appVersion.isNotEmpty)
              Text(
                _appVersion,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'ZIP importeren',
            onPressed: _importZip,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: isNl ? 'Handleiding' : 'User guide',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HandleidingPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: l10n.privacyPolicyMenuItem,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
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
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _loadInspections,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Opnieuw proberen'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _copyError(_loadError!),
                              icon: const Icon(Icons.copy),
                              label: const Text('Foutmelding kopiëren'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
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
                        onExportNoodverlichtingPdf: () =>
                            _exportNoodverlichtingPdf(_inspections[index]),
                        onExportNoodverlichtingInternPdf: () =>
                            _exportNoodverlichtingInternPdf(
                                _inspections[index]),
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
  final VoidCallback onExportNoodverlichtingPdf;
  final VoidCallback onExportNoodverlichtingInternPdf;
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
    required this.onExportNoodverlichtingPdf,
    required this.onExportNoodverlichtingInternPdf,
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
                  case 'pdf_noodverlichting':
                    onExportNoodverlichtingPdf();
                    break;
                  case 'pdf_noodverlichting_intern':
                    onExportNoodverlichtingInternPdf();
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
                  value: 'pdf_noodverlichting',
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.generateNoodverlichtingPdf,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf_noodverlichting_intern',
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.generateNoodverlichtingInternPdf,
                          softWrap: true,
                        ),
                      ),
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
  final Inspection target;
  final List<Inspection> sources;
  final DatabaseService db;

  const _CopySectionsDialog({
    required this.target,
    required this.sources,
    required this.db,
  });

  @override
  State<_CopySectionsDialog> createState() => _CopySectionsDialogState();
}

/// Eén gevonden dubbeling tussen een bron- en een doelrecord, met de
/// door de gebruiker gekozen actie.
class _DuplicateEntry {
  final String category; // 'Verdeler' / 'Zonnestroom-installatie' / 'Constatering'
  final int sourceId;
  final int targetId;
  final String sourceLabel;
  final String targetLabel;
  DuplicateCopyAction action;

  _DuplicateEntry({
    required this.category,
    required this.sourceId,
    required this.targetId,
    required this.sourceLabel,
    required this.targetLabel,
    this.action = DuplicateCopyAction.skip,
  });
}

class _CopySectionsDialogState extends State<_CopySectionsDialog> {
  static const _actionLabels = {
    DuplicateCopyAction.skip: 'Niet overnemen',
    DuplicateCopyAction.copyMarked: 'Overnemen en markeren',
    DuplicateCopyAction.copyUnmarked: 'Overnemen zonder markeren',
    DuplicateCopyAction.replace: 'Overnemen en bestaand vervangen',
  };

  bool _loading = true;
  bool _busy = false;
  int _step = 0;
  int? _sourceId;
  final Map<int, String> _sourceLabels = {};

  bool _copySwitchboards = true;
  bool _copySolar = true;
  bool _copyDefects = true;

  // Aantallen in de (vaste) doelinspectie, éénmalig geladen.
  int _targetSwitchboardCount = 0;
  int _targetSolarCount = 0;
  int _targetDefectCount = 0;

  // Aantallen in de gekozen bron-inspectie, herladen bij wisselen.
  bool _sourceCountsLoading = false;
  int _sourceSwitchboardCount = 0;
  int _sourceSolarCount = 0;
  int _sourceDefectCount = 0;

  List<_DuplicateEntry> _duplicates = [];
  DuplicateCopyAction _bulkAction = DuplicateCopyAction.skip;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatSourceLabel(
      tp.TitlePage? titlePage, GeneralData? generalData, int id) {
    final projectNumber = titlePage?.projectNumber ?? '';
    final objectnaam = generalData?.inspectionAddressName ?? '';
    final title = (titlePage?.title.isNotEmpty == true)
        ? titlePage!.title
        : 'Inspectie #$id';
    final parts = <String>[
      if (projectNumber.isNotEmpty) projectNumber,
      if (objectnaam.isNotEmpty) objectnaam,
      title,
    ];
    return parts.join(' · ');
  }

  Future<void> _load() async {
    final targetId = widget.target.id!;
    final targetCounts = await Future.wait([
      widget.db.getSwitchboards(targetId),
      widget.db.getSolarInstallations(targetId),
      widget.db.getDefects(targetId),
    ]);
    final sourceLabels = await Future.wait(widget.sources.map((i) async {
      final titlePage = await widget.db.getTitlePage(i.id!);
      final generalData = await widget.db.getGeneralData(i.id!);
      return MapEntry(i.id!, _formatSourceLabel(titlePage, generalData, i.id!));
    }));
    if (!mounted) return;
    setState(() {
      _targetSwitchboardCount = (targetCounts[0] as List).length;
      _targetSolarCount = (targetCounts[1] as List).length;
      _targetDefectCount = (targetCounts[2] as List).length;
      for (final entry in sourceLabels) {
        _sourceLabels[entry.key] = entry.value;
      }
      _sourceId = widget.sources.first.id;
      _loading = false;
    });
    await _loadSourceCounts();
  }

  Future<void> _loadSourceCounts() async {
    final sourceId = _sourceId;
    if (sourceId == null) return;
    setState(() => _sourceCountsLoading = true);
    final results = await Future.wait([
      widget.db.getSwitchboards(sourceId),
      widget.db.getSolarInstallations(sourceId),
      widget.db.getDefects(sourceId),
    ]);
    // The selected source may have changed again while this was loading.
    if (!mounted || _sourceId != sourceId) return;
    setState(() {
      _sourceSwitchboardCount = (results[0] as List).length;
      _sourceSolarCount = (results[1] as List).length;
      _sourceDefectCount = (results[2] as List).length;
      _sourceCountsLoading = false;
    });
  }

  String _sourceCountLabel(String label, int count) {
    if (_sourceCountsLoading) return '$label (...)';
    return '$label ($count)';
  }

  bool get _canConfirm =>
      !_busy &&
      _sourceId != null &&
      (_copySwitchboards || _copySolar || _copyDefects);

  String _switchboardLabel(Switchboard s) =>
      s.name.isNotEmpty ? '${s.name} (${s.locationFull})' : s.locationFull;

  String _solarLabel(SolarInstallation s) => s.panelSublocation.isNotEmpty
      ? '${s.locationFull} - ${s.panelSublocation}'
      : s.locationFull;

  String _defectLabel(Defect d) =>
      d.naamCode.isNotEmpty ? '${d.naamCode} (${d.locationFull})' : d.locationFull;

  /// Stap 1 bevestigen: bepaalt duplicaten tussen bron en doel. Als er
  /// duplicaten zijn gaat de dialoog naar stap 2, anders wordt direct
  /// gekopieerd.
  Future<void> _goToDuplicateCheckOrCopy() async {
    if (!_canConfirm) return;
    setState(() => _busy = true);
    final sourceId = _sourceId!;
    final targetId = widget.target.id!;
    final duplicates = <_DuplicateEntry>[];
    try {
      if (_copySwitchboards) {
        final source = await widget.db.getSwitchboards(sourceId);
        final target = await widget.db.getSwitchboards(targetId);
        for (final s in source) {
          final match = target
              .where((t) => s.matchesForDuplicate(t))
              .firstOrNull;
          if (match != null && s.id != null && match.id != null) {
            duplicates.add(_DuplicateEntry(
              category: 'Verdeler',
              sourceId: s.id!,
              targetId: match.id!,
              sourceLabel: _switchboardLabel(s),
              targetLabel: _switchboardLabel(match),
            ));
          }
        }
      }
      if (_copySolar) {
        final source = await widget.db.getSolarInstallations(sourceId);
        final target = await widget.db.getSolarInstallations(targetId);
        for (final s in source) {
          final match = target
              .where((t) => s.matchesForDuplicate(t))
              .firstOrNull;
          if (match != null && s.id != null && match.id != null) {
            duplicates.add(_DuplicateEntry(
              category: 'Zonnestroom-installatie',
              sourceId: s.id!,
              targetId: match.id!,
              sourceLabel: _solarLabel(s),
              targetLabel: _solarLabel(match),
            ));
          }
        }
      }
      if (_copyDefects) {
        final source = await widget.db.getDefects(sourceId);
        final target = await widget.db.getDefects(targetId);
        for (final d in source) {
          final match = target
              .where((t) => d.matchesForDuplicate(t))
              .firstOrNull;
          if (match != null && d.id != null && match.id != null) {
            duplicates.add(_DuplicateEntry(
              category: 'Constatering',
              sourceId: d.id!,
              targetId: match.id!,
              sourceLabel: _defectLabel(d),
              targetLabel: _defectLabel(match),
            ));
          }
        }
      }
      if (!mounted) return;
      if (duplicates.isEmpty) {
        await _executeCopy();
      } else {
        setState(() {
          _duplicates = duplicates;
          _step = 1;
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Controle op duplicaten mislukt: $e')),
      );
    }
  }

  Map<int, DuplicateCopyAction> _decisionsFor(String category) => {
        for (final d in _duplicates.where((d) => d.category == category))
          d.sourceId: d.action,
      };

  Map<int, int> _replaceTargetsFor(String category) => {
        for (final d in _duplicates.where(
            (d) => d.category == category && d.action == DuplicateCopyAction.replace))
          d.sourceId: d.targetId,
      };

  Future<void> _executeCopy() async {
    setState(() => _busy = true);
    final sourceId = _sourceId!;
    final targetId = widget.target.id!;
    try {
      if (_copySwitchboards) {
        await widget.db.copySwitchboardsToInspection(
          sourceId,
          targetId,
          decisions: _decisionsFor('Verdeler'),
          replaceTargetIds: _replaceTargetsFor('Verdeler'),
        );
      }
      if (_copySolar) {
        await widget.db.copySolarInstallationsToInspection(
          sourceId,
          targetId,
          decisions: _decisionsFor('Zonnestroom-installatie'),
          replaceTargetIds: _replaceTargetsFor('Zonnestroom-installatie'),
        );
      }
      if (_copyDefects) {
        await widget.db.copyDefectsToInspection(
          sourceId,
          targetId,
          decisions: _decisionsFor('Constatering'),
          replaceTargetIds: _replaceTargetsFor('Constatering'),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _summaryMessage());
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Overnemen mislukt: $e')),
      );
    }
  }

  String _summaryMessage() {
    if (_duplicates.isEmpty) return 'Onderdelen overgenomen';
    final skipped = _duplicates
        .where((d) => d.action == DuplicateCopyAction.skip)
        .length;
    final marked = _duplicates
        .where((d) => d.action == DuplicateCopyAction.copyMarked)
        .length;
    final replaced = _duplicates
        .where((d) => d.action == DuplicateCopyAction.replace)
        .length;
    final parts = <String>[];
    if (marked > 0) parts.add('$marked gemarkeerd');
    if (replaced > 0) parts.add('$replaced vervangen');
    if (skipped > 0) parts.add('$skipped overgeslagen');
    if (parts.isEmpty) return 'Onderdelen overgenomen';
    return 'Onderdelen overgenomen (${parts.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(640.0, screenSize.width * 0.9);
    final dialogHeight = math.min(680.0, screenSize.height * 0.85);
    return AlertDialog(
      title: Text(_step == 0 ? 'Onderdelen overnemen' : 'Duplicaten gevonden'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: dialogWidth,
              child: _step == 0
                  ? _buildStepOne()
                  : _buildStepTwo(dialogHeight),
            ),
      actions: _step == 0
          ? [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context, null),
                child: const Text('Annuleren'),
              ),
              FilledButton(
                onPressed: _canConfirm ? _goToDuplicateCheckOrCopy : null,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Overnemen'),
              ),
            ]
          : [
              TextButton(
                onPressed:
                    _busy ? null : () => setState(() => _step = 0),
                child: const Text('Terug'),
              ),
              FilledButton(
                onPressed: _busy ? null : _executeCopy,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bevestigen'),
              ),
            ],
    );
  }

  Widget _buildStepOne() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overnemen van:'),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: _sourceId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: widget.sources
              .map((i) => DropdownMenuItem<int>(
                    value: i.id,
                    child: Text(
                      _sourceLabels[i.id] ?? 'Inspectie #${i.id}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: _busy
              ? null
              : (v) {
                  setState(() => _sourceId = v);
                  _loadSourceCounts();
                },
        ),
        const SizedBox(height: 16),
        const Text('Onderdelen:'),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_sourceCountLabel('Verdelers', _sourceSwitchboardCount)),
          subtitle: Text('Doel heeft al: $_targetSwitchboardCount'),
          value: _copySwitchboards,
          onChanged: _busy || _sourceCountsLoading || _sourceSwitchboardCount == 0
              ? null
              : (v) => setState(() => _copySwitchboards = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_sourceCountLabel('Zonnestroom', _sourceSolarCount)),
          subtitle: Text('Doel heeft al: $_targetSolarCount'),
          value: _copySolar,
          onChanged: _busy || _sourceCountsLoading || _sourceSolarCount == 0
              ? null
              : (v) => setState(() => _copySolar = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(_sourceCountLabel('Constateringen', _sourceDefectCount)),
          subtitle: Text('Doel heeft al: $_targetDefectCount'),
          value: _copyDefects,
          onChanged: _busy || _sourceCountsLoading || _sourceDefectCount == 0
              ? null
              : (v) => setState(() => _copyDefects = v ?? false),
        ),
      ],
    );
  }

  Widget _buildStepTwo(double height) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_duplicates.length} record(en) komen mogelijk al voor in de '
            'doelinspectie. Kies een actie voor alle duplicaten, of stel '
            'per record hieronder iets anders in:',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<DuplicateCopyAction>(
                  isExpanded: true,
                  value: _bulkAction,
                  items: _actionLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _bulkAction = v);
                        },
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy || _duplicates.isEmpty
                    ? null
                    : () => setState(() {
                          for (final d in _duplicates) {
                            d.action = _bulkAction;
                          }
                        }),
                child: const Text('Toepassen op alle'),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _duplicates.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entry = _duplicates[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.category}: ${entry.sourceLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Komt al voor als: ${entry.targetLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<DuplicateCopyAction>(
                      isExpanded: true,
                      value: entry.action,
                      items: _actionLabels.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() => entry.action = v);
                            },
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
