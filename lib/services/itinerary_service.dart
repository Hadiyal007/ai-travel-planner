import '../models/trip.dart';
import '../models/itinerary.dart';
import '../models/activity.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

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

  /// Real AI-generated itinerary via Google Gemini. Same return shape
  /// (Itinerary) as generateMockItinerary, so ItineraryScreen needs no changes.
  Future<Itinerary> generateAiItinerary(Trip trip) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
    );

    final tripSummary = {
      'source': trip.source,
      'destination': trip.destination,
      'startDate': trip.startDate.toIso8601String(),
      'endDate': trip.endDate.toIso8601String(),
      'durationInDays': trip.durationInDays,
      'travellers': trip.travellers,
      'budget': trip.budget,
      'interests': trip.interests.map((i) => i.name).toList(),
      'travelStyle': trip.travelStyle.name,
    };

    final prompt = '''
You are an expert local travel planner for ${trip.destination}. Design a detailed, realistic, NON-REPETITIVE day-by-day itinerary.

TRIP DETAILS (use every one of these to shape the plan, don't just acknowledge them):
- From ${trip.source} to ${trip.destination}
- ${trip.durationInDays} days total
- ${trip.travellers} traveller(s)
- Total budget: ₹${trip.budget} for the ENTIRE trip, for all ${trip.travellers} traveller(s), across all ${trip.durationInDays} days
- Interests: ${trip.interests.map((i) => i.name).join(', ')}
- Travel style: ${trip.travelStyle.name}

BUDGET RULE: Divide ₹${trip.budget} across ${trip.durationInDays} days and ${trip.travellers} traveller(s) mentally before planning. If the daily per-person budget is low, choose budget dhabas/street food and free or low-cost attractions. If it's generous, include mid-range or premium restaurants and paid experiences. Make this visibly reflected in the specific places you choose, not stated as a note.

TRAVEL STYLE RULE:
- relaxed: 3-4 activities/day max, long breaks, slower pace
- balanced: 4-5 activities/day, mixed pace
- packed: 6+ activities/day, tightly scheduled

VARIETY RULE (critical): No two days should look alike. Each day must visit DIFFERENT named places — do not repeat the same attraction, restaurant, or generic activity type in the same slot every day. Rotate through different real, specific, well-known (or locally authentic) places in ${trip.destination} that match the traveller's interests.

NAMING RULE: Every activity must name a REAL, SPECIFIC, well-known place in ${trip.destination} — an actual named beach, fort, market, museum, trail, viewpoint, etc. For every meal (breakfast/lunch/dinner), name a REAL or realistic-sounding restaurant/cafe/hotel dining option appropriate to the budget tier, not just "Lunch" or "Dinner." Put the specific place name in the "title" field itself (e.g. "Lunch at Britto's Shack, Baga Beach" not "Lunch").

Use the "notes" field to add a short useful detail: why this place fits their interests, an approximate cost, or a tip (e.g. "Try the seafood platter, ~₹400/person — matches your food interest").

Return ONLY JSON, no markdown, no extra text, matching this exact shape:
{
  "destination": "string",
  "days": [
    {
      "dayNumber": 1,
      "activities": [
        {"time": "09:00", "title": "string", "type": "meal|sightseeing|travel|checkin|leisure|adventure", "notes": "string or null"}
      ]
    }
  ]
}
Generate exactly ${trip.durationInDays} day objects, each with genuinely different activities from every other day.
''';
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': ApiKeys.geminiApiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'responseMimeType': 'application/json','temperature': 0.9,}
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
    final json = jsonDecode(rawText) as Map<String, dynamic>;

    return Itinerary(
      destination: json['destination'] as String,
      days: (json['days'] as List).map((d) {
        return ItineraryDay(
          dayNumber: d['dayNumber'] as int,
          activities: (d['activities'] as List).map((a) {
            return Activity(
              time: a['time'] as String,
              title: a['title'] as String,
              type: ActivityType.values.firstWhere(
                    (t) => t.name == a['type'],
                orElse: () => ActivityType.leisure,
              ),
              notes: a['notes'] as String?,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}