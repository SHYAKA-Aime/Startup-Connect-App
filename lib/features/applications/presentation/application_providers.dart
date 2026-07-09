import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/application.dart';

/// The signed-in student's applications — the "My Applications" tracker, live.
final myApplicationsProvider = StreamProvider<List<Application>>((ref) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(applicationRepositoryProvider).watchForStudent(user.uid);
});

/// Applicants for one opportunity — the startup's review list, live.
final applicantsProvider =
    StreamProvider.family<List<Application>, String>((ref, opportunityId) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(applicationRepositoryProvider)
      .watchForOpportunity(opportunityId, user.uid);
});

/// Whether the current student already applied (drives the Apply button).
final hasAppliedProvider =
    StreamProvider.family<bool, String>((ref, opportunityId) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(false);
  return ref
      .watch(applicationRepositoryProvider)
      .watchHasApplied(opportunityId, user.uid);
});
