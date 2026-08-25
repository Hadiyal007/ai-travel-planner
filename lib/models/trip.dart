enum TravelStyle { relaxed, balanced, packed }

enum Interest { beaches, food, adventure, culture, nightlife, nature, shopping, history }

class Trip {
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travellers;
  final double budget;
  final List<Interest> interests;
  final TravelStyle travelStyle;

  const Trip({
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travellers,
    required this.budget,
    required this.interests,
    required this.travelStyle,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? travellers,
    double? budget,
    List<Interest>? interests,
    TravelStyle? travelStyle,
  }) {
    return Trip(
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