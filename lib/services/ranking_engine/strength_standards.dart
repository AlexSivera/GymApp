// Baseline strength estimates that power the Rangos feature.
//
// These are NOT real population statistics — GymApp has no access to other
// users' data (it's local-only), so there is no honest way to show "you're
// in the top X%". Instead every exercise gets a hand-estimated baseline:
// roughly what an untrained ~27-year-old weighing ~83kg could lift for a
// solid working set. That baseline anchors the middle of the ladder (Plata)
// and scales with the person's own body weight. It's explicitly an estimate,
// and the UI should always frame it as one.
class ExerciseStandard {
  const ExerciseStandard(this.ratio, {this.bodyweightBased = false});

  // baseline 1RM ÷ reference body weight (83kg). Multiply by the current
  // user's body weight to get their personal baseline for this exercise.
  final double ratio;

  // True for exercises where the load logged is *added* weight on top of
  // the lifter's own body weight (dips, pull-ups) — the effective 1RM used
  // for ranking is bodyweight + logged weight, not the logged weight alone.
  final bool bodyweightBased;
}

const referenceBodyweightKg = 83.0;

// Keyed by exercise name (matches exercise_seed_data.dart). Exercises not
// in this map (custom exercises, or seed exercises added later without a
// curated estimate — e.g. pure-bodyweight ab work with no meaningful
// weight signal) simply can't be ranked yet; the Rangos screen skips them.
const exerciseStandards = <String, ExerciseStandard>{
  // Pecho
  'Press banca': ExerciseStandard(40 / referenceBodyweightKg),
  'Press banca inclinado': ExerciseStandard(33 / referenceBodyweightKg),
  'Press banca con mancuernas': ExerciseStandard(18 / referenceBodyweightKg),
  'Aperturas con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Fondos en paralelas': ExerciseStandard(0.75, bodyweightBased: true),
  'Cruces en polea': ExerciseStandard(10 / referenceBodyweightKg),

  // Espalda
  'Dominadas': ExerciseStandard(0.9, bodyweightBased: true),
  'Remo con barra': ExerciseStandard(40 / referenceBodyweightKg),
  'Remo con mancuerna': ExerciseStandard(20 / referenceBodyweightKg),
  'Jalón al pecho': ExerciseStandard(55 / referenceBodyweightKg),
  'Remo en máquina': ExerciseStandard(50 / referenceBodyweightKg),
  'Peso muerto': ExerciseStandard(75 / referenceBodyweightKg),
  'Face pull': ExerciseStandard(12 / referenceBodyweightKg),

  // Hombros
  'Press militar': ExerciseStandard(25 / referenceBodyweightKg),
  'Press militar con mancuernas': ExerciseStandard(12 / referenceBodyweightKg),
  'Elevaciones laterales': ExerciseStandard(6 / referenceBodyweightKg),
  'Elevaciones frontales': ExerciseStandard(6 / referenceBodyweightKg),
  'Pájaros': ExerciseStandard(5 / referenceBodyweightKg),
  'Press Arnold': ExerciseStandard(11 / referenceBodyweightKg),

  // Bíceps
  'Curl con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl martillo': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl en banco Scott': ExerciseStandard(16 / referenceBodyweightKg),

  // Tríceps
  'Press francés': ExerciseStandard(18 / referenceBodyweightKg),
  'Extensión de tríceps en polea': ExerciseStandard(25 / referenceBodyweightKg),
  'Fondos para tríceps': ExerciseStandard(0.7, bodyweightBased: true),
  'Patada de tríceps': ExerciseStandard(4 / referenceBodyweightKg),

  // Cuádriceps
  'Sentadilla': ExerciseStandard(50 / referenceBodyweightKg),
  'Prensa de piernas': ExerciseStandard(120 / referenceBodyweightKg),
  'Zancadas': ExerciseStandard(12 / referenceBodyweightKg),
  'Sentadilla búlgara': ExerciseStandard(10 / referenceBodyweightKg),
  'Extensión de cuádriceps': ExerciseStandard(33 / referenceBodyweightKg),

  // Isquiotibiales
  'Peso muerto rumano': ExerciseStandard(50 / referenceBodyweightKg),
  'Curl femoral': ExerciseStandard(25 / referenceBodyweightKg),

  // Glúteos
  'Hip thrust': ExerciseStandard(70 / referenceBodyweightKg),

  // Gemelos
  'Elevación de gemelos': ExerciseStandard(50 / referenceBodyweightKg),

  // Abdomen: no meaningful added-weight signal for these in most logs, so
  // intentionally left unranked (Crunch, Plancha, Elevación de piernas,
  // Rueda abdominal).
};
