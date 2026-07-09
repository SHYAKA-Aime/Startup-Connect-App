import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/opportunity_repository.dart';
import '../domain/opportunity.dart';

/// Newest open opportunities — the student home "Recent" feed (real-time).
final openOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  // Gated on auth so a signed-out listen can't stick on permission-denied.
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(const <Opportunity>[]);
  }
  return ref.watch(opportunityRepositoryProvider).watchOpen();
});

/// A single opportunity by id, streamed — detail screen + live applicant count.
final opportunityByIdProvider =
    StreamProvider.family<Opportunity?, String>((ref, id) {
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(null);
  }
  return ref.watch(opportunityRepositoryProvider).watchById(id);
});

/// Opportunities posted by a given startup — the startup dashboard list.
final startupOpportunitiesProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, startupId) {
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(const <Opportunity>[]);
  }
  return ref.watch(opportunityRepositoryProvider).watchByStartup(startupId);
});

/// Discovery filter state. Any screen updates it; the results provider recomputes.
class OpportunityFilterNotifier extends Notifier<OpportunityFilter> {
  @override
  OpportunityFilter build() => const OpportunityFilter();

  void setQuery(String q) => state = state.copyWith(query: q);

  void setCategory(String? c) => c == null
      ? state = state.copyWith(clearCategory: true)
      : state = state.copyWith(category: c);

  void setRole(RoleType? r) => r == null
      ? state = state.copyWith(clearRole: true)
      : state = state.copyWith(roleType: r);

  void setLocation(LocationType? l) => l == null
      ? state = state.copyWith(clearLocation: true)
      : state = state.copyWith(locationType: l);

  void clear() => state = const OpportunityFilter();
}

final opportunityFilterProvider =
    NotifierProvider<OpportunityFilterNotifier, OpportunityFilter>(
        OpportunityFilterNotifier.new);

/// Results for the current filter — recomputes whenever the filter changes.
final filteredOpportunitiesProvider =
    StreamProvider<List<Opportunity>>((ref) {
  if (ref.watch(authStateProvider).valueOrNull == null) {
    return Stream.value(const <Opportunity>[]);
  }
  final filter = ref.watch(opportunityFilterProvider);
  return ref.watch(opportunityRepositoryProvider).watchFiltered(filter);
});

/// Ranks open opportunities by skill overlap with the student's profile.
/// Reuses the already-streamed open list, so it adds no Firestore reads.
final recommendedOpportunitiesProvider =
    Provider<List<Opportunity>>((ref) {
  final open = ref.watch(openOpportunitiesProvider).valueOrNull ?? const [];
  final user = ref.watch(appUserProvider);
  final skills =
      (user?.skills ?? const []).map((s) => s.toLowerCase()).toSet();
  if (skills.isEmpty) return open; // no profile skills yet → newest first

  int score(Opportunity o) =>
      o.skillsRequired.where((s) => skills.contains(s.toLowerCase())).length;

  final scored = [...open]..sort((a, b) => score(b).compareTo(score(a)));
  return scored;
});

// Bookmarks
final bookmarkIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(const {});
  return ref.watch(bookmarkRepositoryProvider).watchIds(user.uid);
});
