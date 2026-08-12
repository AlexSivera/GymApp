import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../data/database/app_database.dart';
import '../providers/profile_providers.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(allPersonalRecordsProvider);
    final unit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Récords personales')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(
          message: 'No se han podido cargar tus récords.',
          onRetry: () => ref.invalidate(allPersonalRecordsProvider),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Text(
                'Todavía no tienes récords registrados.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final entry = records[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: const Icon(Icons.emoji_events, size: 20, color: Color(0xFFFBBF24)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.exerciseName, style: theme.textTheme.titleMedium),
                            Text(_typeLabel(entry.record.type), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_valueLabel(entry.record, unit), style: theme.textTheme.titleMedium),
                          Text(
                            DateFormat('d MMM y', 'es').format(entry.record.achievedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
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

  String _typeLabel(PersonalRecordType type) {
    switch (type) {
      case PersonalRecordType.maxWeight:
        return 'Peso máximo';
      case PersonalRecordType.maxReps:
        return 'Repeticiones máximas';
      case PersonalRecordType.estimatedOneRepMax:
        return '1RM estimado';
      case PersonalRecordType.maxVolume:
        return 'Volumen máximo';
    }
  }

  String _valueLabel(PersonalRecord record, WeightUnit unit) {
    switch (record.type) {
      case PersonalRecordType.maxReps:
        return '${record.value.toStringAsFixed(0)} reps';
      default:
        return formatWeight(record.value, unit);
    }
  }
}
