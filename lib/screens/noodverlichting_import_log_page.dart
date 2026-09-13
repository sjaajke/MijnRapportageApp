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
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/noodverlichting_installation.dart';
import '../services/database_service.dart';
import '../services/filemaker_service.dart';

/// Runs the FileMaker login + download for noodverlichting and shows a
/// live, line-by-line log of every step (auth, query, per-record mapping,
/// photo fetches) so import problems can be diagnosed from the log itself.
class NoodverlichtingImportLogPage extends StatefulWidget {
  final int inspectionId;

  const NoodverlichtingImportLogPage({super.key, required this.inspectionId});

  @override
  State<NoodverlichtingImportLogPage> createState() =>
      _NoodverlichtingImportLogPageState();
}

class _NoodverlichtingImportLogPageState
    extends State<NoodverlichtingImportLogPage> {
  final _db = DatabaseService();
  final _scrollController = ScrollController();
  final _log = <String>[];
  bool _running = true;
  bool _cancelled = false;
  int _importedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _logLine(String line) {
    if (!mounted) return;
    setState(() => _log.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _run() async {
    final creds = await _showCredentialsDialog();
    if (creds == null) {
      setState(() {
        _cancelled = true;
        _running = false;
      });
      return;
    }

    final service = FileMakerService(
      server: creds.server,
      database: creds.database,
    );

    _logLine('Verbinden met ${creds.server} / ${creds.database}…');

    String token;
    try {
      _logLine('Authenticeren als "${creds.username}"…');
      token = await service.authenticate(creds.username, creds.password);
      _logLine('✓ Ingelogd, token ontvangen');
    } on FileMakerException catch (e) {
      _logLine('✗ Authenticatie mislukt: ${e.message}');
      setState(() => _running = false);
      return;
    } catch (e) {
      _logLine('✗ Verbindingsfout tijdens authenticatie: $e');
      setState(() => _running = false);
      return;
    }

    List<FileMakerRecord> records;
    try {
      _logLine(
        'Componenten zoeken op layout "moduleComponent" '
        '(ID_Eigenaar="${creds.idEigenaar}", UUID_Object="${creds.uuidObject}")…',
      );
      records = await service.findRecords(token, 'moduleComponent', {
        'ID_Eigenaar': creds.idEigenaar,
        'UUID_Object': creds.uuidObject,
      });
      _logLine('${records.length} component(en) gevonden');
    } on FileMakerException catch (e) {
      _logLine('✗ Fout bij ophalen componenten: ${e.message}');
      setState(() => _running = false);
      return;
    } catch (e) {
      _logLine('✗ Verbindingsfout bij ophalen componenten: $e');
      setState(() => _running = false);
      return;
    }

    if (records.isEmpty) {
      _logLine(
        'Geen componenten gevonden voor deze combinatie van '
        'ID_Eigenaar + UUID_Object.',
      );
      await _diagnoseEmptyResult(service, token, creds.idEigenaar);
      _logLine('Import gestopt.');
      setState(() => _running = false);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importeren uit Inspectora'),
        content: Text(
          '${records.length} component(en) gevonden. Dit vervangt de '
          'bestaande noodverlichting in deze inspectie. Doorgaan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importeren'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      _logLine('Import geannuleerd door gebruiker.');
      setState(() => _running = false);
      return;
    }

    await _applyImport(service, token, records);
    if (mounted) setState(() => _running = false);
  }

  /// Runs a broader find on just ID_Eigenaar to help pinpoint why the
  /// combined query found nothing: wrong layout, wrong owner id, or a
  /// UUID_Object value that doesn't match the format actually stored.
  Future<void> _diagnoseEmptyResult(
    FileMakerService service,
    String token,
    String idEigenaar,
  ) async {
    _logLine('Diagnose: componenten zoeken op alleen ID_Eigenaar="$idEigenaar"…');
    List<FileMakerRecord> broad;
    try {
      broad = await service.findRecords(token, 'moduleComponent', {
        'ID_Eigenaar': idEigenaar,
      });
    } on FileMakerException catch (e) {
      _logLine('  ✗ Diagnose mislukt: ${e.message}');
      return;
    } catch (e) {
      _logLine('  ✗ Diagnose mislukt: $e');
      return;
    }

    if (broad.isEmpty) {
      _logLine(
        '  0 componenten gevonden voor ID_Eigenaar="$idEigenaar" op zich. '
        'Controleer of de layoutnaam "moduleComponent", het veld '
        '"ID_Eigenaar" en de waarde "$idEigenaar" kloppen.',
      );
      return;
    }

    _logLine(
      '  ${broad.length} component(en) gevonden voor deze eigenaar zonder '
      'UUID_Object-filter. Voorbeeld UUID_Object-waarden:',
    );
    final samples = broad.take(5);
    for (final r in samples) {
      final uuid = r.field('UUID_Object');
      final naam = r.field('Component_Naam');
      _logLine(
        '    UUID_Object="$uuid"'
        '${naam.isNotEmpty ? '  ($naam)' : ''}',
      );
    }
    _logLine(
      '  Vergelijk dit met de ingevoerde waarde om te zien of het formaat '
      'overeenkomt.',
    );
  }

  String _deriveStatus(FileMakerRecord r) {
    final herstelStatus = r.field('herstel_status').trim().toLowerCase();
    if (herstelStatus.contains('rood')) return 'R';
    if (herstelStatus.contains('oranje')) return 'O';
    if (herstelStatus.contains('groen')) return 'G';
    if (herstelStatus == 'r' || herstelStatus == 'o' || herstelStatus == 'g') {
      return herstelStatus.toUpperCase();
    }
    final ok = r.field('OK').trim().toLowerCase();
    if (ok.isNotEmpty) {
      return (ok == 'ja' || ok == 'true' || ok == '1') ? 'G' : 'R';
    }
    return 'G';
  }

  Future<void> _applyImport(
    FileMakerService service,
    String token,
    List<FileMakerRecord> records,
  ) async {
    _logLine('Bestaande noodverlichting in deze inspectie verwijderen…');
    await _db.deleteAllNoodverlichtingInstallations(widget.inspectionId);
    final docDir = await getApplicationDocumentsDirectory();

    Future<String?> savePhoto(
      Uint8List? bytes,
      String filename,
      String label,
    ) async {
      if (bytes == null) {
        _logLine('    $label: geen foto');
        return null;
      }
      final path = '${docDir.path}/$filename';
      await File(path).writeAsBytes(bytes);
      _logLine('    $label: opgeslagen (${bytes.length} bytes)');
      return path;
    }

    for (var i = 0; i < records.length; i++) {
      final r = records[i];

      final name = r.field('Component_Naam');
      _logLine(
        'Component ${i + 1}/${records.length}: '
        '"${name.isNotEmpty ? name : '(zonder naam)'}"',
      );

      final location = r.field('Component_Naam_Locatie');
      final locationA = r.field('Component_Naam_Locatie_2');
      final locationB = r.field('Component_Naam_Locatie_3');

      final merk = r.field('Component_Waarde 01');
      final lichtbron = r.field('Component_Waarde 02');
      final accuType = r.field('Component_Waarde 03');
      final typeNoodverlichting = r.field('Component_Waarde 04');
      final hoogte = r.field('Component_Waarde 05');
      final functie = r.field('Component_Waarde 06');
      final montage = r.field('Component_Waarde 07');
      final chemieVanDeAccu = r.field('Component_Waarde 08');

      final jaarVanAanleg = r.field('Jaarvanaanleg');
      final inspectieDatum = r.field('Inspectiedatum');
      final inspectieInterval = r.field('Inspectieinterval');
      final typeInstallatie = r.field('Type_installatie').isNotEmpty
          ? r.field('Type_installatie')
          : 'Noodverlichtingsinstallatie';
      final installatieOnderdeel = r.field('locatie_tijdelijk').isNotEmpty
          ? r.field('locatie_tijdelijk')
          : 'Noodverlichting';

      _logLine('  Foto\'s ophalen…');
      final photoAfbeelding = await service.fetchContainerBytes(
        token,
        r.field('Component_Afbeelding'),
      );
      final photoAfbeeldingSaved = await savePhoto(
        photoAfbeelding,
        'noodverlichting_${widget.inspectionId}_${i}_afbeelding.jpg',
        'Component_Afbeelding',
      );
      final photoAfbeeldingDetail = await service.fetchContainerBytes(
        token,
        r.field('Component_Afbeelding_Detail'),
      );
      final photoAfbeeldingDetailSaved = await savePhoto(
        photoAfbeeldingDetail,
        'noodverlichting_${widget.inspectionId}_${i}_afbeelding_detail.jpg',
        'Component_Afbeelding_Detail',
      );
      final photoAccu = await service.fetchContainerBytes(
        token,
        r.field('Afbeelding 1'),
      );
      final photoAccuSaved = await savePhoto(
        photoAccu,
        'noodverlichting_${widget.inspectionId}_${i}_accu.jpg',
        'Afbeelding 1 (accu)',
      );
      final photoStekker = await service.fetchContainerBytes(
        token,
        r.field('Afbeelding 2'),
      );
      final photoStekkerSaved = await savePhoto(
        photoStekker,
        'noodverlichting_${widget.inspectionId}_${i}_stekker.jpg',
        'Afbeelding 2 (stekkeraansluiting)',
      );
      final photoTypePlaatje = await service.fetchContainerBytes(
        token,
        r.field('Afbeelding 3'),
      );
      final photoTypePlaatjeSaved = await savePhoto(
        photoTypePlaatje,
        'noodverlichting_${widget.inspectionId}_${i}_typeplaatje.jpg',
        'Afbeelding 3 (typeplaatje)',
      );
      final photoPictogram = await service.fetchContainerBytes(
        token,
        r.field('Afbeelding 4'),
      );
      final photoPictogramSaved = await savePhoto(
        photoPictogram,
        'noodverlichting_${widget.inspectionId}_${i}_pictogram.jpg',
        'Afbeelding 4 (pictogram)',
      );

      final installationId = await _db.insertNoodverlichtingInstallation(
        NoodverlichtingInstallation(
          inspectionId: widget.inspectionId,
          componentNr: int.tryParse(r.field('ID_Component')),
          name: name,
          nameCode: r.field('ID_Component_Eigen_Naam'),
          location: location,
          locationA: locationA,
          locationB: locationB,
          merk: merk,
          lichtbron: lichtbron,
          accuType: accuType,
          typeNoodverlichting: typeNoodverlichting,
          hoogte: hoogte,
          functie: functie,
          montage: montage,
          chemieVanDeAccu: chemieVanDeAccu,
          typeInstallatie: typeInstallatie,
          installatieOnderdeel: installatieOnderdeel,
          jaarVanAanleg: jaarVanAanleg,
          inspectieDatum: inspectieDatum,
          inspectieInterval: inspectieInterval,
          photoAfbeeldingPath: photoAfbeeldingSaved,
          photoAfbeeldingDetailPath: photoAfbeeldingDetailSaved,
          photoAccuPath: photoAccuSaved,
          photoStekkerAansluitingPath: photoStekkerSaved,
          photoTypePlaatjePath: photoTypePlaatjeSaved,
          photoGebruiktPictogramPath: photoPictogramSaved,
          status: _deriveStatus(r),
          sortOrder: i,
        ),
      );
      _logLine('  ✓ Opgeslagen als installatie #$installationId');
      _importedCount++;
    }

    _logLine('Klaar: $_importedCount noodverlichting(en) geïmporteerd.');
  }

  static const _prefDatabase = 'fm_database';
  static const _prefEigenaar = 'fm_id_eigenaar';
  static const _prefUuidObject = 'fm_uuid_object';
  static const _prefUsername = 'fm_username';

  Future<void> _saveCredentialPrefs({
    required String database,
    required String idEigenaar,
    required String uuidObject,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDatabase, database);
    await prefs.setString(_prefEigenaar, idEigenaar);
    await prefs.setString(_prefUuidObject, uuidObject);
    await prefs.setString(_prefUsername, username);
  }

  Future<_NoodverlichtingFmCredentials?> _showCredentialsDialog() async {
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
    final uuidObjectCtrl = TextEditingController(
      text: prefs.getString(_prefUuidObject) ?? '',
    );
    final userCtrl = TextEditingController(
      text: prefs.getString(_prefUsername) ?? '',
    );
    final passCtrl = TextEditingController();
    bool obscure = true;

    return showDialog<_NoodverlichtingFmCredentials>(
      context: context,
      barrierDismissible: false,
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
                  controller: uuidObjectCtrl,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'UUID_Object',
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
                    uuidObjectCtrl.text.trim().isEmpty ||
                    userCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  return;
                }
                final creds = _NoodverlichtingFmCredentials(
                  server: serverCtrl.text.trim(),
                  database: dbCtrl.text.trim(),
                  idEigenaar: eigenaarCtrl.text.trim(),
                  uuidObject: uuidObjectCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  password: passCtrl.text,
                );
                Navigator.pop(ctx, creds);
                _saveCredentialPrefs(
                  database: creds.database,
                  idEigenaar: creds.idEigenaar,
                  uuidObject: creds.uuidObject,
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

  void _copyLog() {
    Clipboard.setData(ClipboardData(text: _log.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log gekopieerd'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importlog noodverlichting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Log kopiëren',
            onPressed: _log.isEmpty ? null : _copyLog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_running)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: _log.isEmpty && _cancelled
                  ? const Center(
                      child: Text(
                        'Import geannuleerd.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: SelectableText(
                        _log.join('\n'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _running
                      ? null
                      : () => Navigator.pop(context, _importedCount > 0),
                  child: Text(_running ? 'Bezig…' : 'Sluiten'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoodverlichtingFmCredentials {
  final String server;
  final String database;
  final String idEigenaar;
  final String uuidObject;
  final String username;
  final String password;

  const _NoodverlichtingFmCredentials({
    required this.server,
    required this.database,
    required this.idEigenaar,
    required this.uuidObject,
    required this.username,
    required this.password,
  });
}
