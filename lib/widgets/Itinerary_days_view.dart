import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../firebase/trip_service.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';
import '../screens/day_map_screen.dart';

/// Renders an [Itinerary] as a day-tabbed list of activity cards. Used by
/// both [ItineraryScreen] (right after AI generation) and
/// [SavedItineraryScreen] (viewing a previously saved trip), so the
/// tab/card UI only lives in one place.
class ItineraryDaysView extends StatelessWidget {
  final Itinerary itinerary;

  /// The saved trip's Firestore document id, if this itinerary has been
  /// saved yet. When present, newly-geocoded activity coordinates get
  /// written back to that trip so the same activity is never re-geocoded
  /// on a later visit. Left null for an itinerary that hasn't been saved
  /// yet (nothing to write back to) — the map still works, it just
  /// re-geocodes on every visit until the trip is saved.
  final String? tripId;

  const ItineraryDaysView({super.key, required this.itinerary, this.tripId});

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

  /// One accent per activity type, reusing the app's four accent colors
  /// (there are more activity types than accents, so a couple share —
  /// still far more distinctive than one flat color for everything).
  Color _colorFor(ActivityType type) {
    switch (type) {
      case ActivityType.meal:
        return AppTheme.chili;
      case ActivityType.sightseeing:
        return AppTheme.banyan;
      case ActivityType.travel:
        return AppTheme.indigoNight;
      case ActivityType.checkin:
        return AppTheme.marigold;
      case ActivityType.leisure:
        return AppTheme.banyan;
      case ActivityType.adventure:
        return AppTheme.chili;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: itinerary.days.length,
      child: Column(
        children: [
          const Divider(height: 1),
          TabBar(
            isScrollable: true,
            tabs: itinerary.days
                .map((d) => Tab(text: 'Day ${d.dayNumber}'))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: itinerary.days.map((day) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            '${day.activities.length} stops',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.inkMuted),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayMapScreen(
                                  day: day,
                                  destination: itinerary.destination,
                                  onActivitiesResolved: tripId == null
                                      ? null
                                      : (resolvedActivities) {
                                    final updatedDays = itinerary.days
                                        .map((d) => d.dayNumber == day.dayNumber
                                        ? ItineraryDay(
                                      dayNumber: d.dayNumber,
                                      activities: resolvedActivities,
                                    )
                                        : d)
                                        .toList();
                                    TripService().updateItinerary(
                                      tripId!,
                                      Itinerary(
                                        destination: itinerary.destination,
                                        days: updatedDays,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('View on Map'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: day.activities.length,
                        itemBuilder: (context, index) {
                          final activity = day.activities[index];
                          final isLast = index == day.activities.length - 1;
                          return _TimelineRow(
                            icon: _iconFor(activity.type),
                            color: _colorFor(activity.type),
                            isLast: isLast,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.time,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppTheme.inkMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activity.title,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (activity.notes != null && activity.notes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.notes!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.inkMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a vertical timeline: an icon dot, a connecting line down to
/// the next row (omitted for the last), and the activity's content beside
/// it. Encodes the day's running order visually, matching the numbered
/// stops on the map view of the same day.
class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLast;
  final Widget child;

  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppTheme.hairline),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}