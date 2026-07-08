import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/startup.dart';
import 'startup_providers.dart';

/// The ALU admin verification console — the trust gate that makes the platform
/// ALU-specific. It streams every startup still in `pending` and lets an admin
/// approve or reject. Approval flips `status` to `verified`, which (a) unlocks
/// posting for that startup and (b) is required by the security rules for any
/// opportunity to be created.
///
/// In production the admin flag would be a Firebase custom claim; for this
/// project it's an `isAdmin` boolean on the user document, set once in the
/// Firebase console. That trade-off is called out in the report.
class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Admins only',
          message: 'You do not have access to the verification console.',
        ),
      );
    }

    final pendingAsync = ref.watch(pendingStartupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Startup verification')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_outlined,
              title: 'All caught up',
              message: 'No startups are awaiting verification.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PendingCard(list[i]),
          );
        },
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard(this.startup);
  final Startup startup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(startupRepositoryProvider);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(startup.name, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(startup.tagline,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              TagChip(startup.category, filled: true, color: AppColors.navy),
            ],
          ),
          const SizedBox(height: 12),
          Text(startup.description,
              style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Affiliation: ${startup.aluAffiliation}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      repo.setStatus(startup.id, VerificationStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      repo.setStatus(startup.id, VerificationStatus.verified),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(46)),
                  child: const Text('Verify'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
