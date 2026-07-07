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
import 'package:http/http.dart' as http;
import '../models/herstel.dart';
import 'database_service.dart';
import 'photo_service.dart';

/// Thrown when no herstel-submission exists yet for a given token — this is
/// the expected/common outcome of pressing "Ophalen" before the external
/// person has filled in the web form, not an error condition.
class HerstelSyncNotFoundException implements Exception {
  final String message;
  HerstelSyncNotFoundException(this.message);
}

/// Thrown when the Firestore/Storage REST endpoints could not be reached or
/// returned an unexpected error.
class HerstelSyncException implements Exception {
  final String message;
  HerstelSyncException(this.message);
}

enum HerstelPushOutcome { pushed, alreadySubmitted, failed }

class HerstelPushResult {
  final HerstelPushOutcome outcome;
  final String? error;
  HerstelPushResult(this.outcome, {this.error});
}

class HerstelSubmission {
  final bool isHersteld;
  final String naam;
  final String datum;
  final String toelichting;
  final String? photo1Path;
  final String? photo2Path;

  HerstelSubmission({
    required this.isHersteld,
    required this.naam,
    required this.datum,
    required this.toelichting,
    this.photo1Path,
    this.photo2Path,
  });
}

/// Fetches an externally submitted herstelmelding (filled in via the QR-code
/// web form) using Firestore's and Storage's public REST APIs directly —
/// deliberately without the `cloud_firestore`/`firebase_core` SDKs, so the
/// main app stays free of the Firebase SDK's weight and platform constraints.
/// Only a single, on-demand read is needed (triggered by the "Ophalen"
/// button), so a full SDK is unnecessary.
class HerstelSyncService {
  static const _timeout = Duration(seconds: 15);

  final _db = DatabaseService();

  Future<HerstelSubmission> fetch(String token, {int? inspectionId}) async {
    final companyDetails = await _db.getCompanyDetails();
    final projectId = companyDetails?.herstelFirebaseProjectId;
    final storageBucket = companyDetails?.herstelFirebaseStorageBucket;
    if (projectId == null || projectId.isEmpty) {
      throw HerstelSyncException(
        'Firebase-projectgegevens ontbreken. Vul ze in op de pagina Bedrijfsgegevens.',
      );
    }

    final doc = await _fetchDocument(projectId, token);
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final photo1Path = await _downloadPhotoIfPresent(
      storageBucket,
      token,
      'photo1.jpg',
      inspectionId,
    );
    final photo2Path = await _downloadPhotoIfPresent(
      storageBucket,
      token,
      'photo2.jpg',
      inspectionId,
    );

    return HerstelSubmission(
      isHersteld: _boolField(fields, 'isHersteld'),
      naam: _stringField(fields, 'naam') ?? '',
      datum: _stringField(fields, 'datum') ?? '',
      toelichting: _stringField(fields, 'toelichting') ?? '',
      photo1Path: photo1Path,
      photo2Path: photo2Path,
    );
  }

  /// Pushes a locally filled-in herstelmelding (e.g. one the inspector filled
  /// in directly in the app, without an external QR submission) up to
  /// Firestore/Storage under [token]. Creation is deliberately one-shot, same
  /// as the web form: if a document already exists for this token — meaning
  /// an external submission got there first — that submission is treated as
  /// authoritative and this push is skipped rather than overwriting it.
  Future<HerstelPushResult> push(String token, Herstel herstel) async {
    final companyDetails = await _db.getCompanyDetails();
    final projectId = companyDetails?.herstelFirebaseProjectId;
    if (projectId == null || projectId.isEmpty) {
      return HerstelPushResult(
        HerstelPushOutcome.failed,
        error: 'Firebase-projectgegevens ontbreken. Vul ze in op de pagina Bedrijfsgegevens.',
      );
    }

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/herstel_submissions?documentId=$token',
    );
    final body = jsonEncode({
      'fields': {
        'isHersteld': {'booleanValue': herstel.isHersteld},
        'naam': {'stringValue': herstel.naam},
        'datum': {'stringValue': herstel.datum},
        'toelichting': {'stringValue': herstel.toelichting},
      },
    });
    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);
    } catch (e) {
      return HerstelPushResult(
        HerstelPushOutcome.failed,
        error: 'Kon geen verbinding maken met de herstel-service: $e',
      );
    }
    if (response.statusCode == 403) {
      return HerstelPushResult(HerstelPushOutcome.alreadySubmitted);
    }
    if (response.statusCode != 200) {
      return HerstelPushResult(
        HerstelPushOutcome.failed,
        error: 'De herstel-service gaf een onverwachte fout (${response.statusCode}).',
      );
    }

    final storageBucket = companyDetails?.herstelFirebaseStorageBucket;
    if (storageBucket != null && storageBucket.isNotEmpty) {
      await _uploadPhotoIfPresent(storageBucket, token, 'photo1.jpg', herstel.photo1Path);
      await _uploadPhotoIfPresent(storageBucket, token, 'photo2.jpg', herstel.photo2Path);
    }

    return HerstelPushResult(HerstelPushOutcome.pushed);
  }

  Future<void> _uploadPhotoIfPresent(
    String storageBucket,
    String token,
    String fileName,
    String? localPath,
  ) async {
    if (localPath == null || localPath.isEmpty) return;
    final file = File(localPath);
    if (!await file.exists()) return;
    final uri = Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/$storageBucket/o',
      {'name': 'herstel_photos/$token/$fileName'},
    );
    try {
      await http
          .post(
            uri,
            headers: {'Content-Type': 'image/jpeg'},
            body: await file.readAsBytes(),
          )
          .timeout(_timeout);
    } catch (_) {
      // Best-effort: een mislukte foto-upload mag de rest van de bulk-push
      // niet blokkeren; de tekstvelden staan dan al wel in Firestore.
    }
  }

  Future<Map<String, dynamic>> _fetchDocument(
    String projectId,
    String token,
  ) async {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/herstel_submissions/$token',
    );
    late http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (e) {
      throw HerstelSyncException(
        'Kon geen verbinding maken met de herstel-service: $e',
      );
    }
    if (response.statusCode == 404) {
      throw HerstelSyncNotFoundException(
        'Nog geen inzending gevonden voor dit gebrek.',
      );
    }
    if (response.statusCode != 200) {
      throw HerstelSyncException(
        'De herstel-service gaf een onverwachte fout (${response.statusCode}).',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String?> _downloadPhotoIfPresent(
    String? storageBucket,
    String token,
    String fileName,
    int? inspectionId,
  ) async {
    if (storageBucket == null || storageBucket.isEmpty) return null;
    final objectPath = Uri.encodeComponent('herstel_photos/$token/$fileName');
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/$objectPath?alt=media',
    );
    http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } catch (e) {
      throw HerstelSyncException('Kon foto niet downloaden: $e');
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw HerstelSyncException(
        'Kon foto niet downloaden (${response.statusCode}).',
      );
    }
    return PhotoService().saveBytesAsPhoto(response.bodyBytes, inspectionId);
  }

  String? _stringField(Map<String, dynamic> fields, String key) {
    final value = fields[key] as Map<String, dynamic>?;
    return value?['stringValue'] as String?;
  }

  bool _boolField(Map<String, dynamic> fields, String key) {
    final value = fields[key] as Map<String, dynamic>?;
    return value?['booleanValue'] as bool? ?? false;
  }
}
