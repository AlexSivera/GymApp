import 'package:drift/drift.dart';

import 'database/app_database.dart';

// One exercise inside a template day — mirrors the fields a RoutineExercise
// target already has, minus the ids (resolved by name against the catalog
// when the template is instantiated).
class RoutineTemplateExercise {
  const RoutineTemplateExercise({
    required this.exerciseName,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    this.restSeconds = 90,
  });

  final String exerciseName;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int restSeconds;
}

class RoutineTemplateDay {
  const RoutineTemplateDay({required this.name, required this.exercises});
  final String name;
  final List<RoutineTemplateExercise> exercises;
}

class RoutineTemplate {
  const RoutineTemplate({required this.name, required this.description, required this.days});
  final String name;
  final String description;
  final List<RoutineTemplateDay> days;
}

// Every exercise name here must match Exercise.name exactly (see
// data/seed/exercise_seed_data.dart) — instantiateRoutineTemplate silently
// skips any that don't resolve, so a typo here would just quietly drop that
// exercise rather than crash.
const routineTemplates = [
  RoutineTemplate(
    name: 'Full Body',
    description: 'Un único día de cuerpo completo — ideal para empezar con 2-3 sesiones por semana.',
    days: [
      RoutineTemplateDay(name: 'Día único', exercises: [
        RoutineTemplateExercise(exerciseName: 'Sentadilla', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Press banca', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Remo con barra', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Press militar', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Curl con mancuernas', sets: 2, repsMin: 10, repsMax: 15),
        RoutineTemplateExercise(
            exerciseName: 'Extensión de tríceps en polea', sets: 2, repsMin: 10, repsMax: 15),
      ]),
    ],
  ),
  RoutineTemplate(
    name: 'Empuje / Tirón / Pierna',
    description: 'Split clásico de 3 días — para entrenar de 3 a 6 veces por semana.',
    days: [
      RoutineTemplateDay(name: 'Empuje', exercises: [
        RoutineTemplateExercise(exerciseName: 'Press banca', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Press militar', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Fondos en paralelas', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Elevaciones laterales', sets: 3, repsMin: 12, repsMax: 15),
        RoutineTemplateExercise(
            exerciseName: 'Extensión de tríceps en polea', sets: 3, repsMin: 10, repsMax: 15),
      ]),
      RoutineTemplateDay(name: 'Tirón', exercises: [
        RoutineTemplateExercise(exerciseName: 'Dominadas', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Remo con barra', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Jalón al pecho', sets: 3, repsMin: 10, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Face pull', sets: 3, repsMin: 12, repsMax: 15),
        RoutineTemplateExercise(exerciseName: 'Curl con barra', sets: 3, repsMin: 10, repsMax: 15),
      ]),
      RoutineTemplateDay(name: 'Pierna', exercises: [
        RoutineTemplateExercise(exerciseName: 'Sentadilla', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Peso muerto rumano', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Prensa de piernas', sets: 3, repsMin: 10, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Curl femoral', sets: 3, repsMin: 10, repsMax: 15),
        RoutineTemplateExercise(exerciseName: 'Elevación de gemelos', sets: 4, repsMin: 12, repsMax: 20),
      ]),
    ],
  ),
  RoutineTemplate(
    name: 'Torso / Pierna',
    description: 'Split de 2 días — fácil de repetir 4 veces por semana.',
    days: [
      RoutineTemplateDay(name: 'Torso', exercises: [
        RoutineTemplateExercise(exerciseName: 'Press banca', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Remo con barra', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Press militar', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Jalón al pecho', sets: 3, repsMin: 8, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Curl con mancuernas', sets: 2, repsMin: 10, repsMax: 15),
        RoutineTemplateExercise(
            exerciseName: 'Extensión de tríceps en polea', sets: 2, repsMin: 10, repsMax: 15),
      ]),
      RoutineTemplateDay(name: 'Pierna', exercises: [
        RoutineTemplateExercise(exerciseName: 'Sentadilla', sets: 4, repsMin: 6, repsMax: 10),
        RoutineTemplateExercise(exerciseName: 'Peso muerto', sets: 3, repsMin: 5, repsMax: 8),
        RoutineTemplateExercise(exerciseName: 'Zancadas', sets: 3, repsMin: 10, repsMax: 12),
        RoutineTemplateExercise(exerciseName: 'Curl femoral', sets: 3, repsMin: 10, repsMax: 15),
        RoutineTemplateExercise(exerciseName: 'Elevación de gemelos', sets: 4, repsMin: 12, repsMax: 20),
      ]),
    ],
  ),
  RoutineTemplate(
    name: 'Fuerza básica (5×5)',
    description: 'Programa clásico para principiantes — 2 días alternos con series de 5.',
    days: [
      RoutineTemplateDay(name: 'Día A', exercises: [
        RoutineTemplateExercise(
            exerciseName: 'Sentadilla', sets: 5, repsMin: 5, repsMax: 5, restSeconds: 120),
        RoutineTemplateExercise(
            exerciseName: 'Press banca', sets: 5, repsMin: 5, repsMax: 5, restSeconds: 120),
        RoutineTemplateExercise(
            exerciseName: 'Remo con barra', sets: 5, repsMin: 5, repsMax: 5, restSeconds: 120),
      ]),
      RoutineTemplateDay(name: 'Día B', exercises: [
        RoutineTemplateExercise(
            exerciseName: 'Sentadilla', sets: 5, repsMin: 5, repsMax: 5, restSeconds: 120),
        RoutineTemplateExercise(
            exerciseName: 'Press militar', sets: 5, repsMin: 5, repsMax: 5, restSeconds: 120),
        RoutineTemplateExercise(
            exerciseName: 'Peso muerto', sets: 1, repsMin: 5, repsMax: 5, restSeconds: 150),
      ]),
    ],
  ),
];

// Creates the Routine + its RoutineDays + every RoutineExercise from a
// template, resolving each exercise by exact name against the catalog.
// Returns the new routine's id.
Future<int> instantiateRoutineTemplate(AppDatabase db, RoutineTemplate template) async {
  final allExercises = await db.exercisesDao.watchAll().first;
  final exerciseIdByName = {for (final e in allExercises) e.name: e.id};

  final routineId = await db.routinesDao.createRoutine(RoutinesCompanion.insert(name: template.name));

  for (var dayIndex = 0; dayIndex < template.days.length; dayIndex++) {
    final templateDay = template.days[dayIndex];
    final dayId = await db.routinesDao.createDay(RoutineDaysCompanion.insert(
      routineId: routineId,
      name: templateDay.name,
      dayOrder: dayIndex,
    ));

    for (var i = 0; i < templateDay.exercises.length; i++) {
      final templateExercise = templateDay.exercises[i];
      final exerciseId = exerciseIdByName[templateExercise.exerciseName];
      if (exerciseId == null) continue;
      await db.routinesDao.addExerciseToDay(RoutineExercisesCompanion.insert(
        routineDayId: dayId,
        exerciseId: exerciseId,
        orderIndex: i,
        targetSets: templateExercise.sets,
        targetRepsMin: templateExercise.repsMin,
        targetRepsMax: templateExercise.repsMax,
        restSeconds: Value(templateExercise.restSeconds),
      ));
    }
  }

  return routineId;
}
