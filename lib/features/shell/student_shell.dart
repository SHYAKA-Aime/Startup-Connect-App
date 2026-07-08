import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../applications/presentation/my_applications_screen.dart';
import '../home/presentation/home_screen.dart';
import '../opportunities/presentation/explore_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'shell_providers.dart';

/// The student's main container: four tabs behind a bottom nav bar.
///
/// The active tab lives in [studentTabProvider] (Riverpod) rather than local
/// state, so other screens can switch tabs programmatically. An [IndexedStack]
/// keeps every tab alive (scroll position + active Firestore streams) so
/// returning to a tab doesn't re-fetch.
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  static const _tabs = [
    HomeScreen(),
    ExploreScreen(),
    MyApplicationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(studentTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(studentTabProvider.notifier).state = i,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.navy.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.navy),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppColors.navy),
              label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: AppColors.navy),
              label: 'Applications'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.navy),
              label: 'Profile'),
        ],
      ),
    );
  }
}
