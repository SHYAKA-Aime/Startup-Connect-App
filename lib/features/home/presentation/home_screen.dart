import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../opportunities/presentation/opportunity_providers.dart';
import '../../opportunities/presentation/widgets/opportunity_card.dart';
import '../../shell/shell_providers.dart';

/// Student home: greeting, a skill-matched hero recommendation, category
/// shortcuts and the live "Recent opportunities" feed. Everything below the
/// greeting is driven by Firestore streams, so new posts appear without a
/// refresh.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    final recommended = ref.watch(recommendedOpportunitiesProvider);
    final recentAsync = ref.watch(openOpportunitiesProvider);
    final firstName = (user?.fullName.split(' ').first) ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(openOpportunitiesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $firstName 👋',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Find meaningful ways to contribute.',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  InitialsAvatar(user?.fullName ?? '?', size: 46),
                ],
              ),
              const SizedBox(height: 20),

              // Search bar → switches to the Explore tab
              _SearchBarStub(
                onTap: () =>
                    ref.read(studentTabProvider.notifier).state = 1,
              ),
              const SizedBox(height: 24),

              // Recommended hero
              if (recommended.isNotEmpty) ...[
                SectionHeader(
                  'Recommended for you',
                  action: TextButton(
                    onPressed: () {},
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 8),
                _HeroCard(recommended.first),
                const SizedBox(height: 24),
              ],

              // Categories
              const SectionHeader('Browse by category'),
              const SizedBox(height: 12),
              _CategoryRow(
                onTap: (c) {
                  // Pre-apply the category filter, then jump to Explore.
                  ref.read(opportunityFilterProvider.notifier).setCategory(c);
                  ref.read(studentTabProvider.notifier).state = 1;
                },
              ),
              const SizedBox(height: 24),

              // Recent
              const SectionHeader('Recent opportunities'),
              const SizedBox(height: 12),
              recentAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorView(e,
                    onRetry: () =>
                        ref.invalidate(openOpportunitiesProvider)),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No opportunities yet',
                      message:
                          'Verified startups will post roles here soon. Check back later!',
                    );
                  }
                  return Column(
                    children: [
                      for (final o in list.take(10))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OpportunityCard(o),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBarStub extends StatelessWidget {
  const _SearchBarStub({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('Search opportunities…',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(this.opp);
  final Opportunity opp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${Routes.opportunity}/${opp.id}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(opp.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(opp.startupName,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in opp.skillsRequired.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.onTap});
  final void Function(String) onTap;

  static const _icons = {
    'Design': Icons.design_services_outlined,
    'Engineering': Icons.code,
    'Marketing': Icons.campaign_outlined,
    'Data': Icons.insights_outlined,
    'Other': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final c in kCategories)
          Column(
            children: [
              Material(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onTap(c),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(_icons[c], color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(c, style: const TextStyle(fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
