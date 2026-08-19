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

// Los entrypoint voor het externe Herstel-webformulier, losstaand van de
// hoofdapp (main.dart). Bouwen met:
//   flutter build web -t lib/main_herstel_web.dart --output=build/herstel_web

import 'package:flutter/material.dart';
import 'screens/herstel_submit_page.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = Uri.base.queryParameters['token'];
  // Firebase wordt bewust *na* runApp geïnitialiseerd (zie _HerstelGate):
  // faalt de initialisatie, dan blijft het formulier gewoon bruikbaar in
  // plaats van dat de gebruiker naar een wit scherm kijkt.
  runApp(HerstelWebApp(token: token));
}

class HerstelWebApp extends StatelessWidget {
  final String? token;

  const HerstelWebApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herstelmelding',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
      ),
      home: token == null || token!.isEmpty
          ? const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Ongeldige link: geen token gevonden. Scan de QR-code opnieuw vanaf de PDF.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : _HerstelGate(token: token!),
    );
  }
}

/// Doet één initialisatiepoging voor Firebase en toont daarna hoe dan ook het
/// formulier. Mislukt de poging, dan krijgt [HerstelSubmitPage] de foutmelding
/// mee en kan de gebruiker het bij "Versturen" opnieuw proberen.
class _HerstelGate extends StatefulWidget {
  final String token;

  const _HerstelGate({required this.token});

  @override
  State<_HerstelGate> createState() => _HerstelGateState();
}

class _HerstelGateState extends State<_HerstelGate> {
  bool _bezig = true;
  String? _fout;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await FirebaseBootstrap.ensureInitialized();
    if (!mounted) return;
    setState(() {
      _bezig = false;
      _fout = ok ? null : FirebaseBootstrap.lastError;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bezig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return HerstelSubmitPage(token: widget.token, firebaseFout: _fout);
  }
}
