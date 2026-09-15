import '../models/trip.dart';
import '../models/itinerary.dart';
import '../models/activity.dart';

/// Generates a mock itinerary locally. In Phase 9 this gets replaced by a
/// call to the AI backend, but the return shape (Itinerary) stays the same,
/// so the UI won't need to change.
class ItineraryService {
  Future<Itinerary> generateMockItinerary(Trip trip) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay

    final days = List.generate(trip.durationInDays, (index) {
      final dayNumber = index + 1;
      return ItineraryDay(
        dayNumber: dayNumber,
        activities: _buildDayActivities(trip, dayNumber),
      );
    });

    return Itinerary(destination: trip.destination, days: days);
  }

  List<Activity> _buildDayActivities(Trip trip, int dayNumber) {
    final activities = <Activity>[
      const Activity(time: '09:00', title: 'Breakfast', type: ActivityType.meal),
    ];

    if (dayNumber == 1) {
      activities.add(Activity(
        time: '10:00',
        title: 'Explore ${trip.destination} — main attraction',
        type: ActivityType.sightseeing,
      ));
      activities.add(const Activity(time: '13:00', title: 'Lunch', type: ActivityType.meal));
      activities.add(const Activity(
        time: '15:00',
        title: 'Hotel Check-in',
        type: ActivityType.checkin,
      ));
    } else {
      activities.add(Activity(
        time: '10:00',
        title: 'Visit local spot #$dayNumber',
        type: ActivityType.sightseeing,
      ));
      activities.add(const Activity(time: '13:00', title: 'Lunch', type: ActivityType.meal));
      activities.add(Activity(
        time: '15:30',
        title: trip.travelStyle.name == 'packed'
            ? 'Second attraction stop'
            : 'Leisure time',
        type: trip.travelStyle.name == 'packed'
            ? ActivityType.sightseeing
            : ActivityType.leisure,
      ));
    }

    activities.add(const Activity(time: '19:30', title: 'Dinner', type: ActivityType.meal));
    return activities;
  }
}