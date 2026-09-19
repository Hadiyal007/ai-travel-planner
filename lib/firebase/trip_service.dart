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
}