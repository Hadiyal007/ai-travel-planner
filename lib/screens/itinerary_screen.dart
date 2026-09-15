import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/itinerary_provider.dart';
import '../models/activity.dart';
import '../app/routes.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(state.trip?.destination ?? 'Itinerary')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    Text(state.error!),
                  ],
                ),
              );
            }
            final itinerary = state.itinerary;
            if (itinerary == null) {
              return const Center(child: Text('No itinerary yet'));
            }
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.tripSummary),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('View Trip Summary'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}