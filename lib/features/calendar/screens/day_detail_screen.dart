import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  const DayDetailScreen({super.key, required this.date, this.existingSession});

  final DateTime date;
  final WorkoutSession? existingSession;

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  late SessionStatus _status;
  late final TextEditingController _notesController;
  late final TextEditingController _bodyWeightController;
  int? _feeling;

  @override
  void initState() {
    super.initState();
    final session = widget.existingSession;
    _status = session?.status ??
        (widget.date.isBefore(_dateOnly(DateTime.now()))
            ? SessionStatus.completed
            : SessionStatus.planned);
    _notesController = TextEditingController(text: session?.notes ?? '');
    _bodyWeightController =
        TextEditingController(text: session?.bodyWeightKg?.toString() ?? '');
    _feeling = session?.feeling;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _bodyWeightController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _save() async {
    final dao = ref.read(appDatabaseProvider).workoutSessionsDao;
    final bodyWeight = double.tryParse(_bodyWeightController.text.replaceAll(',', '.'));
    final notes = _notesController.text.trim();

    final existing = widget.existingSession;
    if (existing == null) {
      await dao.createSession(WorkoutSessionsCompanion.insert(
        date: widget.date,
        status: Value(_status),
        notes: Value(notes.isEmpty ? null : notes),
        bodyWeightKg: Value(bodyWeight),
        feeling: Value(_feeling),
      ));
    } else {
      await dao.updateSession(existing.copyWith(
        status: _status,
        notes: Value(notes.isEmpty ? null : notes),
        bodyWeightKg: Value(bodyWeight),
        feeling: Value(_feeling),
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existingSession;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text('¿Seguro que quieres eliminar el entrenamiento de este día?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(appDatabaseProvider).workoutSessionsDao.deleteSession(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE d MMMM', 'es').format(widget.date)),
        actions: [
          if (widget.existingSession != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Estado', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<SessionStatus>(
            segments: const [
              ButtonSegment(value: SessionStatus.planned, label: Text('Planificado')),
              ButtonSegment(value: SessionStatus.completed, label: Text('Completado')),
              ButtonSegment(value: SessionStatus.skipped, label: Text('Saltado')),
            ],
            selected: {_status == SessionStatus.inProgress ? SessionStatus.completed : _status},
            onSelectionChanged: (selection) => setState(() => _status = selection.first),
          ),
          const SizedBox(height: 24),
          Text('Sensación', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final value = i + 1;
              final selected = _feeling == value;
              return IconButton(
                iconSize: 32,
                onPressed: () => setState(() => _feeling = selected ? null : value),
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text('Peso corporal (kg)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Ej. 78.5', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Text('Notas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Cómo te sentiste, ajustes, etc.', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existingSession == null ? 'Crear entrenamiento' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
