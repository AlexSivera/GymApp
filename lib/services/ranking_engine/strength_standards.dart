import '../progression_engine/estimated_one_rep_max.dart';

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
  const ExerciseStandard(this.ratio, {this.bodyweightBased = false})
      : baselineReps = null,
        baselineHoldSeconds = null;

  // Bodyweight, rep-based exercises (ab/core work with no meaningful added
  // weight — Crunch, Dead bug...) skip the weight-ratio formula entirely:
  // the rank compares reps in the best set directly against a hand-
  // estimated baseline rep count, the same "solid working set for an
  // average untrained lifter" idea as the weight-based baselines below.
  const ExerciseStandard.repsBased(this.baselineReps)
      : ratio = 0,
        bodyweightBased = false,
        baselineHoldSeconds = null;

  // Isometric holds (Plancha...) — no weight, no reps, just a duration.
  // Ranked by hold time against a baseline, same idea again.
  const ExerciseStandard.durationBased(this.baselineHoldSeconds)
      : ratio = 0,
        bodyweightBased = false,
        baselineReps = null;

  // baseline 1RM ÷ reference body weight (83kg). Multiply by the current
  // user's body weight to get their personal baseline for this exercise.
  // Unused (0) for repsBased/durationBased standards.
  final double ratio;

  // True for exercises where the load logged is *added* weight on top of
  // the lifter's own body weight (dips, pull-ups) — the effective 1RM used
  // for ranking is bodyweight + logged weight, not the logged weight alone.
  final bool bodyweightBased;

  // Non-null only for repsBased standards — the reps that anchor the middle
  // of the ladder (Plata), same role `ratio * bodyweight` plays for weighted
  // exercises.
  final int? baselineReps;

  // Non-null only for durationBased standards — the hold time (seconds)
  // that anchors the middle of the ladder (Plata).
  final int? baselineHoldSeconds;
}

const referenceBodyweightKg = 83.0;

// For bodyweightBased exercises (dips, pull-ups...), the Epley formula must
// run on the *total* load (bodyweight + added weight), not on the added
// weight alone with bodyweight tacked on afterwards — Epley of 0kg added is
// 0 regardless of reps, so "estimatedOneRepMax(added, reps) + bodyweight"
// gave a strict 10-rep bodyweight-only set the exact same rank as a
// barely-completed 1-rep one. Running Epley on the combined load fixes
// that: more reps at bodyweight alone now genuinely raises the estimate.
double effectiveOneRepMax(ExerciseStandard standard, double weightKg, int reps, double bodyweightKg) {
  final loadKg = standard.bodyweightBased ? weightKg + bodyweightKg : weightKg;
  return estimatedOneRepMax(loadKg, reps);
}

