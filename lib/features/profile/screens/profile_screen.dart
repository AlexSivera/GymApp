import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../insights/screens/insights_screen.dart';
import '../providers/profile_providers.dart';
import 'about_screen.dart';
import 'backups_screen.dart';
import 'body_weight_screen.dart';
import 'goals_screen.dart';
import 'import_export_screen.dart';
import 'personal_records_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final name = ref.watch(userSettingsProvider).valueOrNull?.name?.trim();

    final bodyWeightLog = ref.watch(latestBodyWeightProvider).valueOrNull;
    final totalWorkouts = ref.watch(totalWorkoutsCompletedProvider).valueOrNull;
    final streak = ref.watch(workoutStreakProvider).valueOrNull;
    final records = ref.watch(allPersonalRecordsProvider).valueOrNull;
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final insight = ref.watch(insightOfDayProvider).valueOrNull;

    final bodyWeightText = bodyWeightLog == null ? null : formatWeight(bodyWeightLog.weightKg, unit);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          if (name != null && name.isNotEmpty) ...[
            Text(
              'Hola, $name',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Resumen — a quick read of where things stand, not a set of
          // destinations. Three plain numbers instead of two big icon cards,
          // so it reads as a strip of facts rather than settings-menu tiles.
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: _SummaryMetric(value: bodyWeightText ?? '—', label: 'Peso')),
                _SummaryDivider(),
                Expanded(child: _SummaryMetric(value: totalWorkouts?.toString() ?? '—', label: 'Entrenos')),
                _SummaryDivider(),
                Expanded(
                  child: _SummaryMetric(
                    value: streak == null ? '—' : '$streak ${streak == 1 ? 'día' : 'días'}',
                    label: 'Racha',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          _ProfileSectionHeader('Progreso'),
          _ProfileSection(tiles: [
            _ProfileTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Peso corporal',
              subtitle: bodyWeightText,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BodyWeightScreen())),
            ),
            _ProfileTile(
              icon: Icons.emoji_events_outlined,
              title: 'Récords personales',
              subtitle: records == null
                  ? null
                  : '${records.length} récord${records.length == 1 ? '' : 's'}',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PersonalRecordsScreen())),
            ),
            _ProfileTile(
              icon: Icons.insights_outlined,
              title: 'Insights',
              subtitle: insight?.message,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsightsScreen())),
            ),
            _ProfileTile(
              icon: Icons.flag_outlined,
              title: 'Objetivos',
              subtitle: settings == null
                  ? null
                  : '${settings.weeklyTargetSessions} entrenos/semana',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
            ),
          ]),

          const SizedBox(height: AppSpacing.xxl),
          _ProfileSectionHeader('Aplicación'),
          _ProfileSection(tiles: [
            _ProfileTile(
              title: 'Configuración',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _ProfileTile(
              title: 'Exportar datos',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ImportExportScreen())),
            ),
            _ProfileTile(
              title: 'Copias de seguridad',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupsScreen())),
            ),
            _ProfileTile(
              title: 'Acerca de',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ]),
        ],
      ),
    );
  }
}

// A slim vertical hairline between summary metrics — deliberately not a full
// bordered tile, so the three numbers read as one grouped fact strip.
class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).dividerTheme.color),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

// Groups a section's tiles into a single card with hairline dividers between
// rows, instead of a flat list of individually-bordered ListTiles.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.tiles});

  final List<_ProfileTile> tiles;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

// [icon]/[subtitle] are both optional so the two sections this feeds can
// carry different visual weight from the same widget: Progreso rows get a
// small muted icon plus a real-data subtitle when there's something to show;
// Aplicación rows are plain title-and-chevron, deliberately lighter so the
// whole screen doesn't read as one flat settings list.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({this.icon, required this.title, this.subtitle, required this.onTap});

  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: icon == null ? null : Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      minLeadingWidth: 0,
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
      trailing: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
