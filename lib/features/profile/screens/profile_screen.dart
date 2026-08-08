import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../insights/screens/insights_screen.dart';
import '../../ranking/screens/ranking_screen.dart';
import 'about_screen.dart';
import 'backups_screen.dart';
import 'body_weight_screen.dart';
import 'goals_screen.dart';
import 'import_export_screen.dart';
import 'personal_records_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          _ProfileSectionHeader('Entrenamiento'),
          _ProfileSection(tiles: [
            _ProfileTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Peso corporal',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const BodyWeightScreen())),
            ),
            _ProfileTile(
              icon: Icons.insights_outlined,
              label: 'Insights',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsightsScreen())),
            ),
            _ProfileTile(
              icon: Icons.emoji_events_outlined,
              label: 'Récords personales',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PersonalRecordsScreen())),
            ),
            _ProfileTile(
              icon: Icons.military_tech_outlined,
              label: 'Rangos',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RankingScreen())),
            ),
            _ProfileTile(
              icon: Icons.flag_outlined,
              label: 'Objetivos',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _ProfileSectionHeader('Aplicación'),
          _ProfileSection(tiles: [
            _ProfileTile(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _ProfileTile(
              icon: Icons.import_export,
              label: 'Importar / Exportar datos',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ImportExportScreen())),
            ),
            _ProfileTile(
              icon: Icons.backup_outlined,
              label: 'Copias de seguridad',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupsScreen())),
            ),
            _ProfileTile(
              icon: Icons.info_outline,
              label: 'Acerca de',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ]),
        ],
      ),
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
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
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
            if (i != tiles.length - 1) const Divider(height: 1, indent: 68),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