// Keyed by exercise name (matches exercise_seed_data.dart). Exercises not
// in this map (custom exercises, assisted-machine variants — the assist
// reduces effective bodyweight rather than adding to it, a mechanism this
// model doesn't represent — or exercises with no sensible baseline) simply
// can't be ranked; the Rangos screen skips them. Cardio exercises are
// deliberately never added here — there's no sensible "how much can you
// lift" analogue for them, weight-, rep-, or duration-based.
const exerciseStandards = <String, ExerciseStandard>{
  // Pecho
  'Fondos en paralelas': ExerciseStandard(0.65, bodyweightBased: true),
  'Press banca': ExerciseStandard(40 / referenceBodyweightKg),
  'Press banca declinado': ExerciseStandard(42 / referenceBodyweightKg),
  'Pullover declinado con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Press declinado agarre ancho': ExerciseStandard(40 / referenceBodyweightKg),
  'Flexión arquero': ExerciseStandard.repsBased(6),
  'Aperturas inclinadas en polea': ExerciseStandard(8 / referenceBodyweightKg),
  'Press banca en polea': ExerciseStandard(20 / referenceBodyweightKg),
  'Cruces en polea': ExerciseStandard(10 / referenceBodyweightKg),
  'Flexión profunda con mancuernas': ExerciseStandard.repsBased(14),
  'Pullover con mancuerna': ExerciseStandard(15 / referenceBodyweightKg),
  'Press a un brazo en el suelo con pesa rusa': ExerciseStandard(10 / referenceBodyweightKg),
  'Press alterno en el suelo con pesa rusa': ExerciseStandard(10 / referenceBodyweightKg),
  'Press de pecho en máquina de palanca': ExerciseStandard(35 / referenceBodyweightKg),
  'Press banca agarre ancho en máquina Smith': ExerciseStandard(42 / referenceBodyweightKg),
  'Press banca en máquina Smith': ExerciseStandard(42 / referenceBodyweightKg),
  'Press banca declinado en máquina Smith': ExerciseStandard(38 / referenceBodyweightKg),
  'Fondos en barra con peso añadido': ExerciseStandard(0.65, bodyweightBased: true),
  'Flexión con caída y peso': ExerciseStandard.repsBased(10),

  // Espalda
  // Ratio kept well under 1 on purpose: bodyweightBased exercises rank the
  // *total* load (bodyweight + added weight) against tierStart multipliers
  // that go up to 2.85x at Maestro — a ratio near 1 (like a plain "you can
  // do a bodyweight rep" baseline) blows up into an unachievable added
  // weight at the top of the ladder (0.9 put Maestro at +130kg added, well
  // past any known natural weighted pull-up). 0.6 puts Maestro at a very
  // strong but attainable ~+45-60kg added for a dedicated multi-year lifter.
  'Dominadas': ExerciseStandard(0.6, bodyweightBased: true),
  'Pullover con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Remo con barra': ExerciseStandard(40 / referenceBodyweightKg),
  'Pullover declinado con barra (dorsal)': ExerciseStandard(18 / referenceBodyweightKg),
  'Dominada arquero': ExerciseStandard.repsBased(4),
  'Dominadas en banco (remo invertido)': ExerciseStandard.repsBased(15),
  'Jalón al pecho alterno': ExerciseStandard(50 / referenceBodyweightKg),
  'Jalón al pecho': ExerciseStandard(55 / referenceBodyweightKg),
  'Remo sentado agarre ancho en polea': ExerciseStandard(45 / referenceBodyweightKg),
  'Remo con mancuerna inclinado': ExerciseStandard(20 / referenceBodyweightKg),
  'Encogimientos declinados con mancuernas': ExerciseStandard(30 / referenceBodyweightKg),
  'Pullover tumbado con barra Z': ExerciseStandard(16 / referenceBodyweightKg),
  'Remo inclinado agarre invertido con barra Z': ExerciseStandard(35 / referenceBodyweightKg),
  'Remo a dos manos con pesa rusa': ExerciseStandard(20 / referenceBodyweightKg),
  'Remo renegado alterno con pesas rusas': ExerciseStandard.repsBased(10),
  'Encogimientos en máquina Smith': ExerciseStandard(55 / referenceBodyweightKg),
  'Remo inclinado en máquina Smith': ExerciseStandard(45 / referenceBodyweightKg),
  'Dominada con peso añadido': ExerciseStandard(0.6, bodyweightBased: true),
  'Dominada supina agarre cerrado con peso añadido': ExerciseStandard(0.6, bodyweightBased: true),
  'Hiperextensión lumbar con peso añadido': ExerciseStandard(0.15, bodyweightBased: true),

  // Hombros
  'Elevaciones laterales': ExerciseStandard(6 / referenceBodyweightKg),
  'Press militar': ExerciseStandard(25 / referenceBodyweightKg),
  'Elevación frontal con barra': ExerciseStandard(10 / referenceBodyweightKg),
  'Arrancada a un brazo con barra': ExerciseStandard(12 / referenceBodyweightKg),
  'Elevación posterior con barra': ExerciseStandard(10 / referenceBodyweightKg),
  'Remo para deltoides posteriores con barra': ExerciseStandard(15 / referenceBodyweightKg),
  'Press de hombro alterno en polea': ExerciseStandard(10 / referenceBodyweightKg),
  'Aperturas posteriores cruzadas en polea': ExerciseStandard(12 / referenceBodyweightKg),
  'Elevación frontal en polea': ExerciseStandard(6 / referenceBodyweightKg),
  'Press lateral alterno con mancuerna': ExerciseStandard(10 / referenceBodyweightKg),
  'Press Arnold con mancuernas': ExerciseStandard(11 / referenceBodyweightKg),
  'Press de hombro sentado con mancuernas': ExerciseStandard(12 / referenceBodyweightKg),
  'Press alterno con pesa rusa': ExerciseStandard(8 / referenceBodyweightKg),
  'Press Arnold con pesa rusa': ExerciseStandard(8 / referenceBodyweightKg),
  'Elevación lateral en máquina de palanca': ExerciseStandard(6 / referenceBodyweightKg),
  'Press militar en máquina de palanca': ExerciseStandard(28 / referenceBodyweightKg),
  'Press de hombro sentado en máquina Smith': ExerciseStandard(28 / referenceBodyweightKg),
  'Press tras nuca en máquina Smith': ExerciseStandard(26 / referenceBodyweightKg),
  'Elevación frontal con peso añadido': ExerciseStandard(8 / referenceBodyweightKg),

  // Bíceps
  'Curl con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Dominadas agarre cerrado (bíceps)': ExerciseStandard(0.6, bodyweightBased: true),
  'Dominada supina para bíceps': ExerciseStandard(0.6, bodyweightBased: true),
  'Curl agarre cerrado en polea': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl concentrado en polea': ExerciseStandard(8 / referenceBodyweightKg),
  'Curl alterno con mancuernas': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl martillo en banco Scott alterno': ExerciseStandard(9 / referenceBodyweightKg),
  'Curl concentrado sentado agarre cerrado con barra Z': ExerciseStandard(18 / referenceBodyweightKg),
  'Curl en banco Scott agarre cerrado con barra Z': ExerciseStandard(16 / referenceBodyweightKg),
  'Curl de bíceps en máquina de palanca': ExerciseStandard(20 / referenceBodyweightKg),
  'Curl martillo en banco Scott (máquina)': ExerciseStandard(16 / referenceBodyweightKg),

  // Tríceps
  'Press banca agarre cerrado': ExerciseStandard(35 / referenceBodyweightKg),
  'Press francés declinado con barra': ExerciseStandard(18 / referenceBodyweightKg),
  'Press banca inclinado agarre cerrado': ExerciseStandard(30 / referenceBodyweightKg),
  'Fondos en banco (rodillas flexionadas)': ExerciseStandard.repsBased(15),
  'Fondo explosivo (body-up)': ExerciseStandard.repsBased(8),
  'Extensión de tríceps en polea': ExerciseStandard(25 / referenceBodyweightKg),
  'Extensión de tríceps alterna en polea': ExerciseStandard(15 / referenceBodyweightKg),
  'Press cerrado con mancuernas': ExerciseStandard(14 / referenceBodyweightKg),
  'Press francés tumbado con barra Z': ExerciseStandard(18 / referenceBodyweightKg),
  'Press francés con barra Z sobre fitball': ExerciseStandard(15 / referenceBodyweightKg),
  'Fondos de tríceps en máquina de palanca': ExerciseStandard(25 / referenceBodyweightKg),
  'Press banca agarre cerrado en máquina Smith': ExerciseStandard(30 / referenceBodyweightKg),
  'Fondos en banco con peso añadido': ExerciseStandard(0.5, bodyweightBased: true),

  // Antebrazos
  'Curl de muñeca prono con barra': ExerciseStandard(10 / referenceBodyweightKg),
  'Curl de muñeca supino con barra': ExerciseStandard(20 / referenceBodyweightKg),
  'Curl de muñeca invertido en polea': ExerciseStandard(10 / referenceBodyweightKg),
  'Curl de dedos con mancuerna': ExerciseStandard(8 / referenceBodyweightKg),
  'Pronación tumbado con mancuerna': ExerciseStandard(4 / referenceBodyweightKg),
  'Curl de muñeca sentado en máquina Smith': ExerciseStandard(22 / referenceBodyweightKg),
  'Rodillo de muñeca con peso': ExerciseStandard(6 / referenceBodyweightKg),

  // Cuádriceps
  'Sentadilla': ExerciseStandard(50 / referenceBodyweightKg),
  'Zancadas': ExerciseStandard.repsBased(15),
  'Prensa de piernas': ExerciseStandard(120 / referenceBodyweightKg),
  'Sentadilla frontal sobre banco con barra': ExerciseStandard(40 / referenceBodyweightKg),
  'Cargada y press con barra': ExerciseStandard(35 / referenceBodyweightKg),
  'Sentadilla a una pierna con barra': ExerciseStandard(15 / referenceBodyweightKg),
  'Sentadilla overhead con barra': ExerciseStandard(30 / referenceBodyweightKg),
  'Sentadilla lateral con barra': ExerciseStandard(25 / referenceBodyweightKg),
  'Salto hacia atrás': ExerciseStandard.repsBased(10),
  'Sentadilla goblet con mancuerna': ExerciseStandard(20 / referenceBodyweightKg),
  'Zancada búlgara con mancuernas': ExerciseStandard(10 / referenceBodyweightKg),
  'Zancada con step-up y mancuernas': ExerciseStandard(12 / referenceBodyweightKg),
  'Sentadilla asistida con mancuernas': ExerciseStandard.repsBased(15),
  'Paseo del granjero': ExerciseStandard(50 / referenceBodyweightKg),
  'Prensa de piernas alterna (máquina)': ExerciseStandard(65 / referenceBodyweightKg),
  'Extensión de cuádriceps en máquina': ExerciseStandard(33 / referenceBodyweightKg),
  'Sentadilla en máquina Smith': ExerciseStandard(55 / referenceBodyweightKg),
  'Zancada búlgara en máquina Smith': ExerciseStandard(25 / referenceBodyweightKg),

  // Isquiotibiales
  'Buenos días con barra': ExerciseStandard(30 / referenceBodyweightKg),
  'Peso muerto rumano': ExerciseStandard(50 / referenceBodyweightKg),
  'Cargada de potencia (power clean)': ExerciseStandard(55 / referenceBodyweightKg),
  'Curl nórdico (glute-ham raise)': ExerciseStandard.repsBased(8),
  'Curl femoral invertido en banco': ExerciseStandard.repsBased(12),
  'Curl femoral invertido en polea': ExerciseStandard.repsBased(12),
  'Curl femoral de rodillas en máquina': ExerciseStandard(15 / referenceBodyweightKg),
  'Curl femoral': ExerciseStandard(25 / referenceBodyweightKg),
  'Curl femoral sentado en máquina': ExerciseStandard(25 / referenceBodyweightKg),

  // Glúteos
  'Sentadilla frontal agarre de cargada': ExerciseStandard(40 / referenceBodyweightKg),
  'Peso muerto': ExerciseStandard(75 / referenceBodyweightKg),
  'Extensión de cadera en banco': ExerciseStandard.repsBased(20),
  'Peso muerto en polea': ExerciseStandard(40 / referenceBodyweightKg),
  'Aducción de cadera en polea': ExerciseStandard(20 / referenceBodyweightKg),
  'Pull through en polea': ExerciseStandard(25 / referenceBodyweightKg),
  'Peso muerto piernas rígidas con mancuernas': ExerciseStandard(30 / referenceBodyweightKg),
  'Cargada con mancuernas': ExerciseStandard(25 / referenceBodyweightKg),
  'Sentadilla frontal con pesa rusa': ExerciseStandard(20 / referenceBodyweightKg),
  'Sentadilla goblet con pesa rusa': ExerciseStandard(20 / referenceBodyweightKg),
  'Zancada con paso de pesa rusa': ExerciseStandard.repsBased(12),
  'Peso muerto en máquina de palanca': ExerciseStandard(70 / referenceBodyweightKg),
  'Extensión de cadera en máquina': ExerciseStandard(70 / referenceBodyweightKg),
  'Prensa horizontal a una pierna (máquina)': ExerciseStandard(60 / referenceBodyweightKg),
  'Buenos días rodilla flexionada en máquina Smith': ExerciseStandard(30 / referenceBodyweightKg),
  'Peso muerto en máquina Smith': ExerciseStandard(70 / referenceBodyweightKg),
  'Sentadilla frontal en máquina Smith': ExerciseStandard(40 / referenceBodyweightKg),
  'Sentadilla cosaca con peso': ExerciseStandard.repsBased(10),
  'Zancada con peso y balanceo': ExerciseStandard.repsBased(10),

  // Gemelos
  'Elevación de gemelos': ExerciseStandard(50 / referenceBodyweightKg),
  'Elevación de gemelos sentado con barra': ExerciseStandard(40 / referenceBodyweightKg),
  'Elevación de gemelos de pie (peso corporal)': ExerciseStandard.repsBased(20),
  'Elevación de gemelos de pie en polea': ExerciseStandard(30 / referenceBodyweightKg),
  'Elevación de gemelos a una pierna en polea': ExerciseStandard(15 / referenceBodyweightKg),
  'Elevación de gemelos sentado con mancuerna': ExerciseStandard(15 / referenceBodyweightKg),
  'Elevación de gemelos sentado a una pierna con mancuerna': ExerciseStandard(10 / referenceBodyweightKg),
  'Prensa de gemelos en máquina': ExerciseStandard(80 / referenceBodyweightKg),
  'Elevación de gemelos burro en máquina': ExerciseStandard(70 / referenceBodyweightKg),
  'Elevación de gemelos a una pierna en máquina Smith': ExerciseStandard(30 / referenceBodyweightKg),
  'Elevación de gemelos invertida en máquina Smith': ExerciseStandard(55 / referenceBodyweightKg),

  // Abdomen: most ab/core work has no meaningful *external* weight signal,
  // so it's ranked by reps instead — see ExerciseStandard.repsBased above.
  'Abdominal con press de barra': ExerciseStandard.repsBased(15),
  'Rueda abdominal con barra': ExerciseStandard.repsBased(6),
  'Abdominal 3/4': ExerciseStandard.repsBased(20),
  'Inclinación lateral de tronco': ExerciseStandard.repsBased(15),
  'Bicicleta abdominal': ExerciseStandard.repsBased(20),
  'Molino avanzado con pesa rusa': ExerciseStandard.repsBased(8),
  'Press inclinado con pesa rusa': ExerciseStandard.repsBased(8),
  'Giro de rodillas en máquina': ExerciseStandard.repsBased(15),
  'Abdominal con peso (otis up)': ExerciseStandard.repsBased(10),
  'Crunch con peso': ExerciseStandard.repsBased(12),

  // Abdomen (weighted resistance): these use real adjustable resistance.
  'Crunch sentado en polea': ExerciseStandard(15 / referenceBodyweightKg),
  'Inclinación lateral con mancuerna': ExerciseStandard(12 / referenceBodyweightKg),
  'Rotación de tronco con mancuerna': ExerciseStandard(15 / referenceBodyweightKg),
  'Crunch sentado en máquina': ExerciseStandard(20 / referenceBodyweightKg),
  'Pallof press con banda': ExerciseStandard(15 / referenceBodyweightKg),

  // Abdomen (bodyweight classics, rep-based)
  'Crunch': ExerciseStandard.repsBased(20),
  'Elevación de piernas': ExerciseStandard.repsBased(12),
  'Abdominal completo (sit-up)': ExerciseStandard.repsBased(20),
  'Giro ruso': ExerciseStandard.repsBased(20),
  'Dead bug': ExerciseStandard.repsBased(12),

  // Isometric holds — ranked by seconds held instead of reps or weight.
  'Plancha': ExerciseStandard.durationBased(45),
  'Plancha lateral': ExerciseStandard.durationBased(30),
  'Ejercicio isométrico de cuello (frontal/posterior)': ExerciseStandard.durationBased(20),
  'Ejercicio isométrico de cuello (lateral)': ExerciseStandard.durationBased(20),
};
