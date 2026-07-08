import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/application.dart';
import 'application_providers.dart';

/// Maps each lifecycle status to a brand-consistent colour so the badges read
/// at a glance. Kept next to the screen that renders them.
Color statusColor(ApplicationStatus s) {
  switch (s) {
    case ApplicationStatus.applied:
      return AppColors.info;
    case ApplicationStatus.underReview:
      return AppColors.warning;
    case ApplicationStatus.shortlisted:
      return AppColors.navy;
    case ApplicationStatus.accepted:
      return AppColors.success;
    case ApplicationStatus.rejected:
      return AppColors.danger;
  }
}

/// The student's live application tracker with status filter tabs. Because it
/// watches a Firestore stream, a status change made by a startup shows up here
/// in real time — the headline "real-time updates" demo moment.
class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  // null = All
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications'), centerTitle: false),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _tab('All', null),
                for (final s in ApplicationStatus.values) _tab(s.label, s),
              ],
            ),
          ),
          Expanded(
            child: appsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(e),
              data: (all) {
                final list = _filter == null
                    ? all
                    : all.where((a) => a.status == _filter).toList();
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Nothing here yet',
                    message:
                        'Apply to an opportunity and track its progress here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ApplicationCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, ApplicationStatus? value) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          color: active ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.chipBg,
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard(this.app);
  final Application app;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () =>
          context.push('${Routes.opportunity}/${app.opportunityId}'),
      child: Row(
        children: [
          InitialsAvatar(app.startupName, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.opportunityTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(app.startupName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                if (app.createdAt != null)
                  Text('Applied ${DateFormat.yMMMd().format(app.createdAt!)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(app.status.label, statusColor(app.status)),
        ],
      ),
    );
  }
}
