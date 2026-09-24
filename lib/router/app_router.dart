import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/theme/app_motion.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/dashboard/providers/dashboard_scroll.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/ranking/screens/ranking_screen.dart';
import '../features/workout_session/providers/workout_session_providers.dart';
import '../features/workout_session/screens/workout_branch_screen.dart';
import 'workout_branch_navigator_key.dart';

// Branch indices — used to keep the shell's nav-bar wiring and the route
// table in sync instead of hard-coding raw ints everywhere.
const _dashboardBranch = 0;
const _calendarBranch = 1;
const _rankingBranch = 2;
const _profileBranch = 3;
const _workoutBranch = 4;

// Built once in main() with the initial location resolved from whether
// onboarding has been completed, so a first-time install lands on
// /onboarding instead of racing a redirect against the DB read.
GoRouter buildAppRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    StatefulShellRoute(
      builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          _FadingBranchContainer(currentIndex: navigationShell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/ranking', builder: (context, state) => const RankingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ]),
        // No sessionId in the path on purpose: this branch always resolves
        // whatever session is currently in progress, so it stays valid even
        // if the active session changes (or disappears) while it's open.
        StatefulShellBranch(
          navigatorKey: workoutBranchNavigatorKey,
          routes: [
            GoRoute(path: '/workout', builder: (context, state) => const WorkoutBranchScreen()),
          ],
        ),
      ],
    ),
  ],
);

// Keeps every tab alive like IndexedStack does (each keeps its own scroll
// position and navigation stack), but cross-fades between them instead of
// swapping instantly.
class _FadingBranchContainer extends StatelessWidget {
  const _FadingBranchContainer({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _branch(i, i == currentIndex, reduceMotion),
      ],
    );
  }

  Widget _branch(int index, bool active, bool reduceMotion) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        // The fade itself sits outside TickerMode: muting tickers above it
        // froze the outgoing tab's fade-out at full opacity, leaving it drawn
        // on top of the tab being switched to.
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: reduceMotion ? Duration.zero : AppMotion.normal,
          curve: active ? AppMotion.curve : Curves.easeIn,
          child: TickerMode(
            enabled: active,
            child: FocusScope(canRequestFocus: active, child: children[index]),
          ),
        ),
      ),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Browsers drop a screen wake lock whenever the page is hidden (switching
    // apps, locking the phone), so it's re-requested on every return.
    _lifecycle = AppLifecycleListener(onResume: () => _syncWakeLock(ref.read(activeSessionProvider).valueOrNull));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  // The screen stays on for as long as a workout is in progress — otherwise
  // it dims and locks between sets, and on the web the page (and the rest
  // timer with it) gets frozen in the background.
  void _syncWakeLock(Object? activeSession) {
    WakelockPlus.toggle(enable: activeSession != null).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    ref.listen(activeSessionProvider, (previous, next) {
      if (previous?.valueOrNull?.id != next.valueOrNull?.id) _syncWakeLock(next.valueOrNull);
    });
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
        onSelect: (index) {
          final reselected = index == navigationShell.currentIndex;
          if (reselected && index == _dashboardBranch) scrollDashboardToTop(ref);
          navigationShell.goBranch(index, initialLocation: reselected);
        },
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
    _NavItem(_calendarBranch, Icons.calendar_today_outlined, Icons.calendar_today, 'Planificar'),
    _NavItem(_rankingBranch, Icons.military_tech_outlined, Icons.military_tech, 'Rangos'),
    _NavItem(_profileBranch, Icons.person_outline, Icons.person, 'Perfil'),
  ];
  static const _workoutItem =
      _NavItem(_workoutBranch, Icons.fitness_center_outlined, Icons.fitness_center, 'Entreno');

  @override
  Widget build(BuildContext context) {
    final items = List<_NavItem>.of(_fixedDestinations);
    if (showWorkoutTab) {
      // Center slot: after Planificar, before Rangos.
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
