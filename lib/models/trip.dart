import 'package:cloud_firestore/cloud_firestore.dart';
import 'itinerary.dart';

enum TravelStyle { relaxed, balanced, packed }

enum Interest { beaches, food, adventure, culture, nightlife, nature, shopping, history }

class Trip {
  final String? id;
  final String source;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travellers;
  final double budget;
  final List<Interest> interests;
  final TravelStyle travelStyle;
  final String? specialRequests;
  final Itinerary? itinerary;

  const Trip({
    this.id,
    required this.source,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.budget,
    required this.interests,
    required this.travelStyle,
    this.specialRequests,
    this.itinerary,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  factory Trip.fromMap(Map<String, dynamic> map, {required String id}) {
    return Trip(
      id: id,
      source: map['source'] ?? '',
      destination: map['destination'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      travellers: map['travellers'] ?? 1,
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
      interests: (map['interests'] as List<dynamic>? ?? [])
          .map((name) => Interest.values.firstWhere(
            (interest) => interest.name == name,
        orElse: () => Interest.culture,
      ))
          .toList(),
      travelStyle: TravelStyle.values.firstWhere(
            (style) => style.name == map['travelStyle'],
        orElse: () => TravelStyle.balanced,
      ),
      specialRequests: map['specialRequests'] as String?,
      // Older trips saved before itinerary persistence was added won't
      // have this field — Itinerary? stays null and the UI shows a
      // "not saved" message instead of crashing.
      itinerary: map['itinerary'] != null
          ? Itinerary.fromMap(Map<String, dynamic>.from(map['itinerary'] as Map))
          : null,
    );
  }

  // Deliberately does NOT include `itinerary` — TripService.saveTrip adds
  // it separately as its own field only when one is passed in, so trip
  // creation (no itinerary yet) and itinerary save stay independent calls.
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'travellers': travellers,
      'budget': budget,
      'interests': interests.map((interest) => interest.name).toList(),
      'travelStyle': travelStyle.name,
      'specialRequests': specialRequests,
    };
  }

  Trip copyWith({
    String? id,
    String? source,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? travellers,
    double? budget,
    List<Interest>? interests,
    TravelStyle? travelStyle,
    String? specialRequests,
    Itinerary? itinerary,
  }) {
    return Trip(
      id: id ?? this.id,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travellers: travellers ?? this.travellers,
      budget: budget ?? this.budget,
      interests: interests ?? this.interests,
      travelStyle: travelStyle ?? this.travelStyle,
      specialRequests: specialRequests ?? this.specialRequests,
      itinerary: itinerary ?? this.itinerary,
    );
  }
}