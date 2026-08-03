// Curated starter set of common gym exercises, in Spanish, covering the
// main muscle groups. Imported once into the local database on first
// launch — the app never depends on this list at runtime afterwards.
//
// Images are bundled from free-exercise-db (github.com/yuhonas/free-exercise-db,
// public domain / Unlicense), matched by hand to the closest equivalent
// exercise and downloaded once into assets/exercises/.
class ExerciseSeed {
  const ExerciseSeed({
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.instructions,
    required this.imageAsset,
  });

  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String instructions;
  final String imageAsset;
}

const exerciseSeedData = <ExerciseSeed>[
  // Pecho
  ExerciseSeed(
    name: 'Press banca',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Barra',
    instructions: 'Tumbado en el banco, baja la barra al pecho de forma controlada y empuja hacia arriba.',
    imageAsset: 'assets/exercises/press_banca.jpg',
  ),
  ExerciseSeed(
    name: 'Press banca inclinado',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Barra',
    instructions: 'Banco inclinado 30-45°, baja la barra a la parte alta del pecho y empuja.',
    imageAsset: 'assets/exercises/press_banca_inclinado.jpg',
  ),
  ExerciseSeed(
    name: 'Press banca con mancuernas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Mancuernas',
    instructions: 'Tumbado en el banco, empuja las mancuernas hacia arriba juntando ligeramente al final.',
    imageAsset: 'assets/exercises/press_banca_mancuernas.jpg',
  ),
  ExerciseSeed(
    name: 'Aperturas con mancuernas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Tumbado en el banco, abre los brazos en arco manteniendo un ligero doblez en el codo.',
    imageAsset: 'assets/exercises/aperturas_mancuernas.jpg',
  ),
  ExerciseSeed(
    name: 'Fondos en paralelas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Paralelas',
    instructions: 'Inclina el torso adelante, baja hasta 90° en el codo y empuja hacia arriba.',
    imageAsset: 'assets/exercises/fondos_paralelas.jpg',
  ),
  ExerciseSeed(
    name: 'Cruces en polea',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: [],
    equipment: 'Polea',
    instructions: 'De pie entre las poleas, junta las manos por delante del pecho en un movimiento de arco.',
    imageAsset: 'assets/exercises/cruces_polea.jpg',
  ),

  // Espalda
  ExerciseSeed(
    name: 'Dominadas',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Barra de dominadas',
    instructions: 'Cuelga de la barra con agarre prono y sube hasta que la barbilla la supere.',
    imageAsset: 'assets/exercises/dominadas.jpg',
  ),
  ExerciseSeed(
    name: 'Remo con barra',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Barra',
    instructions: 'Con el torso inclinado hacia adelante, tira de la barra hacia el abdomen.',
    imageAsset: 'assets/exercises/remo_barra.jpg',
  ),
  ExerciseSeed(
    name: 'Remo con mancuerna',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Mancuerna',
    instructions: 'Apoyado en un banco con una rodilla, tira de la mancuerna hacia la cadera.',
    imageAsset: 'assets/exercises/remo_mancuerna.jpg',
  ),
  ExerciseSeed(
    name: 'Jalón al pecho',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Polea',
    instructions: 'Sentado, tira de la barra hacia la parte alta del pecho controlando la subida.',
    imageAsset: 'assets/exercises/jalon_pecho.jpg',
  ),
  ExerciseSeed(
    name: 'Remo en máquina',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Máquina',
    instructions: 'Sentado con el pecho apoyado, tira de las asas hacia el cuerpo.',
    imageAsset: 'assets/exercises/remo_maquina.jpg',
  ),
  ExerciseSeed(
    name: 'Peso muerto',
    primaryMuscles: ['Espalda', 'Isquiotibiales'],
    secondaryMuscles: ['Glúteos', 'Antebrazos'],
    equipment: 'Barra',
    instructions: 'Con la espalda recta, levanta la barra del suelo extendiendo cadera y rodillas a la vez.',
    imageAsset: 'assets/exercises/peso_muerto.jpg',
  ),
  ExerciseSeed(
    name: 'Face pull',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Hombros'],
    equipment: 'Polea',
    instructions: 'Tira de la cuerda hacia la cara separando las manos, codos altos.',
    imageAsset: 'assets/exercises/face_pull.jpg',
  ),

  // Hombros
  ExerciseSeed(
    name: 'Press militar',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Barra',
    instructions: 'De pie o sentado, empuja la barra desde los hombros hasta la extensión completa.',
    imageAsset: 'assets/exercises/press_militar.jpg',
  ),
  ExerciseSeed(
    name: 'Press militar con mancuernas',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Mancuernas',
    instructions: 'Empuja las mancuernas hacia arriba desde la altura de los hombros.',
    imageAsset: 'assets/exercises/press_militar_mancuernas.jpg',
  ),
  ExerciseSeed(
    name: 'Elevaciones laterales',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Eleva los brazos hacia los lados hasta la altura de los hombros.',
    imageAsset: 'assets/exercises/elevaciones_laterales.jpg',
  ),
  ExerciseSeed(
    name: 'Elevaciones frontales',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Eleva un brazo (o ambos) hacia adelante hasta la altura de los hombros.',
    imageAsset: 'assets/exercises/elevaciones_frontales.jpg',
  ),
  ExerciseSeed(
    name: 'Pájaros',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Espalda'],
    equipment: 'Mancuernas',
    instructions: 'Inclinado hacia adelante, eleva los brazos hacia los lados con codos ligeramente flexionados.',
    imageAsset: 'assets/exercises/pajaros.jpg',
  ),
  ExerciseSeed(
    name: 'Press Arnold',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Mancuernas',
    instructions: 'Empieza con palmas hacia ti y rota mientras empujas hacia arriba.',
    imageAsset: 'assets/exercises/press_arnold.jpg',
  ),

  // Bíceps
  ExerciseSeed(
    name: 'Curl con barra',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Barra',
    instructions: 'De pie, flexiona los codos llevando la barra hacia los hombros sin mover el torso.',
    imageAsset: 'assets/exercises/curl_barra.jpg',
  ),
  ExerciseSeed(
    name: 'Curl con mancuernas',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Mancuernas',
    instructions: 'Flexiona los codos alternando o a la vez, controlando la bajada.',
    imageAsset: 'assets/exercises/curl_mancuernas.jpg',
  ),
  ExerciseSeed(
    name: 'Curl martillo',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Mancuernas',
    instructions: 'Igual que el curl normal pero con agarre neutro (palmas encaradas).',
    imageAsset: 'assets/exercises/curl_martillo.jpg',
  ),
  ExerciseSeed(
    name: 'Curl en banco Scott',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: [],
    equipment: 'Barra Z',
    instructions: 'Apoya los brazos en el banco Scott y flexiona los codos.',
    imageAsset: 'assets/exercises/curl_banco_scott.jpg',
  ),

  // Tríceps
  ExerciseSeed(
    name: 'Press francés',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Barra Z',
    instructions: 'Tumbado, baja la barra hacia la frente flexionando solo los codos.',
    imageAsset: 'assets/exercises/press_frances.jpg',
  ),
  ExerciseSeed(
    name: 'Extensión de tríceps en polea',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Polea',
    instructions: 'De pie frente a la polea alta, extiende los codos empujando la barra hacia abajo.',
    imageAsset: 'assets/exercises/extension_triceps_polea.jpg',
  ),
  ExerciseSeed(
    name: 'Fondos para tríceps',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: ['Pecho'],
    equipment: 'Banco',
    instructions: 'Con las manos en el banco detrás de ti, baja el cuerpo flexionando los codos.',
    imageAsset: 'assets/exercises/fondos_triceps.jpg',
  ),
  ExerciseSeed(
    name: 'Patada de tríceps',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Mancuerna',
    instructions: 'Inclinado hacia adelante, extiende el codo hacia atrás manteniendo el brazo pegado al cuerpo.',
    imageAsset: 'assets/exercises/patada_triceps.jpg',
  ),

  // Piernas — cuádriceps
  ExerciseSeed(
    name: 'Sentadilla',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos', 'Isquiotibiales'],
    equipment: 'Barra',
    instructions: 'Baja flexionando cadera y rodillas manteniendo la espalda recta, hasta paralelo o más abajo.',
    imageAsset: 'assets/exercises/sentadilla.jpg',
  ),
  ExerciseSeed(
    name: 'Prensa de piernas',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Máquina',
    instructions: 'Empuja la plataforma extendiendo las piernas sin bloquear del todo la rodilla.',
    imageAsset: 'assets/exercises/prensa_piernas.jpg',
  ),
  ExerciseSeed(
    name: 'Zancadas',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Mancuernas',
    instructions: 'Da un paso adelante y baja hasta que ambas rodillas formen 90°.',
    imageAsset: 'assets/exercises/zancadas.jpg',
  ),
  ExerciseSeed(
    name: 'Sentadilla búlgara',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Mancuernas',
    instructions: 'Con el pie trasero elevado en un banco, baja flexionando la pierna delantera.',
    imageAsset: 'assets/exercises/sentadilla_bulgara.jpg',
  ),
  ExerciseSeed(
    name: 'Extensión de cuádriceps',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'Sentado, extiende las rodillas levantando el peso con las piernas.',
    imageAsset: 'assets/exercises/extension_cuadriceps.jpg',
  ),

  // Piernas — isquios/glúteo
  ExerciseSeed(
    name: 'Peso muerto rumano',
    primaryMuscles: ['Isquiotibiales'],
    secondaryMuscles: ['Glúteos', 'Espalda'],
    equipment: 'Barra',
    instructions: 'Con las rodillas casi extendidas, baja la barra pegada a las piernas hasta notar estiramiento.',
    imageAsset: 'assets/exercises/peso_muerto_rumano.jpg',
  ),
  ExerciseSeed(
    name: 'Curl femoral',
    primaryMuscles: ['Isquiotibiales'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'Tumbado o sentado, flexiona las rodillas llevando el peso hacia los glúteos.',
    imageAsset: 'assets/exercises/curl_femoral.jpg',
  ),
  ExerciseSeed(
    name: 'Hip thrust',
    primaryMuscles: ['Glúteos'],
    secondaryMuscles: ['Isquiotibiales'],
    equipment: 'Barra',
    instructions: 'Con la espalda apoyada en un banco, empuja la cadera hacia arriba con la barra sobre el regazo.',
    imageAsset: 'assets/exercises/hip_thrust.jpg',
  ),
  ExerciseSeed(
    name: 'Elevación de gemelos',
    primaryMuscles: ['Gemelos'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'De pie, elévate sobre las puntas de los pies y baja de forma controlada.',
    imageAsset: 'assets/exercises/elevacion_gemelos.jpg',
  ),

  // Abdomen
  ExerciseSeed(
    name: 'Crunch',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Tumbado boca arriba, eleva los hombros del suelo contrayendo el abdomen.',
    imageAsset: 'assets/exercises/crunch.jpg',
  ),
  ExerciseSeed(
    name: 'Plancha',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Mantén el cuerpo recto apoyado en antebrazos y pies, sin dejar caer la cadera.',
    imageAsset: 'assets/exercises/plancha.jpg',
  ),
  ExerciseSeed(
    name: 'Elevación de piernas',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Colgado de la barra o tumbado, eleva las piernas hacia el pecho controlando el movimiento.',
    imageAsset: 'assets/exercises/elevacion_piernas.jpg',
  ),
  ExerciseSeed(
    name: 'Rueda abdominal',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: ['Hombros'],
    equipment: 'Rueda',
    instructions: 'De rodillas, rueda hacia adelante manteniendo el abdomen contraído y vuelve al punto inicial.',
    imageAsset: 'assets/exercises/rueda_abdominal.jpg',
  ),
];
