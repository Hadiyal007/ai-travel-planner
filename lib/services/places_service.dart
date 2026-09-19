import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// A single autocomplete suggestion.
class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({required this.placeId, required this.description});
}

/// Wraps Places API (New) — places.googleapis.com — rather than the
/// legacy maps.googleapis.com/maps/api/place endpoint. The legacy
/// endpoint sends no CORS headers and simply fails from a browser;
/// the new one supports CORS with a referrer-restricted key, so this
/// works on Flutter Web as well as mobile.
///
/// Needs "Places API (New)" enabled on the Google Cloud project the
/// key belongs to (separate from the legacy "Places API").
class PlacesService {
  static const _endpoint =
      'https://places.googleapis.com/v1/places:autocomplete';

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': ApiKeys.googlePlaces,
      },
      body: jsonEncode({'input': input}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Places lookup failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];

    return suggestions
        .map((item) => item['placePrediction'] as Map<String, dynamic>?)
        .where((prediction) => prediction != null)
        .map((prediction) => PlaceSuggestion(
      placeId: prediction!['placeId'] ?? '',
      description: prediction['text']?['text'] ?? '',
    ))
        .where((suggestion) => suggestion.description.isNotEmpty)
        .toList();
  }
}