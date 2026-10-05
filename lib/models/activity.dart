enum ActivityType { meal, sightseeing, travel, checkin, leisure, adventure }

class Activity {
  final String time; // e.g. "09:00"
  final String title;
  final ActivityType type;
  final String? notes;

  /// Coordinates resolved by [GeocodingService], persisted here so a
  /// saved trip only ever needs to be geocoded once — re-opening
  /// "View on Map" reads these instead of calling the Places API again.
  /// Null means "not yet resolved" (or resolution failed last time),
  /// not "no location".
  final double? latitude;
  final double? longitude;

  /// AI-estimated cost in ₹ for this one activity, total across all
  /// travellers on the trip (not per-person) — so summing every
  /// activity's estimatedCost approximates the whole trip's cost,
  /// directly comparable to Trip.budget. Null means the AI didn't
  /// provide one (older saved trips, or occasionally a free activity
  /// where the AI just omitted it) rather than "costs ₹0" — the budget
  /// summary screen counts these separately instead of silently
  /// treating them as free.
  final double? estimatedCost;

  const Activity({
    required this.time,
    required this.title,
    required this.type,
    this.notes,
    this.latitude,
    this.longitude,
    this.estimatedCost,
  });

  bool get hasLocation => latitude != null && longitude != null;

  /// Returns a copy with latitude/longitude explicitly cleared. Can't be
  /// done via [copyWith] — there, passing null for an argument means
  /// "keep the existing value," so there's no way to use it to actually
  /// null something out. Used when a previously-stored geocode result
  /// turns out to be implausible (e.g. resolved to a same-named place
  /// in a different country entirely) and needs to be discarded rather
  /// than kept.
  Activity clearLocation() {
    return Activity(
      time: time,
      title: title,
      type: type,
      notes: notes,
      estimatedCost: estimatedCost,
    );
  }

  Activity copyWith({
    String? time,
    String? title,
    ActivityType? type,
    String? notes,
    double? latitude,
    double? longitude,
    double? estimatedCost,
  }) {
    return Activity(
      time: time ?? this.time,
      title: title ?? this.title,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'type': type.name,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedCost': estimatedCost,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      time: map['time'] ?? '',
      title: map['title'] ?? '',
      type: ActivityType.values.firstWhere(
            (t) => t.name == map['type'],
        orElse: () => ActivityType.sightseeing,
      ),
      notes: map['notes'] as String?,
      // Older saved trips won't have these fields — stays null and
      // DayMapScreen just geocodes them the first time they're viewed.
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble(),
    );
  }
}