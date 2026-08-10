import '../../data/database/app_database.dart';
import 'met_values.dart';

// Used whenever the user's body weight isn't known yet (skipped onboarding
// on an existing install, or no weigh-in logged) — an average adult weight,
// just enough to keep the estimate from being wildly off rather than zero.
const double fallbackBodyWeightKg = 70.0;

const double _secondsPerRep = 3.0;

class UserProfile {
  const UserProfile({required this.weightKg, this.age, this.gender});

  final double weightKg;
  final int? age;
  final String? gender;
}

int? ageFromBirthDate(DateTime? birthDate, {DateTime? now}) {
  if (birthDate == null) return null;
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  final hadBirthdayThisYear =
      (today.month > birthDate.month) || (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthdayThisYear) age--;
  return age;
}

// Women burn somewhat less than men for the same MET×weight×time — commonly
// modeled with a small flat discount rather than a full separate formula.
// Metabolic rate also drifts down gradually with age. Both are mild
// corrections on top of the MET estimate, not the main driver of the number
// (that's still weight, reps and duration).
double _genderFactor(String? gender) => gender == 'Mujer' ? 0.9 : 1.0;

double _ageFactor(int? age) {
  if (age == null) return 1.0;
  if (age >= 50) return 0.95;
  if (age >= 40) return 0.98;
  return 1.0;
}

// Estimated kcal burned by one completed set. Strength sets derive active
// time from reps (no rest-timer time counted — that's recovery, not effort)
// and scale the MET up or down by how heavy the load is relative to
// bodyweight, so a heavier set of the same rep count reads as more effort.
// Cardio sets use the logged duration directly (or a rough pace-based
// estimate if only distance was logged).
double estimateSetCalories({
  required Exercise exercise,
  required WorkoutSet set,
  required UserProfile profile,
}) {
  if (!set.isCompleted) return 0;
  final correction = _genderFactor(profile.gender) * _ageFactor(profile.age);

  if (exercise.category == ExerciseCategory.cardio) {
    final hours = _cardioHours(exercise, set);
    if (hours <= 0) return 0;
    return metForExercise(exercise) * profile.weightKg * hours * correction;
  }

  final reps = set.reps;
  if (reps == null || reps <= 0) return 0;
  final activeHours = (reps * _secondsPerRep) / 3600;
  // Bodyweight exercises (Crunch, Plancha...) never get an added weight
  // dialed in, so weightKg is either null or left at its 0 default — either
  // way, treat the load as bodyweight itself rather than reading "0kg" as
  // literally no effort (which would floor relativeIntensity at its 0.2
  // minimum and badly under-count the calorie burn).
  final loggedWeight = set.weightKg;
  final load = (loggedWeight == null || loggedWeight == 0) ? profile.weightKg : loggedWeight;
  final relativeIntensity = (load / profile.weightKg).clamp(0.2, 1.5);
  final effectiveMet = strengthMet * (0.7 + relativeIntensity);
  return effectiveMet * profile.weightKg * activeHours * correction;
}

double _cardioHours(Exercise exercise, WorkoutSet set) {
  final duration = set.durationSeconds;
  if (duration != null && duration > 0) return duration / 3600;
  final distance = set.distanceMeters;
  if (distance != null && distance > 0) {
    final km = distance / 1000;
    final minutes = km * paceMinPerKmForExercise(exercise);
    return minutes / 60;
  }
  return 0;
}

// Builds the profile every estimate above needs, straight from the DB —
// shared by the post-workout summary and the dashboard's daily total so
// both use the exact same weight/age/gender at any given moment.
Future<UserProfile> loadUserProfile(AppDatabase db) async {
  final settings = await db.userSettingsDao.watchSettings().first;
  final latestWeight = await db.bodyWeightDao.watchLatest().first;
  return UserProfile(
    weightKg: latestWeight?.weightKg ?? fallbackBodyWeightKg,
    age: ageFromBirthDate(settings?.birthDate),
    gender: settings?.gender,
  );
}

// Sums the estimate above across every completed set in a session.
Future<double> estimateSessionCalories(
  AppDatabase db, {
  required int sessionId,
  required UserProfile profile,
}) async {
  final sessionExercises = await db.sessionLoggingDao.watchSessionExercises(sessionId).first;
  if (sessionExercises.isEmpty) return 0;

  final allExercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in allExercises) e.id: e};

  var total = 0.0;
  for (final sessionExercise in sessionExercises) {
    final exercise = exercisesById[sessionExercise.exerciseId];
    if (exercise == null) continue;
    final sets = await db.sessionLoggingDao.getSets(sessionExercise.id);
    for (final set in sets) {
      total += estimateSetCalories(exercise: exercise, set: set, profile: profile);
    }
  }
  return total;
}
