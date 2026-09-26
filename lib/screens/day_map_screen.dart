import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';
import '../services/geocoding_service.dart';

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
/// green for the first stop of the day, red for the last, blue in between.
class DayMapScreen extends StatefulWidget {
  final ItineraryDay day;
  final String destination;

  const DayMapScreen({super.key, required this.day, required this.destination});

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

  /// Builds the geocoding query for one activity. Most activities (meals,
  /// check-ins, sightseeing) have a title that's already a place name, so
  /// appending the destination for disambiguation is enough. `travel`
  /// activities are different: their title is a sentence describing a
  /// journey (e.g. "Travel from Nadiad to Surat by Shatabdi Express"),
  /// which Places Text Search can't match as-is — so pull out the "to X"
  /// destination and geocode that instead, falling back to the day's
  /// destination city if no "to X" is found.
  String _queryFor(Activity activity) {
    if (activity.type == ActivityType.travel) {
      final match = RegExp(r'\bto\s+(.+?)(?:\s+(?:by|via)\s+.+)?$',
          caseSensitive: false)
          .firstMatch(activity.title);
      final place = match?.group(1)?.trim();
      if (place != null && place.isNotEmpty) {
        return '$place, ${widget.destination}';
      }
      return widget.destination;
    }
    return '${activity.title}, ${widget.destination}';
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
    final results = await _geocodeAll(activities.map(_queryFor).toList());

    final stops = <_Stop>[];
    final points = <LatLng>[];
    var unresolved = 0;

    for (var i = 0; i < activities.length; i++) {
      final point = results[i];
      stops.add(_Stop(activity: activities[i], order: i + 1, point: point));
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
            ? Colors.green.shade600
            : isLast
            ? Colors.red.shade600
            : Colors.blue.shade600,
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
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(
                '$_unresolvedCount location${_unresolvedCount == 1 ? '' : 's'} '
                    'couldn\'t be found and ${_unresolvedCount == 1 ? 'is' : 'are'} not shown',
                style: const TextStyle(fontSize: 12),
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
              ? Colors.green.shade600
              : isLast
              ? Colors.red.shade600
              : Colors.blue.shade600;

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