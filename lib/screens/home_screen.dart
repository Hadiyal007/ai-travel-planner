import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/destination.dart';
import '../models/trip.dart';
import '../widgets/destination_card.dart';
import '../app/routes.dart';
import '../firebase/firestore_providers.dart';
import '../firebase/auth_providers.dart';
import '../firebase/trip_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Travel Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.authGate,
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Where to next?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Let AI plan your perfect trip',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.createTrip),
              icon: const Icon(Icons.add),
              label: const Text('Plan a New Trip'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Popular Destinations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // Real-time Firestore data
            ref.watch(popularDestinationsProvider).when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (destinations) {
                if (destinations.isEmpty) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('No destinations available'),
                    ),
                  );
                }

                return SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final destination = destinations[index];

                      return DestinationCard(
                        destination: destination,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.createTrip,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 28),
            Text(
              'Your Trips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ref.watch(userTripsProvider).when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Error loading trips: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (trips) {
                if (trips.isEmpty) {
                  return _EmptyTripsState(
                    onCreate: () =>
                        Navigator.pushNamed(context, AppRoutes.createTrip),
                  );
                }
                return Column(
                  children:
                  trips.map((trip) => _TripListTile(trip: trip)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  final Trip trip;

  const _TripListTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.card_travel),
        title: Text('${trip.source} → ${trip.destination}'),
        subtitle: Text(
          '${_fmt(trip.startDate)} – ${_fmt(trip.endDate)} · '
              '${trip.travellers} traveller${trip.travellers == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// Shown when the signed-in user has no saved trips yet (userTripsProvider
/// returned an empty list).
class _EmptyTripsState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTripsState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.map_outlined,
            size: 40,
            color: Colors.black38,
          ),
          const SizedBox(height: 8),
          const Text(
            'No trips yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create your first AI-planned itinerary',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('Start Planning'),
          ),
        ],
      ),
    );
  }
}