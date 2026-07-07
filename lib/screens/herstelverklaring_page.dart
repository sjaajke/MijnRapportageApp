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
import '../widgets/custom_text_field.dart';
import '../widgets/section_header.dart';

class HerstelverklaringPage extends StatefulWidget {
  final int inspectionId;

  const HerstelverklaringPage({super.key, required this.inspectionId});

  @override
  State<HerstelverklaringPage> createState() => _HerstelverklaringPageState();
}

class _HerstelverklaringPageState extends State<HerstelverklaringPage> {
  final _omschrijving = TextEditingController();
  final _uitgevoerdDoor = TextEditingController();
  final _datumHerstel = TextEditingController();
  final _verklaring = TextEditingController();
  final _opmerking = TextEditingController();

  @override
  void dispose() {
    _omschrijving.dispose();
    _uitgevoerdDoor.dispose();
    _datumHerstel.dispose();
    _verklaring.dispose();
    _opmerking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Herstelverklaring')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Herstelwerkzaamheden'),
            CustomTextField(
              label: 'Omschrijving herstelwerkzaamheden',
              controller: _omschrijving,
              maxLines: 5,
            ),
            CustomTextField(
              label: 'Uitgevoerd door',
              controller: _uitgevoerdDoor,
            ),
            CustomTextField(
              label: 'Datum herstel',
              controller: _datumHerstel,
              hint: 'dd-mm-jjjj',
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Verklaring'),
            CustomTextField(
              label: 'Verklaring',
              controller: _verklaring,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Opmerkingen'),
            CustomTextField(
              label: 'Opmerkingen',
              controller: _opmerking,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
