import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/database_provider.dart';
import 'data/seed/exercise_seeder.dart';
import 'router/app_router.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/reminder_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await NotificationService.init();

  final db = AppDatabase();
  await syncSeedExercises(db);
  await db.userSettingsDao.ensureDefaultRow();
  final onboardingDone = await db.userSettingsDao.isOnboardingCompleted();
  unawaited(refreshDailyReminders(db));

  final router = buildAppRouter(initialLocation: onboardingDone ? '/dashboard' : '/onboarding');

  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: GymApp(router: router),
  ));
}
