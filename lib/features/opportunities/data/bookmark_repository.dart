import 'package:cloud_firestore/cloud_firestore.dart';

/// Bookmarks live under `users/{uid}/bookmarks/{oppId}` — a private per-user
/// subcollection.
class BookmarkRepository {
  BookmarkRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('bookmarks');

  Stream<Set<String>> watchIds(String uid) =>
      _col(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> toggle(String uid, String opportunityId, bool saved) {
    final ref = _col(uid).doc(opportunityId);
    return saved
        ? ref.set({'savedAt': FieldValue.serverTimestamp()})
        : ref.delete();
  }
}
