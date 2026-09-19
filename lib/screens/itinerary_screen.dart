import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/itinerary_provider.dart';
import '../models/activity.dart';
//import '../app/routes.dart';
import '../firebase/auth_providers.dart';
import '../firebase/trip_providers.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  bool _isSaving = false;

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

  Future<void> _saveTrip() async {
    final state = ref.read(itineraryProvider);
    final trip = state.trip;
    if (trip == null) return;

    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in again to save this trip')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(tripServiceProvider).saveTrip(trip, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trip saved!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save trip: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTrip,
                      icon: _isSaving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Trip'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  //   child: OutlinedButton.icon(
                  //     onPressed: () =>
                  //         Navigator.pushNamed(context, AppRoutes.tripSummary),
                  //     icon: const Icon(Icons.check_circle_outline),
                  //     label: const Text('View Trip Summary'),
                  //     style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}