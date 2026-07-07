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
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class FileMakerRecord {
  final String recordId;
  final Map<String, dynamic> fieldData;

  FileMakerRecord({required this.recordId, required this.fieldData});

  String field(String name) {
    final v = fieldData[name];
    if (v == null) return '';
    return v.toString();
  }
}

class FileMakerImportResult {
  final FileMakerRecord rapport;
  final FileMakerRecord? klant;
  final FileMakerRecord? object;
  final FileMakerRecord? plan;
  final List<FileMakerRecord> constateringen;
  final List<Uint8List?> constateringFotos;
  final List<Uint8List?> constateringFotoDetails;
  final Uint8List? objectFotoBytes;
  final List<String> containerLog;
  final List<FileMakerRecord> sviRecords;
  final List<Uint8List?> sviFotos;
  final List<Uint8List?> sviFotoDetails;

  FileMakerImportResult({
    required this.rapport,
    this.klant,
    this.object,
    this.plan,
    this.constateringen = const [],
    this.constateringFotos = const [],
    this.constateringFotoDetails = const [],
    this.objectFotoBytes,
    this.containerLog = const [],
    this.sviRecords = const [],
    this.sviFotos = const [],
    this.sviFotoDetails = const [],
  });
}

class _ContainerResponse {
  final int statusCode;
  final Uint8List bodyBytes;
  final Map<String, String> headers;
  final Uri url;
  final int redirects;

  const _ContainerResponse({
    required this.statusCode,
    required this.bodyBytes,
    required this.headers,
    required this.url,
    required this.redirects,
  });
}

class FileMakerService {
  static const defaultServer = 'svr6.inspectora.nl';
  static const defaultDatabase = 'Inspectora-EPM';

  final String server;
  final String database;

  FileMakerService({
    this.server = defaultServer,
    this.database = defaultDatabase,
  });

  String get _baseUrl => 'https://$server/fmi/data/v1/databases/$database';

  // Custom client that accepts the server's SSL certificate
  late final http.Client _client = IOClient(
    HttpClient()..badCertificateCallback = (cert, host, port) => true,
  );

  // Opgeslagen na authenticate(), gebruikt als fallback voor container-URLs.
  String? _basicAuth;
  final _cookies = <String, String>{};

