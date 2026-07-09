import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/applications/data/application_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/opportunities/data/bookmark_repository.dart';
import '../features/opportunities/data/opportunity_repository.dart';
import '../features/startups/data/startup_repository.dart';

/// Global providers: Firebase singletons, repositories, and auth state.
/// The dependency chain flows one way: Firebase → repositories → providers → UI.

// Firebase singletons
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Repositories — the only layer that talks to Firebase
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

// Authentication state

/// Raw Firebase auth state; the router redirects on this.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user's profile document, streamed live (null when signed out).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUser(auth.uid);
});

/// The resolved AppUser without the AsyncValue wrapper.
final appUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(currentUserProvider).valueOrNull,
);
