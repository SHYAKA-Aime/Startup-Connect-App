import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

/// Wraps Firebase Authentication + the `users` collection.
///
/// The rest of the app never touches [FirebaseAuth] or [FirebaseFirestore]
/// directly — everything goes through repositories. That single seam is what
/// lets us swap the backend or mock it in tests without touching the UI, and is
/// the core of the layered architecture described in the report.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Emits every time the user signs in or out. The router listens to this to
  /// redirect between the auth flow and the main app automatically.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentAuthUser => _auth.currentUser;

  /// Live profile document for a uid. Returns null until the doc is written.
  Stream<AppUser?> watchUser(String uid) =>
      _users.doc(uid).snapshots().map((doc) =>
          doc.exists ? AppUser.fromDoc(doc) : null);

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Creates the auth credential AND the profile document in one flow. If the
  /// profile write fails we surface the error rather than leaving a half-created
  /// account silently — the caller decides how to react.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(fullName.trim());

    final user = AppUser(
      uid: uid,
      email: email.trim(),
      fullName: fullName.trim(),
      role: role,
    );
    await _users.doc(uid).set(user.toMap());
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile(AppUser user) =>
      _users.doc(user.uid).update(user.toMap());
}
