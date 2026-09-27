import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_keys.dart';

/// Resolves a free-text place name (e.g. an itinerary activity's title,
/// like "Lunch at Britto's Shack, Baga Beach") to coordinates. Activities
/// are only ever stored as AI-generated text, never lat/lng, so this is
/// what makes the map view possible.
///
/// Tries Google's Places API (New) Text Search first (same
/// GOOGLE_PLACES_API_KEY as PlacesService, same "Places API (New)" that
/// must be enabled for autocomplete to work). Deliberately NOT the legacy
/// maps.googleapis.com/maps/api/geocode/json endpoint: that one sends no
/// CORS headers and every request to it fails silently from Flutter Web.
///
/// Without a billing account attached to the Cloud project, Google caps
/// this at a very small daily quota (observed: 100 requests/day, shared
/// across the whole project) as an anti-abuse safeguard rather than a
/// real supported tier. Rather than requiring billing, every Google
/// failure — quota exhausted, transient error, or a genuine no-match —
/// falls back to OpenStreetMap's Nominatim search, which is free and
/// needs no API key or billing at all. It's slower (rate-limited to
/// roughly one request/second per Nominatim's usage policy: see
/// https://operations.osmfoundation.org/policies/nominatim/) and
/// sometimes less precise for obscure named restaurants, but it's a
/// solid safety net for addresses, attractions, and landmarks.
class GeocodingService {
  static const _googleEndpoint = 'https://places.googleapis.com/v1/places:searchText';
  static const _nominatimEndpoint = 'https://nominatim.openstreetmap.org/search';
  static const _maxAttempts = 3;

  /// Caches only *confirmed* outcomes (a resolved point, or a genuine
  /// "no such place" — from both Google and the Nominatim fallback
  /// returning nothing) for the process's lifetime, keyed by query
  /// string — so re-opening "View on Map" for the same day reuses those
  /// instead of re-hitting the network. Transient failures (rate limit,
  /// server error, exhausted retries) are deliberately NOT cached:
  /// caching a temporary failure as if it were permanent would mean one
  /// bad burst of requests locks that activity out of ever resolving
  /// again for the rest of the session, even after the underlying rate
  /// limit or quota window clears.
  static final Map<String, LatLng?> _cache = {};

  /// Serializes Nominatim requests so they're spaced at least ~1.1s
  /// apart, regardless of how many geocode() calls are in flight at
  /// once — required by Nominatim's usage policy, since it's a shared
  /// free public service with no API key to enforce this for us.
  static Future<void> _nominatimGate = Future.value();

  Future<LatLng?> geocode(String query) async {
    if (_cache.containsKey(query)) return _cache[query];

    final googleResult = await _geocodeWithGoogle(query);
    if (googleResult != null) {
      _cache[query] = googleResult;
      return googleResult;
    }

    // Google didn't resolve it — for any reason. Try the free fallback
    // before giving up, since it doesn't cost anything to try.
    final osmResult = await _geocodeWithNominatim(query);
    if (osmResult != null) {
      _log(query, 'Resolved via Nominatim fallback after Google failed/missed.');
      _cache[query] = osmResult;
    } else {
      // Neither service found it — but only cache this as a genuine
      // miss if Google's failure wasn't itself a transient one (that
      // check already happened inside _geocodeWithGoogle, which only
      // returns null for transient cases without touching the cache
      // key here — so it's safe to leave uncached in that case and let
      // a future visit try again).
    }
    return osmResult;
  }

  /// Attempts Google Places Text Search with retries for transient
  /// failures. Returns null on any failure (transient or permanent) or a
  /// genuine no-match — callers fall back to Nominatim in every null
  /// case, since it costs nothing to try.
  Future<LatLng?> _geocodeWithGoogle(String query) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(_googleEndpoint),
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
          _log(query, 'Google HTTP ${response.statusCode} '
              '(attempt ${attempt + 1}/$_maxAttempts): ${response.body}');
          if (isDailyQuotaExhausted) {
            // A per-day quota is exhausted for the whole project until it
            // resets — retrying immediately hits the exact same wall and
            // just burns time for nothing, so stop right away and let
            // the Nominatim fallback take over instead.
            return null;
          }
          if (attempt < _maxAttempts - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
          return null; // exhausted retries — transient
        }

        if (response.statusCode != 200) {
          // Non-retryable: bad request, auth/permission/referrer problem,
          // etc. Log clearly, then let the Nominatim fallback take over.
          _log(query, 'Google HTTP ${response.statusCode} (non-retryable): '
              '${response.body}');
          return null;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final places = decoded['places'] as List<dynamic>?;
        if (places == null || places.isEmpty) {
          _log(query, 'Google: no match (200, empty places[])');
          return null; // genuine "no such place" per Google
        }

        final location = places.first['location'] as Map<String, dynamic>?;
        return location == null
            ? null
            : LatLng(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        );
      } catch (e) {
        _log(query, 'Google exception (attempt ${attempt + 1}/$_maxAttempts): $e');
        if (attempt < _maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        return null; // exhausted retries
      }
    }
    return null;
  }

  /// Free fallback via OpenStreetMap's Nominatim search — no API key or
  /// billing required. Only ever called after Google has already failed
  /// or missed, so there's no reason to retry aggressively here; one
  /// attempt is enough for a fallback path.
  Future<LatLng?> _geocodeWithNominatim(String query) async {
    // Chain onto the previous caller's gate so requests from concurrent
    // geocode() calls still end up spaced out, not fired together.
    final previousGate = _nominatimGate;
    final completer = Completer<void>();
    _nominatimGate = completer.future;
    await previousGate;

    try {
      await Future.delayed(const Duration(milliseconds: 1100));

      final uri = Uri.parse(_nominatimEndpoint).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '1',
      });
      final response = await http.get(
        uri,
        headers: {
          // Nominatim's usage policy requires a real identifying
          // User-Agent on every request.
          'User-Agent': 'AITravelPlanner/1.0 (Flutter app; geocoding fallback)',
        },
      );

      if (response.statusCode != 200) {
        _log(query, 'Nominatim HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (decoded.isEmpty) {
        _log(query, 'Nominatim: no match (200, empty array)');
        return null;
      }

      final first = decoded.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return LatLng(lat, lon);
    } catch (e) {
      _log(query, 'Nominatim exception: $e');
      return null;
    } finally {
      completer.complete();
    }
  }

  void _log(String query, String message) {
    if (kDebugMode) {
      debugPrint('[GeocodingService] "$query" -> $message');
    }
  }
}