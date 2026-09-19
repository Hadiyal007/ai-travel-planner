import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Saves [trip] to the `trips` collection tagged with [userId], so
  /// Firestore rules can later restrict each document to
  /// `resource.data.userId == request.auth.uid`.
  Future<void> saveTrip(Trip trip, String userId) async {
    await _firestore.collection('trips').add({
      ...trip.toMap(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
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