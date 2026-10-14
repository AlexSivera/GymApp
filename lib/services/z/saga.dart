import 'package:flutter/painting.dart';

// Sagas measure the journey, not the strength: they only ever advance, one
// per completed-session milestone, and each one changes the Kame House sky.
enum Saga {
  saiyan('Saga Saiyan', 0, 'saga_saiyan', Color(0xFF6FB8FF)),
  namek('Saga de Namek', 25, 'saga_namek', Color(0xFF7BE3A8)),
  androides('Saga de los Androides', 75, 'saga_androides', Color(0xFFE0B07A)),
  buu('Saga de Buu', 150, 'saga_buu', Color(0xFFFF8FC8)),
  superSaga('Saga Super', 300, 'saga_super', Color(0xFFB69CFF));

  const Saga(this.label, this.startsAt, this.mediaSlot, this.color);

  final String label;
  // Completed sessions needed to enter this saga.
  final int startsAt;
  final String mediaSlot;
  final Color color;

  Saga? get next => index + 1 < Saga.values.length ? Saga.values[index + 1] : null;

  static Saga forCompletedSessions(int completed) {
    var saga = Saga.saiyan;
    for (final s in Saga.values) {
      if (completed >= s.startsAt) saga = s;
    }
    return saga;
  }

  // 0..1 through this saga toward the next one (1 in the last saga).
  double progress(int completed) {
    final next = this.next;
    if (next == null) return 1;
    return ((completed - startsAt) / (next.startsAt - startsAt)).clamp(0.0, 1.0);
  }
}
