import 'activity.dart';

class ItineraryDay {
  final int dayNumber;
  final List<Activity> activities;

  const ItineraryDay({required this.dayNumber, required this.activities});

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'activities': activities.map((a) => a.toMap()).toList(),
    };
  }

  factory ItineraryDay.fromMap(Map<String, dynamic> map) {
    return ItineraryDay(
      dayNumber: map['dayNumber'] ?? 0,
      activities: (map['activities'] as List<dynamic>? ?? [])
          .map((a) => Activity.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
    );
  }
}

class Itinerary {
  final String destination;
  final List<ItineraryDay> days;

  const Itinerary({required this.destination, required this.days});

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'days': days.map((d) => d.toMap()).toList(),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      destination: map['destination'] ?? '',
      days: (map['days'] as List<dynamic>? ?? [])
          .map((d) => ItineraryDay.fromMap(Map<String, dynamic>.from(d)))
          .toList(),
    );
  }
}