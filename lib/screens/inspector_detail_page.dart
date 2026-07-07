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
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../l10n/app_localizations.dart';
import '../models/company_inspector.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class InspectorDetailPage extends StatefulWidget {
  final CompanyInspector? inspector;

  const InspectorDetailPage({super.key, this.inspector});

  @override
  State<InspectorDetailPage> createState() => _InspectorDetailPageState();
}

class _InspectorDetailPageState extends State<InspectorDetailPage> {
  final _db = DatabaseService();
  final _nameCtrl = TextEditingController();
  final _functieCtrl = TextEditingController();

  late final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _savedSignature = '';
  bool get _isNew => widget.inspector == null;

  @override
  void initState() {
    super.initState();
    final insp = widget.inspector;
    if (insp != null) {
      _nameCtrl.text = insp.name;
      _functieCtrl.text = insp.functie;
      _savedSignature = insp.handtekening;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _functieCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSig() async {
    if (_sigCtrl.isEmpty) return;
    final bytes = await _sigCtrl.toPngBytes();
    if (bytes == null) return;
    setState(() {
      _savedSignature = base64Encode(bytes);
      _sigCtrl.clear();
    });
  }

  void _clearSig() => setState(() {
        _savedSignature = '';
        _sigCtrl.clear();
      });

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    // If the pad still has strokes, save them first
    if (_sigCtrl.isNotEmpty) await _saveSig();

    final inspector = CompanyInspector(
      id: widget.inspector?.id,
      name: name,
      functie: _functieCtrl.text.trim(),
      handtekening: _savedSignature,
    );

    if (_isNew) {
      await _db.insertCompanyInspector(inspector);
    } else {
      await _db.updateCompanyInspector(inspector);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.addInspector : l10n.editInspector),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.inspectorDetails),
            CustomTextField(
              label: l10n.name,
              controller: _nameCtrl,
            ),
            CustomTextField(
              label: l10n.signatoryFunction,
              controller: _functieCtrl,
            ),
            const SizedBox(height: 16),
            SectionHeader(title: l10n.signature),
            const SizedBox(height: 4),
            if (_savedSignature.isNotEmpty) ...[
              // Show saved signature
              Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    base64Decode(_savedSignature),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearSig,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.clearSignature),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ] else ...[
              // Signature pad
              Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    Signature(
                      controller: _sigCtrl,
                      backgroundColor: Colors.white,
                    ),
                    ListenableBuilder(
                      listenable: _sigCtrl,
                      builder: (context, _) {
                        if (_sigCtrl.isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Center(
                          child: Text(
                            l10n.signHere,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _sigCtrl.clear(),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Wissen'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saveSig,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.save),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
