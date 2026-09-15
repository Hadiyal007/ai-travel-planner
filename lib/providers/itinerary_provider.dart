import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/trip.dart';
import '../models/itinerary.dart';
import '../services/itinerary_service.dart';

class ItineraryState {
  final Trip? trip;
  final Itinerary? itinerary;
  final bool isLoading;
  final String? error;

  const ItineraryState({this.trip, this.itinerary, this.isLoading = false, this.error});

  ItineraryState copyWith({
    Trip? trip,
    Itinerary? itinerary,
    bool? isLoading,
    String? error,
  }) {
    return ItineraryState(
      trip: trip ?? this.trip,
      itinerary: itinerary ?? this.itinerary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ItineraryNotifier extends StateNotifier<ItineraryState> {
  final ItineraryService _service;
  ItineraryNotifier(this._service) : super(const ItineraryState());

  Future<void> generate(Trip trip) async {
    state = state.copyWith(trip: trip, isLoading: true, error: null);
    try {
      final itinerary = await _service.generateMockItinerary(trip);
      state = state.copyWith(itinerary: itinerary, isLoading: false);
    } catch (e) {
      state = ItineraryState(trip: trip, isLoading: false, error: 'Failed to generate itinerary');
    }
  }
}

final itineraryServiceProvider = Provider((ref) => ItineraryService());

final itineraryProvider =
StateNotifierProvider<ItineraryNotifier, ItineraryState>((ref) {
  return ItineraryNotifier(ref.read(itineraryServiceProvider));
});