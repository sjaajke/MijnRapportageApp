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

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../services/firebase_bootstrap.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';
import '../widgets/web_photo_picker.dart';

/// Webformulier waarmee een externe reparateur (zonder de app) — via de
/// QR-code op de PDF — de herstelstatus van één gebrek invult. Schrijft
/// rechtstreeks naar Firestore/Storage; er is bewust geen autosave zoals in
/// de app, want de Firestore-rules staan maar één (create-once) schrijfactie
/// per token toe.
class HerstelSubmitPage extends StatefulWidget {
  final String token;

  /// Foutmelding van een mislukte Firebase-initialisatie. Is deze gevuld, dan
  /// is het formulier gewoon in te vullen, maar wordt er bij "Versturen" eerst
  /// opnieuw geprobeerd verbinding te maken.
  final String? firebaseFout;

  const HerstelSubmitPage({
    super.key,
    required this.token,
    this.firebaseFout,
  });

  @override
  State<HerstelSubmitPage> createState() => _HerstelSubmitPageState();
}

class _HerstelSubmitPageState extends State<HerstelSubmitPage> {
  final _naamController = TextEditingController();
  final _datumController = TextEditingController();
  final _toelichtingController = TextEditingController();

  bool _isHersteld = false;
  Uint8List? _photo1;
  Uint8List? _photo2;
  bool _versturen = false;
  bool _verstuurd = false;
  String? _foutmelding;
  late bool _firebaseOffline = widget.firebaseFout != null;

  Future<void> _pickDatum() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _datumController.text =
        '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
  }

  Future<void> _versturenAction() async {
    setState(() {
      _versturen = true;
      _foutmelding = null;
    });

    // Lukte de initialisatie bij het opstarten niet, probeer het hier opnieuw:
    // de verbinding kan intussen hersteld zijn.
    final firebaseOk = await FirebaseBootstrap.ensureInitialized();
    if (!mounted) return;
    if (!firebaseOk) {
      setState(() {
        _versturen = false;
        _firebaseOffline = true;
        _foutmelding =
            'Geen verbinding met de herstel-service. Controleer je internetverbinding '
            'en druk opnieuw op Versturen — je ingevulde gegevens blijven staan.';
      });
      return;
    }
    setState(() => _firebaseOffline = false);

    try {
      final ref = FirebaseStorage.instance.ref('herstel_photos/${widget.token}');
      String? photo1Path;
      String? photo2Path;
      if (_photo1 != null) {
        await ref.child('photo1.jpg').putData(
              _photo1!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
        photo1Path = 'herstel_photos/${widget.token}/photo1.jpg';
      }
      if (_photo2 != null) {
        await ref.child('photo2.jpg').putData(
              _photo2!,
              SettableMetadata(contentType: 'image/jpeg'),
            );
        photo2Path = 'herstel_photos/${widget.token}/photo2.jpg';
      }

      await FirebaseFirestore.instance
          .collection('herstel_submissions')
          .doc(widget.token)
          .set({
        'isHersteld': _isHersteld,
        'naam': _naamController.text,
        'datum': _datumController.text,
        'toelichting': _toelichtingController.text,
        'photo1Path': ?photo1Path,
        'photo2Path': ?photo2Path,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _versturen = false;
        _verstuurd = true;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _versturen = false;
        _foutmelding = e.code == 'permission-denied'
            ? 'Versturen is niet gelukt. Mogelijk is dit gebrek al eerder gemeld via deze link.'
            : 'Versturen is niet gelukt (${e.code}). Controleer je internetverbinding '
                  'en probeer het opnieuw — je ingevulde gegevens blijven staan.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _versturen = false;
        _foutmelding =
            'Versturen is niet gelukt. Controleer je internetverbinding en probeer '
            'het opnieuw — je ingevulde gegevens blijven staan. ($e)';
      });
    }
  }

  @override
  void dispose() {
    _naamController.dispose();
    _datumController.dispose();
    _toelichtingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_verstuurd) {
      return Scaffold(
        appBar: AppBar(title: const Text('Herstelmelding')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text(
                  'Bedankt! De herstelmelding is verstuurd.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Herstelmelding invullen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_firebaseOffline)
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Geen verbinding met de herstel-service. Je kunt het formulier '
                          'gewoon invullen; bij "Versturen" wordt opnieuw geprobeerd '
                          'verbinding te maken.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SectionHeader(title: 'Status'),
            Card(
              color: _isHersteld ? Colors.green.shade50 : Colors.orange.shade50,
              child: SwitchListTile(
                title: Text(_isHersteld ? 'Gebrek hersteld' : 'Nog niet hersteld'),
                value: _isHersteld,
                onChanged: (v) => setState(() => _isHersteld = v),
              ),
            ),
            const SectionHeader(title: 'Herstelgegevens'),
            CustomTextField(label: 'Naam uitvoerder', controller: _naamController),
            CustomTextField(
              label: 'Datum herstel',
              controller: _datumController,
              hint: 'dd-mm-jjjj',
              readOnly: true,
              onTap: _pickDatum,
            ),
            const SectionHeader(title: "Foto's"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WebPhotoPicker(
                    label: 'Foto 1',
                    bytes: _photo1,
                    onPhotoSelected: (b) => setState(() => _photo1 = b),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WebPhotoPicker(
                    label: 'Foto 2',
                    bytes: _photo2,
                    onPhotoSelected: (b) => setState(() => _photo2 = b),
                  ),
                ),
              ],
            ),
            const SectionHeader(title: 'Toelichting'),
            CustomTextField(
              label: 'Toelichting',
              controller: _toelichtingController,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            if (_foutmelding != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_foutmelding!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _versturen ? null : _versturenAction,
              child: _versturen
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Versturen'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
