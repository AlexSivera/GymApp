import 'campaign.dart';

// Texts for "¡En el próximo episodio de GymZ!" and "Anteriormente en
// GymZ…", built from the user's real data. Pure functions so they can be
// tested without a database.

String _days(int n) => n == 1 ? '1 día' : '$n días';

class EpisodeText {
  const EpisodeText({required this.headline, required this.body, this.footer});

  final String headline;
  final String body;
  final String? footer;
}

class NextEpisodeInput {
  const NextEpisodeInput({
    required this.name,
    required this.campaign,
    required this.doneThisWeek,
    required this.weeklyTarget,
    this.todaysCombat,
    this.extraHit = 0,
    this.nextSessionLabel,
    this.dragonBalls = 0,
    this.thisWeekBallMet = false,
    this.nearMaster,
  });

  final String name;
  final CampaignState campaign;
  final int doneThisWeek;
  final int weeklyTarget;
  final CampaignEvent? todaysCombat;
  final double extraHit;
  // "el jueves · Cápsula Nº 02 · Tirón"
  final String? nextSessionLabel;
  final int dragonBalls;
  final bool thisWeekBallMet;
  // ("Vegeta", "8/10 límites superados")
  final (String, String)? nearMaster;
}

EpisodeText nextEpisode(NextEpisodeInput i) {
  final footer = i.nextSessionLabel == null ? null : 'Próximo combate: ${i.nextSessionLabel}';
  final combat = i.todaysCombat;
  if (combat != null) {
    final next = combat.nextFight;
    if (next == null) {
      return EpisodeText(
        headline: '¡El final de la campaña!',
        body: '${i.name} ha derrotado a ${combat.fight.displayName}. No queda nadie en el universo capaz de pararle… por ahora.',
        footer: footer,
      );
    }
    if (combat.transforms) {
      return EpisodeText(
        headline: '¡${combat.fight.villain} se transforma!',
        body: '${i.name} ha vencido a ${combat.fight.displayName}, pero aún no ha mostrado todo su poder. '
            'La semana que viene le espera ${next.displayName}. ¡No te lo pierdas!',
        footer: footer,
      );
    }
    if (combat.endsSaga) {
      return EpisodeText(
        headline: '¡Rumbo a la ${next.saga.label}!',
        body: '${i.name} ha terminado la ${combat.fight.saga.label}. Un nuevo enemigo le espera: ${next.displayName}. ¡No te lo pierdas!',
        footer: footer,
      );
    }
    return EpisodeText(
      headline: '¡${next.villain} entra en escena!',
      body: 'Tras derrotar a ${combat.fight.displayName}, ${i.name} tendrá que enfrentarse a ${next.displayName}. ¿Estará a la altura?',
      footer: footer,
    );
  }

  final fight = i.campaign.current;
  if (fight == null) {
    return EpisodeText(
      headline: '¡Un guerrero en paz!',
      body: '${i.name} ha completado la campaña. Sigue entrenando: nuevos enemigos llegarán pronto.',
      footer: footer,
    );
  }

  if (i.extraHit > 0) {
    return EpisodeText(
      headline: '¡Golpe de ventaja!',
      body: '${i.name} ya le ha quitado un ${(i.extraHit * 100).round()} % a ${fight.displayName} antes del combate. ¡No te lo pierdas!',
      footer: footer,
    );
  }

  if (i.dragonBalls == 6 && !i.thisWeekBallMet) {
    final left = (i.weeklyTarget - i.doneThisWeek).clamp(0, i.weeklyTarget);
    return EpisodeText(
      headline: '¡La séptima esfera!',
      body: 'A ${i.name} le ${left == 1 ? 'queda 1 combate' : 'quedan $left combates'} esta semana para reunir las siete esferas e invocar a Shenlong. ¡No te lo pierdas!',
      footer: footer,
    );
  }

  final remaining = (i.weeklyTarget - i.doneThisWeek).clamp(0, i.weeklyTarget);
  final wounded = i.campaign.hp < 0.999;
  final tease = i.nearMaster == null ? '' : ' Y ojo: ${i.nearMaster!.$1} está a punto de reconocerte (${i.nearMaster!.$2}).';
  return EpisodeText(
    headline: wounded ? '¡${fight.villain}, herido!' : '¡${fight.villain} te espera!',
    body: 'Te ${remaining == 1 ? 'queda' : 'quedan'} ${_days(remaining)} para el combate contra ${fight.displayName}. '
        '¿Podrá ${i.name} acabar con él?$tease',
    footer: footer,
  );
}

