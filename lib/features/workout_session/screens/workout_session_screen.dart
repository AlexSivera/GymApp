import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/top_toast.dart';
import '../../../core/utils/set_format.dart';
import '../../../core/utils/superset_grouping.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/session_logging_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../../services/progression_engine/check_and_record_prs.dart';
import '../../../services/progression_engine/previous_performance.dart';
import '../../../services/progression_engine/suggest_next_load.dart';
import '../../../services/ranking_engine/compute_new_rank_achievements.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../ranking/screens/rank_achievement_screen.dart';
import '../../routines/providers/routines_providers.dart';
import '../providers/rest_timer_controller.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/rest_timer_banner.dart';
import 'session_summary_screen.dart';

class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionByIdProvider(sessionId));
    final sessionExercisesAsync = ref.watch(sessionExercisesProvider(sessionId));
    final allExercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
    final exercisesById = {for (final e in allExercises) e.id: e};

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorRetryView(
          message: 'No se ha podido cargar el entrenamiento.',
          onRetry: () => ref.invalidate(sessionByIdProvider(sessionId)),
        ),
      ),
      data: (session) {
        if (session == null) {
          return const Scaffold(body: Center(child: Text('Entrenamiento no encontrado')));
        }

        final title = ref.watch(routineDaySessionTitleProvider(session.routineDayId)) ?? 'Entrenamiento libre';
        final routineExercises = session.routineDayId == null
            ? const <RoutineExercise>[]
            : ref.watch(dayExercisesProvider(session.routineDayId!)).valueOrNull ?? const [];
        final targetsByExercise = {
          for (final re in routineExercises)
            re.exerciseId: (
              restSeconds: re.restSeconds ?? 90,
              repsMin: re.targetRepsMin,
              repsMax: re.targetRepsMax,
              sets: re.targetSets,
            ),
        };

        return sessionExercisesAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: ErrorRetryView(
              message: 'No se han podido cargar los ejercicios de este entrenamiento.',
              onRetry: () => ref.invalidate(sessionExercisesProvider(sessionId)),
            ),
          ),
          data: (sessionExercises) {
            final completedCount = sessionExercises
                .where((e) =>
                    e.status == SessionExerciseStatus.completed ||
                    e.status == SessionExerciseStatus.skipped)
                .length;
            final allDone = sessionExercises.isNotEmpty && completedCount == sessionExercises.length;
            final supersetLabels = supersetGroupLabels(sessionExercises, (e) => e.supersetGroup);

            // Progress by series, not just whole exercises: ticking off a set
            // should visibly move the bar. Planned = the routine's target
            // sets (or however many exist, if more were added).
            final sessionSets = ref.watch(setsForSessionProvider(sessionId)).valueOrNull ?? const [];
            final doneSets = sessionSets.where((s) => s.isCompleted).length;
            var plannedSets = 0;
            for (final sessionExercise in sessionExercises) {
              if (sessionExercise.status == SessionExerciseStatus.skipped) continue;
              final created = sessionSets.where((s) => s.sessionExerciseId == sessionExercise.id).length;
              final target = targetsByExercise[sessionExercise.exerciseId]?.sets ?? 0;
              plannedSets += created > target ? created : target;
            }
            final progress = plannedSets > 0
                ? (doneSets / plannedSets).clamp(0.0, 1.0)
                : sessionExercises.isEmpty
                    ? 0.0
                    : completedCount / sessionExercises.length;

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                // Finishing is always one tap away, but no longer the biggest
                // button on screen while there's still work left — that's
                // what made it easy to end a session by accident. Once
                // everything is done it moves to the big bottom button.
                actions: [
                  if (!allDone)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: TextButton(
                        onPressed: () => _completeSession(context, ref, session, sessionExercises),
                        child: const Text('Finalizar'),
                      ),
                    ),
                ],
              ),
              // No FAB here: it floated right on top of "Finalizar
              // entrenamiento". Adding an exercise lives at the end of the
              // list instead (see the footer below).
              bottomNavigationBar: const RestTimerBanner(),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _ElapsedTime(startedAt: session.startedAt)),
                            Text(
                              plannedSets > 0
                                  ? '$doneSets/$plannedSets series · $completedCount/${sessionExercises.length} ejercicios'
                                  : '$completedCount de ${sessionExercises.length} ejercicios',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        if (sessionExercises.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                            // Glides to the new value instead of jumping.
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: progress),
                              duration: AppMotion.slow,
                              curve: AppMotion.curve,
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (allDone)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: FadeSlideIn(
                        child: AppCard(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.of(context).statusCompleted, size: 26),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text('¡Entrenamiento completado!',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  Expanded(
                    child: sessionExercises.isEmpty
                        ? Center(
                            child: OutlinedButton.icon(
                              onPressed: () => _addExercise(context, ref, 0),
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir ejercicio'),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                            itemCount: sessionExercises.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                _reorder(ref, sessionExercises, oldIndex, newIndex),
                            // Long-press to reorder on every platform. The
                            // default desktop/web drag handle is drawn on top
                            // of the row's trailing status icon.
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, index) {
                              final sessionExercise = sessionExercises[index];
                              final exercise = exercisesById[sessionExercise.exerciseId];
                              final groupLabel = sessionExercise.supersetGroup == null
                                  ? null
                                  : supersetLabels[sessionExercise.supersetGroup];
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey(sessionExercise.id),
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: _ExerciseRow(
                                    sessionId: sessionId,
                                    sessionExercise: sessionExercise,
                                    exerciseName: exercise?.name ?? 'Ejercicio',
                                    imagePaths: exercise?.imagePaths ?? const [],
                                    category: exercise?.category ?? ExerciseCategory.strength,
                                    targets: targetsByExercise[sessionExercise.exerciseId],
                                    groupLabel: groupLabel,
                                  ),
                                ),
                              );
                            },
                            footer: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _addExercise(context, ref, sessionExercises.length),
                                icon: const Icon(Icons.add),
                                label: const Text('Añadir ejercicio'),
                              ),
                            ),
                          ),
                  ),
                  AnimatedSize(
                    duration: AppMotion.normal,
                    curve: AppMotion.curve,
                    alignment: Alignment.bottomCenter,
                    child: allDone
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                            child: FadeSlideIn(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _completeSession(context, ref, session, sessionExercises),
                                  icon: const Icon(Icons.flag_rounded),
                                  label: const Text('Finalizar entrenamiento'),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<SessionExercise> current,
    int oldIndex,
    int newIndex,
  ) async {
    final list = [...current];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await ref.read(sessionLoggingDaoProvider).reorderSessionExercises(list.map((e) => e.id).toList());
  }

  // Finishing with work left undone asks first — otherwise one stray tap on
  // "Finalizar" ends the session on the spot. Returns false if the user
  // chose to keep training.
  Future<bool> _confirmFinishIfIncomplete(
    BuildContext context,
    WidgetRef ref,
    List<SessionExercise> sessionExercises,
  ) async {
    final dao = ref.read(sessionLoggingDaoProvider);
    var completedSets = 0;
    var pendingExercises = 0;
    for (final sessionExercise in sessionExercises) {
      final sets = await dao.getSets(sessionExercise.id);
      completedSets += sets.where((s) => s.isCompleted).length;
      if (sessionExercise.status != SessionExerciseStatus.completed &&
          sessionExercise.status != SessionExerciseStatus.skipped) {
        pendingExercises++;
      }
    }
    if (pendingExercises == 0 || !context.mounted) return true;

    final message = completedSets == 0
        ? 'No has marcado ninguna serie como hecha, así que este entrenamiento se guardará vacío.'
        : 'Te ${pendingExercises == 1 ? 'queda 1 ejercicio' : 'quedan $pendingExercises ejercicios'} '
            'por completar. Las series que no hayas marcado como hechas no se guardarán.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar el entrenamiento?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir entrenando')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Terminar')),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _completeSession(
    BuildContext context,
    WidgetRef ref,
    WorkoutSession session,
    List<SessionExercise> sessionExercises,
  ) async {
    if (!await _confirmFinishIfIncomplete(context, ref, sessionExercises)) return;
    if (!context.mounted) return;

    // Everything needed from ref is read up front: once the session is
    // marked completed below, this widget is unmounted and ref stops working.
    final db = ref.read(appDatabaseProvider);
    final unit = ref.read(weightUnitProvider);
    final durationSeconds = session.startedAt != null
        ? DateTime.now().difference(session.startedAt!).inSeconds
        : null;

    // Capture the Navigator before marking the session completed. Doing the
    // opposite order flips activeSessionProvider to null first, which makes
    // WorkoutBranchScreen swap this whole screen out for a blank placeholder
    // mid-flight — a captured NavigatorState stays usable even after that
    // happens, unlike calling Navigator.of(context) afterward (which would
    // hit an unmounted context and silently no-op). Marking the session
    // completed first is required here too: rank achievements are detected
    // from the best-set query, which only looks at completed sessions.
    final navigator = Navigator.of(context);

    await db.workoutSessionsDao.updateSession(
      session.copyWith(
        status: SessionStatus.completed,
        completedAt: Value(DateTime.now()),
        durationSeconds: Value(durationSeconds),
      ),
    );
    await db.sessionLoggingDao.deleteUncompletedSetsOfFinishedSessions(sessionId: sessionId);

    final summary = await computeSessionSummary(db, sessionId: sessionId, unit: unit);
    final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

    navigator.push(
      MaterialPageRoute(
        // The rank-up screen (pushed on top) already throws confetti — the
        // summary underneath only celebrates when it's the first thing shown.
        builder: (_) => SessionSummaryScreen(summary: summary, celebrate: achievements.isEmpty),
      ),
    );
    if (achievements.isNotEmpty) {
      navigator.push(
        MaterialPageRoute(builder: (_) => RankAchievementScreen(achievements: achievements)),
      );
    }
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref, int currentCount) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null) return;
    await ref.read(sessionLoggingDaoProvider).addSessionExercise(SessionExercisesCompanion.insert(
          workoutSessionId: sessionId,
          exerciseId: exercise.id,
          orderIndex: currentCount,
        ));
  }
}

