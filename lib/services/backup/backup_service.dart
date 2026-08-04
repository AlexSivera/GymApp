import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

Future<Directory> _backupsDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'backups'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

// Copies the live SQLite file into the app's own backups folder. Restoring
// it requires an app restart (the running connection can't be hot-swapped
// safely), which the caller should tell the user.
Future<File> createBackup() async {
  final docs = await getApplicationDocumentsDirectory();
  final source = File(p.join(docs.path, 'gymapp.sqlite'));
  final dir = await _backupsDir();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final target = File(p.join(dir.path, 'backup_$timestamp.sqlite'));
  return source.copy(target.path);
}

Future<List<File>> listBackups() async {
  final dir = await _backupsDir();
  final entries = await dir.list().toList();
  final files = entries.whereType<File>().toList()
    ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}

// Overwrites the live database file with a previous backup. The app must be
// restarted afterwards for the change to take effect.
Future<void> restoreBackup(File backup) async {
  final docs = await getApplicationDocumentsDirectory();
  final target = File(p.join(docs.path, 'gymapp.sqlite'));
  await backup.copy(target.path);
}

// Human-readable JSON snapshot of routines and workout history, for the
// user's own records — not intended to be re-imported.
Future<File> exportDataAsJson(AppDatabase db) async {
  final routines = await db.routinesDao.watchAllRoutines().first;
  final exercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in exercises) e.id: e};

  final routinesJson = [];
  for (final routine in routines) {
    final days = await db.routinesDao.watchDays(routine.id).first;
    final daysJson = [];
    for (final day in days) {
      final dayExercises = await db.routinesDao.watchExercisesForDay(day.id).first;
      daysJson.add({
        'name': day.name,
        'exercises': [
          for (final re in dayExercises)
            {
              'exercise': exercisesById[re.exerciseId]?.name ?? 'Ejercicio',
              'sets': re.targetSets,
              'repsMin': re.targetRepsMin,
              'repsMax': re.targetRepsMax,
            },
        ],
      });
    }
    routinesJson.add({'name': routine.name, 'days': daysJson});
  }

  final completedSessions = await db.workoutSessionsDao.getCompletedSessionsInRange(
    DateTime(2000),
    DateTime(2100),
  );

  final data = {
    'exportedAt': DateTime.now().toIso8601String(),
    'routines': routinesJson,
    'completedWorkouts': completedSessions.length,
  };

  final dir = await _backupsDir();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File(p.join(dir.path, 'export_$timestamp.json'));
  return file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
}
