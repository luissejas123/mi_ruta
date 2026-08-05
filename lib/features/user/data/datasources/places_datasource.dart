import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';

/// Acceso a la Places API de Google via HTTP.
class PlacesDatasource {
  String get _apiKey =>
      dotenv.env['PLACES_API_KEY'] ?? dotenv.env['MAPS_API_KEY'] ?? '';

  /// Devuelve lista de predicciones de autocompletado para [input].
  Future<List<Map<String, dynamic>>> fetchPredictions({
    required String input,
    LatLng? location,
  }) async {
    final params = <String, String>{
      'input': input,
      'key': _apiKey,
      'language': 'es',
      'components': 'country:bo',
    };

    if (location != null) {
      params['location'] = '${location.latitude},${location.longitude}';
      params['radius'] = '50000';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error HTTP: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Error Places API: $status');
    }

    return (data['predictions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// Obtiene las coordenadas y nombre de un lugar por su [prediction].
  Future<PlaceResult> fetchPlaceDetail(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'] as String?;
    if (placeId == null) throw Exception('Place ID nulo');

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'geometry,name',
        'language': 'es',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error HTTP: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    final loc = result?['geometry']?['location'] as Map<String, dynamic>?;

    if (loc == null) throw Exception('No se encontró la ubicación del lugar');

    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    final sf = prediction['structured_formatting'] as Map<String, dynamic>?;
    final name =
        (result?['name'] as String?) ??
        (sf?['main_text'] as String?) ??
        (prediction['description'] as String?) ??
        '';

    return PlaceResult(latLng: LatLng(lat, lng), name: name);
  }
}