class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.startedAt});

  final DateTime? startedAt;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.startedAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.startedAt;
    if (startedAt == null) return const SizedBox.shrink();
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = elapsed.inHours;
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

typedef _ExerciseTargets = ({int restSeconds, int repsMin, int repsMax, int sets});
enum _ExerciseMenuAction { history, notes, skip }

// What a finished set carries: weight/reps for strength, duration/distance
// for cardio — always one pair or the other, never both. rir (reps in
// reserve) is strength-only and optional — null means "not logged", not "0".
typedef _SetResult = ({
  double? weight,
  int? reps,
  int? durationSeconds,
  double? distanceMeters,
  double? rir,
});

// "12 min" / "45s" / "5 km" / "12 min · 5 km" — whichever of duration/distance
// a cardio or isometric set actually has (isometric sets never carry
// distance, so that half is simply skipped for them). Shared by every
// duration-tracked set display below.
String _fmtDuration(WorkoutSet set) {
  final parts = <String>[];
  final duration = set.durationSeconds;
  if (duration != null) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    parts.add(minutes > 0 ? '$minutes min' : '${seconds}s');
  }
  final distance = set.distanceMeters;
  if (distance != null) {
    final km = distance / 1000;
    parts.add(km >= 1 ? '${_fmtDecimal(km)} km' : '${distance.round()} m');
  }
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _fmtDecimal(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    required this.sessionId,
    required this.sessionExercise,
    required this.exerciseName,
    required this.imagePaths,
    required this.category,
    required this.targets,
    required this.groupLabel,
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final String exerciseName;
  final List<String> imagePaths;
  final ExerciseCategory category;
  final _ExerciseTargets? targets;
  final String? groupLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sets = ref.watch(setsForExerciseProvider(sessionExercise.id)).valueOrNull ?? const [];
    final isExpanded = ref.watch(expandedSessionExerciseIdProvider) == sessionExercise.id;
    final unit = ref.watch(weightUnitProvider);
    // Whenever this card opens — tapped, or auto-advanced to after the
    // previous exercise was finished — bring it on screen. Waits for the
    // card that just closed above it to finish collapsing, otherwise the
    // scroll target moves mid-animation.
    ref.listen(expandedSessionExerciseIdProvider, (previous, next) {
      if (next != sessionExercise.id || previous == sessionExercise.id) return;
      _ensurePlannedSets(ref);
      Future.delayed(AppMotion.normal + const Duration(milliseconds: 30), () {
        if (!context.mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.02,
          duration: AppMotion.slow,
          curve: AppMotion.curve,
        );
      });
    });

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (groupLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text('SUPERSERIE $groupLabel',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.5)),
            ),
          ListTile(
            leading: ExerciseThumbnail(imagePaths: imagePaths),
            title: Text(exerciseName),
            subtitle: Text(_setsSummary(sets, unit)),
            trailing: _StatusIcon(status: sessionExercise.status),
            onTap: () => _toggleExpanded(ref),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _ExpandedExerciseDetail(
                    sessionId: sessionId,
                    sessionExercise: sessionExercise,
                    exerciseName: exerciseName,
                    category: category,
                    targets: targets,
                    sets: sets,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded(WidgetRef ref) {
    final notifier = ref.read(expandedSessionExerciseIdProvider.notifier);
    notifier.state = notifier.state != sessionExercise.id ? sessionExercise.id : null;
  }

  // Opening a routine-backed exercise for the first time — by tapping it, or
  // by being auto-advanced to — pre-creates all of its target sets
  // (prefilled from last time / the suggested weight) so the checklist
  // matches the plan immediately, instead of starting empty.
  Future<void> _ensurePlannedSets(WidgetRef ref) async {
    if (targets == null) return;
    // Everything from ref is read before the first await: this row can be
    // rebuilt (or scrolled away) while the inserts below are in flight.
    final db = ref.read(appDatabaseProvider);
    final dao = ref.read(sessionLoggingDaoProvider);
    if ((await dao.getSets(sessionExercise.id)).isNotEmpty) return;

    final previousSets = await getPreviousSetsForExercise(
      db,
      exerciseId: sessionExercise.exerciseId,
      excludeSessionId: sessionId,
    );
    final isStrength = category == ExerciseCategory.strength;
    final isCardio = category == ExerciseCategory.cardio;
    // suggestNextLoad's progression heuristic is rep-range based and doesn't
    // apply to cardio/isometric — those sets just carry over duration (and,
    // for cardio, distance) as-is.
    final suggestion = !isStrength || previousSets.isEmpty
        ? null
        : suggestNextLoad(
            previousSets: previousSets,
            targetRepsMin: targets!.repsMin,
            targetRepsMax: targets!.repsMax,
          );

    for (var i = 0; i < targets!.sets; i++) {
      final matchingPrevious = i < previousSets.length ? previousSets[i] : null;
      await dao.addSet(WorkoutSetsCompanion.insert(
        sessionExerciseId: sessionExercise.id,
        setNumber: i + 1,
        // The suggestion wins over last time's weight, so every set starts at
        // the load the "Prueba con X kg" hint above is recommending.
        weightKg: Value(isStrength ? suggestion?.suggestedWeight ?? matchingPrevious?.weightKg : null),
        reps: Value(isStrength ? matchingPrevious?.reps ?? targets!.repsMax : null),
        durationSeconds: Value(isStrength ? null : matchingPrevious?.durationSeconds),
        distanceMeters: Value(isCardio ? matchingPrevious?.distanceMeters : null),
        isCompleted: const Value(false),
      ));
    }
  }

  // Only sets actually ticked off are summarized — pending ones are just
  // pre-filled suggestions. Until the first one is done, the row shows the
  // plan instead ("3 × 8–12 reps").
  String _setsSummary(List<WorkoutSet> allSets, WeightUnit unit) {
    final sets = allSets.where((s) => s.isCompleted).toList();
    if (sets.isEmpty) return _plannedSummary(allSets.length);
    if (category != ExerciseCategory.strength) {
      final valid = sets.where((s) => s.durationSeconds != null || s.distanceMeters != null).toList();
      if (valid.isEmpty) return '${sets.length} serie${sets.length == 1 ? '' : 's'}';
      final parts = valid.take(3).map(_fmtDuration);
      final suffix = valid.length > 3 ? ' +${valid.length - 3}' : '';
      return '${parts.join(' · ')}$suffix';
    }
    final valid = sets.where((s) => s.weightKg != null && s.reps != null).toList();
    if (valid.isEmpty) return '${sets.length} serie${sets.length == 1 ? '' : 's'}';
    return summarizeStrengthSets([for (final s in valid) (weightKg: s.weightKg!, reps: s.reps!)], unit);
  }

  String _plannedSummary(int createdSets) {
    final plannedSets = targets?.sets ?? createdSets;
    if (plannedSets == 0) return 'Sin series todavía';
    if (category == ExerciseCategory.strength && targets != null) {
      final reps = targets!.repsMin == targets!.repsMax
          ? '${targets!.repsMin}'
          : '${targets!.repsMin}–${targets!.repsMax}';
      return '$plannedSets × $reps reps';
    }
    return '$plannedSets serie${plannedSets == 1 ? '' : 's'}';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final SessionExerciseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Widget icon;
    switch (status) {
      case SessionExerciseStatus.pending:
        icon = Icon(Icons.circle_outlined, size: 20, color: colors.statusEmpty);
      case SessionExerciseStatus.inProgress:
        icon = Icon(Icons.circle, size: 12, color: colors.statusPlanned);
      case SessionExerciseStatus.completed:
        icon = Icon(Icons.check_circle, size: 20, color: colors.statusCompleted);
      case SessionExerciseStatus.skipped:
        icon = Icon(Icons.remove_circle, size: 20, color: colors.statusSkipped);
    }
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.curve,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
      child: KeyedSubtree(key: ValueKey(status), child: icon),
    );
  }
}

