import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination.dart';
import 'destination_seed_data.dart';

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

  /// One-time (safe to call repeatedly) seed of `popular_destinations`
  /// from [destinationSeedData] — adds only the destinations that
  /// aren't already there (matched by name, case-insensitively), so
  /// running it again after adding more destinations to that list won't
  /// create duplicates of ones you already have. New entries are appended
  /// after the current highest `sortOrder` rather than a hardcoded
  /// number, so this doesn't fight with whatever's already seeded.
  ///
  /// Returns how many destinations were actually added.
  // Future<int> seedPopularDestinations() async {
  //   final collection = _firestore.collection('popular_destinations');
  //   final existing = await collection.get();
  //
  //   final existingNames = existing.docs
  //       .map((doc) => (doc.data()['name'] as String? ?? '').toLowerCase())
  //       .toSet();
  //
  //   var nextSortOrder = existing.docs.fold<int>(0, (max, doc) {
  //     final order = (doc.data()['sortOrder'] as num?)?.toInt() ?? 0;
  //     return order > max ? order : max;
  //   }) +
  //       1;
  //
  //   final batch = _firestore.batch();
  //   var added = 0;
  //
  //   for (final destination in destinationSeedData) {
  //     final name = destination['name'] as String;
  //     if (existingNames.contains(name.toLowerCase())) continue;
  //
  //     batch.set(collection.doc(), {
  //       ...destination,
  //       'sortOrder': nextSortOrder,
  //       'galleryImages': destination['galleryImages'] ?? <String>[],
  //     });
  //     nextSortOrder++;
  //     added++;
  //   }
  //
  //   if (added > 0) {
  //     await batch.commit();
  //   }
  //   return added;
  // }
  //
  // /// Overwrites `imageUrl` (and `galleryImages`, if set) on destinations
  // /// that already exist in Firestore, matched by name against
  // /// [destinationSeedData]. Doesn't add new destinations — pair with
  // /// [seedPopularDestinations] for that — and doesn't touch any
  // /// destination whose name isn't in the current seed list.
  // ///
  // /// Use this after editing the placeholder `imageUrl` values in
  // /// destination_seed_data.dart with real photo URLs, to push that
  // /// change onto destinations you already seeded once.
  // ///
  // /// Returns how many destinations were actually updated.
  // Future<int> updatePopularDestinationImages() async {
  //   final collection = _firestore.collection('popular_destinations');
  //   final existing = await collection.get();
  //
  //   final seedByName = {
  //     for (final destination in destinationSeedData)
  //       (destination['name'] as String).toLowerCase(): destination,
  //   };
  //
  //   final batch = _firestore.batch();
  //   var updated = 0;
  //
  //   for (final doc in existing.docs) {
  //     final name = (doc.data()['name'] as String? ?? '').toLowerCase();
  //     final seed = seedByName[name];
  //     if (seed == null) continue;
  //
  //     batch.update(doc.reference, {
  //       'imageUrl': seed['imageUrl'],
  //       if (seed['galleryImages'] != null) 'galleryImages': seed['galleryImages'],
  //     });
  //     updated++;
  //   }
  //
  //   if (updated > 0) {
  //     await batch.commit();
  //   }
  //   return updated;
  // }
}