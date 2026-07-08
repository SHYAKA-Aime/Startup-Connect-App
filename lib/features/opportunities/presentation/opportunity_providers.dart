import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/opportunity_repository.dart';
import '../domain/opportunity.dart';

/// Newest open opportunities — the student home "Recent" feed (real-time).
final openOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  // Gate on being signed in. A Firestore listen fired while signed out gets a
  // permanent permission-denied that never recovers, so we hold an empty
  // stream until authenticated — and re-subscribe the moment auth changes.
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

/// --- Discovery / search state -----------------------------------------------
/// The active filter is held in a Notifier so any screen can update it and the
/// results provider below rebuilds automatically. This is the classic
/// "derived state" pattern: UI writes the filter, a computed provider reads it.
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

/// --- Recommendations --------------------------------------------------------
/// A lightweight recommendation system: score each open opportunity by how many
/// of its required skills overlap with the student's profile skills, then sort
/// best-match first. It reuses the already-streamed open list, so it costs no
/// extra Firestore reads — a scalability point worth making in the report.
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

/// --- Bookmarks --------------------------------------------------------------
final bookmarkIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(appUserProvider);
  if (user == null) return Stream.value(const {});
  return ref.watch(bookmarkRepositoryProvider).watchIds(user.uid);
});
