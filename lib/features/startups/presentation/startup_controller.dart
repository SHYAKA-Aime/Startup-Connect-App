import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/startup.dart';

/// Write-side controller for a founder's own startup profile. Creating a startup
/// always lands it in `pending` — it cannot post opportunities until an ALU
/// admin verifies it. That rule is enforced here, in the UI, and again in the
/// Firestore security rules (defence in depth).
class StartupController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createOrUpdate({
    String? existingId,
    required String name,
    required String tagline,
    required String description,
    required String category,
    required String aluAffiliation,
    String? website,
  }) async {
    final user = ref.read(appUserProvider);
    if (user == null) return false;
    final repo = ref.read(startupRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (existingId == null) {
        final startup = Startup(
          id: '',
          ownerUid: user.uid,
          name: name.trim(),
          tagline: tagline.trim(),
          description: description.trim(),
          category: category,
          aluAffiliation: aluAffiliation.trim(),
          website: website?.trim(),
          // status defaults to pending
        );
        await repo.create(startup);
      } else {
        // Editing details never silently re-verifies: updateDetails writes only
        // the editable fields and leaves `status` untouched.
        final current = Startup(
          id: existingId,
          ownerUid: user.uid,
          name: name.trim(),
          tagline: tagline.trim(),
          description: description.trim(),
          category: category,
          aluAffiliation: aluAffiliation.trim(),
          website: website?.trim(),
        );
        await repo.updateDetails(current);
      }
    });
    return !state.hasError;
  }
}

final startupControllerProvider =
    AutoDisposeAsyncNotifierProvider<StartupController, void>(
        StartupController.new);
