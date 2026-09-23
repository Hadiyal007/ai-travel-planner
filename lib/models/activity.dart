enum ActivityType { meal, sightseeing, travel, checkin, leisure, adventure }

class Activity {
  final String time; // e.g. "09:00"
  final String title;
  final ActivityType type;
  final String? notes;

  const Activity({
    required this.time,
    required this.title,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'type': type.name,
      'notes': notes,
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
    );
  }
}