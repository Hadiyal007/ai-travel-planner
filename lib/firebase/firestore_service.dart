import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Destination>> getPopularDestinations() {
    return _firestore
        .collection('popular_destinations')
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Destination.fromMap(doc.data()))
          .toList();
    });
  }
}