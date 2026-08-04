import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/backup/backup_service.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  late Future<List<File>> _backupsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _backupsFuture = listBackups();
  }

  void _refresh() => setState(() => _backupsFuture = listBackups());

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      await createBackup();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Copia de seguridad creada.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(File backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar copia de seguridad'),
        content: const Text(
          'Se reemplazarán todos tus datos actuales por los de esta copia. Tendrás que reiniciar la aplicación para completar la restauración. ¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmed != true) return;

    await restoreBackup(backup);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copia restaurada. Cierra y vuelve a abrir la aplicación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de seguridad')),
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _createBackup,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<File>>(
        future: _backupsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final backups = snapshot.data!;
          if (backups.isEmpty) {
            return Center(
              child: Text(
                'Todavía no has creado ninguna copia de seguridad.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final file = backups[index];
              final modified = file.statSync().modified;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE d MMMM, HH:mm', 'es').format(modified),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      TextButton(onPressed: () => _restore(file), child: const Text('Restaurar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
