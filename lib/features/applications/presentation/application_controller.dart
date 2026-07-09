import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/domain/app_user.dart';
import '../../opportunities/domain/opportunity.dart';
import '../domain/application.dart';

/// Write-side controller for applications: submit, and advance status.
class ApplicationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Student applies to an opportunity with an optional cover note.
  Future<bool> apply({
    required Opportunity opp,
    required AppUser student,
    required String coverNote,
  }) async {
    final repo = ref.read(applicationRepositoryProvider);
    final application = Application(
      id: Application.buildId(opp.id, student.uid),
      opportunityId: opp.id,
      opportunityTitle: opp.title,
      startupId: opp.startupId,
      startupOwnerUid: opp.startupOwnerUid,
      startupName: opp.startupName,
      studentUid: student.uid,
      studentName: student.fullName,
      studentHeadline: student.headline,
      coverNote: coverNote.trim(),
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.apply(application));
    return !state.hasError;
  }

  /// Startup changes an applicant's status (under review / shortlisted / …).
  Future<void> setStatus(String applicationId, ApplicationStatus status) {
    return ref
        .read(applicationRepositoryProvider)
        .setStatus(applicationId, status);
  }
}

final applicationControllerProvider =
    AutoDisposeAsyncNotifierProvider<ApplicationController, void>(
        ApplicationController.new);
