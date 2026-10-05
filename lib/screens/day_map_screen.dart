import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../app/theme.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';
import '../services/geocoding_service.dart';
import '../utils/route_optimizer.dart';

/// One point on the map, in the day's running order, and if it could be
/// resolved, its coordinates. Usually one [_Stop] per [Activity] — but a
/// travel activity with a recognizable "X to Y" shape produces two: an
/// origin stop (synthetic — not its own saved Activity) and the main
/// stop for the activity itself, so a flight or transfer shows where it
/// starts as well as where it ends rather than only the arrival point.
class _Stop {
  final Activity activity;
  final int order; // 1-based position within the day
  final LatLng? point;
  final String? titleOverride;
  final bool isOrigin;

  const _Stop({
    required this.activity,
    required this.order,
    this.point,
    this.titleOverride,
    this.isOrigin = false,
  });

  String get title => titleOverride ?? activity.title;

  bool get isFirst => order == 1;
}

/// Plots one [ItineraryDay]'s activities on a map, in order, connected by
/// a route line — reached from the "View on Map" button on that day's tab
/// in [ItineraryDaysView]. Geocodes each activity's title (scoped to the
/// trip's destination for disambiguation) on open; activities that can't
/// be resolved are skipped on the map but still listed below it, marked
/// as not found.
///
/// Markers are numbered to match the order strip beneath the map, so it's
/// clear at a glance which stop is which and what order they run in —
/// marigold for the first stop of the day, chili-red for the last,
/// indigo for everything between (the app's own stop-order palette).
class DayMapScreen extends StatefulWidget {
  final ItineraryDay day;
  final String destination;

  /// Called once, only if at least one activity that didn't already have
  /// stored coordinates got newly geocoded — with the day's full
  /// activity list, in order, coordinates merged in. Callers that have
  /// somewhere to persist this (a saved trip's Firestore doc) should
  /// write it back so the same activity never needs geocoding again.
  /// Left null for itineraries that aren't saved yet (nothing to write
  /// back to).
  final ValueChanged<List<Activity>>? onActivitiesResolved;

  const DayMapScreen({
    super.key,
    required this.day,
    required this.destination,
    this.onActivitiesResolved,
  });

  @override
  State<DayMapScreen> createState() => _DayMapScreenState();
}

class _DayMapScreenState extends State<DayMapScreen> {
  final _geocodingService = GeocodingService();

