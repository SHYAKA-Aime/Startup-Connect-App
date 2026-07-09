import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/opportunity.dart';
import '../opportunity_providers.dart';

/// Compact opportunity row (Home / Explore / Saved) with a live bookmark toggle.
class OpportunityCard extends ConsumerWidget {
  const OpportunityCard(this.opp, {super.key});

  final Opportunity opp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(bookmarkIdsProvider).valueOrNull?.contains(opp.id) ??
        false;

    return SoftCard(
      onTap: () => context.push('${Routes.opportunity}/${opp.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(opp.startupName, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opp.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(opp.startupName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(opp.roleType.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 10),
                    Icon(Icons.place_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(opp.locationType.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                color: saved ? AppColors.navy : AppColors.textSecondary),
            onPressed: () {
              final user = ref.read(appUserProvider);
              if (user == null) return;
              ref
                  .read(bookmarkRepositoryProvider)
                  .toggle(user.uid, opp.id, !saved);
            },
          ),
        ],
      ),
    );
  }
}
