import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../opportunities/presentation/opportunity_providers.dart';
import '../domain/application.dart';
import 'application_controller.dart';
import 'application_providers.dart';
import 'my_applications_screen.dart' show statusColor;

/// The startup's applicant-review screen for one opportunity.
class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppAsync = ref.watch(opportunityByIdProvider(opportunityId));
    final applicantsAsync = ref.watch(applicantsProvider(opportunityId));

    return Scaffold(
      appBar: AppBar(
        title: Text(oppAsync.valueOrNull?.title ?? 'Applicants'),
      ),
      body: applicantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No applicants yet',
              message: 'Applications will appear here as students apply.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ApplicantCard(list[i]),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard(this.app);
  final Application app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(app.studentName, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (app.studentHeadline.isNotEmpty)
                      Text(app.studentHeadline,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(app.status.label, statusColor(app.status)),
            ],
          ),
          if (app.coverNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(app.coverNote,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
          const Divider(height: 24),
          const Text('Update status',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in ApplicationStatus.values)
                _statusButton(ref, s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(WidgetRef ref, ApplicationStatus s) {
    final selected = app.status == s;
    final color = statusColor(s);
    return GestureDetector(
      onTap: selected
          ? null
          : () => ref
              .read(applicationControllerProvider.notifier)
              .setStatus(app.id, s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          s.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
