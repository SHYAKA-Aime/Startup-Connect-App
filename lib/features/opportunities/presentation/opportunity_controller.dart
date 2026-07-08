import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../startups/domain/startup.dart';
import '../domain/opportunity.dart';

/// Write-side controller for opportunities (create / edit / open-close /
/// delete). A startup may only create an opportunity if its profile is
/// verified — checked here before the write and again in the security rules.
class OpportunityController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> save({
    String? existingId,
    required Startup startup,
    required String title,
    required String description,
    required String category,
    required RoleType roleType,
    required LocationType locationType,
    required String commitment,
    required List<String> skills,
  }) async {
    if (!startup.isVerified) {
      state = AsyncError(
        StateError('Your startup must be verified before posting.'),
        StackTrace.current,
      );
      return false;
    }
    final repo = ref.read(opportunityRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final opp = Opportunity(
        id: existingId ?? '',
        startupId: startup.id,
        startupName: startup.name,
        title: title.trim(),
        description: description.trim(),
        category: category,
        roleType: roleType,
        locationType: locationType,
        commitment: commitment.trim(),
        skillsRequired: skills,
      );
      if (existingId == null) {
        await repo.create(opp);
      } else {
        await repo.update(opp);
      }
    });
    return !state.hasError;
  }

  Future<void> setOpen(String id, bool isOpen) =>
      ref.read(opportunityRepositoryProvider).setOpen(id, isOpen);

  Future<void> delete(String id) =>
      ref.read(opportunityRepositoryProvider).delete(id);
}

final opportunityControllerProvider =
    AutoDisposeAsyncNotifierProvider<OpportunityController, void>(
        OpportunityController.new);
