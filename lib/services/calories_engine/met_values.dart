import '../../data/database/app_database.dart';

// MET (Metabolic Equivalent of Task) values — the standard building block
// for estimating calorie burn from an activity, roughly: kcal/hour =
// MET × bodyweightKg. Values below are ballpark figures from the widely
// used Compendium of Physical Activities, picked per cardio exercise; a
// single flat value covers strength training since we don't track exertion
// level per set.
const double strengthMet = 5.0;

// Static holds (Plancha, isometric neck exercises...) burn less than active
// cardio but more than sitting still — "abdominal exercise, plank" sits
// around this in the Compendium.
const double isometricMet = 3.5;

const Map<String, double> _cardioMetByExerciseName = {
  'Bicicleta': 8.0,
  'Bicicleta estática': 7.0,
  'Elíptica': 5.0,
  'Trote en cinta': 7.0,
  'Sprint con trineo (prowler)': 8.0,
  'Bicicleta reclinada': 5.0,
  'Comba (saltar la cuerda)': 10.0,
  'Remo estático': 7.0,
  'Correr en cinta': 9.0,
  'Patinaje': 7.0,
  'Escaladora (stairmaster)': 8.0,
  'Escalera mecánica (step mill)': 8.0,
  'Trail running / senderismo': 7.0,
  'Caminar en cinta': 3.5,
};

// Rough pace (minutes per km) used only when a cardio set logged distance
// but no duration — lets that set still count instead of contributing 0.
const Map<String, double> _cardioPaceMinPerKm = {
  'Bicicleta': 3.0,
  'Bicicleta estática': 3.0,
  'Trote en cinta': 7.0,
  'Correr en cinta': 6.0,
  'Trail running / senderismo': 8.0,
  'Caminar en cinta': 12.0,
};
const double _defaultPaceMinPerKm = 6.0;

double metForExercise(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.cardio:
      return _cardioMetByExerciseName[exercise.name] ?? 6.0;
    case ExerciseCategory.isometric:
      return isometricMet;
    case ExerciseCategory.strength:
      return strengthMet;
  }
}

double paceMinPerKmForExercise(Exercise exercise) =>
    _cardioPaceMinPerKm[exercise.name] ?? _defaultPaceMinPerKm;
