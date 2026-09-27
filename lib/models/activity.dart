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

  const Activity({
    required this.time,
    required this.title,
    required this.type,
    this.notes,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Activity copyWith({
    String? time,
    String? title,
    ActivityType? type,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return Activity(
      time: time ?? this.time,
      title: title ?? this.title,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
    );
  }
}