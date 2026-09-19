import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import 'auth_providers.dart';
import 'trip_service.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService();
});

/// The signed-in user's saved trips, newest first. Re-subscribes
/// automatically when the signed-in user changes (including to
/// signed-out, where it emits an empty list rather than erroring).
final userTripsProvider = StreamProvider<List<Trip>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value(<Trip>[]);

  final tripService = ref.watch(tripServiceProvider);
  return tripService.getUserTrips(userId);
});