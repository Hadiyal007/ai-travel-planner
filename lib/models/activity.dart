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
}