// Everything that used to live in the standalone ExerciseLoggingScreen,
// now rendered inline when a checklist row is expanded: last time, load
// suggestion, the set table, and the overflow menu — no navigation away
// from the checklist.
class _ExpandedExerciseDetail extends ConsumerWidget {
  const _ExpandedExerciseDetail({
    required this.sessionId,
    required this.sessionExercise,
    required this.exerciseName,
    required this.category,
    required this.targets,
    required this.sets,
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final String exerciseName;
  final ExerciseCategory category;
  final _ExerciseTargets? targets;
  final List<WorkoutSet> sets;

  bool get isStrength => category == ExerciseCategory.strength;
  int get exerciseId => sessionExercise.exerciseId;
  int get restSeconds => targets?.restSeconds ?? 90;
  int get repsMin => targets?.repsMin ?? 8;
  int get repsMax => targets?.repsMax ?? 12;
  int? get targetSets => targets?.sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final previousSetsAsync = ref.watch(
      previousSetsProvider((exerciseId: exerciseId, excludeSessionId: sessionId)),
    );
    final previousSets = previousSetsAsync.valueOrNull ?? const <WorkoutSet>[];
    // suggestNextLoad's progression heuristic is rep-range based and doesn't
    // apply to cardio/isometric.
    final suggestion = !isStrength || previousSets.isEmpty
        ? null
        : suggestNextLoad(
            previousSets: previousSets,
            targetRepsMin: repsMin,
            targetRepsMax: repsMax,
            unit: unit,
          );

    final incompleteSets = sets.where((s) => !s.isCompleted);
    final activeSet = incompleteSets.isEmpty ? null : incompleteSets.first;
    final otherSets = [for (final s in sets) if (s.id != activeSet?.id) s];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.lg),
          if (previousSets.isNotEmpty || suggestion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (previousSets.isNotEmpty)
                          Text(
                            'Última vez: ${_lastTimeSummary(previousSets, unit)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        if (suggestion != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              suggestion.message,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _OverflowMenu(onSelected: (action) => _handleMenuAction(context, ref, action)),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: _OverflowMenu(onSelected: (action) => _handleMenuAction(context, ref, action)),
            ),
          // The next set slides in as the one just logged moves down into
          // the list below, so it reads as "that one's done, here's the next".
          AnimatedSwitcher(
            duration: AppMotion.normal,
            switchInCurve: AppMotion.curve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: activeSet == null
                ? const SizedBox(width: double.infinity, key: ValueKey('no-active'))
                : Padding(
                    key: ValueKey('active-${activeSet.id}'),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ActiveSetCard(
                      set: activeSet,
                      category: category,
                      onComplete: (result) => _completeSet(context, ref, activeSet, result),
                    ),
                  ),
          ),
          for (final set in otherSets)
            FadeSlideIn(
              key: ValueKey('row-${set.id}-${set.isCompleted}'),
              child: _CompactSetRow(
                set: set,
                category: category,
                onDelete: () => _deleteSet(context, ref, set.id),
              ),
            ),
          if (otherSets.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSet(ref, sets, suggestion),
              icon: const Icon(Icons.add),
              label: const Text('Añadir otra serie'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeExercise(context, ref),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Cambiar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _lastTimeSummary(List<WorkoutSet> previousSets, WeightUnit unit) {
    if (!isStrength) return previousSets.map(_fmtDuration).join(', ');
    final valid = previousSets.where((s) => s.weightKg != null && s.reps != null);
    if (valid.isEmpty) return '—';
    return summarizeStrengthSets([for (final s in valid) (weightKg: s.weightKg!, reps: s.reps!)], unit);
  }

  Future<void> _addSet(WidgetRef ref, List<WorkoutSet> existingSets, LoadSuggestion? suggestion) async {
    final last = existingSets.isEmpty ? null : existingSets.last;
    final isCardio = category == ExerciseCategory.cardio;
    await ref.read(sessionLoggingDaoProvider).addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: sessionExercise.id,
          setNumber: existingSets.length + 1,
          weightKg: Value(isStrength ? last?.weightKg ?? suggestion?.suggestedWeight : null),
          reps: Value(isStrength ? last?.reps : null),
          durationSeconds: Value(isStrength ? null : last?.durationSeconds),
          distanceMeters: Value(isCardio ? last?.distanceMeters : null),
          isCompleted: const Value(false),
        ));
  }

  Future<void> _completeSet(
    BuildContext context,
    WidgetRef ref,
    WorkoutSet set,
    _SetResult result,
  ) async {
    final setId = set.id;
    final dao = ref.read(sessionLoggingDaoProvider);
    final db = ref.read(appDatabaseProvider);
    // Finishing an exercise's last set auto-advances to the next one, which
    // unmounts this detail view mid-way through the method — so the overlay
    // the record toast goes on is looked up now, while it's still mounted.
    final toastOverlay = Overlay.of(context, rootOverlay: true);
    final recordColor = AppColors.of(context).statusPlanned;
    // Carry over *before* marking this set done: marking it done is what
    // turns the next set into the active card, and that card reads its
    // starting weight/reps only once, when it's created. Doing it the other
    // way round showed the next set at 0 kg.
    await _carryOverToNextSet(dao, set, result);
    await dao.updateSet(set.copyWith(
          weightKg: Value(result.weight),
          reps: Value(result.reps),
          durationSeconds: Value(result.durationSeconds),
          distanceMeters: Value(result.distanceMeters),
          rir: Value(result.rir),
          isCompleted: true,
          completedAt: Value(DateTime.now()),
        ));

    HapticFeedback.lightImpact();
    final nextInSuperset = await _nextSupersetPartnerNeedingThisRound(ref, dao);
    if (nextInSuperset != null) {
      // Part of a superset/circuit and a partner hasn't done this round yet
      // — move straight to it instead of starting the rest timer, which only
      // fires once every exercise in the group has caught up.
      ref.read(expandedSessionExerciseIdProvider.notifier).state = nextInSuperset.id;
    } else {
      ref.read(restTimerControllerProvider.notifier).start(restSeconds);
    }
    await _syncExerciseStatus(ref);

    if (result.weight != null && result.reps != null) {
      final achieved = await checkAndRecordPRs(
        db,
        exerciseId: exerciseId,
        setId: setId,
        weightKg: result.weight!,
        reps: result.reps!,
      );
      // The very first time an exercise is done, every set "beats" an empty
      // record. Those still get stored (as the baseline), but a record only
      // gets celebrated once there's a past session to have beaten.
      final hasHistory = achieved.isNotEmpty &&
          (await getPreviousSetsForExercise(db, exerciseId: exerciseId, excludeSessionId: sessionId))
              .isNotEmpty;
      if (hasHistory) {
        HapticFeedback.heavyImpact();
        showTopToast(
          toastOverlay,
          icon: Icons.emoji_events_rounded,
          iconColor: recordColor,
          message: '¡Nuevo récord personal en $exerciseName!',
        );
      }
    }
  }

  // Pre-fills every later not-yet-completed set with whatever was just
  // logged, so the user only has to touch the fields when they actually
  // change weight/reps (or duration/distance) between sets. All of them, not
  // just the next one: the queued rows below show these values too, and a
  // stale "12.5 kg" under a set just done at 15 kg looked like a mistake.
  Future<void> _carryOverToNextSet(
    SessionLoggingDao dao,
    WorkoutSet completedSet,
    _SetResult result,
  ) async {
    final later = sets.where((s) => s.setNumber > completedSet.setNumber && !s.isCompleted);
    final isCardio = category == ExerciseCategory.cardio;
    for (final next in later) {
      await dao.updateSet(next.copyWith(
            weightKg: Value(isStrength ? result.weight : null),
            reps: Value(isStrength ? result.reps : null),
            durationSeconds: Value(isStrength ? null : result.durationSeconds),
            distanceMeters: Value(isCardio ? result.distanceMeters : null),
          ));
    }
  }

  // Null if this exercise isn't in a superset, or every partner already has
  // at least as many completed sets as this exercise now does (i.e. this was
  // the last one to finish the current round, so it's time to actually
  // rest). Otherwise, the partner earliest in the day's order that still
  // needs this round.
  Future<SessionExercise?> _nextSupersetPartnerNeedingThisRound(
    WidgetRef ref,
    SessionLoggingDao dao,
  ) async {
    final group = sessionExercise.supersetGroup;
    if (group == null) return null;

    final thisCompletedCount =
        (await dao.getSets(sessionExercise.id)).where((s) => s.isCompleted).length;
    final siblings = ref.read(sessionExercisesProvider(sessionId)).valueOrNull ?? const [];
    final partners = siblings
        .where((s) => s.supersetGroup == group && s.id != sessionExercise.id)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (final partner in partners) {
      final partnerCompletedCount = (await dao.getSets(partner.id)).where((s) => s.isCompleted).length;
      if (partnerCompletedCount < thisCompletedCount) return partner;
    }
    return null;
  }

  Future<void> _syncExerciseStatus(WidgetRef ref) async {
    final currentSets = await ref.read(sessionLoggingDaoProvider).getSets(sessionExercise.id);
    final completedCount = currentSets.where((s) => s.isCompleted).length;
    // Straight from the database: reading the (unwatched) stream provider
    // here returned "still loading" the first time after an app start, so
    // the first set logged never updated the exercise's status.
    final current = await ref.read(sessionLoggingDaoProvider).watchById(sessionExercise.id).first;
    if (current == null || current.status == SessionExerciseStatus.skipped) return;

    final next = targetSets != null && completedCount >= targetSets!
        ? SessionExerciseStatus.completed
        : completedCount > 0
            ? SessionExerciseStatus.inProgress
            : SessionExerciseStatus.pending;
    if (next != current.status) {
      await ref.read(sessionLoggingDaoProvider).updateSessionExerciseStatus(sessionExercise.id, next);
    }

    if (next == SessionExerciseStatus.completed) {
      final expandedNotifier = ref.read(expandedSessionExerciseIdProvider.notifier);
      if (expandedNotifier.state == sessionExercise.id) {
        // Auto-advance: open the next exercise still to do (in the day's
        // order, wrapping around to earlier ones left pending), so the user
        // doesn't have to find and tap it between sets.
        final all = [...ref.read(sessionExercisesProvider(sessionId)).valueOrNull ?? const <SessionExercise>[]]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        bool pending(SessionExercise e) =>
            e.id != sessionExercise.id &&
            (e.status == SessionExerciseStatus.pending || e.status == SessionExerciseStatus.inProgress);
        final after = all.where((e) => e.orderIndex > sessionExercise.orderIndex && pending(e));
        final nextUp = after.isNotEmpty ? after.first : all.where(pending).firstOrNull;
        expandedNotifier.state = nextUp?.id;
      }
    }
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, _ExerciseMenuAction action) async {
    switch (action) {
      case _ExerciseMenuAction.history:
        await _showHistory(context, ref);
      case _ExerciseMenuAction.notes:
        await _editNotes(context, ref);
      case _ExerciseMenuAction.skip:
        await ref
            .read(sessionLoggingDaoProvider)
            .updateSessionExerciseStatus(sessionExercise.id, SessionExerciseStatus.skipped);
        ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
    }
  }

  Future<void> _changeExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null) return;
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSessionExercise(sessionExercise.copyWith(exerciseId: exercise.id));
    ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
  }

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final unit = ref.read(weightUnitProvider);
    final history = await db.progressDao.estimatedOneRepMaxHistory(exerciseId);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial (1RM estimado)'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text('Todavía no hay historial para este ejercicio.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final point in history.reversed)
                      ListTile(
                        dense: true,
                        title: Text(formatWeight(point.value, unit)),
                        trailing: Text(DateFormat('d MMM', 'es').format(point.date)),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: sessionExercise.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas'),
        content: TextField(controller: controller, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSessionExercise(sessionExercise.copyWith(notes: Value(result.isEmpty ? null : result)));
  }

  Future<void> _deleteSet(BuildContext context, WidgetRef ref, int setId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar serie'),
        content: const Text('Se eliminará esta serie del entrenamiento.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await ref.read(sessionLoggingDaoProvider).deleteSet(setId);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text('Se eliminará este ejercicio y sus series de este entrenamiento.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionLoggingDaoProvider).removeSessionExercise(sessionExercise.id);
    ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<_ExerciseMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExerciseMenuAction>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ExerciseMenuAction.history, child: Text('Historial')),
        PopupMenuItem(value: _ExerciseMenuAction.notes, child: Text('Notas')),
        PopupMenuItem(value: _ExerciseMenuAction.skip, child: Text('Omitir ejercicio')),
      ],
    );
  }
}

