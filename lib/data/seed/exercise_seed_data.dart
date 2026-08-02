// Curated starter set of common gym exercises, in Spanish, covering the
// main muscle groups. Imported once into the local database on first
// launch — the app never depends on this list at runtime afterwards.
class ExerciseSeed {
  const ExerciseSeed({
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.instructions,
  });

  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String instructions;
}

const exerciseSeedData = <ExerciseSeed>[
  // Pecho
  ExerciseSeed(
    name: 'Press banca',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Barra',
    instructions: 'Tumbado en el banco, baja la barra al pecho de forma controlada y empuja hacia arriba.',
  ),
  ExerciseSeed(
    name: 'Press banca inclinado',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Barra',
    instructions: 'Banco inclinado 30-45°, baja la barra a la parte alta del pecho y empuja.',
  ),
  ExerciseSeed(
    name: 'Press banca con mancuernas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Mancuernas',
    instructions: 'Tumbado en el banco, empuja las mancuernas hacia arriba juntando ligeramente al final.',
  ),
  ExerciseSeed(
    name: 'Aperturas con mancuernas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Tumbado en el banco, abre los brazos en arco manteniendo un ligero doblez en el codo.',
  ),
  ExerciseSeed(
    name: 'Fondos en paralelas',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: ['Tríceps', 'Hombros'],
    equipment: 'Paralelas',
    instructions: 'Inclina el torso adelante, baja hasta 90° en el codo y empuja hacia arriba.',
  ),
  ExerciseSeed(
    name: 'Cruces en polea',
    primaryMuscles: ['Pecho'],
    secondaryMuscles: [],
    equipment: 'Polea',
    instructions: 'De pie entre las poleas, junta las manos por delante del pecho en un movimiento de arco.',
  ),

  // Espalda
  ExerciseSeed(
    name: 'Dominadas',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Barra de dominadas',
    instructions: 'Cuelga de la barra con agarre prono y sube hasta que la barbilla la supere.',
  ),
  ExerciseSeed(
    name: 'Remo con barra',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Barra',
    instructions: 'Con el torso inclinado hacia adelante, tira de la barra hacia el abdomen.',
  ),
  ExerciseSeed(
    name: 'Remo con mancuerna',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Mancuerna',
    instructions: 'Apoyado en un banco con una rodilla, tira de la mancuerna hacia la cadera.',
  ),
  ExerciseSeed(
    name: 'Jalón al pecho',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Polea',
    instructions: 'Sentado, tira de la barra hacia la parte alta del pecho controlando la subida.',
  ),
  ExerciseSeed(
    name: 'Remo en máquina',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Bíceps'],
    equipment: 'Máquina',
    instructions: 'Sentado con el pecho apoyado, tira de las asas hacia el cuerpo.',
  ),
  ExerciseSeed(
    name: 'Peso muerto',
    primaryMuscles: ['Espalda', 'Isquiotibiales'],
    secondaryMuscles: ['Glúteos', 'Antebrazos'],
    equipment: 'Barra',
    instructions: 'Con la espalda recta, levanta la barra del suelo extendiendo cadera y rodillas a la vez.',
  ),
  ExerciseSeed(
    name: 'Face pull',
    primaryMuscles: ['Espalda'],
    secondaryMuscles: ['Hombros'],
    equipment: 'Polea',
    instructions: 'Tira de la cuerda hacia la cara separando las manos, codos altos.',
  ),

  // Hombros
  ExerciseSeed(
    name: 'Press militar',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Barra',
    instructions: 'De pie o sentado, empuja la barra desde los hombros hasta la extensión completa.',
  ),
  ExerciseSeed(
    name: 'Press militar con mancuernas',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Mancuernas',
    instructions: 'Empuja las mancuernas hacia arriba desde la altura de los hombros.',
  ),
  ExerciseSeed(
    name: 'Elevaciones laterales',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Eleva los brazos hacia los lados hasta la altura de los hombros.',
  ),
  ExerciseSeed(
    name: 'Elevaciones frontales',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: [],
    equipment: 'Mancuernas',
    instructions: 'Eleva un brazo (o ambos) hacia adelante hasta la altura de los hombros.',
  ),
  ExerciseSeed(
    name: 'Pájaros',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Espalda'],
    equipment: 'Mancuernas',
    instructions: 'Inclinado hacia adelante, eleva los brazos hacia los lados con codos ligeramente flexionados.',
  ),
  ExerciseSeed(
    name: 'Press Arnold',
    primaryMuscles: ['Hombros'],
    secondaryMuscles: ['Tríceps'],
    equipment: 'Mancuernas',
    instructions: 'Empieza con palmas hacia ti y rota mientras empujas hacia arriba.',
  ),

  // Bíceps
  ExerciseSeed(
    name: 'Curl con barra',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Barra',
    instructions: 'De pie, flexiona los codos llevando la barra hacia los hombros sin mover el torso.',
  ),
  ExerciseSeed(
    name: 'Curl con mancuernas',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Mancuernas',
    instructions: 'Flexiona los codos alternando o a la vez, controlando la bajada.',
  ),
  ExerciseSeed(
    name: 'Curl martillo',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: ['Antebrazos'],
    equipment: 'Mancuernas',
    instructions: 'Igual que el curl normal pero con agarre neutro (palmas encaradas).',
  ),
  ExerciseSeed(
    name: 'Curl en banco Scott',
    primaryMuscles: ['Bíceps'],
    secondaryMuscles: [],
    equipment: 'Barra Z',
    instructions: 'Apoya los brazos en el banco Scott y flexiona los codos.',
  ),

  // Tríceps
  ExerciseSeed(
    name: 'Press francés',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Barra Z',
    instructions: 'Tumbado, baja la barra hacia la frente flexionando solo los codos.',
  ),
  ExerciseSeed(
    name: 'Extensión de tríceps en polea',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Polea',
    instructions: 'De pie frente a la polea alta, extiende los codos empujando la barra hacia abajo.',
  ),
  ExerciseSeed(
    name: 'Fondos para tríceps',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: ['Pecho'],
    equipment: 'Banco',
    instructions: 'Con las manos en el banco detrás de ti, baja el cuerpo flexionando los codos.',
  ),
  ExerciseSeed(
    name: 'Patada de tríceps',
    primaryMuscles: ['Tríceps'],
    secondaryMuscles: [],
    equipment: 'Mancuerna',
    instructions: 'Inclinado hacia adelante, extiende el codo hacia atrás manteniendo el brazo pegado al cuerpo.',
  ),

  // Piernas — cuádriceps
  ExerciseSeed(
    name: 'Sentadilla',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos', 'Isquiotibiales'],
    equipment: 'Barra',
    instructions: 'Baja flexionando cadera y rodillas manteniendo la espalda recta, hasta paralelo o más abajo.',
  ),
  ExerciseSeed(
    name: 'Prensa de piernas',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Máquina',
    instructions: 'Empuja la plataforma extendiendo las piernas sin bloquear del todo la rodilla.',
  ),
  ExerciseSeed(
    name: 'Zancadas',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Mancuernas',
    instructions: 'Da un paso adelante y baja hasta que ambas rodillas formen 90°.',
  ),
  ExerciseSeed(
    name: 'Sentadilla búlgara',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: ['Glúteos'],
    equipment: 'Mancuernas',
    instructions: 'Con el pie trasero elevado en un banco, baja flexionando la pierna delantera.',
  ),
  ExerciseSeed(
    name: 'Extensión de cuádriceps',
    primaryMuscles: ['Cuádriceps'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'Sentado, extiende las rodillas levantando el peso con las piernas.',
  ),

  // Piernas — isquios/glúteo
  ExerciseSeed(
    name: 'Peso muerto rumano',
    primaryMuscles: ['Isquiotibiales'],
    secondaryMuscles: ['Glúteos', 'Espalda'],
    equipment: 'Barra',
    instructions: 'Con las rodillas casi extendidas, baja la barra pegada a las piernas hasta notar estiramiento.',
  ),
  ExerciseSeed(
    name: 'Curl femoral',
    primaryMuscles: ['Isquiotibiales'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'Tumbado o sentado, flexiona las rodillas llevando el peso hacia los glúteos.',
  ),
  ExerciseSeed(
    name: 'Hip thrust',
    primaryMuscles: ['Glúteos'],
    secondaryMuscles: ['Isquiotibiales'],
    equipment: 'Barra',
    instructions: 'Con la espalda apoyada en un banco, empuja la cadera hacia arriba con la barra sobre el regazo.',
  ),
  ExerciseSeed(
    name: 'Elevación de gemelos',
    primaryMuscles: ['Gemelos'],
    secondaryMuscles: [],
    equipment: 'Máquina',
    instructions: 'De pie, elévate sobre las puntas de los pies y baja de forma controlada.',
  ),

  // Abdomen
  ExerciseSeed(
    name: 'Crunch',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Tumbado boca arriba, eleva los hombros del suelo contrayendo el abdomen.',
  ),
  ExerciseSeed(
    name: 'Plancha',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Mantén el cuerpo recto apoyado en antebrazos y pies, sin dejar caer la cadera.',
  ),
  ExerciseSeed(
    name: 'Elevación de piernas',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: [],
    equipment: 'Peso corporal',
    instructions: 'Colgado de la barra o tumbado, eleva las piernas hacia el pecho controlando el movimiento.',
  ),
  ExerciseSeed(
    name: 'Rueda abdominal',
    primaryMuscles: ['Abdomen'],
    secondaryMuscles: ['Hombros'],
    equipment: 'Rueda',
    instructions: 'De rodillas, rueda hacia adelante manteniendo el abdomen contraído y vuelve al punto inicial.',
  ),
];
