import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../applications/presentation/application_controller.dart';
import '../../applications/presentation/application_providers.dart';
import '../../startups/domain/startup.dart';
import '../../startups/presentation/startup_providers.dart';
import '../domain/opportunity.dart';
import 'opportunity_providers.dart';

/// Full opportunity view and the Apply action. Streams the opportunity and
/// `hasApplied` so the count and button update live.
class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppAsync = ref.watch(opportunityByIdProvider(opportunityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity Details')),
      body: oppAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (opp) {
          if (opp == null) {
            return const EmptyState(
                icon: Icons.link_off,
                title: 'Opportunity not found',
                message: 'It may have been removed by the startup.');
          }
          return _Content(opp: opp);
        },
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.opp});
  final Opportunity opp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    final startupAsync = ref.watch(startupByIdProvider(opp.startupId));
    final isOwner = user != null && user.uid == startupOwnerUid(startupAsync);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Row(
                children: [
                  InitialsAvatar(opp.startupName, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opp.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        startupAsync.when(
                          loading: () => Text(opp.startupName,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          error: (_, __) => Text(opp.startupName),
                          data: (s) => Row(
                            children: [
                              Flexible(
                                child: Text(opp.startupName,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                              if (s?.isVerified ?? false) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 16, color: AppColors.navy),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TagChip(opp.category, filled: true, color: AppColors.navy),
                  for (final s in opp.skillsRequired) TagChip(s),
                ],
              ),
              const SizedBox(height: 20),
              _MetaRow(Icons.schedule, opp.roleType.label,
                  subtitle: opp.commitment),
              _MetaRow(Icons.place_outlined, opp.locationType.label),
              _MetaRow(Icons.people_outline,
                  '${opp.applicantCount} applicant${opp.applicantCount == 1 ? '' : 's'}'),
              if (opp.createdAt != null)
                _MetaRow(Icons.calendar_today_outlined,
                    'Posted ${DateFormat.yMMMd().format(opp.createdAt!)}'),
              const SizedBox(height: 20),
              const Text('About this role',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(opp.description,
                  style: const TextStyle(height: 1.5, fontSize: 14.5)),
              const SizedBox(height: 20),
              _AboutStartup(startupAsync: startupAsync),
            ],
          ),
        ),
        _BottomBar(opp: opp, isOwner: isOwner),
      ],
    );
  }

  /// Helper: pull the owner uid out of the async startup value if loaded.
  String? startupOwnerUid(AsyncValue<Startup?> a) => a.valueOrNull?.ownerUid;
}

class _AboutStartup extends StatelessWidget {
  const _AboutStartup({required this.startupAsync});
  final AsyncValue<Startup?> startupAsync;

  @override
  Widget build(BuildContext context) {
    final s = startupAsync.valueOrNull;
    if (s == null) return const SizedBox.shrink();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('About the startup',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (s.isVerified)
                const StatusBadge('Verified', AppColors.navy),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.tagline,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(s.description,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.icon, this.text, {this.subtitle});
  final IconData icon;
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text('· $subtitle',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// The sticky bottom action. It adapts to who's viewing:
///   • startup owner  → informational (their own post)
///   • student, open  → Apply / Applied
///   • closed         → disabled
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.opp, required this.isOwner});
  final Opportunity opp;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);

    if (user == null) return const SizedBox.shrink();

    if (user.isStartup || isOwner) {
      return const SizedBox.shrink();
    }

    if (!opp.isOpen) {
      return _bar(
        context,
        const ElevatedButton(
          onPressed: null,
          child: Text('Applications closed'),
        ),
      );
    }

    final hasApplied =
        ref.watch(hasAppliedProvider(opp.id)).valueOrNull ?? false;
    final submitting =
        ref.watch(applicationControllerProvider).isLoading;

    return _bar(
      context,
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.chipBg,
          disabledForegroundColor: AppColors.textSecondary,
        ),
        onPressed: hasApplied || submitting
            ? null
            : () => _showApplySheet(context, ref, opp, user),
        child: submitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : hasApplied
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Applied'),
                    ],
                  )
                : const Text('Apply now'),
      ),
    );
  }

  Widget _bar(BuildContext context, Widget child) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }

  Future<void> _showApplySheet(
      BuildContext context, WidgetRef ref, Opportunity opp, user) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply to ${opp.title}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Add a short note on why you\'re a good fit (optional).',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'I\'m excited about this because…',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final ok = await ref
                    .read(applicationControllerProvider.notifier)
                    .apply(
                      opp: opp,
                      student: user,
                      coverNote: controller.text,
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Application submitted! Track it under Applications.'
                      : ref
                          .read(applicationControllerProvider)
                          .error
                          .toString()),
                ));
              },
              child: const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}
