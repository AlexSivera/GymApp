import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/mentor_lines.dart';
import '../providers/z_providers.dart';
import '../widgets/campaign_widgets.dart';

// Ficha → Maestros y ataques: your main master, the training combats still
// ahead (with their trial progress) and the attack collection.
class MastersScreen extends ConsumerWidget {
  const MastersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(zStateValueProvider);
    final main = ref.watch(mainMasterProvider);
    final trials = ref.watch(masterTrialsProvider);
    final unlocked = state.unlockedMasterIds;
    final unlockedAttacks = state.unlockedAttackIds;
    final equipped = ref.watch(equippedAttackProvider);
    final actions = ref.read(zStateActionsProvider);

    String lockedAttackHint(ZAttack attack) {
      final master = masters.where((m) => m.attackId == attack.id).firstOrNull;
      if (master != null) return master.id == 'kaio' ? 'Reúne las 7 esferas' : 'Vence a ${master.name}';
      final fight = campaignFights.where((f) => f.reward.attackId == attack.id).firstOrNull;
      return fight == null ? '' : 'Derrota a ${fight.displayName}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Maestros y ataques')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            borderColor: main.color.withValues(alpha: 0.6),
            child: Row(
              children: [
                MentorPortrait(master: main, size: 64),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAESTRO PRINCIPAL', style: ZText.hud(size: 11, color: main.color)),
                      Text(main.name, style: theme.textTheme.headlineMedium),
                      Text('Te da los consejos y los avisos. ${main.personality}.',
                          style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Tus maestros', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final master in masters)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MasterRow(
                master: master,
                unlocked: unlocked.contains(master.id),
                isMain: master.id == main.id,
                trial: trials[master.id]!,
                onMakeMain: () => actions.setMainMaster(master.id),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Ataque final', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('El que lanzas al terminar cada entrenamiento. Son estéticos: todos hacen el mismo daño.',
              style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.55,
            children: [
              for (final attack in zAttacks)
                _AttackTile(
                  attack: attack,
                  unlocked: unlockedAttacks.contains(attack.id),
                  equipped: attack.id == equipped.id,
                  hint: lockedAttackHint(attack),
                  onTap: () => actions.setAttack(attack.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasterRow extends StatelessWidget {
  const _MasterRow({required this.master, required this.unlocked, required this.isMain, required this.trial, required this.onMakeMain});

  final Master master;
  final bool unlocked;
  final bool isMain;
  final MasterTrial trial;
  final VoidCallback onMakeMain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isMain ? master.color : null,
      child: Row(
        children: [
          Opacity(
            opacity: unlocked ? 1 : 0.4,
            child: MentorPortrait(master: master, mood: unlocked ? MentorMood.contento : MentorMood.serio, size: 48),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(master.name, style: theme.textTheme.titleMedium),
                if (unlocked)
                  Text('Enseña: ${attackById(master.attackId).name}', style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted))
                else ...[
                  Text(master.trialText, style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: trial.progress, minHeight: 5, color: master.color),
                  ),
                  const SizedBox(height: 2),
                  Text(trial.label, style: ZText.hud(size: 10, color: ZColors.muted)),
                ],
              ],
            ),
          ),
          if (unlocked)
            isMain
                ? Text('PRINCIPAL', style: ZText.hud(size: 10, color: master.color))
                : TextButton(onPressed: onMakeMain, child: const Text('Elegir')),
        ],
      ),
    );
  }
}

class _AttackTile extends StatelessWidget {
  const _AttackTile({required this.attack, required this.unlocked, required this.equipped, required this.hint, required this.onTap});

  final ZAttack attack;
  final bool unlocked;
  final bool equipped;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Material(
        color: ZColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: equipped ? ZColors.gold : ZColors.line, width: equipped ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: unlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: unlocked
                          ? [attack.colors.first.withValues(alpha: 0.15), attack.colors.first, attack.colors.last]
                          : const [Color(0xFF2A3160), Color(0xFF3A4170)],
                    ),
                  ),
                ),
                const Spacer(),
                Text(attack.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  equipped ? 'Equipado' : unlocked ? attack.source : '🔒 $hint',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: equipped ? ZColors.gold : ZColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
