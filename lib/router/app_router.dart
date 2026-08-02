import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/screens/calendar_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/insights/screens/insights_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/routines/screens/routines_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
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
          GoRoute(path: '/routines', builder: (context, state) => const RoutinesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/insights', builder: (context, state) => const InsightsScreen()),
        ]),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
        ],
      ),
    );
  }
}
