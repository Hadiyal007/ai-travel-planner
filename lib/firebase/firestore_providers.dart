import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/destination.dart';
import 'firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final popularDestinationsProvider =
StreamProvider<List<Destination>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.getPopularDestinations();
});