// "58 min" under an hour, "1h 02m" from 60 minutes up — shared by every
// place that surfaces a session's logged duration (hero card, activity feed).
String formatWorkoutDuration(int totalSeconds) {
  final totalMinutes = (totalSeconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours <= 0) return '$totalMinutes min';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
