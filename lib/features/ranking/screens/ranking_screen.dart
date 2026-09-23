import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/muscle_groups.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../providers/ranking_providers.dart';
import '../widgets/body_diagram.dart';
import '../widgets/body_masks.dart';
import '../widgets/body_thumbnail.dart';
import '../widgets/rank_badge.dart';
import 'exercise_rank_detail_screen.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final predicted = ref.watch(overallPredictedRankProvider);
    final muscleRanks = ref.watch(muscleRanksProvider);
    final available = ref.watch(availableMusclesProvider);
    // Every muscle of the body diagram is always listed (unranked ones as
    // "Sin rango"), plus any extra muscle a custom exercise uses.
    final grouped = groupedAvailableMuscles([...muscleGroups.values.expand((m) => m), ...available]);

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
                          Text('RANGO ESTIMADO',
                              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.5)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(predicted?.label ?? 'Sin rango', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            predicted == null
                                ? 'Termina un entrenamiento para empezar a ver tu rango.'
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (predicted == null)
            const _RankingEmptyState()
          else ...[
            AppCard(
              padding: EdgeInsets.zero,
              color: BodyDiagram.backgroundColor,
              child: BodyDiagram(colorsByMuscle: colorsByMuscle),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Rankings musculares', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final MapEntry(key: group, value: muscles) in grouped.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: muscleGroups[group]?.length == 1
                    ? _MuscleCard(muscle: muscles.single, rank: muscleRanks[muscles.single], standalone: true)
                    : _MuscleGroupCard(group: group, muscles: muscles, ranks: muscleRanks),
              ),
          ],
        ],
      ),
    );
  }
}

// Shown instead of the (otherwise all-grey) body diagram and muscle list
// until the user has completed a single workout — without this, a brand-new
// install just shows an empty silhouette with no explanation of what "Rangos"
// even is or how to unlock it.
class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.military_tech_rounded, color: colors.accent, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Aquí verás tu progreso por músculo', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cada ejercicio que completes te acerca a un rango, de Hierro a Maestro. '
            'Termina tu primer entrenamiento para desbloquear el primero.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/calendar'),
              child: const Text('Ir a mis rutinas'),
            ),
          ),
        ],
      ),
    );
  }
}

// Highlight for a muscle in the list thumbnails: its rank color, or a faint
// white when unranked so it's still clear which muscle the row is about.
Color _thumbnailColor(Rank? rank) =>
    rank == null ? Colors.white.withValues(alpha: 0.28) : rankTierColors[rank.tier]!;

// Card tinted by a rank's color (plain surface when there's no rank).
class _RankTintedCard extends StatelessWidget {
  const _RankTintedCard({required this.rank, required this.child, this.onTap});

  final Rank? rank;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tier = rank == null ? null : rankTierColors[rank!.tier];
    return Material(
      color: tier == null ? colors.surface : Color.alphaBlend(tier.withValues(alpha: 0.08), colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: tier?.withValues(alpha: 0.4) ?? colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
      ),
    );
  }
}

// "ORO III · 1/3" / "SIN RANGO · 0/6" — [count] only for groups.
class _RankLine extends StatelessWidget {
  const _RankLine({required this.rank, this.count});

  final Rank? rank;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: rank?.label.toUpperCase() ?? 'SIN RANGO',
          style: base?.copyWith(
            color: rank == null ? theme.colorScheme.onSurfaceVariant : rankTierColors[rank!.tier],
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null) TextSpan(text: ' · $count', style: base?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.frame, required this.colorsByMuscle, required this.shape, required this.icon});

  final BodyFrame? frame;
  final Map<String, Color> colorsByMuscle;
  final BodyThumbnailShape shape;
  final IconData icon; // fallback for muscles outside the body diagram

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    if (frame case final frame?) {
      return BodyThumbnail(frame: frame, colorsByMuscle: colorsByMuscle, size: size, shape: shape);
    }
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
      child: Icon(icon, color: theme.colorScheme.primary),
    );
  }
}

// One muscle: hexagon icon when it stands alone (Pecho, Hombros...), round
// icon plus rank badge when it's listed inside an expanded group.
class _MuscleCard extends StatelessWidget {
  const _MuscleCard({required this.muscle, required this.rank, this.standalone = false});

  final String muscle;
  final Rank? rank;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _RankTintedCard(
      rank: rank,
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MuscleDetailSheet(muscle: muscle),
      ),
      child: Row(
        children: [
          _Thumbnail(
            frame: muscleFrames[muscle],
            colorsByMuscle: {muscle: _thumbnailColor(rank)},
            shape: standalone ? BodyThumbnailShape.hexagon : BodyThumbnailShape.circle,
            icon: iconForMuscle(muscle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(muscle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                _RankLine(rank: rank),
              ],
            ),
          ),
          if (!standalone && rank != null) RankBadge(rank: rank!, size: 36),
        ],
      ),
    );
  }
}

// Brazos / Piernas / Espalda: collapsed to one row with the group's average
// rank and how many of its muscles are ranked; tap to show each muscle.
class _MuscleGroupCard extends StatefulWidget {
  const _MuscleGroupCard({required this.group, required this.muscles, required this.ranks});

  final String group;
  final List<String> muscles;
  final Map<String, Rank> ranks;

  @override
  State<_MuscleGroupCard> createState() => _MuscleGroupCardState();
}

class _MuscleGroupCardState extends State<_MuscleGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = [for (final m in widget.muscles) ?widget.ranks[m]];
    final groupRank = ranked.isEmpty ? null : averageRank(ranked);

    return Column(
      children: [
        _RankTintedCard(
          rank: groupRank,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              _Thumbnail(
                frame: bestGroupFrame(widget.group, [for (final m in widget.muscles) if (widget.ranks.containsKey(m)) m]),
                colorsByMuscle: {for (final m in widget.muscles) m: _thumbnailColor(widget.ranks[m])},
                shape: BodyThumbnailShape.hexagon,
                icon: Icons.category_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.group, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    _RankLine(rank: groupRank, count: '${ranked.length}/${widget.muscles.length}'),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.sm),
                  child: Column(
                    children: [
                      for (final muscle in widget.muscles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _MuscleCard(muscle: muscle, rank: widget.ranks[muscle]),
                        ),
                    ],
                  ),
                ),
        ),
      ],
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
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ExerciseRankDetailScreen(
                          exerciseId: info.exercise.id,
                          exerciseName: info.exercise.name,
                        ),
                      )),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
