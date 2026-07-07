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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/defect.dart';
import '../models/inspection_detail.dart';
import '../models/switchboard.dart';
import '../models/title_page.dart' as model;
import '../services/database_service.dart';
import '../services/filemaker_service.dart';
import '../widgets/section_header.dart';

class DownloadPage extends StatefulWidget {
  final int inspectionId;

  const DownloadPage({super.key, required this.inspectionId});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _db = DatabaseService();
  final _downloadController = TextEditingController();
  var _containerLog = <String>[];

  @override
  void initState() {
    super.initState();
    _loadDownloadText();
  }

  Future<File> _downloadFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/download_${widget.inspectionId}.json');
  }

  Future<void> _loadDownloadText() async {
    try {
      final file = await _downloadFile();
      if (await file.exists()) {
        final text = await file.readAsString();
        if (mounted) _downloadController.text = text;
      }
    } catch (_) {}
  }

  Future<void> _saveDownloadText(String text) async {
    try {
      final file = await _downloadFile();
      await file.writeAsString(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _downloadController.dispose();
    super.dispose();
  }

  // ── FileMaker import ────────────────────────────────────────────────────

  Future<void> _importFromFileMaker() async {
    final creds = await _showCredentialsDialog();
    if (creds == null) return;

    final service = FileMakerService(
      server: creds.server,
      database: creds.database,
    );
    if (!mounted) return;

    String token;
    try {
      token = await _withProgress(
        'Authenticeren…',
        () => service.authenticate(creds.username, creds.password),
      );
    } on FileMakerException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      _showError('Verbindingsfout: $e');
      return;
    }

    List<FileMakerRecord> rapporten;
    try {
      rapporten = await _withProgress(
        'Rapporten ophalen…',
        () => service.findByEigenaar(
          token,
          'moduleRapport',
          creds.idEigenaar,
          idRapport: creds.idRapport,
        ),
      );
    } on FileMakerException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      _showError('Verbindingsfout: $e');
      return;
    }

    if (!mounted) return;
    if (rapporten.isEmpty) {
      _showError(
        'Geen rapporten gevonden voor ID_Eigenaar "${creds.idEigenaar}".',
      );
      return;
    }

    final chosen = await _showRapportPicker(rapporten);
    if (chosen == null || !mounted) return;

    FileMakerImportResult result;
    try {
      result = await _withProgress(
        'Gegevens en foto\'s ophalen…',
        () => service.fetchImportData(
          token,
          chosen,
          useContainerApi: creds.useContainerApi,
        ),
      );
    } on FileMakerException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      _showError('Verbindingsfout: $e');
      return;
    }

    if (!mounted) return;
    await _applyImport(result);
    if (mounted) setState(() => _containerLog = result.containerLog);
  }

  Future<void> _applyImport(FileMakerImportResult r) async {
    // Save Objectfoto to disk if present
    String? fotoPath;
    if (r.objectFotoBytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      fotoPath = '${dir.path}/inspectora_objectfoto_${widget.inspectionId}.jpg';
      await File(fotoPath).writeAsBytes(r.objectFotoBytes!);
    }

    // Build combined JSON and put it in the Download text field
    Map<String, dynamic> recJson(FileMakerRecord? rec) => rec == null
        ? {}
        : {'recordId': rec.recordId, 'fieldData': rec.fieldData};

    final combined = <String, dynamic>{
      'moduleRapport': recJson(r.rapport),
      'moduleKlant': recJson(r.klant),
      'moduleObject': recJson(r.object),
      'modulePlan': recJson(r.plan),
      'moduleConstatering': r.constateringen
          .map((c) => {'recordId': c.recordId, 'fieldData': c.fieldData})
          .toList(),
      'moduleSVI': r.sviRecords
          .map((s) => {'recordId': s.recordId, 'fieldData': s.fieldData})
          .toList(),
      if (fotoPath != null)
        'Objectfoto': {
          'opgeslagen': fotoPath,
          'bytes': r.objectFotoBytes!.length,
        },
    };

    final downloadText = const JsonEncoder.withIndent('  ').convert(combined);
    setState(() => _downloadController.text = downloadText);
    await _saveDownloadText(downloadText);

    // Also map known fields and save to InspectionDetail
    final p = r.plan;
    String? pick(List<String?> c) {
      for (final v in c) {
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final scopeDesc = pick([
      p?.field('Omvang'),
      p?.field('omvang_beschrijving'),
      p?.field('ScopeDescription'),
    ]);
    final notInspected = pick([
      p?.field('NietGeïnspecteerd'),
      p?.field('niet_geïnspecteerd'),
    ]);
    final notInspReason = pick([
      p?.field('RedenNietGeïnspecteerd'),
      p?.field('reden_niet_geinspecteerd'),
    ]);
    final inspReason = pick([
      p?.field('AanleidingInspectie'),
      p?.field('aanleiding_inspectie'),
      p?.field('Aanleiding'),
    ]);
    final performedAccTo = pick([
      p?.field('UitgevoerdVolgens'),
      p?.field('uitgevoerd_volgens'),
      p?.field('Uitgevoerd_Norm'),
    ]);
    final testedAgainst = pick([
      p?.field('GetoetsdTegen'),
      p?.field('getoetst_tegen'),
      p?.field('Norm'),
    ]);
    final methodeVisuele = pick([
      p?.field('MethodeVisueleInspectie'),
      p?.field('methode_visuele_inspectie'),
    ]);
    final methodeMetingen = pick([
      p?.field('MethodeMetingen'),
      p?.field('methode_metingen'),
    ]);
    final methodeAanvullend = pick([
      p?.field('MethodeAanvullend'),
      p?.field('methode_aanvullend'),
    ]);
    final methodeCriteria = pick([
      p?.field('MethodeCriteria'),
      p?.field('methode_criteria'),
    ]);
    final inleiding = pick([
      p?.field('Inleiding'),
      p?.field('inleiding'),
      p?.field('InleidingToelichting'),
    ]);

    var detail = await _db.getInspectionDetail(widget.inspectionId);
    if (detail == null) {
      await _db.insertInspectionDetail(
        InspectionDetail(inspectionId: widget.inspectionId),
      );
      detail = await _db.getInspectionDetail(widget.inspectionId);
    }
    if (detail != null) {
      var updated = detail;
      if (scopeDesc != null) {
        updated = updated.copyWith(scopeDescription: scopeDesc);
      }
      if (notInspected != null) {
        updated = updated.copyWith(notInspectedParts: notInspected);
      }
      if (notInspReason != null) {
        updated = updated.copyWith(notInspectedReason: notInspReason);
      }
      if (inspReason != null) {
        updated = updated.copyWith(inspectionReason: inspReason);
      }
      if (performedAccTo != null) {
        updated = updated.copyWith(performedAccordingTo: performedAccTo);
      }
      if (testedAgainst != null) {
        updated = updated.copyWith(testedAgainst: testedAgainst);
      }
      if (methodeVisuele != null) {
        updated = updated.copyWith(methodeVisueleInspectie: methodeVisuele);
      }
      if (methodeMetingen != null) {
        updated = updated.copyWith(methodeMetingen: methodeMetingen);
      }
      if (methodeAanvullend != null) {
        updated = updated.copyWith(
          methodeAanvullendOnderzoek: methodeAanvullend,
        );
      }
      if (methodeCriteria != null) {
        updated = updated.copyWith(methodeCriteria: methodeCriteria);
      }
      if (inleiding != null) {
        updated = updated.copyWith(inleidingToelichting: inleiding);
      }
      await _db.updateInspectionDetail(updated);
    }

    final docDir = await getApplicationDocumentsDirectory();

    Future<String?> savePhotoBytes(List<int>? bytes, String filename) async {
      if (bytes == null) return null;
      final path = '${docDir.path}/$filename';
      await File(path).writeAsBytes(bytes);
      return path;
    }

    // Import constateringen as defects (replaces existing defects)
    if (r.constateringen.isNotEmpty) {
      await _db.deleteAllDefects(widget.inspectionId);

      for (int i = 0; i < r.constateringen.length; i++) {
        final c = r.constateringen[i];

        // Location: concatenate the three location parts, skip empty
        final locParts = [
          c.field('Locatie_Gebouwdeel'),
          c.field('Locatie_Verdieping'),
          c.field('Locatie_Ruimte'),
        ].where((v) => v.isNotEmpty).toList();
        final location = locParts.join(' ');

        final descParts = [
          c.field('Afwijking'),
          c.field('afwijkingen'),
        ].where((v) => v.isNotEmpty).toList();
        final description = descParts.join('\n');

        final photo1Path = await savePhotoBytes(
          r.constateringFotos[i],
          'constatering_${widget.inspectionId}_${i}_1.jpg',
        );
        final photo2Path = await savePhotoBytes(
          r.constateringFotoDetails[i],
          'constatering_${widget.inspectionId}_${i}_2.jpg',
        );

        final kwalificatie = c.field('kwalificatie');
        final classification = Defect.classifications.contains(kwalificatie)
            ? kwalificatie
            : 'Gr';

        await _db.insertDefect(
          Defect(
            inspectionId: widget.inspectionId,
            description: description,
            location: location,
            classification: classification,
            photo1Path: photo1Path,
            photo2Path: photo2Path,
          ),
        );
      }
    }

    // Import SVI records as switchboards (replaces existing)
    if (r.sviRecords.isNotEmpty) {
      await _db.deleteAllSwitchboards(widget.inspectionId);

      int? parseNum(String s) {
        if (s.isEmpty) return null;
        return int.tryParse(s) ?? double.tryParse(s)?.toInt();
      }

      for (int i = 0; i < r.sviRecords.length; i++) {
        final s = r.sviRecords[i];

        // Location: concatenate the three location parts, skip empty
        final locParts = [
          s.field('Locatie_Gebouwdeel'),
          s.field('Locatie_Verdieping'),
          s.field('Locatie_Ruimte'),
        ].where((v) => v.isNotEmpty).toList();

        // Protection: combine karakteristiek + stroom (e.g. "B 40")
        final protKar = s.field(
          'verdelerVoeding_Voorbeveiliging_Karakteristiek',
        );
        final protStroom = s.field('verdelerVoeding_Voorbeveiliging_stroom');
        final prot = [protKar, protStroom].where((v) => v.isNotEmpty).join(' ');

        // Visual inspection: defaults first, FM values override
        final vi = <String, String>{
          for (final item in Switchboard.visualInspectionItems) item: 'N.v.t.',
          if (s.field('Visuele inspectie1').isNotEmpty)
            'Verdeler eenduidig herkenbaar': s.field('Visuele inspectie1'),
          if (s.field('Visuele inspectie2').isNotEmpty)
            'Installatieschema actueel': s.field('Visuele inspectie2'),
          if (s.field('Visuele inspectie3').isNotEmpty)
            'Codering; aansluitklemmen, bedrading': s.field(
              'Visuele inspectie3',
            ),
          if (s.field('Visuele inspectie4').isNotEmpty)
            'Verdeler aanraakveilig': s.field('Visuele inspectie4'),
          if (s.field('Visuele inspectie5').isNotEmpty)
            'Overeenstemming met de omgeving': s.field('Visuele inspectie5'),
          if (s.field('Visuele inspectie6').isNotEmpty)
            'Aansluitingen zijn correct uitgevoerd': s.field(
              'Visuele inspectie6',
            ),
          if (s.field('Visuele inspectie7').isNotEmpty)
            'Veilige scheiding van stroomketens': s.field('Visuele inspectie7'),
          if (s.field('Visuele inspectie8').isNotEmpty)
            'Vrij van stof, vuil en water': s.field('Visuele inspectie8'),
          if (s.field('Visuele inspectie9').isNotEmpty)
            'Verdeler toegankelijk': s.field('Visuele inspectie9'),
          if (s.field('Visuele inspectie10').isNotEmpty)
            'Beveiligingstoestellen aanwezig zijn': s.field(
              'Visuele inspectie10',
            ),
          if (s.field('Visuele inspectie11').isNotEmpty)
            'Beveiligingstoestellen juist gekozen zijn': s.field(
              'Visuele inspectie11',
            ),
        };

        // Measurements: defaults first, FM values override
        final meas = <String, String>{
          for (final item in Switchboard.measurementItems) item: 'N.v.t.',
          if (s.field('Metingen_1').isNotEmpty)
            'Impedantie foutstroomketen': s.field('Metingen_1'),
          if (s.field('Metingen_2').isNotEmpty)
            'Isolatieweerstand': s.field('Metingen_2'),
          if (s.field('Metingen_3').isNotEmpty)
            'Aardlekbeveiliging': s.field('Metingen_3'),
          if (s.field('Metingen_4').isNotEmpty)
            'Thermografie': s.field('Metingen_4'),
        };

        final photo1Path = await savePhotoBytes(
          r.sviFotos[i],
          'verdeler_${widget.inspectionId}_${i}_1.jpg',
        );
        final photo2Path = await savePhotoBytes(
          r.sviFotoDetails[i],
          'verdeler_${widget.inspectionId}_${i}_2.jpg',
        );

        await _db.insertSwitchboard(
          Switchboard(
            inspectionId: widget.inspectionId,
            name: s.field('verdelerNaam'),
            location: locParts.join(' '),
            system: s.field('Stelsel').isNotEmpty ? s.field('Stelsel') : 'TN-S',
            mainSwitchCurrent: parseNum(
              s.field('verdelerHoofdschakelaar 1_Vermogen'),
            ),
            mainSwitchPoles: parseNum(s.field('1_aantal polen')),
            cableCrossSection: parseNum(
              s.field('verdelerVoeding_Leiding_doorsnede'),
            ),
            protection: prot.isNotEmpty ? prot : 'B 40 A',
            photo1Path: photo1Path,
            photo2Path: photo2Path,
            visualInspection: vi,
            measurements: meas,
          ),
        );
      }
    }

    // Update title page inspection date
    final datum = r.rapport.field('Datum');
    if (datum.isNotEmpty) {
      var titlePage = await _db.getTitlePage(widget.inspectionId);
      if (titlePage == null) {
        await _db.insertTitlePage(
          model.TitlePage(inspectionId: widget.inspectionId),
        );
        titlePage = await _db.getTitlePage(widget.inspectionId);
      }
      if (titlePage != null) {
        await _db.updateTitlePage(titlePage.copyWith(inspectionDate: datum));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gegevens gedownload en opgeslagen')),
      );
    }
  }

  Future<T> _withProgress<T>(String message, Future<T> Function() work) async {
    if (!mounted) return work();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
    try {
      return await work();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importfout'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gekopieerd'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Kopiëren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static const _prefDatabase = 'fm_database';
  static const _prefEigenaar = 'fm_id_eigenaar';
  static const _prefRapport = 'fm_id_rapport';
  static const _prefUsername = 'fm_username';

  Future<void> _saveCredentialPrefs({
    required String database,
    required String idEigenaar,
    required String idRapport,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDatabase, database);
    await prefs.setString(_prefEigenaar, idEigenaar);
    await prefs.setString(_prefRapport, idRapport);
    await prefs.setString(_prefUsername, username);
  }

  Future<_FmCredentials?> _showCredentialsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return null;

    final serverCtrl = TextEditingController(
      text: FileMakerService.defaultServer,
    );
    final dbCtrl = TextEditingController(
      text: prefs.getString(_prefDatabase) ?? FileMakerService.defaultDatabase,
    );
    final eigenaarCtrl = TextEditingController(
      text: prefs.getString(_prefEigenaar) ?? '',
    );
    final rapportCtrl = TextEditingController(
      text: prefs.getString(_prefRapport) ?? '',
    );
    final userCtrl = TextEditingController(
      text: prefs.getString(_prefUsername) ?? '',
    );
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool useContainerApi = true;

    return showDialog<_FmCredentials>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Importeren uit Inspectora'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serverCtrl,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Server',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dbCtrl,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Database',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eigenaarCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID_Eigenaar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rapportCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID_Rapport',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: userCtrl,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Gebruikersnaam',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Wachtwoord',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Foto's via container API"),
                  subtitle: Text(
                    useContainerApi
                        ? 'Container veld (hoge resolutie)'
                        : 'Base64 tekstveld',
                  ),
                  value: useContainerApi,
                  onChanged: (v) => setS(() => useContainerApi = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                if (eigenaarCtrl.text.trim().isEmpty ||
                    userCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  return;
                }
                final creds = _FmCredentials(
                  server: serverCtrl.text.trim(),
                  database: dbCtrl.text.trim(),
                  idEigenaar: eigenaarCtrl.text.trim(),
                  idRapport: rapportCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  password: passCtrl.text,
                  useContainerApi: useContainerApi,
                );
                Navigator.pop(ctx, creds);
                _saveCredentialPrefs(
                  database: creds.database,
                  idEigenaar: creds.idEigenaar,
                  idRapport: creds.idRapport,
                  username: creds.username,
                );
              },
              child: const Text('Verbinden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<FileMakerRecord?> _showRapportPicker(List<FileMakerRecord> rapporten) {
    return showDialog<FileMakerRecord>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rapport selecteren (${rapporten.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: rapporten.length,
            itemBuilder: (_, i) {
              final r = rapporten[i];
              final datum = r.field('Datum');
              final id = r.field('ID_rapport');
              final maker = r.field('Gemaakt door_Naam');
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(datum.isNotEmpty ? datum : 'Rapport #$id'),
                subtitle: Text(
                  [
                    if (id.isNotEmpty) 'ID: $id',
                    if (maker.isNotEmpty) maker,
                  ].join('  •  '),
                ),
                onTap: () => Navigator.pop(ctx, r),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Importeren uit Inspectora',
            onPressed: _importFromFileMaker,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Download'),
            TextField(
              controller: _downloadController,
              maxLines: null,
              readOnly: false,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Download',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_containerLog.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Foto container log',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _containerLog.join('\n'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FmCredentials {
  final String server;
  final String database;
  final String idEigenaar;
  final String idRapport;
  final String username;
  final String password;
  final bool useContainerApi;

  const _FmCredentials({
    required this.server,
    required this.database,
    required this.idEigenaar,
    required this.idRapport,
    required this.username,
    required this.password,
    required this.useContainerApi,
  });
}
