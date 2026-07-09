import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/startup.dart';

/// Owns all reads/writes for the `startups` collection.
class StartupRepository {
  StartupRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('startups');

  /// The startup profile owned by a given user (a founder has exactly one).
  Stream<Startup?> watchByOwner(String ownerUid) => _col
      .where('ownerUid', isEqualTo: ownerUid)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Startup.fromDoc(s.docs.first));

  Stream<Startup?> watchById(String id) =>
      _col.doc(id).snapshots().map((d) => d.exists ? Startup.fromDoc(d) : null);

  /// Queue of startups awaiting review — powers the admin verification console.
  Stream<List<Startup>> watchByStatus(VerificationStatus status) => _col
      .where('status', isEqualTo: status.asString)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Startup.fromDoc).toList());

  Future<String> create(Startup startup) async {
    final ref = await _col.add(startup.toMap());
    return ref.id;
  }

  /// Updates only founder-editable fields (never status or ownerUid).
  Future<void> updateDetails(Startup startup) =>
      _col.doc(startup.id).update({
        'name': startup.name,
        'tagline': startup.tagline,
        'description': startup.description,
        'category': startup.category,
        'website': startup.website,
        'aluAffiliation': startup.aluAffiliation,
      });

  /// Admin action — moves a startup between verification states.
  Future<void> setStatus(String id, VerificationStatus status) =>
      _col.doc(id).update({'status': status.asString});
}
