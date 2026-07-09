import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../applications/presentation/my_applications_screen.dart';
import '../home/presentation/home_screen.dart';
import '../opportunities/presentation/explore_screen.dart';
import '../profile/presentation/profile_screen.dart';
import 'shell_providers.dart';

/// The student's four-tab container. The active tab lives in [studentTabProvider]
/// so other screens can switch tabs; IndexedStack keeps each tab alive.
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
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Applications'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
