import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../data/opportunity_repository.dart';
import '../domain/opportunity.dart';
import 'opportunity_providers.dart';
import 'widgets/opportunity_card.dart';

/// Discovery + search. The search box and filter chips write into
/// [opportunityFilterProvider]; the list watches [filteredOpportunitiesProvider].
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reflect any filter pre-applied from Home (e.g. category tap).
    _search.text = ref.read(opportunityFilterProvider).query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(opportunityFilterProvider);
    final notifier = ref.read(opportunityFilterProvider.notifier);
    final resultsAsync = ref.watch(filteredOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore'), centerTitle: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: notifier.setQuery,
              decoration: InputDecoration(
                hintText: 'Search roles, startups, skills…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryFilter(filter: filter, notifier: notifier),
                const SizedBox(width: 8),
                _RoleFilter(filter: filter, notifier: notifier),
                const SizedBox(width: 8),
                _LocationFilter(filter: filter, notifier: notifier),
                if (!filter.isEmpty) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear'),
                    avatar: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      _search.clear();
                      notifier.clear();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(e),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try removing a filter or searching differently.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => OpportunityCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.filter, required this.notifier});
  final OpportunityFilter filter;
  final OpportunityFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: notifier.setCategory,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All categories')),
        ...kCategories.map((c) => PopupMenuItem(value: c, child: Text(c))),
      ],
      child: _FilterChip(
        label: filter.category ?? 'Category',
        active: filter.category != null,
      ),
    );
  }
}

class _RoleFilter extends StatelessWidget {
  const _RoleFilter({required this.filter, required this.notifier});
  final OpportunityFilter filter;
  final OpportunityFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RoleType?>(
      onSelected: notifier.setRole,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Any type')),
        ...RoleType.values
            .map((r) => PopupMenuItem(value: r, child: Text(r.label))),
      ],
      child: _FilterChip(
        label: filter.roleType?.label ?? 'Type',
        active: filter.roleType != null,
      ),
    );
  }
}

class _LocationFilter extends StatelessWidget {
  const _LocationFilter({required this.filter, required this.notifier});
  final OpportunityFilter filter;
  final OpportunityFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LocationType?>(
      onSelected: notifier.setLocation,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Anywhere')),
        ...LocationType.values
            .map((l) => PopupMenuItem(value: l, child: Text(l.label))),
      ],
      child: _FilterChip(
        label: filter.locationType?.label ?? 'Location',
        active: filter.locationType != null,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.navy : AppColors.chipBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textPrimary)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              size: 18,
              color: active ? Colors.white : AppColors.textSecondary),
        ],
      ),
    );
  }
}
