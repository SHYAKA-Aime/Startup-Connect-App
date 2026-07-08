import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../opportunities/presentation/opportunity_controller.dart';
import '../../opportunities/presentation/opportunity_providers.dart';
import '../domain/startup.dart';
import 'startup_providers.dart';

/// The startup founder's home. It gates on verification status:
///   • no profile   → prompt to create one
///   • pending      → info banner, posting disabled
///   • verified     → post button + live list of their opportunities
class StartupDashboardScreen extends ConsumerWidget {
  const StartupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    final startupAsync = ref.watch(myStartupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                user?.fullName.split(' ').first ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: startupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (startup) {
          if (startup == null) return const _NoStartupYet();
          return _DashboardBody(startup: startup);
        },
      ),
      floatingActionButton: startupAsync.valueOrNull?.isVerified == true
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.navy,
              onPressed: () => context.push(Routes.postOpportunity),
              icon: const Icon(Icons.add),
              label: const Text('Post role'),
            )
          : null,
    );
  }
}

class _NoStartupYet extends StatelessWidget {
  const _NoStartupYet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_outlined,
                size: 64, color: AppColors.navy),
            const SizedBox(height: 16),
            const Text('Set up your startup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Create your startup profile to get verified by ALU and start '
              'posting opportunities.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push(Routes.startupSetup),
              child: const Text('Create startup profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppsAsync = ref.watch(startupOpportunitiesProvider(startup.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        // Verification status banner
        if (!startup.isVerified) _VerificationBanner(startup: startup),

        Text(startup.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(startup.tagline,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        const SectionHeader('Your opportunities'),
        const SizedBox(height: 12),
        oppsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorView(e),
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.post_add,
                title: startup.isVerified
                    ? 'No opportunities yet'
                    : 'Verification pending',
                message: startup.isVerified
                    ? 'Tap "Post role" to publish your first opportunity.'
                    : 'You can post once an ALU admin verifies your startup.',
              );
            }
            return Column(
              children: [
                for (final o in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StartupOppCard(o),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final rejected = startup.status == VerificationStatus.rejected;
    final color = rejected ? AppColors.danger : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(rejected ? Icons.cancel_outlined : Icons.hourglass_top,
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rejected
                  ? 'Your startup was not verified. Review your details and resubmit.'
                  : 'Your startup is pending ALU verification. Posting unlocks once approved.',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupOppCard extends ConsumerWidget {
  const _StartupOppCard(this.opp);
  final Opportunity opp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      onTap: () => context.push('${Routes.applicants}/${opp.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(opp.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              StatusBadge(
                opp.isOpen ? 'Open' : 'Closed',
                opp.isOpen ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${opp.applicantCount} applicants',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Text('· Tap to review',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _action(Icons.edit_outlined, 'Edit',
                  () => context.push('${Routes.postOpportunity}?id=${opp.id}')),
              _action(
                opp.isOpen ? Icons.lock_outline : Icons.lock_open_outlined,
                opp.isOpen ? 'Close' : 'Reopen',
                () => ref
                    .read(opportunityControllerProvider.notifier)
                    .setOpen(opp.id, !opp.isOpen),
              ),
              _action(Icons.delete_outline, 'Delete', () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete opportunity?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref
                      .read(opportunityControllerProvider.notifier)
                      .delete(opp.id);
                }
              }, color: AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? AppColors.navy;
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: c),
        label: Text(label,
            style: TextStyle(color: c, fontSize: 13)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }
}
