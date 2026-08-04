import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../insights/screens/insights_screen.dart';
import '../../progress/screens/progress_screen.dart';
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _ProfileSectionHeader('Entrenamiento'),
          _ProfileTile(
            icon: Icons.monitor_weight_outlined,
            label: 'Peso corporal',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BodyWeightScreen())),
          ),
          _ProfileTile(
            icon: Icons.show_chart,
            label: 'Progreso',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
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
            icon: Icons.flag_outlined,
            label: 'Objetivos',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          const Divider(height: AppSpacing.xxl),
          _ProfileSectionHeader('Aplicación'),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
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
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
