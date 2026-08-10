import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_motion.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/workout_session/providers/workout_session_providers.dart';
import '../features/workout_session/screens/workout_branch_screen.dart';

// Branch indices — used to keep the shell's nav-bar wiring and the route
// table in sync instead of hard-coding raw ints everywhere.
const _dashboardBranch = 0;
const _calendarBranch = 1;
const _profileBranch = 2;
const _workoutBranch = 3;

// Built once in main() with the initial location resolved from whether
// onboarding has been completed, so a first-time install lands on
// /onboarding instead of racing a redirect against the DB read.
GoRouter buildAppRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ]),
        // No sessionId in the path on purpose: this branch always resolves
        // whatever session is currently in progress, so it stays valid even
        // if the active session changes (or disappears) while it's open.
        StatefulShellBranch(routes: [
          GoRoute(path: '/workout', builder: (context, state) => const WorkoutBranchScreen()),
        ]),
      ],
    ),
  ],
);

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveSession = ref.watch(activeSessionProvider).valueOrNull != null;
    // Deliberately no auto-redirect when the session ends: the user may
    // still be looking at the just-finished session's summary screen,
    // pushed on top of this branch's own navigator. Keep the tab visible
    // (and correctly highlighted) while they're still on that branch, even
    // though the session itself is no longer active — it only drops out of
    // the bottom nav once they navigate elsewhere, so they can't tap back
    // into it later.
    final onWorkoutBranch = navigationShell.currentIndex == _workoutBranch;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        showWorkoutTab: hasActiveSession || onWorkoutBranch,
        onSelect: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.showWorkoutTab,
    required this.onSelect,
  });

  final int currentIndex;
  final bool showWorkoutTab;
  final ValueChanged<int> onSelect;

  static const _fixedDestinations = [
    _NavItem(_dashboardBranch, Icons.home_outlined, Icons.home, 'Inicio'),
    _NavItem(_calendarBranch, Icons.calendar_today_outlined, Icons.calendar_today, 'Calendario'),
    _NavItem(_profileBranch, Icons.person_outline, Icons.person, 'Perfil'),
  ];
  static const _workoutItem =
      _NavItem(_workoutBranch, Icons.fitness_center_outlined, Icons.fitness_center, 'Entreno');

  @override
  Widget build(BuildContext context) {
    final items = List<_NavItem>.of(_fixedDestinations);
    if (showWorkoutTab) {
      // Center slot: after Calendario, before Perfil.
      items.insert(2, _workoutItem);
    }

    return NavigationBar(
      selectedIndex: items.indexWhere((i) => i.branchIndex == currentIndex).clamp(0, items.length - 1),
      onDestinationSelected: (uiIndex) => onSelect(items[uiIndex].branchIndex),
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Icon(item.icon, key: ValueKey(item.branchIndex)),
            ),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.branchIndex, this.icon, this.selectedIcon, this.label);

  final int branchIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