  bool _isLoading = true;
  int _unresolvedCount = 0;
  final List<_Stop> _stops = [];
  final Set<Marker> _markers = {};
  final List<LatLng> _routePoints = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _resolveLocations();
  }

  /// Strips a stray activity-type label the AI sometimes bakes directly
  /// into the title text itself (e.g. "Sightseeing: Calangute Beach, Goa,
  /// India", "Checkin: Taj Exotica Resort, Goa, India") — on top of the
  /// separate structured `type` field. Left in, it becomes noise at the
  /// front of the geocoding query; Google's fuzzy search often shrugs it
  /// off, but Nominatim's stricter parser frequently returns zero
  /// results for a query starting with a label like that.
  String _stripTypeLabel(String title) {
    final match = RegExp(
      r'^(meal|breakfast|lunch|dinner|sightseeing|travel|check-?in|leisure|adventure)\s*:\s*',
      caseSensitive: false,
    ).firstMatch(title);
    return match == null ? title : title.substring(match.end).trim();
  }

  /// Appends disambiguating context to a bare place name — but only the
  /// day's destination if that place genuinely looks like part of it.
  /// Blindly appending the destination to EVERY place name is wrong for
  /// a travel leg's origin (e.g. the "Surat" side of a Haridwar→Surat
  /// return flight): querying "Surat, Haridwar" is a contradiction that
  /// fails to resolve at all, which is why return-journey legs were
  /// silently disappearing from the map entirely.
  String _withContext(String place) {
    final normalizedPlace = place.toLowerCase();
    final normalizedDestination = widget.destination.toLowerCase();
    if (normalizedDestination.contains(normalizedPlace) ||
        normalizedPlace.contains(normalizedDestination)) {
      return '$place, ${widget.destination}';
    }
    // Not part of this day's destination (most likely a different city
    // entirely, like a flight's other end) — a generic country-level
    // hint is safer than actively wrong context.
    return '$place, India';
  }

  /// Pulls the origin and destination place names out of a travel
  /// activity's title (e.g. "Flight Surat to Haridwar", "Travel from
  /// Nadiad to Surat by Shatabdi Express") — both groups, not just the
  /// destination, so a flight/transfer can be plotted as two points
  /// (where it starts, where it ends) rather than silently dropping the
  /// origin. Returns null if the title doesn't match this shape at all
  /// (e.g. "Transfer to hotel" has no clear origin).
  RegExpMatch? _travelLegMatch(String title) {
    return RegExp(
      r'^(?:\w+[:\s]+)?(?:from\s+)?(.+?)\s+to\s+(.+?)(?:\s+(?:by|via)\s+.+)?$',
      caseSensitive: false,
    ).firstMatch(title);
  }

  /// Strips a trailing parenthetical aside from an extracted place name
  /// — the AI sometimes writes multi-leg journeys like "Nadiad Bus Stand
  /// to Goa (bus to Ahmedabad + flight from Ahmedabad)", where the whole
  /// "(...)" is detail about the journey, not part of the place name.
  /// Left in, it gets sent to the geocoder as part of the query and
  /// produces a near-random wrong match instead of just "Goa".
  String _cleanPlaceName(String raw) {
    final withoutParens = raw.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return withoutParens.isEmpty ? raw.trim() : withoutParens;
  }

  /// Builds the geocoding query for one activity's own point. Most
  /// activities (meals, check-ins, sightseeing) have a title that's
  /// already a place name, so appending context is enough. `travel`
  /// activities are different: the title is a sentence describing a
  /// journey, so this extracts just the arrival place (the "to Y" part)
  /// rather than geocoding the whole sentence — the origin side ("from
  /// X") is handled separately in [_resolveLocations] as its own extra
  /// point, not folded into this one.
  String _queryFor(Activity activity) {
    final title = _stripTypeLabel(activity.title);

    if (activity.type == ActivityType.travel) {
      final match = _travelLegMatch(title);
      final arrival = match?.group(2)?.trim();
      if (arrival != null && arrival.isNotEmpty) {
        return _withContext(_cleanPlaceName(arrival));
      }
      return widget.destination;
    }

    // The AI sometimes already includes the destination city in the
    // title itself (e.g. "Calangute Beach, Goa, India") — appending it
    // again produces a duplicated, noisier query that trips up
    // Nominatim's parser more often than it helps disambiguate.
    if (title.toLowerCase().contains(widget.destination.toLowerCase())) {
      return title;
    }
    // Unlike a travel leg's origin/destination, a regular stop is
    // always located AT this day's destination by definition — so
    // always anchor it there, rather than routing through _withContext's
    // more cautious "only if it textually overlaps" logic. A query like
    // "Taj Exotica Resort & Spa" mentions neither Goa nor India, so
    // without this it fell back to a bare ", India" — vague enough that
    // the geocoder picked the far more famous same-named resort in the
    // Maldives instead of the actual Goa property.
    return '$title, ${widget.destination}';
  }

  /// Rough straight-line distance in km between two points (haversine).
  /// Used only to sanity-check a regular stop's geocoded result against
  /// the day's actual destination — never applied to travel-leg points,
  /// which are expected to span long distances on purpose.
  double _kmBetween(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180);
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  /// A regular stop resolving further than this from the day's
  /// destination almost certainly means the geocoder matched the wrong
  /// same-named place in a different city or country entirely, not a
  /// legitimately far-flung local day-trip spot.
  static const _sameAreaRadiusKm = 150.0;

  /// Geocodes every activity's query, but in small batches rather than
  /// all at once. A day with 8-9 activities firing that many concurrent
  /// requests can burst past the API key's rate limit, which is what was
  /// causing a random subset to fail differently on every single visit
  /// to the same day.
  Future<List<LatLng?>> _geocodeAll(List<String> queries) async {
    const batchSize = 3;
    final results = <LatLng?>[];
    for (var i = 0; i < queries.length; i += batchSize) {
      final end = (i + batchSize < queries.length) ? i + batchSize : queries.length;
      final batch = queries.sublist(i, end);
      results.addAll(await Future.wait(batch.map(_geocodingService.geocode)));
      if (end < queries.length) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    return results;
  }

  Future<void> _resolveLocations() async {
    final activities = widget.day.activities;

    // A rough anchor for "where this day actually happens" — used below
    // to sanity-check regular (non-travel) stops against. Resolving it
    // once up front is cheap (one extra geocode call per day opened)
    // and is what makes it possible to catch a wrong-city match instead
    // of just trusting whatever the geocoder returns.
    final destinationAnchor = await _geocodingService.geocode(widget.destination);

    bool isSane(Activity a, LatLng point) {
      if (a.type == ActivityType.travel || destinationAnchor == null) return true;
      return _kmBetween(point, destinationAnchor) <= _sameAreaRadiusKm;
    }

    // Activities that already carry stored coordinates (from a previous
    // visit, persisted via onActivitiesResolved) normally skip
    // geocoding entirely — this is what keeps a saved trip's map from
    // re-hitting the (heavily rate-limited) Places API on every
    // revisit. The one exception, besides travel-leg origins (handled
    // separately below): a stored point that fails the sanity check
    // above — e.g. a previously-saved "Taj Exotica Resort & Spa" that
    // resolved to the Maldives before this check existed — gets a
    // chance to re-resolve properly instead of silently keeping a
    // wrong location forever.
    final needsGeocode = <int>[];
    final queries = <String>[];
    for (var i = 0; i < activities.length; i++) {
      final a = activities[i];
      final storedPoint = a.hasLocation ? LatLng(a.latitude!, a.longitude!) : null;
      if (storedPoint == null || !isSane(a, storedPoint)) {
        needsGeocode.add(i);
        queries.add(_queryFor(a));
      }
    }

    final freshResults = await _geocodeAll(queries);

    final resolvedActivities = List<Activity>.from(activities);
    var anyNewlyResolved = false;
    for (var j = 0; j < needsGeocode.length; j++) {
      final point = freshResults[j];
      final i = needsGeocode[j];
      if (point == null || !isSane(activities[i], point)) {
        // Either didn't resolve, or resolved somewhere implausible —
        // either way, don't keep a bad stored coordinate from before.
        if (activities[i].hasLocation) {
          resolvedActivities[i] = activities[i].clearLocation();
          anyNewlyResolved = true;
        }
        continue;
      }
      resolvedActivities[i] = activities[i].copyWith(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      anyNewlyResolved = true;
    }

    // Reorder the day's flexible stops (sightseeing/leisure/adventure)
    // to shorten the route; meals, check-ins, travel legs and
    // time-specific stops keep their place. See RouteOptimizer.
    final optimized = RouteOptimizer.optimize(resolvedActivities);
    var orderChanged = false;
    for (var i = 0; i < optimized.length; i++) {
      if (optimized[i].title != resolvedActivities[i].title) {
        orderChanged = true;
        break;
      }
    }

    if (anyNewlyResolved || orderChanged) {
      widget.onActivitiesResolved?.call(optimized);
    }

    // Travel activities get a second, synthetic "origin" query — e.g.
    // "Flight Surat to Haridwar" produces both a Surat point and a
    // Haridwar point, instead of only the arrival. Built as a separate
    // pass (not merged into the main geocode batch above) because the
    // origin side is never persisted to the Activity, so it has to be
    // resolved fresh on every visit regardless of hasLocation.
    final originQueries = <int, String>{}; // activity index -> query
    for (var i = 0; i < optimized.length; i++) {
      final a = optimized[i];
      if (a.type != ActivityType.travel) continue;
      final match = _travelLegMatch(_stripTypeLabel(a.title));
      final origin = match?.group(1)?.trim();
      if (origin == null || origin.isEmpty) continue;
      originQueries[i] = _withContext(_cleanPlaceName(origin));
    }
    final originResults = await _geocodeAll(originQueries.values.toList());
    final originPoints = <int, LatLng>{};
    var oi = 0;
    for (final index in originQueries.keys) {
      final point = originResults[oi++];
      if (point != null) originPoints[index] = point;
    }

    final stops = <_Stop>[];
    final points = <LatLng>[];
    var unresolved = 0;
    var order = 1;

    for (var i = 0; i < optimized.length; i++) {
      final a = optimized[i];

      final originPoint = originPoints[i];
      if (originPoint != null) {
        stops.add(_Stop(
          activity: a,
          order: order++,
          point: originPoint,
          titleOverride: 'Depart: ${_cleanPlaceName(_travelLegMatch(_stripTypeLabel(a.title))?.group(1)?.trim() ?? '')}',
          isOrigin: true,
        ));
        points.add(originPoint);
      }

      final point = a.hasLocation ? LatLng(a.latitude!, a.longitude!) : null;
      stops.add(_Stop(activity: a, order: order++, point: point));
      if (point == null) {
        unresolved++;
      } else {
        points.add(point);
      }
    }

    final markers = <Marker>{};
    final lastOrder = stops.isEmpty ? 0 : stops.last.order;
    for (final stop in stops) {
      final point = stop.point;
      if (point == null) continue;
      final isLast = stop.order == lastOrder;
      final icon = await _numberedMarkerIcon(
        stop.order,
        color: stop.isFirst
            ? AppTheme.stopFirst
            : isLast
            ? AppTheme.stopLast
            : AppTheme.stopMiddle,
      );
      markers.add(Marker(
        markerId: MarkerId('${stop.order}_${stop.title}'),
        position: point,
        icon: icon,
        infoWindow: InfoWindow(
          title: '${stop.order}. ${stop.title}',
          snippet: stop.activity.time,
        ),
      ));
    }

    if (!mounted) return;
    setState(() {
      _stops.addAll(stops);
      _markers.addAll(markers);
      _routePoints.addAll(points);
      _unresolvedCount = unresolved;
      _isLoading = false;
    });
  }

  /// Draws a small filled, numbered circle to use as a marker icon, so
  /// each pin on the map shows its position in the day's running order
  /// instead of a plain default pin.
  Future<BitmapDescriptor> _numberedMarkerIcon(int number,
      {required Color color}) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final circlePaint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, circlePaint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _focusOn(LatLng point) async {
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Day ${widget.day.dayNumber} · ${widget.destination}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routePoints.isEmpty
          ? const Center(child: Text('Could not locate any activities for this day'))
          : Column(
        children: [
          if (_unresolvedCount > 0)
            Container(
              width: double.infinity,
              color: AppTheme.chili.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.chili),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$_unresolvedCount location${_unresolvedCount == 1 ? '' : 's'} '
                          'couldn\'t be found and ${_unresolvedCount == 1 ? 'is' : 'are'} not shown',
                      style: const TextStyle(fontSize: 12, color: AppTheme.chili),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _routePoints.first,
                zoom: 12,
              ),
              markers: _markers,
              polylines: {
                Polyline(
                  polylineId: const PolylineId('day_route'),
                  points: _routePoints,
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
                if (_routePoints.length < 2) return;
                // Give the map a moment to lay out before fitting
                // bounds — animateCamera on the very first frame
                // is unreliable on some devices.
                Future.delayed(const Duration(milliseconds: 300), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(_boundsFor(_routePoints), 48),
                  );
                });
              },
            ),
          ),
          _StopsStrip(stops: _stops, onTap: _focusOn),
        ],
      ),
    );
  }
}

/// Horizontal strip of the day's stops in order, below the map. Tapping a
/// resolved stop pans and zooms the map to it; unresolved stops are shown
/// greyed out and are not tappable, since there's no location to jump to.
class _StopsStrip extends StatelessWidget {
  final List<_Stop> stops;
  final ValueChanged<LatLng> onTap;

  const _StopsStrip({required this.stops, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 128,
      color: theme.colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: stops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final stop = stops[index];
          final resolved = stop.point != null;
          final isLast = stop.order == stops.length;
          final badgeColor = !resolved
              ? Colors.grey.shade400
              : stop.isFirst
              ? AppTheme.stopFirst
              : isLast
              ? AppTheme.stopLast
              : AppTheme.stopMiddle;

          return Opacity(
            opacity: resolved ? 1 : 0.55,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: resolved ? () => onTap(stop.point!) : null,
              child: Container(
                width: 190,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: badgeColor,
                      child: Text(
                        '${stop.order}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.activity.time,
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stop.isOrigin) ...[
                                const Icon(Icons.flight_takeoff, size: 12, color: AppTheme.inkMuted),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  stop.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          if (!resolved)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                'Location not found',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}