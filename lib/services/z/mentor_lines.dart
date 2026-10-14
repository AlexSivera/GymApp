import '../insights_engine/daily_insight.dart';

// Each master's voice. Placeholders: {n} number, {m} muscle, {e} exercise,
// {w} weight.

enum MentorMood { contento, serio, riendo, preocupado }

class MentorLine {
  const MentorLine(this.text, this.mood);

  final String text;
  final MentorMood mood;
}

const _c = MentorMood.contento;
const _s = MentorMood.serio;
const _r = MentorMood.riendo;
const _p = MentorMood.preocupado;

const Map<String, Map<InsightKind, (String, MentorMood)>> _tips = {
  'kaio': {
    InsightKind.zenkai: ('¡Zenkai! {n} días sin entrenar y vuelves más fuerte… o eso dicen los saiyans. Hoy baja la gravedad un 10 %, ¿eh?', _r),
    InsightKind.volumeUp: ('¡Tu Genkidama es un {n} % más grande que la semana pasada! Hasta Bubbles está impresionado.', _c),
    InsightKind.volumeDown: ('Tu Genkidama va un {n} % por debajo. ¿Sabes qué le pasa a una pila sin cargar? ¡Que no carga! … Vale, entrena.', _p),
    InsightKind.muscleGap: ('Hace {n} días que no entrenas {m}. ¡Ni Gregory se salta tantos días!', _s),
    InsightKind.loadTip: ('{e}: sube la gravedad a {w}. Te lo digo por telepatía y todo.', _c),
    InsightKind.empty: ('Todavía no he sentido tu energía. Entrena una vez y empezaré a leer tu nivel de poder.', _p),
  },
  'roshi': {
    InsightKind.zenkai: ('Je, je… {n} días de vacaciones. Hasta yo entreno más, y tengo trescientos años. Hoy empieza suave.', _r),
    InsightKind.volumeUp: ('Un {n} % más de volumen esta semana. Así se forja un discípulo de la Kame House.', _c),
    InsightKind.volumeDown: ('Un {n} % menos de volumen… El caparazón de tortuga no se lleva solo, muchacho.', _p),
    InsightKind.muscleGap: ('{n} días sin entrenar {m}. Un buen artista marcial entrena todo el cuerpo, no solo lo que se ve en la playa.', _s),
    InsightKind.loadTip: ('{e}: prueba con {w}. Trabaja duro, come bien, descansa… y sube el peso.', _c),
    InsightKind.empty: ('Ponte el caparazón y haz tu primer combate. La leche no se reparte sola.', _p),
  },
  'krilin': {
    InsightKind.zenkai: ('¡Vaya, {n} días! Bueno, yo también me tomé mis vacaciones… Hoy ve con calma, ¿vale?', _r),
    InsightKind.volumeUp: ('¡Un {n} % más que la semana pasada! ¡Ya casi me superas! … Espera, ¿ya me has superado?', _c),
    InsightKind.volumeDown: ('Un {n} % menos esta semana… No pasa nada, a mí también me cuesta seguir el ritmo. ¡Venga!', _p),
    InsightKind.muscleGap: ('Llevas {n} días sin entrenar {m}. ¡Entrénalo, que luego todo son sustos!', _s),
    InsightKind.loadTip: ('{e}: ¿probamos con {w}? Yo creo que puedes. Bueno, casi seguro.', _c),
    InsightKind.empty: ('¡Hola! ¿Empezamos con un combate suave? Prometo no reírme.', _c),
  },
  'piccolo': {
    InsightKind.zenkai: ('{n} días. Inaceptable. Hoy vuelves, pero con un 10 % menos de carga. No me hagas repetirlo.', _s),
    InsightKind.volumeUp: ('Un {n} % más. Bien. No te acomodes.', _c),
    InsightKind.volumeDown: ('Un {n} % menos. Si en un combate real bajas así la guardia, estás acabado.', _p),
    InsightKind.muscleGap: ('{n} días sin entrenar {m}. Un guerrero sin equilibrio es un guerrero vencido.', _s),
    InsightKind.loadTip: ('{e}: {w}. Sin excusas.', _s),
    InsightKind.empty: ('Deja de mirar la pantalla y empieza a entrenar.', _s),
  },
  'gohan': {
    InsightKind.zenkai: ('¡Bienvenido de vuelta! Tras {n} días el cuerpo necesita readaptarse: hoy un 10 % menos, ¿vale?', _c),
    InsightKind.volumeUp: ('Según mis cálculos, has movido un {n} % más que la semana pasada. ¡Gran trabajo!', _c),
    InsightKind.volumeDown: ('Tu volumen ha bajado un {n} %. He leído que la constancia importa más que la intensidad.', _p),
    InsightKind.muscleGap: ('Hace {n} días que no entrenas {m}. El equilibrio muscular también previene lesiones.', _s),
    InsightKind.loadTip: ('{e}: estás listo para {w}. Lo he comprobado con tus últimas series.', _c),
    InsightKind.empty: ('Hola, soy Gohan. Haz tu primer entreno y estudiaremos juntos tus datos.', _c),
  },
  'trunks': {
    InsightKind.zenkai: ('En mi futuro no hay tiempo que perder. {n} días… Vuelve hoy, con un 10 % menos de carga.', _s),
    InsightKind.volumeUp: ('Un {n} % más. Así sí podremos cambiar el futuro.', _c),
    InsightKind.volumeDown: ('Un {n} % menos. He visto cómo acaba un futuro sin entrenar. No dejes que pase.', _p),
    InsightKind.muscleGap: ('{n} días sin entrenar {m}. Los androides no esperan a que estés equilibrado.', _s),
    InsightKind.loadTip: ('{e}: {w}. Lo vamos a necesitar.', _s),
    InsightKind.empty: ('Vengo del futuro para decirte una cosa: entrena hoy.', _s),
  },
  'vegeta': {
    InsightKind.zenkai: ('¿{n} días sin entrenar? ¡Patético! Un saiyan de verdad volvería con más carga… pero hoy, por esta vez, quita un 10 %.', _s),
    InsightKind.volumeUp: ('Un {n} % más. No está mal… para un insecto.', _c),
    InsightKind.volumeDown: ('¿Un {n} % menos? ¡Me das vergüenza ajena, insecto!', _s),
    InsightKind.muscleGap: ('{n} días sin entrenar {m}. ¿Quieres que Kakarotto te gane con una mano atada?', _s),
    InsightKind.loadTip: ('{e}: {w}. Yo lo haría con el doble.', _s),
    InsightKind.empty: ('¿Aún no has entrenado? El príncipe de los saiyans no espera a nadie.', _s),
  },
  'goku': {
    InsightKind.zenkai: ('¡Hola! ¡{n} días sin vernos! Hoy vamos suave y luego a comer, ¿vale?', _r),
    InsightKind.volumeUp: ('¡Un {n} % más que la semana pasada! ¡Qué ganas de luchar contra ti! Me ha entrado hambre.', _c),
    InsightKind.volumeDown: ('Un {n} % menos… ¡No pasa nada! Mañana entrenamos el doble y comemos el triple.', _p),
    InsightKind.muscleGap: ('¡Oye! Llevas {n} días sin entrenar {m}. Hasta yo me acuerdo de eso, y eso que se me olvida todo.', _r),
    InsightKind.loadTip: ('{e}: ¡prueba con {w}! Seguro que puedes, ¡estoy emocionado!', _c),
    InsightKind.empty: ('¡Hola, soy Goku! ¿Entrenamos? ¡Tengo muchas ganas!', _c),
  },
};

