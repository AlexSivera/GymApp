import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = await exportBackup(ref.read(appDatabaseProvider));
      final dateSuffix = DateTime.now().toIso8601String().split('T').first;
      await FilePicker.saveFile(
        fileName: 'gymapp_backup_$dateSuffix.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (mounted) _showMessage('Copia de seguridad guardada.');
    } catch (e) {
      if (mounted) _showMessage('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar copia de seguridad'),
        content: const Text(
          'Las rutinas, entrenamientos y registros del archivo se añadirán a los que ya tienes '
          '— no se borra nada existente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final summary = await importBackup(ref.read(appDatabaseProvider), utf8.decode(bytes));
      if (mounted) {
        _showMessage(
          'Importado: ${summary.routines} rutina${summary.routines == 1 ? '' : 's'}, '
          '${summary.workoutSessions} entrenamiento${summary.workoutSessions == 1 ? '' : 's'}, '
          '${summary.bodyWeightLogs} registro${summary.bodyWeightLogs == 1 ? '' : 's'} de peso.',
        );
      }
    } on BackupFormatException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage('No se pudo importar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
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
                    child: Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Guarda tus rutinas, historial de entrenamientos, récords y peso corporal en un '
                    'archivo, para tenerlos a salvo o llevártelos a otro dispositivo.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _export,
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text(_busy ? 'Exportando...' : 'Exportar copia de seguridad'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
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
                    child: Icon(Icons.file_upload_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Restaura una copia de seguridad exportada antes — desde este dispositivo o desde otro.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _import,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: Text(_busy ? 'Importando...' : 'Importar copia de seguridad'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
