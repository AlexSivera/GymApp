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
// in this map (custom exercises, or exercises with no meaningful *external*
// weight signal — pure bodyweight core/glute/lumbar work like Crunch,
// Flexiones, Puente de glúteos, Hiperextensiones lumbares, Glute ham raise...
// where people don't log an added weight in practice) simply can't be
// ranked yet; the Rangos screen skips them. Cardio and isometric (duration-
// based) exercises never reach this map at all — they never carry
// weightKg/reps in the first place.
const exerciseStandards = <String, ExerciseStandard>{
  // Pecho
  'Press banca': ExerciseStandard(40 / referenceBodyweightKg),
  'Press banca inclinado': ExerciseStandard(33 / referenceBodyweightKg),
  'Press banca con mancuernas': ExerciseStandard(18 / referenceBodyweightKg),
  'Aperturas con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Fondos en paralelas': ExerciseStandard(0.75, bodyweightBased: true),
  'Cruces en polea': ExerciseStandard(10 / referenceBodyweightKg),
  'Contractor de pecho (máquina)': ExerciseStandard(12 / referenceBodyweightKg),
  'Press de pecho en polea': ExerciseStandard(20 / referenceBodyweightKg),
  'Aperturas en polea (banco plano)': ExerciseStandard(9 / referenceBodyweightKg),
  'Press inclinado con mancuernas': ExerciseStandard(16 / referenceBodyweightKg),
  'Press de pecho en máquina': ExerciseStandard(35 / referenceBodyweightKg),
  'Pullover con mancuerna': ExerciseStandard(15 / referenceBodyweightKg),
  'Press declinado en máquina Smith': ExerciseStandard(38 / referenceBodyweightKg),
  'Press de pecho inclinado en polea': ExerciseStandard(16 / referenceBodyweightKg),
  'Press banca en máquina Smith': ExerciseStandard(42 / referenceBodyweightKg),
  'Press banca inclinado en máquina Smith': ExerciseStandard(35 / referenceBodyweightKg),

  // Espalda
  'Dominadas': ExerciseStandard(0.9, bodyweightBased: true),
  'Remo con barra': ExerciseStandard(40 / referenceBodyweightKg),
  'Remo con mancuerna': ExerciseStandard(20 / referenceBodyweightKg),
  'Jalón al pecho': ExerciseStandard(55 / referenceBodyweightKg),
  'Remo en máquina': ExerciseStandard(50 / referenceBodyweightKg),
  'Peso muerto': ExerciseStandard(75 / referenceBodyweightKg),
  'Face pull': ExerciseStandard(12 / referenceBodyweightKg),
  'Remo en T': ExerciseStandard(45 / referenceBodyweightKg),
  'Remo inclinado con mancuernas': ExerciseStandard(20 / referenceBodyweightKg),
  'Jalón con brazos rectos (polea)': ExerciseStandard(20 / referenceBodyweightKg),
  'Jalón al pecho agarre cerrado (V)': ExerciseStandard(55 / referenceBodyweightKg),
  'Remo en polea alta de rodillas': ExerciseStandard(35 / referenceBodyweightKg),
  'Remo con dos mancuernas inclinado': ExerciseStandard(20 / referenceBodyweightKg),
  'Remo sentado en polea a una mano': ExerciseStandard(20 / referenceBodyweightKg),
  'Remo inclinado en máquina Smith': ExerciseStandard(45 / referenceBodyweightKg),
  'Remo en T tumbado (máquina)': ExerciseStandard(50 / referenceBodyweightKg),
  'Remo alto en máquina': ExerciseStandard(45 / referenceBodyweightKg),

  // Trapecio
  'Encogimientos con barra': ExerciseStandard(60 / referenceBodyweightKg),
  'Encogimientos con mancuernas': ExerciseStandard(30 / referenceBodyweightKg),
  'Encogimientos en polea': ExerciseStandard(40 / referenceBodyweightKg),
  'Encogimientos en máquina': ExerciseStandard(50 / referenceBodyweightKg),
  'Remo al mentón con mancuernas': ExerciseStandard(15 / referenceBodyweightKg),
  'Remo al mentón con barra': ExerciseStandard(20 / referenceBodyweightKg),

  // Lumbares
  'Buenos días con barra': ExerciseStandard(30 / referenceBodyweightKg),

  // Hombros
  'Press militar': ExerciseStandard(25 / referenceBodyweightKg),
  'Press militar con mancuernas': ExerciseStandard(12 / referenceBodyweightKg),
  'Elevaciones laterales': ExerciseStandard(6 / referenceBodyweightKg),
  'Elevaciones frontales': ExerciseStandard(6 / referenceBodyweightKg),
  'Pájaros': ExerciseStandard(5 / referenceBodyweightKg),
  'Press Arnold': ExerciseStandard(11 / referenceBodyweightKg),
  'Press militar en máquina': ExerciseStandard(28 / referenceBodyweightKg),
  'Elevación frontal en polea': ExerciseStandard(6 / referenceBodyweightKg),
  'Remo con cuerda para deltoides posterior': ExerciseStandard(10 / referenceBodyweightKg),
  'Rotación externa de hombro con mancuerna': ExerciseStandard(3 / referenceBodyweightKg),
  'Aperturas posteriores en máquina': ExerciseStandard(15 / referenceBodyweightKg),
  'Push press con barra': ExerciseStandard(45 / referenceBodyweightKg),
  'Thruster con kettlebell': ExerciseStandard(20 / referenceBodyweightKg),
  'Press militar en máquina Smith': ExerciseStandard(28 / referenceBodyweightKg),

  // Bíceps
  'Curl con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl martillo': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl en banco Scott': ExerciseStandard(16 / referenceBodyweightKg),
  'Curl de concentración': ExerciseStandard(8 / referenceBodyweightKg),
  'Curl con barra Z': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl de bíceps en máquina': ExerciseStandard(20 / referenceBodyweightKg),
  'Curl de bíceps en polea': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl Zottman': ExerciseStandard(8 / referenceBodyweightKg),
  'Curl con barra Z agarre cerrado': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl inclinado con mancuernas': ExerciseStandard(7 / referenceBodyweightKg),
  'Curl Scott en máquina': ExerciseStandard(16 / referenceBodyweightKg),

  // Tríceps
  'Press francés': ExerciseStandard(18 / referenceBodyweightKg),
  'Extensión de tríceps en polea': ExerciseStandard(25 / referenceBodyweightKg),
  'Fondos para tríceps': ExerciseStandard(0.7, bodyweightBased: true),
  'Patada de tríceps': ExerciseStandard(4 / referenceBodyweightKg),
  'Press cerrado con mancuernas': ExerciseStandard(14 / referenceBodyweightKg),
  'Extensión de tríceps en máquina': ExerciseStandard(25 / referenceBodyweightKg),
  'Extensión de tríceps por encima de la cabeza con barra': ExerciseStandard(15 / referenceBodyweightKg),
  'Extensión de tríceps con cuerda por encima de la cabeza': ExerciseStandard(15 / referenceBodyweightKg),
  'Press de tríceps sentado con mancuerna': ExerciseStandard(12 / referenceBodyweightKg),
  'Extensión de tríceps inclinado en polea': ExerciseStandard(20 / referenceBodyweightKg),
  'JM press con barra': ExerciseStandard(30 / referenceBodyweightKg),
  'Fondos en máquina': ExerciseStandard(25 / referenceBodyweightKg),
  'Press cerrado en máquina Smith': ExerciseStandard(30 / referenceBodyweightKg),

  // Antebrazo
  'Curl de muñeca con barra (palmas arriba)': ExerciseStandard(20 / referenceBodyweightKg),
  'Curl de muñeca con barra (palmas abajo)': ExerciseStandard(10 / referenceBodyweightKg),
  'Curl de muñeca con mancuerna': ExerciseStandard(8 / referenceBodyweightKg),
  'Rotación de muñeca con barra': ExerciseStandard(5 / referenceBodyweightKg),

  // Cuádriceps
  'Sentadilla': ExerciseStandard(50 / referenceBodyweightKg),
  'Prensa de piernas': ExerciseStandard(120 / referenceBodyweightKg),
  'Zancadas': ExerciseStandard(12 / referenceBodyweightKg),
  'Sentadilla búlgara': ExerciseStandard(10 / referenceBodyweightKg),
  'Extensión de cuádriceps': ExerciseStandard(33 / referenceBodyweightKg),
  'Step-ups con barra': ExerciseStandard(20 / referenceBodyweightKg),
  'Sentadilla frontal': ExerciseStandard(40 / referenceBodyweightKg),
  'Sentadilla goblet': ExerciseStandard(20 / referenceBodyweightKg),
  'Sentadilla hack (máquina)': ExerciseStandard(60 / referenceBodyweightKg),
  'Zancada caminando con barra': ExerciseStandard(20 / referenceBodyweightKg),
  'Step-up con mancuernas': ExerciseStandard(12 / referenceBodyweightKg),
  'Sentadilla Zercher': ExerciseStandard(35 / referenceBodyweightKg),
  'Peso muerto con trap bar': ExerciseStandard(80 / referenceBodyweightKg),
  'Extensión de cuádriceps a una pierna (máquina)': ExerciseStandard(16 / referenceBodyweightKg),
  'Prensa de piernas pies juntos': ExerciseStandard(100 / referenceBodyweightKg),
  'Sentadilla en máquina Smith': ExerciseStandard(55 / referenceBodyweightKg),

  // Isquiotibiales
  'Peso muerto rumano': ExerciseStandard(50 / referenceBodyweightKg),
  'Curl femoral': ExerciseStandard(25 / referenceBodyweightKg),
  'Hiperextensión inversa en máquina': ExerciseStandard(30 / referenceBodyweightKg),
  'Swing con kettlebell a una mano': ExerciseStandard(16 / referenceBodyweightKg),
  'Curl femoral sentado (máquina)': ExerciseStandard(25 / referenceBodyweightKg),
  'Curl femoral de pie (máquina)': ExerciseStandard(15 / referenceBodyweightKg),

  // Glúteos
  'Hip thrust': ExerciseStandard(70 / referenceBodyweightKg),
  'Patada de glúteo en polea': ExerciseStandard(12 / referenceBodyweightKg),
  'Pull through en polea': ExerciseStandard(25 / referenceBodyweightKg),

  // Gemelos
  'Elevación de gemelos': ExerciseStandard(50 / referenceBodyweightKg),
  'Elevación de gemelos en prensa': ExerciseStandard(80 / referenceBodyweightKg),
  'Elevación de gemelos sentado': ExerciseStandard(40 / referenceBodyweightKg),
  'Elevación de gemelos en máquina Smith': ExerciseStandard(55 / referenceBodyweightKg),

  // Aductores / Abductores
  'Máquina de aductores': ExerciseStandard(35 / referenceBodyweightKg),
  'Máquina de abductores': ExerciseStandard(35 / referenceBodyweightKg),

  // Abdomen: most ab/core work has no meaningful *external* weight signal
  // (Crunch, Elevación de piernas, Rueda abdominal, Bicicleta abdominal,
  // Abdominal completo, Giro ruso, Dead bug — all bodyweight, intentionally
  // left unranked), but these few use real adjustable resistance:
  'Máquina de abdominales (crunch)': ExerciseStandard(20 / referenceBodyweightKg),
  'Pallof press en polea': ExerciseStandard(15 / referenceBodyweightKg),
  'Leñador en polea (wood chop)': ExerciseStandard(20 / referenceBodyweightKg),
  'Inclinación lateral con mancuerna': ExerciseStandard(12 / referenceBodyweightKg),

  // Other bodyweight-only exercises intentionally left unranked for the same
  // reason as the abdomen ones above (no external weight typically logged):
  // Flexiones, Flexiones con pies elevados, Hiperextensiones lumbares,
  // Glute ham raise, Puente de glúteos, Puente de glúteo a una pierna,
  // Step-up con elevación de rodilla.
};