// The one set the user is currently meant to log, front and center with
// +/- steppers instead of raw text fields — matches "no abrir una ventana
// con teclado para poner los kilos".
class _ActiveSetCard extends ConsumerStatefulWidget {
  const _ActiveSetCard({required this.set, required this.category, required this.onComplete});

  final WorkoutSet set;
  final ExerciseCategory category;
  final Future<void> Function(_SetResult result) onComplete;

  @override
  ConsumerState<_ActiveSetCard> createState() => _ActiveSetCardState();
}

class _ActiveSetCardState extends ConsumerState<_ActiveSetCard> {
  late double _weight;
  late int _reps;
  late int _durationMin;
  late double _distanceKm;
  late int _isometricSeconds;
  int? _rir;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _weight = widget.set.weightKg ?? 0;
    _reps = widget.set.reps ?? 0;
    _durationMin = ((widget.set.durationSeconds ?? 0) / 60).round();
    _distanceKm = (widget.set.distanceMeters ?? 0) / 1000;
    _isometricSeconds = widget.set.durationSeconds ?? 0;
    _rir = widget.set.rir?.round();
  }

  // delta is expressed in kg regardless of display unit, so the lb stepper
  // passes the kg-equivalent of a clean 5 lb step (rather than a raw 2.5,
  // which would show as an odd non-round lb number after each tap).
  void _adjustWeight(double delta) => setState(() => _weight = (_weight + delta).clamp(0, 999));
  void _adjustReps(int delta) => setState(() => _reps = (_reps + delta).clamp(0, 99));
  void _adjustDuration(int delta) => setState(() => _durationMin = (_durationMin + delta).clamp(0, 999));
  void _adjustDistance(double delta) => setState(
      () => _distanceKm = (((_distanceKm + delta).clamp(0, 999)) * 10).round() / 10);
  void _adjustIsometric(int delta) =>
      setState(() => _isometricSeconds = (_isometricSeconds + delta).clamp(0, 3600));

  // Typing the exact value beats tapping +/- dozens of times (a 50-minute
  // run at 1 min per tap, for instance) — every stepper's value is also a
  // button that opens this quick numeric-entry dialog.
  Future<void> _promptValue({
    required String label,
    required num currentValue,
    required bool decimal,
    required void Function(num value) onSubmit,
  }) async {
    final controller = TextEditingController(
      text: decimal ? _fmt(currentValue.toDouble()) : currentValue.round().toString(),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.center,
          style: Theme.of(dialogContext).textTheme.headlineMedium,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            if (decimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*$'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final parsed = num.tryParse(result.replaceAll(',', '.'));
    if (parsed == null) return;
    onSubmit(parsed);
  }

  Future<void> _markSet() async {
    setState(() => _submitting = true);
    final _SetResult result = switch (widget.category) {
      ExerciseCategory.strength => (
          weight: _weight,
          reps: _reps,
          durationSeconds: null,
          distanceMeters: null,
          rir: _rir?.toDouble(),
        ),
      ExerciseCategory.cardio => (
          weight: null,
          reps: null,
          durationSeconds: _durationMin > 0 ? _durationMin * 60 : null,
          distanceMeters: _distanceKm > 0 ? _distanceKm * 1000 : null,
          rir: null,
        ),
      ExerciseCategory.isometric => (
          weight: null,
          reps: null,
          durationSeconds: _isometricSeconds > 0 ? _isometricSeconds : null,
          distanceMeters: null,
          rir: null,
        ),
    };
    await widget.onComplete(result);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final weightStepKg = unit == WeightUnit.lb ? lbToKg(5) : 2.5;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SERIE ${widget.set.setNumber}', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          switch (widget.category) {
            ExerciseCategory.cardio => Row(
                children: [
                  Expanded(
                      child: _Stepper(
                          label: 'min',
                          value: '$_durationMin',
                          onDecrement: () => _adjustDuration(-1),
                          onIncrement: () => _adjustDuration(1),
                          onTap: () => _promptValue(
                                label: 'Minutos',
                                currentValue: _durationMin,
                                decimal: false,
                                onSubmit: (v) =>
                                    setState(() => _durationMin = v.toInt().clamp(0, 999)),
                              ))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _Stepper(
                          label: 'km',
                          value: _fmt(_distanceKm),
                          onDecrement: () => _adjustDistance(-0.1),
                          onIncrement: () => _adjustDistance(0.1),
                          onTap: () => _promptValue(
                                label: 'Kilómetros',
                                currentValue: _distanceKm,
                                decimal: true,
                                onSubmit: (v) => setState(
                                    () => _distanceKm = v.toDouble().clamp(0, 999)),
                              ))),
                ],
              ),
            ExerciseCategory.isometric => _Stepper(
                label: 'segundos',
                value: '$_isometricSeconds',
                onDecrement: () => _adjustIsometric(-5),
                onIncrement: () => _adjustIsometric(5),
                onTap: () => _promptValue(
                      label: 'Segundos',
                      currentValue: _isometricSeconds,
                      decimal: false,
                      onSubmit: (v) =>
                          setState(() => _isometricSeconds = v.toInt().clamp(0, 3600)),
                    ),
              ),
            ExerciseCategory.strength => Row(
                children: [
                  Expanded(
                      child: _Stepper(
                          label: weightUnitLabel(unit),
                          value: formatWeightValue(_weight, unit),
                          onDecrement: () => _adjustWeight(-weightStepKg),
                          onIncrement: () => _adjustWeight(weightStepKg),
                          onTap: () => _promptValue(
                                label: unit == WeightUnit.lb ? 'Libras' : 'Kilos',
                                currentValue: kgToDisplayUnit(_weight, unit),
                                decimal: true,
                                onSubmit: (v) => setState(
                                    () => _weight = displayUnitToKg(v.toDouble(), unit).clamp(0, 999)),
                              ))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _Stepper(
                          label: 'reps',
                          value: '$_reps',
                          onDecrement: () => _adjustReps(-1),
                          onIncrement: () => _adjustReps(1),
                          onTap: () => _promptValue(
                                label: 'Repeticiones',
                                currentValue: _reps,
                                decimal: false,
                                onSubmit: (v) => setState(() => _reps = v.toInt().clamp(0, 99)),
                              ))),
                ],
              ),
          },
          if (widget.category == ExerciseCategory.strength) ...[
            const SizedBox(height: AppSpacing.md),
            Text('RIR (reps en reserva)',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final option in const [0, 1, 2, 3, 4])
                  ChoiceChip(
                    label: Text(option == 4 ? '4+' : '$option'),
                    selected: _rir == option,
                    onSelected: (selected) => setState(() => _rir = selected ? option : null),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _markSet,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar serie'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  // Lets the value itself be tapped to type an exact number instead of
  // stepping to it one +/- at a time.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColumn = Column(
      children: [
        Text(value, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepperButton(icon: Icons.remove, onTap: onDecrement),
        Expanded(
          child: onTap == null
              ? valueColumn
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: valueColumn,
                    ),
                  ),
                ),
        ),
        _StepperButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// A set that isn't the active one — either already completed, or queued
// further down the plan. Shown as a plain summary row with a way to remove it.
class _CompactSetRow extends ConsumerWidget {
  const _CompactSetRow({required this.set, required this.category, required this.onDelete});

  final WorkoutSet set;
  final ExerciseCategory category;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // A just-completed set's check pops in (rows are keyed by their
          // completion state, so this plays once, right when it's ticked).
          TweenAnimationBuilder<double>(
            tween: Tween(begin: set.isCompleted ? 0.3 : 1, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Icon(
              set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: set.isCompleted ? AppColors.of(context).statusCompleted : mutedColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Serie ${set.setNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(color: set.isCompleted ? null : mutedColor),
            ),
          ),
          Text(
            category == ExerciseCategory.strength
                ? '${set.weightKg == null ? '—' : formatWeightValue(set.weightKg!, unit)} ${weightUnitLabel(unit)} × ${set.reps ?? '—'}'
                    '${set.rir == null ? '' : ' · RIR ${set.rir!.round()}'}'
                : _fmtDuration(set),
            style: theme.textTheme.bodyMedium?.copyWith(color: set.isCompleted ? null : mutedColor),
          ),
          IconButton(
            tooltip: 'Eliminar serie',
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
