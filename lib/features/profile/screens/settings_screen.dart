import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  String _units = 'kg';
  bool _initialized = false;

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
    await ref.read(appDatabaseProvider).userSettingsDao.updateSettings(UserSettingsCompanion(
          units: Value(_units),
          name: Value(_nameController.text.trim().isEmpty ? null : _nameController.text.trim()),
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias guardadas.')));
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
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Nombre', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Tu nombre')),
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
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
