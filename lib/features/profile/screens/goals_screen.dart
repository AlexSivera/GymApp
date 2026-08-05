import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _weeklyTarget = 4;
  late final TextEditingController _notesController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(appDatabaseProvider).userSettingsDao.updateSettings(UserSettingsCompanion(
          weeklyTargetSessions: Value(_weeklyTarget),
          goals: Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Objetivos guardados.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    if (settings != null && !_initialized) {
      _weeklyTarget = settings.weeklyTargetSessions;
      _notesController.text = settings.goals ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrenamientos por semana', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove,
                      onTap: _weeklyTarget > 1 ? () => setState(() => _weeklyTarget--) : null,
                    ),
                    SizedBox(
                      width: 64,
                      child: Text('$_weeklyTarget',
                          textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                    ),
                    _RoundIconButton(
                      icon: Icons.add,
                      onTap: _weeklyTarget < 7 ? () => setState(() => _weeklyTarget++) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Objetivo personal', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Ej. Llegar a 100 kg en press banca'),
                ),
              ],
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22, color: onTap == null ? theme.colorScheme.onSurfaceVariant : null),
        ),
      ),
    );
  }
}
