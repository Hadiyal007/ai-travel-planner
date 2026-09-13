import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/destination.dart';
import '../widgets/destination_card.dart';
import '../app/routes.dart';
import '../firebase/firestore_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Travel Planner')),
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
            _EmptyTripsState(
              onCreate: () =>
                  Navigator.pushNamed(context, AppRoutes.createTrip),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the user has no saved trips yet. Will be replaced by a real
/// list once local/Firebase trip storage exists (Phase 5 / 6).
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