  Map<String, String> get _cookieHeaders {
    if (_cookies.isEmpty) return {};
    return {
      'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    };
  }

  void _storeCookiesFrom(http.BaseResponse response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;

    final ignored = {
      'expires',
      'path',
      'domain',
      'max-age',
      'secure',
      'httponly',
      'samesite',
    };
    final matches = RegExp(
      r'(?:^|,)\s*([^=;,\s]+)=([^;]*)',
    ).allMatches(setCookie);
    for (final match in matches) {
      final name = match.group(1);
      final value = match.group(2);
      if (name == null || value == null) continue;
      if (ignored.contains(name.toLowerCase())) continue;
      _cookies[name] = value;
    }
  }

  List<({String label, Map<String, String> headers})> _containerAuthOptions(
    String token,
  ) {
    Map<String, String> headers([Map<String, String> auth = const {}]) => {
      'Accept': 'image/*,*/*',
      ...auth,
      ..._cookieHeaders,
    };

    final options = <({String label, Map<String, String> headers})>[
      (label: 'Bearer', headers: headers({'Authorization': 'Bearer $token'})),
    ];
    if (_basicAuth != null) {
      options.add((
        label: 'Basic',
        headers: headers({'Authorization': 'Basic $_basicAuth'}),
      ));
    }
    if (_cookies.isNotEmpty) {
      options.add((label: 'Cookie', headers: headers()));
    }
    return options;
  }

  bool _isRedirect(int statusCode) =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;

  bool _looksLikeContainerBytes(Uint8List bytes, String contentType) {
    if (bytes.isEmpty) return false;
    final lowerType = contentType.toLowerCase();
    if (lowerType.startsWith('image/') ||
        lowerType == 'application/octet-stream') {
      return true;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return true;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return true;
    }
    return false;
  }

  Future<_ContainerResponse> _getContainerResponse(
    String fullUrl,
    Map<String, String> headers,
  ) async {
    var uri = Uri.parse(fullUrl);
    var redirects = 0;
    var currentHeaders = Map<String, String>.from(headers);

    while (true) {
      currentHeaders = {...currentHeaders, ..._cookieHeaders};
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll(currentHeaders);

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      _storeCookiesFrom(streamed);

      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 30));
      _storeCookiesFrom(response);

      final location = response.headers['location'];
      if (_isRedirect(response.statusCode) &&
          location != null &&
          location.isNotEmpty &&
          redirects < 5) {
        redirects++;
        uri = uri.resolve(location);
        currentHeaders = {...currentHeaders, ..._cookieHeaders};
        continue;
      }

      return _ContainerResponse(
        statusCode: response.statusCode,
        bodyBytes: response.bodyBytes,
        headers: response.headers,
        url: uri,
        redirects: redirects,
      );
    }
  }

  // Step 1: authenticate, returns token
  Future<String> authenticate(String username, String password) async {
    _basicAuth = base64Encode(utf8.encode('$username:$password'));
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/sessions'),
          headers: {
            'Authorization': 'Basic $_basicAuth',
            'Content-Type': 'application/json',
          },
          body: '{}',
        )
        .timeout(const Duration(seconds: 15));
    _storeCookiesFrom(response);

    if (response.statusCode != 200) {
      final body = _parseBody(response.body);
      final msg = _firstMessage(body);
      throw FileMakerException(
        msg ?? 'Authenticatie mislukt (${response.statusCode})',
      );
    }

    final body = _parseBody(response.body);
    final token = body['response']?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FileMakerException('Geen token ontvangen');
    }
    return token;
  }

  // Step 2: find records on a layout filtered by ID_Eigenaar (and optionally ID_rapport)
  Future<List<FileMakerRecord>> findByEigenaar(
    String token,
    String layout,
    String idEigenaar, {
    String? idRapport,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{'ID_Eigenaar': idEigenaar};
    if (idRapport != null && idRapport.isNotEmpty) {
      query['ID_rapport'] = idRapport;
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/layouts/$layout/_find'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': [query],
            'limit': limit.toString(),
            'sort': [
              {'fieldName': 'Datum', 'sortOrder': 'descend'},
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) return [];

    final body = _parseBody(response.body);

    // FileMaker returns code 401 (no records found) inside a 200 response
    final code = _firstCode(body);
    if (code == '401') return [];

    if (response.statusCode != 200) {
      final msg = _firstMessage(body);
      throw FileMakerException(
        msg ?? 'Fout bij ophalen $layout (${response.statusCode})',
      );
    }

    final data = body['response']?['data'] as List<dynamic>? ?? [];
    return data.map((r) {
      return FileMakerRecord(
        recordId: r['recordId']?.toString() ?? '',
        fieldData: Map<String, dynamic>.from(r['fieldData'] as Map? ?? {}),
      );
    }).toList();
  }

  // Fetch a single record via recordId
  Future<FileMakerRecord?> getRecord(
    String token,
    String layout,
    String recordId,
  ) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/layouts/$layout/records/$recordId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    final body = _parseBody(response.body);
    final data = body['response']?['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;

    final r = data.first;
    return FileMakerRecord(
      recordId: r['recordId']?.toString() ?? '',
      fieldData: Map<String, dynamic>.from(r['fieldData'] as Map? ?? {}),
    );
  }

  // Fetch one record from a layout matching a specific field value
  Future<FileMakerRecord?> findOne(
    String token,
    String layout,
    String fieldName,
    String value,
  ) async {
    if (value.isEmpty || value == '0') return null;
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/layouts/$layout/_find'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': [
              {fieldName: '==$value'},
            ],
            'limit': '1',
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parseBody(response.body);
    if (_firstCode(body) == '401') return null;
    if (response.statusCode != 200) return null;

    final data = body['response']?['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;

    final r = data.first;
    return FileMakerRecord(
      recordId: r['recordId']?.toString() ?? '',
      fieldData: Map<String, dynamic>.from(r['fieldData'] as Map? ?? {}),
    );
  }

  // Generic find: accepts any query map, returns all matching records
  Future<List<FileMakerRecord>> findRecords(
    String token,
    String layout,
    Map<String, String> query, {
    int limit = 1000,
  }) async {
    if (query.isEmpty) return [];
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/layouts/$layout/_find'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': [query],
            'limit': limit.toString(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 404) return [];
    final body = _parseBody(response.body);
    if (_firstCode(body) == '401') return [];
    if (response.statusCode != 200) {
      final msg = _firstMessage(body);
      throw FileMakerException(
        msg ?? 'Fout bij ophalen $layout (${response.statusCode})',
      );
    }

    final data = body['response']?['data'] as List<dynamic>? ?? [];
    return data
        .map(
          (r) => FileMakerRecord(
            recordId: r['recordId']?.toString() ?? '',
            fieldData: Map<String, dynamic>.from(r['fieldData'] as Map? ?? {}),
          ),
        )
        .toList();
  }

  // Fetch container field (foto) as raw bytes; returns null on any failure
  Future<Uint8List?> fetchContainerBytes(String token, String url) async {
    if (url.isEmpty) return null;
    final fullUrl = url.startsWith('https://') ? url : 'https://$server$url';
    for (final auth in _containerAuthOptions(token)) {
      try {
        final response = await _getContainerResponse(fullUrl, auth.headers);
        final contentType = response.headers['content-type'] ?? '';
        if (response.statusCode == 200 &&
            _looksLikeContainerBytes(response.bodyBytes, contentType)) {
          return response.bodyBytes;
        }
        if (response.statusCode != 401 && response.statusCode != 403) {
          return null;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // High-level: fetch all related data for a rapport record
  Future<FileMakerImportResult> fetchImportData(
    String token,
    FileMakerRecord rapport, {
    bool useContainerApi = true,
  }) async {
    final idKlant = rapport.field('ID_Klant');
    final idObject = rapport.field('ID_Object');
    final idPlan = rapport.field('ID_Inspectieplan');
    final idRapport = rapport.field('ID_rapport');

    final results = await Future.wait([
      findOne(token, 'moduleKlant', 'ID_Klant', idKlant),
      findOne(token, 'moduleObject', 'ID_Object', idObject),
      findOne(token, 'modulePlan', 'ID_Inspectieplan', idPlan),
      // Fetch all constateringen for this rapport
      if (idRapport.isNotEmpty)
        findRecords(token, 'moduleConstatering', {'ID_rapport': idRapport})
      else
        Future.value(<FileMakerRecord>[]),
      // Fetch all SVI records for this rapport
      if (idRapport.isNotEmpty)
        findRecords(token, 'moduleSVI', {'ID_rapport': idRapport})
      else
        Future.value(<FileMakerRecord>[]),
    ]);

    final objectRecord = results[1] as FileMakerRecord?;
    final constateringen = results[3] as List<FileMakerRecord>;
    final sviRecords = results[4] as List<FileMakerRecord>;

    Uint8List? objectFotoBytes;
    if (objectRecord != null) {
      final fotoUrl = objectRecord.field('Objectfoto');
      if (fotoUrl.isNotEmpty) {
        objectFotoBytes = await fetchContainerBytes(token, fotoUrl);
      }
    }

    List<Uint8List?> constateringFotos = List.filled(
      constateringen.length,
      null,
    );
    List<Uint8List?> constateringFotoDetails = List.filled(
      constateringen.length,
      null,
    );
    List<Uint8List?> sviFotos = List.filled(sviRecords.length, null);
    List<Uint8List?> sviFotoDetails = List.filled(sviRecords.length, null);
    final containerLog = <String>[];
    if (constateringen.isNotEmpty || sviRecords.isNotEmpty) {
      if (useContainerApi) {
        Future<Uint8List?> fetchLogged(
          String layout,
          String recordId,
          String fieldName,
          String fieldValue,
        ) async {
          final value = fieldValue.trim();

          // Empty container fields have no downloadable container.
          if (value.isEmpty) {
            containerLog.add(
              'NIL  $layout rec=$recordId  "$fieldName"  (leeg veld)',
            );
            return null;
          }

          // FileMaker returns the usable container URL in fieldData.
          final path = value;
          final fullUrl = path.startsWith('https://')
              ? path
              : 'https://$server$path';
          containerLog.add(
            'TRY  $layout rec=$recordId  "$fieldName"  fieldData="$value"',
          );

          for (final auth in _containerAuthOptions(token)) {
            try {
              final response = await _getContainerResponse(
                fullUrl,
                auth.headers,
              );
              final contentType = response.headers['content-type'] ?? '';
              if (response.statusCode == 200 &&
                  _looksLikeContainerBytes(response.bodyBytes, contentType)) {
                containerLog.add(
                  'OK   $layout rec=$recordId  "$fieldName"  ${response.bodyBytes.length} bytes  auth=${auth.label}  redirects=${response.redirects}  type="$contentType"',
                );
                return response.bodyBytes;
              }
              containerLog.add(
                'HTTP ${response.statusCode}  $layout rec=$recordId  "$fieldName"  auth=${auth.label}  redirects=${response.redirects}  bytes=${response.bodyBytes.length}  type="$contentType"  ${response.url}',
              );
              if (response.statusCode != 401 && response.statusCode != 403) {
                return null;
              }
            } catch (e) {
              containerLog.add(
                'ERR  $layout rec=$recordId  "$fieldName"  auth=${auth.label}  $e',
              );
              return null;
            }
          }
          return null;
        }

        for (int i = 0; i < constateringen.length; i++) {
          final c = constateringen[i];
          constateringFotos[i] = await fetchLogged(
            'moduleConstatering',
            c.recordId,
            'foto',
            c.field('foto'),
          );
          constateringFotoDetails[i] = await fetchLogged(
            'moduleConstatering',
            c.recordId,
            'foto detail',
            c.field('foto detail'),
          );
        }
        for (int i = 0; i < sviRecords.length; i++) {
          final s = sviRecords[i];
          sviFotos[i] = await fetchLogged(
            'moduleSVI',
            s.recordId,
            'foto',
            s.field('foto'),
          );
          sviFotoDetails[i] = await fetchLogged(
            'moduleSVI',
            s.recordId,
            'foto detail',
            s.field('foto detail'),
          );
        }
      } else {
        // Fetch via base64 tekstvelden
        for (int i = 0; i < constateringen.length; i++) {
          final c = constateringen[i];
          final b64foto = c.field('foto_base64');
          final b64detail = c.field('foto detail_base64');
          if (b64foto.isNotEmpty) {
            try {
              constateringFotos[i] = base64Decode(b64foto);
              containerLog.add(
                'OK   rec=${c.recordId}  "foto_base64"  ${constateringFotos[i]!.length} bytes',
              );
            } catch (e) {
              containerLog.add('ERR  rec=${c.recordId}  "foto_base64"  $e');
            }
          } else {
            containerLog.add(
              'NIL  rec=${c.recordId}  "foto_base64"  (leeg veld)',
            );
          }
          if (b64detail.isNotEmpty) {
            try {
              constateringFotoDetails[i] = base64Decode(b64detail);
              containerLog.add(
                'OK   rec=${c.recordId}  "foto detail_base64"  ${constateringFotoDetails[i]!.length} bytes',
              );
            } catch (e) {
              containerLog.add(
                'ERR  rec=${c.recordId}  "foto detail_base64"  $e',
              );
            }
          } else {
            containerLog.add(
              'NIL  rec=${c.recordId}  "foto detail_base64"  (leeg veld)',
            );
          }
        }
        for (int i = 0; i < sviRecords.length; i++) {
          final s = sviRecords[i];
          final b64foto = s.field('foto_base64');
          final b64detail = s.field('foto detail_base64');
          if (b64foto.isNotEmpty) {
            try {
              sviFotos[i] = base64Decode(b64foto);
              containerLog.add(
                'OK   moduleSVI rec=${s.recordId}  "foto_base64"  ${sviFotos[i]!.length} bytes',
              );
            } catch (e) {
              containerLog.add(
                'ERR  moduleSVI rec=${s.recordId}  "foto_base64"  $e',
              );
            }
          } else {
            containerLog.add(
              'NIL  moduleSVI rec=${s.recordId}  "foto_base64"  (leeg veld)',
            );
          }
          if (b64detail.isNotEmpty) {
            try {
              sviFotoDetails[i] = base64Decode(b64detail);
              containerLog.add(
                'OK   moduleSVI rec=${s.recordId}  "foto detail_base64"  ${sviFotoDetails[i]!.length} bytes',
              );
            } catch (e) {
              containerLog.add(
                'ERR  moduleSVI rec=${s.recordId}  "foto detail_base64"  $e',
              );
            }
          } else {
            containerLog.add(
              'NIL  moduleSVI rec=${s.recordId}  "foto detail_base64"  (leeg veld)',
            );
          }
        }
      }
    }

    return FileMakerImportResult(
      rapport: rapport,
      klant: results[0] as FileMakerRecord?,
      object: objectRecord,
      plan: results[2] as FileMakerRecord?,
      constateringen: constateringen,
      constateringFotos: constateringFotos,
      constateringFotoDetails: constateringFotoDetails,
      objectFotoBytes: objectFotoBytes,
      containerLog: containerLog,
      sviRecords: sviRecords,
      sviFotos: sviFotos,
      sviFotoDetails: sviFotoDetails,
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String? _firstMessage(Map<String, dynamic> body) {
    final messages = body['messages'] as List<dynamic>?;
    return messages?.firstOrNull?['message'] as String?;
  }

  String? _firstCode(Map<String, dynamic> body) {
    final messages = body['messages'] as List<dynamic>?;
    return messages?.firstOrNull?['code'] as String?;
  }
}

class FileMakerException implements Exception {
  final String message;
  const FileMakerException(this.message);
  @override
  String toString() => message;
}
