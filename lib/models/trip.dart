enum TravelStyle { relaxed, balanced, packed }

enum Interest { beaches, food, adventure, culture, nightlife, nature, shopping, history }

class Trip {
  final String source;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travellers;
  final double budget;
  final List<Interest> interests;
  final TravelStyle travelStyle;

  const Trip({
    required this.source,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.budget,
    required this.interests,
    required this.travelStyle,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Plain-field map for Firestore. Enum fields are stored as their
  /// name (e.g. 'balanced') so they read back without relying on enum
  /// index order. userId/createdAt are added by TripService, not here,
  /// so this model stays free of any Firestore-specific types.
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
    };
  }

  Trip copyWith({
    String? source,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? travellers,
    double? budget,
    List<Interest>? interests,
    TravelStyle? travelStyle,
  }) {
    return Trip(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travellers: travellers ?? this.travellers,
      budget: budget ?? this.budget,
      interests: interests ?? this.interests,
      travelStyle: travelStyle ?? this.travelStyle,
    );
  }
}