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
import 'package:http/http.dart' as http;

/// Thrown when the BAG lookup could not find a matching address or building.
class BagNotFoundException implements Exception {
  final String message;
  BagNotFoundException(this.message);
}

/// Thrown when the PDOK services could not be reached or returned an error.
class BagLookupException implements Exception {
  final String message;
  BagLookupException(this.message);
}

class BagResult {
  final String matchedAddress;
  final int? bouwjaar;
  final int? oppervlakte;
  final List<String> gebruiksdoelen;
  final double? gebouwhoogte;

  BagResult({
    required this.matchedAddress,
    this.bouwjaar,
    this.oppervlakte,
    this.gebruiksdoelen = const [],
    this.gebouwhoogte,
  });
}

/// Looks up building data (bouwjaar, gebruiksdoel, oppervlakte, gebouwhoogte)
/// for a Dutch address via the free, keyless PDOK and 3DBAG services:
/// - Locatieserver (geocoding: address text -> BAG verblijfsobject id)
/// - BAG WFS (verblijfsobject id -> bouwjaar/oppervlakte/gebruiksdoel/pand id)
/// - 3DBAG API (pand id -> dak- en maaiveldhoogte, waaruit de gebouwhoogte
///   wordt berekend als hoogste dakhoogte minus maaiveldhoogte)
class BagService {
  static const _locatieserverUrl =
      'https://api.pdok.nl/bzk/locatieserver/search/v3_1/free';
  static const _wfsUrl = 'https://service.pdok.nl/lv/bag/wfs/v2_0';
  static const _bag3dUrl = 'https://api.3dbag.nl/collections/pand/items';
  static const _timeout = Duration(seconds: 10);

  /// Maps official BAG gebruiksdoel categories onto this app's
  /// "Gebouwfunctie volgens Bbl" checklist labels. BAG only knows the coarse
  /// categories, so finer Bbl subcategories (e.g. "Lichte industriefunctie")
  /// are never produced here.
  static const Map<String, String> _gebruiksdoelMap = {
    'woonfunctie': 'Woonfunctie',
    'bijeenkomstfunctie': 'Bijeenkomstfunctie',
    'celfunctie': 'Celfunctie',
    'gezondheidszorgfunctie': 'Gezondheidsfunctie',
    'industriefunctie': 'Industriefunctie',
    'kantoorfunctie': 'Kantoorfunctie',
    'logiesfunctie': 'Logiefunctie',
    'onderwijsfunctie': 'Onderwijsfunctie',
    'sportfunctie': 'Sportfunctie',
    'winkelfunctie': 'Winkelfunctie',
    'overige gebruiksfunctie': 'Overige',
  };

  Future<BagResult> lookup(String street, String postalCity) async {
    final query = '$street $postalCity'.trim();
    if (query.isEmpty) {
      throw BagNotFoundException(
        'Vul eerst het inspectieadres in op de pagina Algemene Gegevens.',
      );
    }

    final addressDoc = await _findAddress(query);
    final objectId = addressDoc['adresseerbaarobject_id'] as String?;
    if (objectId == null || objectId.isEmpty) {
      throw BagNotFoundException(
        'Geen BAG-verblijfsobject gevonden voor dit adres.',
      );
    }

    final verblijfsobject = await _findVerblijfsobject(objectId);
    final props = verblijfsobject['properties'] as Map<String, dynamic>;

    final bouwjaar = props['bouwjaar'];
    final oppervlakte = props['oppervlakte'];
    final gebruiksdoelRaw = props['gebruiksdoel'] as String?;
    final pandId = props['pandidentificatie'] as String?;

    final gebruiksdoelen = <String>{};
    if (gebruiksdoelRaw != null && gebruiksdoelRaw.isNotEmpty) {
      for (final part in gebruiksdoelRaw.split(',')) {
        final normalized = part.trim().toLowerCase();
        final mapped = _gebruiksdoelMap[normalized];
        if (mapped != null) gebruiksdoelen.add(mapped);
      }
    }

    double? gebouwhoogte;
    if (pandId != null && pandId.isNotEmpty) {
      gebouwhoogte = await _fetchGebouwhoogte(pandId);
    }

    return BagResult(
      matchedAddress: addressDoc['weergavenaam'] as String? ?? query,
      bouwjaar: bouwjaar is int ? bouwjaar : int.tryParse('$bouwjaar'),
      oppervlakte: oppervlakte is int
          ? oppervlakte
          : int.tryParse('$oppervlakte'),
      gebruiksdoelen: gebruiksdoelen.toList(),
      gebouwhoogte: gebouwhoogte,
    );
  }

  /// Calculates the gebouwhoogte (highest roof height minus maaiveldhoogte)
  /// for a pand via the 3DBAG API. Returns null if the pand is not present
  /// in 3DBAG or the service could not be reached, since this is a
  /// supplementary value and shouldn't fail the whole BAG lookup.
  Future<double?> _fetchGebouwhoogte(String pandId) async {
    try {
      final uri = Uri.parse('$_bag3dUrl/NL.IMBAG.Pand.$pandId');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final cityObjects =
          (body['feature'] as Map<String, dynamic>?)?['CityObjects']
              as Map<String, dynamic>?;
      final pandObject =
          cityObjects?['NL.IMBAG.Pand.$pandId'] as Map<String, dynamic>?;
      final attributes = pandObject?['attributes'] as Map<String, dynamic>?;
      if (attributes == null) return null;

      final maaiveld = attributes['b3_h_maaiveld'];
      final dakMax = attributes['b3_h_dak_max'];
      if (maaiveld is! num || dakMax is! num) return null;

      final hoogte = dakMax - maaiveld;
      return double.parse(hoogte.toStringAsFixed(1));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _findAddress(String query) async {
    final uri = Uri.parse(
      _locatieserverUrl,
    ).replace(queryParameters: {'q': query, 'fq': 'type:adres', 'rows': '1'});
    final response = await _get(uri);
    final docs =
        (jsonDecode(response.body) as Map<String, dynamic>)['response']['docs']
            as List;
    if (docs.isEmpty) {
      throw BagNotFoundException(
        'Geen adres gevonden in het BAG-register voor "$query". Controleer het adres op de pagina Algemene Gegevens.',
      );
    }
    return docs.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _findVerblijfsobject(
    String identificatie,
  ) async {
    final filter =
        '<Filter xmlns="http://www.opengis.net/fes/2.0">'
        '<PropertyIsEqualTo>'
        '<ValueReference>identificatie</ValueReference>'
        '<Literal>$identificatie</Literal>'
        '</PropertyIsEqualTo>'
        '</Filter>';
    final uri = Uri.parse(_wfsUrl).replace(
      queryParameters: {
        'service': 'WFS',
        'version': '2.0.0',
        'request': 'GetFeature',
        'typeName': 'bag:verblijfsobject',
        'outputFormat': 'application/json',
        'filter': filter,
      },
    );
    final response = await _get(uri);
    final features =
        (jsonDecode(response.body) as Map<String, dynamic>)['features'] as List;
    if (features.isEmpty) {
      throw BagNotFoundException(
        'Geen pandgegevens gevonden voor dit adres in het BAG-register.',
      );
    }
    return features.first as Map<String, dynamic>;
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw BagLookupException(
          'Het BAG-register gaf een onverwachte fout (${response.statusCode}).',
        );
      }
      return response;
    } on BagLookupException {
      rethrow;
    } catch (e) {
      throw BagLookupException(
        'Kon geen verbinding maken met het BAG-register: $e',
      );
    }
  }
}
