import '../../data/database/app_database.dart';
import 'dragon_balls.dart' show addWeeks, weekStartOf;

// La Genkidama: this week's training volume gathered into a sphere, full
// once it matches the average of the previous 4 weeks (weeks with no
// training don't drag the average down — a holiday shouldn't make the next
// week's sphere trivially easy to fill... nor impossible).
class Genkidama {
  const Genkidama({required this.volumeThisWeek, required this.averageVolume});

  final double volumeThisWeek;
  // 0 when there's no history to compare against yet.
  final double averageVolume;

  // 0..1.5 — can overflow a bit past "full" so a big week still shows.
  double get fill {
    if (averageVolume <= 0) return volumeThisWeek > 0 ? 1 : 0;
    return (volumeThisWeek / averageVolume).clamp(0.0, 1.5);
  }

  int get percent => (fill * 100).round();
  bool get isFull => fill >= 1;
}

Future<Genkidama> computeGenkidama(AppDatabase db, {DateTime? now}) async {
  final thisWeek = weekStartOf(now ?? DateTime.now());
  final volumeThisWeek =
      await db.progressDao.totalVolumeInRange(thisWeek, addWeeks(thisWeek, 1));

  final previous = <double>[];
  for (var i = 1; i <= 4; i++) {
    final start = addWeeks(thisWeek, -i);
    final volume = await db.progressDao.totalVolumeInRange(start, addWeeks(start, 1));
    if (volume > 0) previous.add(volume);
  }
  final average = previous.isEmpty ? 0.0 : previous.reduce((a, b) => a + b) / previous.length;
  return Genkidama(volumeThisWeek: volumeThisWeek, averageVolume: average);
}