String _fill(String template, DailyInsight insight) => template
    .replaceAll('{n}', '${insight.number ?? ''}')
    .replaceAll('{m}', insight.subject ?? '')
    .replaceAll('{e}', insight.subject ?? '')
    .replaceAll('{w}', insight.detail ?? '');

MentorLine mentorTip(String masterId, DailyInsight insight) {
  final entry = (_tips[masterId] ?? _tips['kaio']!)[insight.kind];
  if (entry == null) return MentorLine(insight.message, _c);
  return MentorLine(_fill(entry.$1, insight), entry.$2);
}

// What each master says when you beat their trial and they join you.
const masterUnlockSpeech = <String, String>{
  'kaio': '¡Has reunido las siete esferas! Te has ganado mi técnica secreta: la Genkidama.',
  'roshi': '¡Has aguantado cinco combates! Te enseñaré la técnica de la Escuela Tortuga: el Kamehameha.',
  'krilin': '¡Dos semanas seguidas! Vale, vale, me has ganado. Toma, mi Kienzan. ¡Cuidado con los dedos!',
  'piccolo': 'Cuatro semanas sin fallar. Me has vencido. A partir de ahora te entreno yo. Aprende el Makankosappo.',
  'gohan': '¡Todos tus grupos musculares tienen lectura! Eso es equilibrio. Te enseño el Masenko.',
  'trunks': 'Veinticinco combates. Con guerreros como tú, el futuro tiene esperanza. Toma, el Burning Attack.',
  'vegeta': 'Diez límites superados… Tsk. Está bien, lo admito: eres fuerte. Te enseñaré el Galick Gun. No lo malgastes.',
  'goku': '¡Ya eres Super Saiyan! ¡Esto hay que celebrarlo! Te enseño mi Kamehameha instantáneo.',
};

// Cameos in big moments, when that master is already on your side.
const vegetaRecordCameo = 'Hmph. Has superado tu límite. No te creas que ya estás a mi altura.';
const gokuTransformCameo = '¡Increíble, te has transformado! ¡Ahora sí que tengo ganas de pelear contigo!';

// Reminder notifications, in the main master's voice.
const _plannedToday = <String, String>{
  'kaio': 'Hoy toca combate. Te espero en la cámara de gravedad.',
  'roshi': 'Hoy toca entrenar. ¡Al caparazón!',
  'krilin': '¡Hoy toca entreno! ¿Vamos juntos?',
  'piccolo': 'Hoy entrenas. Punto.',
  'gohan': 'Hoy tienes entreno planificado. ¡Yo ya he estirado!',
  'trunks': 'Hoy hay combate. El futuro depende de ello.',
  'vegeta': 'Hoy entrenas, insecto. No me hagas ir a buscarte.',
  'goku': '¡Hoy toca entrenar! ¡Qué ganas!',
};

const _streakRisk = <String, String>{
  'kaio': 'Llevas {n} días sin entrenar. Tu ki se está enfriando.',
  'roshi': '{n} días sin entrenar… hasta las tortugas se mueven más.',
  'krilin': '{n} días… ¿todo bien? ¡Vuelve, que no quiero entrenar solo!',
  'piccolo': '{n} días sin entrenar. Vuelve hoy.',
  'gohan': '{n} días sin entrenar. Tu racha está en peligro.',
  'trunks': '{n} días sin entrenar. No dejes que tu futuro se pierda.',
  'vegeta': '{n} días sin entrenar. ¿Te has rendido, insecto?',
  'goku': '¡{n} días sin entrenar! ¿Vamos a por ello hoy?',
};

String plannedTodayReminder(String masterId) => _plannedToday[masterId] ?? _plannedToday['kaio']!;

String streakRiskReminder(String masterId, int days) =>
    (_streakRisk[masterId] ?? _streakRisk['kaio']!).replaceAll('{n}', '$days');