// ------------------------------------------------- Anteriormente en GymZ…

class RecapInput {
  const RecapInput({
    required this.name,
    required this.weekStart,
    required this.done,
    required this.target,
    required this.ballEarned,
    required this.genkidamaPercent,
    required this.records,
    required this.combats,
    required this.mastersJoined,
    required this.campaign,
    required this.dragonBalls,
  });

  final String name;
  final DateTime weekStart;
  final int done;
  final int target;
  final bool ballEarned;
  final int genkidamaPercent;
  final int records;
  // Combats resolved for that week (normally one).
  final List<CampaignEvent> combats;
  final List<String> mastersJoined;
  final CampaignState campaign;
  final int dragonBalls;
}

class RecapPage {
  const RecapPage({required this.kicker, required this.title, this.lines = const []});

  final String kicker;
  final String title;
  // (big number or word, text)
  final List<(String, String)> lines;
}

List<RecapPage> recapPages(RecapInput i) {
  final ratio = i.target <= 0 ? 0 : i.done / i.target;
  final cover = ratio >= 1
      ? '${i.name} entrenó como nunca en la cámara de gravedad'
      : i.done == 0
          ? '${i.name} desapareció de la cámara de gravedad… ¿dónde se habrá metido?'
          : '${i.name} siguió entrenando, aunque se dejó algún día por el camino';

  final campaignLines = <(String, String)>[];
  for (final combat in i.combats) {
    if (combat.defeated) {
      campaignLines.add(('K.O.', '${i.name} derrotó a ${combat.fight.displayName}'));
      final next = combat.nextFight;
      if (combat.transforms && next != null) {
        campaignLines.add(('→', '${combat.fight.villain} se transformó: ahora es ${next.displayName}'));
      } else if (next != null) {
        campaignLines.add(('→', 'Nuevo rival: ${next.displayName}'));
      }
    } else {
      campaignLines.add(('${(combat.damage * 100).round()} %', 'de daño a ${combat.fight.displayName}'));
      campaignLines.add((
        '${(combat.hpAfter * 100).round()} %',
        'de vida le queda… y se curará un ${combat.fight.healPercent} %',
      ));
    }
  }
  for (final master in i.mastersJoined) {
    campaignLines.add(('+', '$master se unió como maestro'));
  }
  if (campaignLines.isEmpty) campaignLines.add(('—', 'La campaña siguió en calma'));

  final current = i.campaign.current;
  return [
    RecapPage(kicker: 'ANTERIORMENTE EN GYMZ…', title: cover),
    RecapPage(kicker: 'LA SEMANA', title: ratio >= 1 ? 'Semana cumplida' : 'Semana a medias', lines: [
      ('${i.done}', 'combates de ${i.target}'),
      (i.ballEarned ? '★' : '—', i.ballEarned ? 'Esfera conseguida' : 'Sin esfera esta vez'),
      ('${i.genkidamaPercent} %', 'de Genkidama'),
      ('${i.records}', i.records == 1 ? 'límite superado' : 'límites superados'),
    ]),
    RecapPage(kicker: 'LA CAMPAÑA', title: i.combats.any((c) => c.defeated) ? '¡Victoria!' : 'El combate sigue', lines: campaignLines),
    RecapPage(kicker: 'ESTA SEMANA', title: current == null ? 'Campaña completada' : 'Te espera ${current.displayName}', lines: [
      if (current != null) ('${(i.campaign.hp * 100).round()} %', 'de vida de tu rival'),
      ('${i.target}', 'combates para vencerle'),
      ('${i.dragonBalls}/7', 'esferas reunidas'),
    ]),
  ];
}
