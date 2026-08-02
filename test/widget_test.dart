import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gymapp/app.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/data/database/database_provider.dart';

void main() {
  testWidgets('App starts and shows the dashboard', (WidgetTester tester) async {
    await initializeDateFormatting('es');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
        child: const GymApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hoy'), findsOneWidget);

    // Unmount while still inside the test body so drift's cleanup timer
    // (scheduled when the database's stream subscriptions are cancelled)
    // fires before the test framework's final "no pending timers" check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
