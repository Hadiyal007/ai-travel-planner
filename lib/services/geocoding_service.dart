import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_keys.dart';

/// Resolves a free-text place name (e.g. an itinerary activity's title,
/// like "Lunch at Britto's Shack, Baga Beach") to coordinates via the
/// Places API (New) Text Search endpoint. Activities are only ever stored
/// as AI-generated text, never lat/lng, so this is what makes the map
/// view possible.
///
/// Uses the same GOOGLE_PLACES_API_KEY as PlacesService, and the same
/// "Places API (New)" that must be enabled for autocomplete to work.
/// Deliberately NOT the legacy maps.googleapis.com/maps/api/geocode/json
/// endpoint: that one sends no CORS headers and every request to it fails
/// silently from Flutter Web, which is why the map screen was showing
/// "Could not locate any activities" for every day.
class GeocodingService {
  static const _endpoint = 'https://places.googleapis.com/v1/places:searchText';
  static const _maxAttempts = 3;

  /// Caches only *confirmed* outcomes (a resolved point, or a genuine
  /// "no such place" from a 200 response with no results) for the
  /// process's lifetime, keyed by query string — so re-opening "View on
  /// Map" for the same day reuses those instead of re-hitting the network.
  /// Transient failures (rate limit, server error, exhausted retries) are
  /// deliberately NOT cached: caching a temporary failure as if it were
  /// permanent would mean one bad burst of requests locks that activity
  /// out of ever resolving again for the rest of the session, even after
  /// the underlying rate limit or quota window clears.
  static final Map<String, LatLng?> _cache = {};

  Future<LatLng?> geocode(String query) async {
    if (_cache.containsKey(query)) return _cache[query];

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': ApiKeys.googlePlacesApiKey,
            'X-Goog-FieldMask': 'places.location',
          },
          body: jsonEncode({'textQuery': query}),
        );

        if (response.statusCode == 429 || response.statusCode >= 500) {
          final isDailyQuotaExhausted = response.statusCode == 429 &&
              response.body.contains('PerDayPerProject');
          _log(query, 'HTTP ${response.statusCode} (attempt ${attempt + 1}/$_maxAttempts): '
              '${response.body}');
          if (isDailyQuotaExhausted) {
            // A per-day quota is exhausted for the whole project until it
            // resets — retrying immediately hits the exact same wall and
            // just burns time for nothing, so stop right away instead of
            // spending the remaining attempts on a guaranteed failure.
            return null;
          }
          if (attempt < _maxAttempts - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
          return null; // exhausted retries — transient, not cached
        }

        if (response.statusCode != 200) {
          // Non-retryable: bad request, auth/permission/referrer problem,
          // etc. This will keep failing on retry, so log it clearly but
          // don't cache it either — if the person fixes the API key or
          // console config mid-session, it should be able to succeed on
          // the next attempt without an app restart.
          _log(query, 'HTTP ${response.statusCode} (non-retryable): ${response.body}');
          return null;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final places = decoded['places'] as List<dynamic>?;
        if (places == null || places.isEmpty) {
          // A real "no such place" — safe to cache.
          _cache[query] = null;
          return null;
        }

        final location = places.first['location'] as Map<String, dynamic>?;
        final result = location == null
            ? null
            : LatLng(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        );
        _cache[query] = result;
        return result;
      } catch (e) {
        _log(query, 'Exception (attempt ${attempt + 1}/$_maxAttempts): $e');
        if (attempt < _maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        return null; // exhausted retries — not cached
      }
    }
    return null;
  }

  void _log(String query, String message) {
    if (kDebugMode) {
      debugPrint('[GeocodingService] "$query" -> $message');
    }
  }
}