import 'activity.dart';

class ItineraryDay {
  final int dayNumber;
  final List<Activity> activities;

  const ItineraryDay({required this.dayNumber, required this.activities});
}

class Itinerary {
  final String destination;
  final List<ItineraryDay> days;

  const Itinerary({required this.destination, required this.days});
}