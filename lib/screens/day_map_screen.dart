import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../app/theme.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';
import '../services/geocoding_service.dart';
import '../utils/route_optimizer.dart';

/// One activity plus its place in the day's running order and, if it
/// could be resolved, its coordinates.
class _Stop {
  final Activity activity;
  final int order; // 1-based position within the day
  final LatLng? point;

  const _Stop({required this.activity, required this.order, this.point});

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

  /// Builds the geocoding query for one activity. Most activities (meals,
  /// check-ins, sightseeing) have a title that's already a place name, so
  /// appending the destination for disambiguation is enough. `travel`
  /// activities are different: their title is a sentence describing a
  /// journey (e.g. "Travel from Nadiad to Surat by Shatabdi Express"),
  /// which Places Text Search can't match as-is — so pull out the "to X"
  /// destination and geocode that instead, falling back to the day's
  /// destination city if no "to X" is found.
  String _queryFor(Activity activity) {
    final title = _stripTypeLabel(activity.title);

    if (activity.type == ActivityType.travel) {
      final match = RegExp(r'\bto\s+(.+?)(?:\s+(?:by|via)\s+.+)?$',
          caseSensitive: false)
          .firstMatch(title);
      final place = match?.group(1)?.trim();
      if (place != null && place.isNotEmpty) {
        return '$place, ${widget.destination}';
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
    return '$title, ${widget.destination}';
  }

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

    // Activities that already carry stored coordinates (from a previous
    // visit, persisted via onActivitiesResolved) skip geocoding entirely
    // — this is what keeps a saved trip's map from re-hitting the
    // (heavily rate-limited) Places API on every revisit.
    final needsGeocode = <int>[];
    final queries = <String>[];
    for (var i = 0; i < activities.length; i++) {
      if (!activities[i].hasLocation) {
        needsGeocode.add(i);
        queries.add(_queryFor(activities[i]));
      }
    }

    final freshResults = await _geocodeAll(queries);

    final resolvedActivities = List<Activity>.from(activities);
    var anyNewlyResolved = false;
    for (var j = 0; j < needsGeocode.length; j++) {
      final point = freshResults[j];
      if (point == null) continue;
      final i = needsGeocode[j];
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

    final stops = <_Stop>[];
    final points = <LatLng>[];
    var unresolved = 0;

    for (var i = 0; i < optimized.length; i++) {
      final a = optimized[i];
      final point = a.hasLocation ? LatLng(a.latitude!, a.longitude!) : null;
      stops.add(_Stop(activity: a, order: i + 1, point: point));
      if (point == null) {
        unresolved++;
      } else {
        points.add(point);
      }
    }

    final markers = <Marker>{};
    for (final stop in stops) {
      final point = stop.point;
      if (point == null) continue;
      final isLast = stop.order == activities.length;
      final icon = await _numberedMarkerIcon(
        stop.order,
        color: stop.isFirst
            ? AppTheme.stopFirst
            : isLast
            ? AppTheme.stopLast
            : AppTheme.stopMiddle,
      );
      markers.add(Marker(
        markerId: MarkerId('${stop.order}_${stop.activity.title}'),
        position: point,
        icon: icon,
        infoWindow: InfoWindow(
          title: '${stop.order}. ${stop.activity.title}',
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
                          Text(
                            stop.activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
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