import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/data/database/database_provider.dart';
import 'package:gymapp/features/z/screens/boss_fight_screen.dart';
import 'package:gymapp/features/z/screens/episode_screens.dart';
import 'package:gymapp/features/z/screens/master_unlock_screen.dart';
import 'package:gymapp/features/z/screens/masters_screen.dart';
import 'package:gymapp/services/z/campaign.dart';
import 'package:gymapp/services/z/episodes.dart';
import 'package:gymapp/services/z/masters.dart';

// Pumps each phase-2 screen on a small phone and runs its animations to the
// end: any overflow or layout error fails the test.
void main() {
  late AppDatabase db;

  setUp(() async {
    await initializeDateFormatting('es');
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: AppTheme.gymz, home: screen),
    ));
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  final week = DateTime(2026, 10, 12);
  CampaignEvent event(String id, {required bool defeated}) {
    final index = campaignFights.indexWhere((f) => f.id == id);
    return CampaignEvent(
      weekStart: week,
      fightIndex: index,
      done: defeated ? 4 : 2,
      target: 4,
      damage: defeated ? 1 : 0.4,
      hpBefore: defeated ? 1 : 0.5,
      hpAfter: defeated ? 0 : 0.1,
      defeated: defeated,
      healed: defeated ? 0 : 0.25,
    );
  }

  testWidgets('combate: K.O. con transformación y recompensa', (tester) async {
    await pump(tester, BossFightScreen(event: event('freezer_100', defeated: true), attack: attackById('galick_gun')));
    expect(find.text('K.O.'), findsOneWidget);
    expect(find.textContaining('Rayo mortal'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('combate del domingo: el villano resiste', (tester) async {
    await pump(tester, BossFightScreen(event: event('nappa', defeated: false), attack: attackById('rafaga'), sundayResult: true));
    expect(find.text('¡RESISTE!'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('combate de entrenamiento con un maestro', (tester) async {
    await pump(tester, MasterUnlockScreen(master: masterById('vegeta')));
    expect(find.textContaining('Galick Gun'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('próximo episodio', (tester) async {
    final text = nextEpisode(NextEpisodeInput(name: 'Alex', campaign: CampaignState.start(week), doneThisWeek: 1, weeklyTarget: 4, nextSessionLabel: 'jueves 15 · Tirón'));
    await pump(tester, NextEpisodeScreen(text: text, sagaSlot: 'saga_saiyan'));
    expect(find.textContaining('Te quedan 3 días'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('anteriormente en GymZ', (tester) async {
    final pages = recapPages(RecapInput(
      name: 'Alex',
      weekStart: week,
      done: 3,
      target: 4,
      ballEarned: false,
      genkidamaPercent: 87,
      records: 2,
      combats: [event('nappa', defeated: false)],
      mastersJoined: const ['Roshi'],
      campaign: CampaignState.start(week),
      dragonBalls: 3,
    ));
    await pump(tester, RecapScreen(pages: pages, sagaSlot: 'saga_saiyan'));
    expect(find.textContaining('ANTERIORMENTE'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('maestros y ataques', (tester) async {
    await pump(tester, const MastersScreen());
    expect(find.text('Tus maestros'), findsOneWidget);
    await unmount(tester);
  });
}
