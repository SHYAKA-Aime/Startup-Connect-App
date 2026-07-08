import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/application.dart';

/// Owns all reads/writes for the `applications` collection.
class ApplicationRepository {
  ApplicationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('applications');

  /// Submit an application. Uses a Firestore transaction so that:
  ///   1. we reject a second application for the same opportunity, and
  ///   2. the opportunity's denormalised `applicantCount` is incremented
  ///      atomically with the write.
  /// Doing both in one transaction is what keeps the counter and the documents
  /// consistent even if two students apply at the same instant.
  Future<void> apply(Application application) async {
    final appRef = _col.doc(application.id);
    final oppRef =
        _db.collection('opportunities').doc(application.opportunityId);

    await _db.runTransaction((txn) async {
      final existing = await txn.get(appRef);
      if (existing.exists) {
        throw StateError('You have already applied to this opportunity.');
      }
      txn.set(appRef, application.toMap());
      txn.update(oppRef, {'applicantCount': FieldValue.increment(1)});
    });
  }

  /// A student's own applications — powers the "My Applications" tracker.
  Stream<List<Application>> watchForStudent(String studentUid) => _col
      .where('studentUid', isEqualTo: studentUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Application.fromDoc).toList());

  /// Everyone who applied to a specific opportunity — the startup's review list.
  Stream<List<Application>> watchForOpportunity(String opportunityId) => _col
      .where('opportunityId', isEqualTo: opportunityId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Application.fromDoc).toList());

  /// Whether the current student has already applied (drives the Apply button).
  Stream<bool> watchHasApplied(String opportunityId, String studentUid) => _col
      .doc(Application.buildId(opportunityId, studentUid))
      .snapshots()
      .map((d) => d.exists);

  /// Startup moves an application along its lifecycle. The student sees the new
  /// status instantly because their tracker is a live snapshot of this same doc.
  Future<void> setStatus(String applicationId, ApplicationStatus status) =>
      _col.doc(applicationId).update({'status': status.asString});
}
