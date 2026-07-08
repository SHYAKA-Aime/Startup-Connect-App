import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/applications/data/application_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/opportunities/data/bookmark_repository.dart';
import '../features/opportunities/data/opportunity_repository.dart';
import '../features/startups/data/startup_repository.dart';

/// ---------------------------------------------------------------------------
/// GLOBAL PROVIDER GRAPH
/// ---------------------------------------------------------------------------
/// This file wires the whole app together with Riverpod. The dependency chain
/// flows one way:
///
///   Firebase SDK  ->  Repositories  ->  Stream/State providers  ->  Widgets
///
/// Widgets never construct a repository or a Firestore instance themselves; they
/// only `ref.watch(...)` a provider. That makes every layer independently
/// replaceable (e.g. override the repository with a fake in tests) and is the
/// backbone of the state-management story in the report.
/// ---------------------------------------------------------------------------

// --- Firebase SDK singletons -------------------------------------------------
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// --- Repositories (the only things that talk to Firebase) --------------------
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final startupRepositoryProvider = Provider<StartupRepository>(
  (ref) => StartupRepository(ref.watch(firestoreProvider)),
);

final opportunityRepositoryProvider = Provider<OpportunityRepository>(
  (ref) => OpportunityRepository(ref.watch(firestoreProvider)),
);

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepository(ref.watch(firestoreProvider)),
);

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(ref.watch(firestoreProvider)),
);

// --- Authentication state ----------------------------------------------------

/// Raw Firebase auth state (signed in / out). The router redirects on this.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user's full profile document, streamed live. Rebuilds anything
/// that depends on the profile (role, name, skills) the moment it changes in
/// Firestore. Emits null when signed out or before the doc exists.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(auth.uid);
});

/// Convenience: the resolved AppUser or null, without the AsyncValue wrapper.
final appUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(currentUserProvider).valueOrNull,
);
