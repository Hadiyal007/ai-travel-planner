import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/trip.dart';
import '../widgets/itinerary_days_view.dart';
import 'budget_summary_screen.dart';

/// Shows a previously saved [Trip]'s itinerary, read-only — reached by
/// tapping a trip on Home's "Your Trips" list. Unlike [ItineraryScreen],
/// this doesn't touch [itineraryProvider] (that's for the active
/// generate-then-save flow); it just renders whatever `trip.itinerary`
/// Firestore gave back.
class SavedItineraryScreen extends StatelessWidget {
  final Trip trip;

  const SavedItineraryScreen({super.key, required this.trip});

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final itinerary = trip.itinerary;

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip.source} → ${trip.destination}'),
        actions: [
          if (itinerary != null)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Budget Summary',
              color: AppTheme.indigoNight,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetSummaryScreen(trip: trip, itinerary: itinerary),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: itinerary == null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_busy, size: 40, color: Colors.black38),
                const SizedBox(height: 12),
                const Text(
                  'No saved itinerary for this trip',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(trip.startDate)} – ${_fmt(trip.endDate)} · '
                      '${trip.travellers} traveller${trip.travellers == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        )
            : ItineraryDaysView(itinerary: itinerary, tripId: trip.id),
      ),
    );
  }
}