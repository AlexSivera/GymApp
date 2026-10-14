import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/power_level.dart';
import '../../../services/z/saga.dart';
import '../../../services/z/z_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/z_providers.dart';
import 'kame_house_cards.dart';

// The top of the Ficha de guerrero: avatar in its aura, name and title,
// scouter reading and the saga the user is in.
class WarriorCard extends ConsumerWidget {
  const WarriorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userSettingsProvider).valueOrNull?.name?.trim();
    final state = ref.watch(zStateValueProvider);
    final reading = ref.watch(powerReadingProvider);
    final saga = ref.watch(sagaProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2860), Color(0xFF121838)],
        ),
        border: Border.all(color: ZColors.gold.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            bottom: -26,
            child: Text('戦士', style: ZText.display(size: 64, color: Colors.white.withValues(alpha: 0.06))),
          ),
          Row(
            children: [
              const WarriorAvatar(size: 64),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? 'Guerrero' : name,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state.title != null && state.title!.isNotEmpty)
                      Text(state.title!, style: ZText.hud(size: 12, color: ZColors.gold)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reading == null
                          ? 'PWR — · SIN LECTURA'
                          : 'PWR ${formatPowerLevel(reading.level)} · ${reading.rank.shortLabel.toUpperCase()}',
                      style: ZText.hud(size: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SagaPill(saga: saga),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SagaPill extends StatelessWidget {
  const _SagaPill({required this.saga});

  final Saga saga;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: saga.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: saga.color),
      ),
      child: Text(saga.label, style: TextStyle(color: saga.color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class SagaProgressCard extends ConsumerWidget {
  const SagaProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completed = ref.watch(completedSessionsCountProvider);
    final saga = ref.watch(sagaProvider);
    final next = saga.next;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROGRESO DE SAGA', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
              const Spacer(),
              Text(
                next == null ? '$completed combates' : '$completed de ${next.startsAt} combates',
                style: ZText.hud(size: 11, color: ZColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final s in Saga.values) ...[
                Expanded(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: s.index < saga.index ? 1 : s == saga ? saga.progress(completed) : 0,
                          minHeight: 6,
                          color: s.color,
                          backgroundColor: ZColors.panelRaised,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.label.replaceFirst('Saga de los ', '').replaceFirst('Saga de ', '').replaceFirst('Saga ', ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: s == saga ? FontWeight.w800 : FontWeight.w500,
                          color: s == saga ? s.color : ZColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s != Saga.values.last) const SizedBox(width: 4),
              ],
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Te ${next.startsAt - completed == 1 ? 'falta 1 combate' : 'faltan ${next.startsAt - completed} combates'} para la ${next.label}.',
              style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

// Wish rewards: pick which unlocked aura and title to wear. Hidden until
// Shenlong has granted at least one.
class WishRewardsCard extends ConsumerWidget {
  const WishRewardsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(zStateValueProvider);
    final actions = ref.read(zStateActionsProvider);
    final auras = state.ownedAuras;
    final titles = state.ownedTitles;
    if (auras.isEmpty && titles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ZColors.namek.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESEOS DE SHENLONG', style: theme.textTheme.labelMedium?.copyWith(color: ZColors.namek)),
          if (auras.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Aura', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Mi transformación'),
                  selected: state.aura == null,
                  onSelected: (_) => actions.setAura(''),
                ),
                for (final ZAura aura in auras)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: aura.color, radius: 6),
                    label: Text(aura.label),
                    selected: state.auraId == aura.id,
                    onSelected: (_) => actions.setAura(aura.id),
                  ),
              ],
            ),
          ],
          if (titles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Título', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Ninguno'),
                  selected: state.title == null || state.title!.isEmpty,
                  onSelected: (_) => actions.setTitle(''),
                ),
                for (final title in titles)
                  ChoiceChip(
                    label: Text(title),
                    selected: state.title == title,
                    onSelected: (_) => actions.setTitle(title),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
