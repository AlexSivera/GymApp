import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/health_connect/health_connect_service.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../z/providers/z_providers.dart';

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
        ));
    await refreshDailyReminders(db);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias guardadas.')));
    }
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
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
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
          // Applied immediately, like the other switches that act at once.
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              title: const Text('Sonidos'),
              subtitle: const Text('Golpes, Kamehameha, transformaciones… (los del pack de recursos)'),
              value: ref.watch(zStateValueProvider).soundEnabled,
              onChanged: (value) => ref.read(zStateActionsProvider).setSoundEnabled(value),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              title: const Text('Episodios'),
              subtitle: const Text('«¡En el próximo episodio!» al terminar y «Anteriormente en GymZ…» cada semana'),
              value: ref.watch(zStateValueProvider).episodesEnabled,
              onChanged: (value) => ref.read(zStateActionsProvider).setEpisodesEnabled(value),
            ),
          ),
          // Reminders are local notifications and Health Connect is an
          // Android service — neither exists in the web version, so the PWA
          // doesn't show switches that would silently do nothing.
          if (!kIsWeb) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                title: const Text('Recordatorios'),
                subtitle: const Text('Que mi maestro me avise si hoy toca entrenar o si mi racha está en peligro'),
                value: _remindersEnabled,
                onChanged: (value) => setState(() => _remindersEnabled = value),
              ),
            ),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                title: const Text('Health Connect'),
                subtitle: const Text(
                    'Usar las calorías registradas por tu pulsera o reloj (Mi Fitness, etc.) en vez de la estimación de GymZ'),
                value: _healthConnectEnabled,
                onChanged: _healthConnectBusy ? null : _toggleHealthConnect,
              ),
            ),
          ],
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
