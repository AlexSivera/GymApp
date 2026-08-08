import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/muscle_groups.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../providers/ranking_providers.dart';
import '../widgets/body_diagram.dart';
import '../widgets/rank_badge.dart';
import 'classify_exercises_screen.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final predicted = ref.watch(overallPredictedRankProvider);
    final unclassified = ref.watch(unclassifiedExercisesProvider);
    final muscleRanks = ref.watch(muscleRanksProvider);
    final available = ref.watch(availableMusclesProvider);
    final grouped = groupedAvailableMuscles(available);

    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final colorsByMuscle = {
      for (final entry in muscleRanks.entries) entry.key: rankTierColors[entry.value.tier]!,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Rangos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RANGO PREDECIDO',
                              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.5)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(predicted?.label ?? 'Sin rango', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            predicted == null
                                ? 'Completa y clasifica al menos un ejercicio.'
                                : 'Estimación a partir de tu propio progreso — no te compara con otras personas.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    RankBadge(rank: predicted ?? const Rank(RankTier.hierro, 1), size: 56),
                  ],
                ),
                if (unclassified.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassifyExercisesScreen()),
                      ),
                      child: Text('Clasificar ejercicios · ${unclassified.length} restantes'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(child: BodyDiagram(colorsByMuscle: colorsByMuscle, emptyColor: emptyColor)),
          const SizedBox(height: AppSpacing.xl),
          Text('Rankings musculares', style: theme.textTheme.titleLarge),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
              child: Text(entry.key,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    _MuscleRow(muscle: entry.value[i], rank: muscleRanks[entry.value[i]]),
                    if (i != entry.value.length - 1) const Divider(height: 1, indent: 68),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.muscle, required this.rank});

  final String muscle;
  final Rank? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Icon(iconForMuscle(muscle), size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(muscle),
      subtitle: Text(
        rank?.label ?? 'Sin rango',
        style: theme.textTheme.bodySmall?.copyWith(
          color: rank == null ? theme.colorScheme.onSurfaceVariant : rankTierColors[rank!.tier],
          fontWeight: rank == null ? null : FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MuscleDetailSheet(muscle: muscle),
      ),
    );
  }
}

class _MuscleDetailSheet extends ConsumerWidget {
  const _MuscleDetailSheet({required this.muscle});

  final String muscle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(exercisesForMuscleProvider(muscle));
    final muscleRank = ref.watch(muscleRanksProvider)[muscle];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(muscle, style: theme.textTheme.titleLarge),
                      if (muscleRank != null)
                        Text(muscleRank.label,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: rankTierColors[muscleRank.tier])),
                    ],
                  ),
                ),
                if (muscleRank != null) RankBadge(rank: muscleRank, size: 40),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Rangos de tus ejercicios',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Todavía no has clasificado ningún ejercicio de este grupo.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              for (final info in exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: ExerciseThumbnail(imagePaths: info.exercise.imagePaths),
                      title: Text(info.exercise.name),
                      subtitle: Text(info.rank.label,
                          style: TextStyle(color: rankTierColors[info.rank.tier])),
                      trailing: RankBadge(rank: info.rank, size: 32),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
