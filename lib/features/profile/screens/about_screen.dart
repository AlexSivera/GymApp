import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Icon(Icons.fitness_center, size: 28, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('GymApp', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Versión 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Registra tus entrenamientos de fuerza, sigue tu progreso y planifica tus rutinas — todo almacenado localmente en tu dispositivo.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
