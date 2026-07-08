import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../opportunities/presentation/opportunity_providers.dart';
import '../../../opportunities/presentation/widgets/opportunity_card.dart';

/// Opens the "Saved opportunities" bottom sheet. The saved list is the
/// intersection of the user's bookmark ids with the live open-opportunities
/// stream, so un-saving one removes it from the sheet immediately.
Future<void> showSavedOpportunitiesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _SavedSheet(),
  );
}

class _SavedSheet extends ConsumerWidget {
  const _SavedSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(bookmarkIdsProvider).valueOrNull ?? const {};
    final all = ref.watch(openOpportunitiesProvider).valueOrNull ?? const [];
    final saved = all.where((o) => ids.contains(o.id)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Saved opportunities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: saved.isEmpty
                ? const EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'No saved opportunities',
                    message: 'Tap the bookmark icon on any role to save it.',
                  )
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => OpportunityCard(saved[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
