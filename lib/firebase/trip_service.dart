import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/itinerary.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Saves [trip] to the `trips` collection tagged with [userId], so
  /// Firestore rules can later restrict each document to
  /// `resource.data.userId == request.auth.uid`. If [itinerary] is
  /// provided (the AI-generated plan the user reviewed), it's nested
  /// under an `itinerary` field on the same document rather than a
  /// separate collection — one doc per trip keeps reads simple.
  Future<void> saveTrip(Trip trip, String userId, {Itinerary? itinerary}) async {
    await _firestore.collection('trips').add({
      ...trip.toMap(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      if (itinerary != null) 'itinerary': itinerary.toMap(),
    });
  }

  /// Live stream of [userId]'s saved trips, newest first. Requires a
  /// composite index (userId equality + createdAt order) — Firestore
  /// will throw with a console link to create it on first run if it's
  /// missing.
  Stream<List<Trip>> getUserTrips(String userId) {
    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Trip.fromMap(doc.data(), id: doc.id))
        .toList());
  }
}