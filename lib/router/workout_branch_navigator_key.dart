import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

// The workout branch's own Navigator, exposed so session-start call sites
// (HeroTodayCard, RoutineDayEditorScreen) can pop it back to its root before
// navigating there. SessionSummaryScreen/RankAchievementScreen are pushed
// onto this Navigator imperatively (see workout_session_screen.dart), which
// go_router's declarative `context.go('/workout')` never removes on its own
// — without this, starting a fresh session would reveal whichever of those
// screens was left on top from the *previous* one instead of the new live
// workout screen.
//
// Kept in its own file (rather than app_router.dart) so screens that need it
// don't have to import the router itself.
final workoutBranchNavigatorKey = GlobalKey<NavigatorState>();

// Every call site that starts a brand-new session should navigate with
// this instead of a bare `context.go('/workout')`.
void goToFreshWorkout(BuildContext context) {
  workoutBranchNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  context.go('/workout');
}
