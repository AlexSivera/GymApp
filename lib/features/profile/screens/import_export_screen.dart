import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/backup/backup_service.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final file = await exportDataAsJson(db);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Datos exportados en ${file.path}')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Importar / Exportar datos')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(Icons.upload_file_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Exporta un resumen en JSON de tus rutinas y tu historial de entrenamientos, guardado dentro del propio dispositivo.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_exporting ? 'Exportando...' : 'Exportar datos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
