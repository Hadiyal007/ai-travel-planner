import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'destination_detail_screen.dart';
import '../app/theme.dart';
import '../models/destination.dart';
import '../models/trip.dart';
import '../widgets/destination_card.dart';
import '../app/routes.dart';
import '../firebase/firestore_providers.dart';
import '../firebase/auth_providers.dart';
import '../firebase/trip_providers.dart';
import 'saved_itinerary_screen.dart';

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
            _HeroBanner(
              onPlan: () => Navigator.pushNamed(context, AppRoutes.createTrip),
            ),
            const SizedBox(height: 28),
            Text('Popular Destinations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Real-time Firestore data
            ref.watch(popularDestinationsProvider).when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Error: $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (destinations) {
                if (destinations.isEmpty) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: Text('No destinations available')),
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DestinationDetailScreen(destination: destination),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 28),
            Text('Your Trips', style: Theme.of(context).textTheme.titleLarge),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (trips) {
                if (trips.isEmpty) {
                  return _EmptyTripsState(
                    onCreate: () => Navigator.pushNamed(context, AppRoutes.createTrip),
                  );
                }
                return Column(
                  children: trips.map((trip) => _BoardingPassTripCard(trip: trip)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Opening hero: the one bold gesture on this screen, per the app's
/// design direction — an indigo "travel document" panel that carries
/// the greeting and the single most important action, rather than the
/// greeting sitting as plain text loose on the page.
class _HeroBanner extends StatelessWidget {
  final VoidCallback onPlan;

  const _HeroBanner({required this.onPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.indigoNight, AppTheme.indigoNightLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to next?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Let AI plan your perfect trip, stop by stop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPlan,
            icon: const Icon(Icons.add),
            label: const Text('Plan a New Trip'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}

/// A saved trip rendered as a boarding-pass stub: the route as the main
/// "flight" line, a dashed perforation, and a stub showing trip length —
/// encoding real information (route, duration) in a travel-native form
/// rather than a plain generic list tile.
class _BoardingPassTripCard extends StatelessWidget {
  final Trip trip;

  const _BoardingPassTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final nights = trip.durationInDays - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SavedItineraryScreen(trip: trip)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hairline),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.flight_takeoff, size: 14, color: AppTheme.inkMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${_fmt(trip.startDate)} – ${_fmt(trip.endDate)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppTheme.inkMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${trip.source} → ${trip.destination}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${trip.travellers} traveller${trip.travellers == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _Perforation(),
                  Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$nights',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.marigold,
                          ),
                        ),
                        Text(
                          nights == 1 ? 'night' : 'nights',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right, size: 18, color: AppTheme.inkMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// A vertical dashed line simulating a boarding-pass perforation between
/// the route section and the "stub". Drawn with a CustomPainter rather
/// than LayoutBuilder: this sits inside an IntrinsicHeight, and
/// LayoutBuilder can't report intrinsic dimensions (it throws during
/// layout, which left the whole "Your Trips" list blank).
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.hairline
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      final end = y + dash > size.height ? size.height : y + dash;
      canvas.drawLine(Offset(0, y), Offset(0, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        color: AppTheme.indigoNight.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppTheme.marigold),
          const SizedBox(height: 8),
          Text('No trips yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Create your first AI-planned itinerary',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onCreate, child: const Text('Start Planning')),
        ],
      ),
    );
  }
}