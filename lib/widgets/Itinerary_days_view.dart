import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';

/// Renders an [Itinerary] as a day-tabbed list of activity cards. Used by
/// both [ItineraryScreen] (right after AI generation) and
/// [SavedItineraryScreen] (viewing a previously saved trip), so the
/// tab/card UI only lives in one place.
class ItineraryDaysView extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryDaysView({super.key, required this.itinerary});

  IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.meal:
        return Icons.restaurant;
      case ActivityType.sightseeing:
        return Icons.photo_camera_outlined;
      case ActivityType.travel:
        return Icons.directions_car_outlined;
      case ActivityType.checkin:
        return Icons.hotel_outlined;
      case ActivityType.leisure:
        return Icons.self_improvement;
      case ActivityType.adventure:
        return Icons.hiking;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: itinerary.days.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.black54,
            tabs: itinerary.days
                .map((d) => Tab(text: 'Day ${d.dayNumber}'))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: itinerary.days.map((day) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: day.activities.length,
                  itemBuilder: (context, index) {
                    final activity = day.activities[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(_iconFor(activity.type),
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(activity.title),
                        subtitle: Text(activity.time),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}