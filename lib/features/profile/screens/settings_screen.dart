import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/health_connect/health_connect_service.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  String _units = 'kg';
  bool _remindersEnabled = true;
  bool _healthConnectEnabled = false;
  bool _healthConnectBusy = false;
  AppThemeMode _themeMode = AppThemeMode.dark;
  bool _initialized = false;
  final _healthConnect = const HealthConnectService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = ref.read(appDatabaseProvider);
    await db.userSettingsDao.updateSettings(UserSettingsCompanion(
          units: Value(_units),
          name: Value(_nameController.text.trim().isEmpty ? null : _nameController.text.trim()),
          remindersEnabled: Value(_remindersEnabled),
          themeMode: Value(_themeMode.key),
        ));
    await refreshDailyReminders(db);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias guardadas.')));
    }
  }

  // Applied immediately (unlike the other fields, which wait for "Guardar")
  // so picking a theme gives instant visual feedback instead of requiring a
  // save-then-look round trip.
  Future<void> _selectTheme(AppThemeMode mode) async {
    setState(() => _themeMode = mode);
    final db = ref.read(appDatabaseProvider);
    await db.userSettingsDao.updateSettings(UserSettingsCompanion(themeMode: Value(mode.key)));
  }

  // Also applied immediately: turning this on needs to walk through Health
  // Connect availability + a permissions prompt right away, so the switch
  // needs to reflect whether that actually succeeded, not just what the
  // user tapped.
  Future<void> _toggleHealthConnect(bool value) async {
    if (!value) {
      setState(() => _healthConnectEnabled = false);
      await ref
          .read(appDatabaseProvider)
          .userSettingsDao
          .updateSettings(const UserSettingsCompanion(healthConnectEnabled: Value(false)));
      return;
    }

    setState(() => _healthConnectBusy = true);
    try {
      await _healthConnect.configure();
      if (!await _healthConnect.isAvailable()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Instala la app Health Connect desde Play Store para poder vincularla.'),
          ));
        }
        return;
      }
      final granted = await _healthConnect.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se concedió permiso para leer las calorías de Health Connect.'),
          ));
        }
        return;
      }
      setState(() => _healthConnectEnabled = true);
      await ref
          .read(appDatabaseProvider)
          .userSettingsDao
          .updateSettings(const UserSettingsCompanion(healthConnectEnabled: Value(true)));
    } finally {
      if (mounted) setState(() => _healthConnectBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    if (settings != null && !_initialized) {
      _units = settings.units;
      _nameController.text = settings.name ?? '';
      _remindersEnabled = settings.remindersEnabled;
      _healthConnectEnabled = settings.healthConnectEnabled;
      _themeMode = AppThemeMode.fromKey(settings.themeMode);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                    controller: _nameController, decoration: const InputDecoration(hintText: 'Tu nombre')),
                const SizedBox(height: AppSpacing.lg),
                Text('Unidades', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('kg')),
                    ButtonSegment(value: 'lb', label: Text('lb')),
                  ],
                  selected: {_units},
                  onSelectionChanged: (selection) => setState(() => _units = selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apariencia', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final mode in AppThemeMode.values)
                      _ThemeSwatch(
                        mode: mode,
                        selected: mode == _themeMode,
                        onTap: () => _selectTheme(mode),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recordatorios'),
              subtitle: const Text('Avisarme si hoy toca entrenar o si mi racha está en riesgo'),
              value: _remindersEnabled,
              onChanged: (value) => setState(() => _remindersEnabled = value),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Health Connect'),
              subtitle: const Text(
                  'Usar las calorías registradas por tu pulsera/reloj (Mi Fitness, etc.) en vez de la estimación de Machoke'),
              value: _healthConnectEnabled,
              onChanged: _healthConnectBusy ? null : _toggleHealthConnect,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Guardar')),
          ),
        ],
      ),
    );
  }
}

// A small self-contained preview of a theme's own palette (not the currently
// active one) so the user can compare all 5 options side by side before
// picking one.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.mode, required this.selected, required this.onTap});

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppTheme.colorsFor(mode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? colors.accent : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(colors.accent),
                const SizedBox(width: 4),
                _dot(colors.surfaceRaised),
                const SizedBox(width: 4),
                _dot(colors.statusCompleted),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              mode.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
