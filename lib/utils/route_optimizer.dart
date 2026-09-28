import 'dart:math' as math;

import '../models/activity.dart';

/// Reorders a day's flexible stops so the traveller covers less ground.
///
/// Only sightseeing / leisure / adventure stops that have coordinates are
/// movable, and only *within* a run of consecutive movable stops. Anything
/// tied to a time or place stays exactly where it is: meals, check-ins,
/// travel legs, stops without coordinates, and stops whose title says when
/// they happen ("sunset", "morning", "night", ...). Each run is ordered
/// to minimise the walking/driving distance from the stop before it,
/// through the run, to the stop after it — brute-forced (exactly optimal)
/// for runs of up to [_maxExactRun] stops, nearest-neighbour beyond that.
///
/// Times stay in their original slots (the run's times are re-assigned in
/// order), so a day's schedule still reads 10:00, 11:30, 14:00 ... after
/// reordering. Distances are straight-line (haversine), not road distance.
class RouteOptimizer {
  RouteOptimizer._();

  static const _maxExactRun = 7;
  static const _flexible = {
    ActivityType.sightseeing,
    ActivityType.leisure,
    ActivityType.adventure,
  };
  static final _timeBound = RegExp(
    r'sunrise|sunset|dawn|dusk|morning|evening|night|midnight|breakfast|lunch|dinner',
    caseSensitive: false,
  );

  static bool _movable(Activity a) =>
      a.hasLocation && _flexible.contains(a.type) && !_timeBound.hasMatch(a.title);

  /// Returns a new list of the same length; unchanged if no run of two or
  /// more movable stops exists or reordering wouldn't shorten the route.
  static List<Activity> optimize(List<Activity> input) {
    final result = List<Activity>.from(input);
    var i = 0;
    while (i < result.length) {
      if (!_movable(result[i])) {
        i++;
        continue;
      }
      var j = i;
      while (j < result.length && _movable(result[j])) {
        j++;
      }
      if (j - i >= 2) {
        final run = result.sublist(i, j);
        final times = run.map((a) => a.time).toList();
        final ordered = _bestOrder(run, _locatedBefore(result, i), _locatedAfter(result, j - 1));
        for (var k = 0; k < ordered.length; k++) {
          result[i + k] = ordered[k].copyWith(time: times[k]);
        }
      }
      i = j;
    }
    return result;
  }

  /// Total straight-line length in km of [activities] visited in order
  /// (only stops with coordinates count). Handy for showing the saving.
  static double totalDistanceKm(List<Activity> activities) {
    final pts = activities.where((a) => a.hasLocation).map(_pt).toList();
    var sum = 0.0;
    for (var k = 1; k < pts.length; k++) {
      sum += _km(pts[k - 1], pts[k]);
    }
    return sum;
  }

  static _P? _locatedBefore(List<Activity> list, int index) {
    for (var k = index - 1; k >= 0; k--) {
      if (list[k].hasLocation) return _pt(list[k]);
    }
    return null;
  }

  static _P? _locatedAfter(List<Activity> list, int index) {
    for (var k = index + 1; k < list.length; k++) {
      if (list[k].hasLocation) return _pt(list[k]);
    }
    return null;
  }

  static List<Activity> _bestOrder(List<Activity> run, _P? start, _P? end) {
    double cost(List<Activity> order) {
      var sum = 0.0;
      _P? prev = start;
      for (final a in order) {
        final p = _pt(a);
        if (prev != null) sum += _km(prev, p);
        prev = p;
      }
      if (prev != null && end != null) sum += _km(prev, end);
      return sum;
    }

    final originalCost = cost(run);
    List<Activity> best;

    if (run.length <= _maxExactRun) {
      best = run;
      var bestCost = originalCost;
      void permute(List<Activity> current, List<Activity> remaining) {
        if (remaining.isEmpty) {
          final c = cost(current);
          if (c < bestCost - 1e-9) {
            bestCost = c;
            best = List<Activity>.from(current);
          }
          return;
        }
        for (var k = 0; k < remaining.length; k++) {
          final next = remaining[k];
          permute(
            [...current, next],
            [...remaining.sublist(0, k), ...remaining.sublist(k + 1)],
          );
        }
      }
      permute(const [], run);
    } else {
      // Greedy nearest-neighbour for long runs.
      final remaining = List<Activity>.from(run);
      final order = <Activity>[];
      _P cursor = start ?? _pt(remaining.first);
      while (remaining.isNotEmpty) {
        final from = cursor;
        remaining.sort((a, b) => _km(from, _pt(a)).compareTo(_km(from, _pt(b))));
        final next = remaining.removeAt(0);
        order.add(next);
        cursor = _pt(next);
      }
      best = cost(order) < originalCost - 1e-9 ? order : run;
    }
    return best;
  }

  static _P _pt(Activity a) => _P(a.latitude!, a.longitude!);

  static double _km(_P a, _P b) {
    const r = 6371.0;
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

class _P {
  final double lat;
  final double lng;
  const _P(this.lat, this.lng);
}