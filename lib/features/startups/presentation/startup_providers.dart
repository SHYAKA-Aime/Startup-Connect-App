import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/startup.dart';

/// The startup profile owned by the currently signed-in founder (or null if
/// they haven't created one yet). Drives the "set up your startup" gate.
final myStartupProvider = StreamProvider<Startup?>((ref) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(startupRepositoryProvider).watchByOwner(user.uid);
});

/// A single startup by id — used on the opportunity detail screen.
final startupByIdProvider =
    StreamProvider.family<Startup?, String>((ref, id) {
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(null);
  }
  return ref.watch(startupRepositoryProvider).watchById(id);
});

/// Verification queue for the admin console (gated on auth so it re-subscribes
/// cleanly after an account switch).
final pendingStartupsProvider = StreamProvider<List<Startup>>((ref) {
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(const <Startup>[]);
  }
  return ref
      .watch(startupRepositoryProvider)
      .watchByStatus(VerificationStatus.pending);
});
