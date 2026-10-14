import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/services/z/campaign.dart';
import 'package:gymapp/services/z/episodes.dart';
import 'package:gymapp/services/z/masters.dart';

void main() {
  // Mondays.
  final w1 = DateTime(2026, 10, 5);
  final w2 = DateTime(2026, 10, 12);
  final w3 = DateTime(2026, 10, 19);
  final w4 = DateTime(2026, 10, 26);

  int indexOf(String id) => campaignFights.indexWhere((f) => f.id == id);

  CampaignState at(String fightId, {double hp = 1, bool fought = false, DateTime? lastResolved}) => CampaignState(
        startWeek: w1,
        lastResolvedWeek: lastResolved ?? w1.subtract(const Duration(days: 7)),
        fightIndex: indexOf(fightId),
        hp: hp,
        foughtBefore: fought,
        extraHitsThisWeek: 0,
        history: const [],
        unseen: const [],
      );

  group('daño semanal', () {
    test('la curva acordada', () {
      expect(weeklyDamage(4, 4), 1);
      expect(weeklyDamage(3, 4), closeTo(0.75, 1e-9));
      expect(weeklyDamage(2, 4), closeTo(0.40, 1e-9));
      expect(weeklyDamage(1, 4), closeTo(0.15, 1e-9));
      expect(weeklyDamage(0, 4), 0);
      expect(weeklyDamage(6, 4), 1);
    });

    test('sirve para otros objetivos', () {
      expect(weeklyDamage(4, 5), closeTo(0.80, 0.005));
      expect(weeklyDamage(3, 5), closeTo(0.54, 0.005));
      expect(weeklyDamage(2, 3), closeTo(0.633, 0.005));
    });
  });

  group('el ejemplo del jefe de 1.000 de vida (cura 25 %)', () {
    // Freezer 1.ª forma se cura un 25 %, como el ejemplo.
    CampaignState afterWeek1() {
      final s = catchUpCampaign(at('freezer_1'), perWeek: {w1: 3}, weeklyTarget: 4, now: w2);
      expect(s.hp, closeTo(0.25, 1e-9), reason: '3/4 le quita 750');
      expect(s.foughtBefore, isTrue);
      return s;
    }

    test('la semana siguiente 3/4 lo derrota', () {
      final s = catchUpCampaign(afterWeek1(), perWeek: {w2: 3}, weeklyTarget: 4, now: w3);
      expect(s.fightIndex, indexOf('freezer_2'));
      final event = s.unseen.last;
      expect(event.healed, closeTo(0.25, 1e-9));
      expect(event.hpBefore, closeTo(0.5, 1e-9), reason: 'se cura 250 → 500');
      expect(event.defeated, isTrue);
      expect(event.transforms, isTrue);
    });

    test('pero 2/4 no (le quedan 100)', () {
      final s = catchUpCampaign(afterWeek1(), perWeek: {w2: 2}, weeklyTarget: 4, now: w3);
      expect(s.fightIndex, indexOf('freezer_1'));
      expect(s.hp, closeTo(0.10, 1e-9));
    });

    test('1/4 tampoco', () {
      final s = catchUpCampaign(afterWeek1(), perWeek: {w2: 1}, weeklyTarget: 4, now: w3);
      expect(s.hp, closeTo(0.35, 1e-9));
    });
  });

  test('Raditz (15 %) se remata con 2/4 tras un 3/4', () {
    final s = catchUpCampaign(at('raditz'), perWeek: {w1: 3, w2: 2}, weeklyTarget: 4, now: w3);
    expect(s.fightIndex, indexOf('nappa'));
  });

  test('Cell superperfecto (60 %) exige la semana perfecta tras un 3/4', () {
    final s = catchUpCampaign(at('cell_superperfecto'), perWeek: {w1: 3, w2: 3}, weeklyTarget: 4, now: w3);
    expect(s.fightIndex, indexOf('cell_superperfecto'));
  });

  test('una semana sin entrenar no hace daño y el jefe se cura', () {
    final s = catchUpCampaign(at('nappa', hp: 0.5, fought: true), perWeek: const {}, weeklyTarget: 4, now: w2);
    expect(s.hp, closeTo(0.7, 1e-9));
    expect(s.unseen.single.damage, 0);
  });

  test('una forma nueva no se cura en su primera semana', () {
    final s = catchUpCampaign(at('raditz'), perWeek: {w1: 4, w2: 1}, weeklyTarget: 4, now: w3);
    expect(s.fightIndex, indexOf('nappa'));
    expect(s.unseen.last.healed, 0);
    expect(s.hp, closeTo(0.85, 1e-9));
  });

  group('combate al completar la semana', () {
    test('el entreno que completa el objetivo es un K.O.', () {
      final result = onSessionCompleted(at('raditz'), doneThisWeek: 4, weeklyTarget: 4, now: w1.add(const Duration(days: 3)));
      expect(result.event!.defeated, isTrue);
      expect(result.state.fightIndex, indexOf('nappa'));
      expect(result.state.lastResolvedWeek, w1);
    });

    test('antes del objetivo no hay combate', () {
      final result = onSessionCompleted(at('raditz'), doneThisWeek: 3, weeklyTarget: 4, now: w1);
      expect(result.event, isNull);
      expect(result.state.fightIndex, indexOf('raditz'));
    });

    test('los días extra quitan un 10 % al siguiente, hasta un 30 %', () {
      var s = onSessionCompleted(at('raditz'), doneThisWeek: 4, weeklyTarget: 4, now: w1).state;
      for (var i = 0; i < 4; i++) {
        s = onSessionCompleted(s, doneThisWeek: 5 + i, weeklyTarget: 4, now: w1).state;
      }
      expect(s.hp, closeTo(0.7, 1e-9));
    });

    test('una semana ya resuelta no se vuelve a resolver el domingo', () {
      final s = onSessionCompleted(at('raditz'), doneThisWeek: 4, weeklyTarget: 4, now: w1).state;
      final caught = catchUpCampaign(s, perWeek: {w1: 4}, weeklyTarget: 4, now: w2);
      expect(caught.fightIndex, indexOf('nappa'));
      expect(caught.hp, 1);
      expect(caught.unseen, isEmpty);
    });
  });

  test('el estado sobrevive a guardarse y cargarse', () {
    final s = catchUpCampaign(at('freezer_1'), perWeek: {w1: 3, w2: 3, w3: 1}, weeklyTarget: 4, now: w4);
    final loaded = CampaignState.decode(s.encode())!;
    expect(loaded.encode(), s.encode());
    expect(loaded.history.length, 3);
  });

  test('la campaña tiene 31 combates y empieza en Raditz', () {
    expect(campaignFights.length, 31);
    expect(CampaignState.start(w1).current!.id, 'raditz');
  });

  test('racha de semanas para Krilin y Piccolo', () {
    final perWeek = {w1: 4, w2: 4, w3: 2, w4: 4};
    expect(bestWeekStreak(perWeek, 4, from: w1, currentWeek: w4), 2);
    expect(bestWeekStreak(perWeek, 4, from: w1, currentWeek: w4, protectedWeeks: {w3}), 4);
  });

  test('el próximo episodio usa el texto acordado', () {
    final text = nextEpisode(NextEpisodeInput(
      name: 'Alex',
      campaign: at('nappa'),
      doneThisWeek: 2,
      weeklyTarget: 4,
    ));
    expect(text.body, startsWith('Te quedan 2 días para el combate contra Nappa.'));
  });
}
