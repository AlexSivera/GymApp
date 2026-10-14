import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/data/database/database_provider.dart';
import 'package:gymapp/features/z/screens/shenlong_screen.dart';
import 'package:gymapp/services/z/z_state.dart';

void main() {
  testWidgets('Shenlong appears, offers three wishes and grants one', (tester) async {
    await initializeDateFormatting('es');
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.gymz,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(ShenlongScreen.route()),
                  child: const Text('invocar'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('invocar'));
    // The whole summoning sequence.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Pide un deseo'), findsOneWidget);
    expect(find.text('Una semana libre'), findsOneWidget);
    expect(find.textContaining('Aura de Ultra Instinto'), findsOneWidget);

    await tester.tap(find.textContaining('Guerrero de las 7 esferas'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final stored = await db.zStateDao.read(ZKeys.title);
    expect(stored, 'Guerrero de las 7 esferas');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
  });
}
