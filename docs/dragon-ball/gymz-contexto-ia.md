# GymZ — documento de contexto del proyecto

> **Versión:** 15 de octubre de 2026 · rama `dragon-ball` (último commit `c70a389`)
> **Para quién es:** cualquier persona o IA que vaya a opinar sobre el proyecto sin haber visto el código ni las conversaciones anteriores.

---

## 0. Instrucciones para la IA que lea esto

Te paso este documento para que tengas **todo el contexto** de una app personal de gimnasio con temática Dragon Ball. Lo que busco de ti:

1. **Cambios y mejoras** a lo que ya existe (reglas de juego, pantallas, textos, equilibrio).
2. **Ideas nuevas** que encajen con el universo y con el uso real de una app de gimnasio.
3. **Opinión sincera** sobre lo que no funcione o sobre riesgos que no hayamos visto.

Cómo responder, por favor:

- **En castellano.**
- Para cada propuesta: **qué es**, **por qué mejora la app**, **dificultad** (baja / media / alta) y **qué partes toca** (pantalla, regla, pack de recursos…).
- **Respeta las reglas del apartado 8** (lenguaje y restricciones). Por ejemplo: un entrenamiento nunca es un «combate».
- **No propongas** lo que ya está descartado en el apartado 10, salvo que tengas un argumento nuevo de verdad.
- Si algo del documento te parece contradictorio o poco claro, **pregúntalo** en vez de suponer.

---

## 1. Resumen en 30 segundos

- **Machoke** es una app de gimnasio Android (Flutter) que el usuario usa a diario: registro de entrenos, rutinas, calendario, historial, gráficas y un sistema de **rangos por ejercicio y por músculo**.
- **GymZ** es una **copia experimental de Machoke reinterpretada en el universo Dragon Ball**: los mismos datos y entrenos, pero cada concepto del gimnasio se convierte en algo del anime (nivel de poder, transformaciones, esferas del dragón, villanos semanales, maestros…).
- Es una **app personal que nunca se publicará**. Por eso usa nombres reales del anime e imágenes, vídeos y sonidos reales, que **no van en el código**: se importan en el móvil desde un `.zip` («pack de recursos»).
- Estado: **fase 1 y fase 2 implementadas**. Ahora mismo estamos **completando el pack de recursos** (imágenes, clips y sonidos) y **puliendo reglas** a raíz de las pruebas.

---

## 2. El proyecto y sus límites

| Tema | Detalle |
|---|---|
| Usuario | Una sola persona, sin experiencia programando. Toma las decisiones de diseño; el código lo escribe una IA (Claude Code). |
| Machoke | App original. **No se toca** desde el experimento. Vive en la rama `main`. |
| GymZ | Rama `dragon-ball`, en una carpeta aparte (`GymApp-DragonBall`). Es **otra app Android** (`com.alexsivera.gymz`, nombre «GymZ», icono propio): se instala junto a Machoke sin pisarla. Los datos pasan de una a otra con la copia de seguridad (exportar/importar). |
| Publicación | Nunca. Uso personal. |
| Repositorio | **Público** en GitHub. Por eso ningún material del anime entra en el repositorio: va en el pack. |
| Plataforma | Android primero. También compila para web (sirve para probar en el ordenador). Sin Mac, así que no hay iOS. |
| Compilación | El ordenador del usuario no puede compilar Android. El APK se genera en **GitHub Actions** y se instala en el móvil. Los tests y la web sí funcionan en local. |
| Idioma | Castellano de España en toda la app. |

---

## 3. Tecnología (resumen para orientarse)

- **Flutter / Dart**, gestión de estado con **Riverpod**, base de datos local **SQLite (drift)**, navegación con **go_router**.
- Vídeo con `video_player`, sonido con `audioplayers`, `.zip` con `archive`.
- Todo es **local**: sin servidor ni cuentas. La IA de consejos es un motor de reglas local, no un modelo de lenguaje.
- El código de GymZ está separado del de Machoke:
  - `lib/services/z/`: reglas puras (nivel de poder, esferas, Genkidama, campaña, maestros, episodios, pack, sonidos).
  - `lib/features/z/`: pantallas y componentes visuales.
- Base de datos: GymZ solo añade una tabla clave-valor (`ZKeyValues`) para su estado de juego. Así las copias de seguridad de Machoke se importan sin problemas.
- **111 tests automáticos** pasando (reglas de la campaña, nivel de poder, esferas, pantallas en móvil pequeño…).

---

## 4. Qué es Machoke (la base)

Funciones que ya existían antes de GymZ y que GymZ conserva:

- **Entreno en vivo:** series con peso y repeticiones, temporizador de descanso, superseries, notas, RIR, sugerencias de progresión (subir peso), kg o lb.
- **Ejercicios:** unos 250, con GIF animados. Tres tipos: fuerza, cardio (tiempo y km) e isométricos (segundos). Permite crear ejercicios propios.
- **Rutinas** de uno o varios días, plantillas y archivado.
- **Calendario:** planificar, asignar rutinas a días y reorganizar entrenos perdidos.
- **Historial y gráficas** de progreso.
- **Récords personales.**
- **Calorías estimadas** (MET), con integración opcional con Health Connect.
- **Rangos:** cada ejercicio con estándares de fuerza (243 lo tienen) recibe un rango de 8 niveles × 3 grados según tu 1RM estimado relativo al peso corporal. Hay un diagrama corporal con 17 músculos en 7 grupos (Brazos, Piernas, Espalda, Pecho, Hombros, Abdominales, Cuello).
- **Consejos diarios** y **notificaciones** proactivas (entreno planificado hoy, racha en riesgo).
- **Copia de seguridad** (exportar/importar).
- **Objetivo semanal** de entrenamientos (por ejemplo, 4 días por semana).

---

## 5. El mapa: qué se convierte en qué

Estado: ✅ hecho · 🟡 parcial · 💭 idea sin hacer.

| Machoke | GymZ | Estado |
|---|---|---|
| Inicio | **Kame House**: nivel de poder, entreno de hoy, rival de la semana, esferas, Genkidama, kcal y el maestro asomándose con un consejo. Fondo = escena de la saga actual. | ✅ |
| Calendario / planificar | **Radar del dragón** (incluye las rutinas) | ✅ |
| Rutinas | **Cápsulas** (Nº 01, Nº 02…) | ✅ |
| Biblioteca de ejercicios | **Técnicas** (cardio = Nube Kinton) | ✅ |
| Entreno en vivo | **Cámara de gravedad** («sube la gravedad +2,5 kg») | ✅ |
| Descanso | **Semilla del ermitaño** | ✅ |
| Superseries | **Fusión** | ✅ |
| Terminar entreno | **Botón Kamehameha**: mantener pulsado para cargar y lanzar el ataque equipado | ✅ |
| Resumen de sesión | **¡Entrenamiento terminado!** en estilo viñeta de manga, con esfera ganada, golpe al villano y cameo de Vegeta si hay récord | ✅ |
| Récord personal | **Límite superado** / Técnicas dominadas | ✅ |
| Calorías | **Ki gastado** | ✅ |
| Volumen semanal | **Genkidama** | ✅ |
| Objetivo semanal / racha | **Esferas del dragón** | ✅ |
| Rangos | **Poder**: diagrama con auras por músculo y lectura del rastreador | ✅ |
| Subida de rango de un ejercicio | **¡Transformación!** con la imagen de la forma | ✅ |
| Subida de la media corporal | **Transformación general** con el clip de vídeo de la forma | ✅ |
| Consejo del día / notificaciones | Habla tu **maestro principal** (Kaio-sama al empezar) | ✅ |
| Perfil | **Ficha de guerrero**: aura, título, saga, maestros y ataques | ✅ |
| Copia de seguridad | **Cápsula de respaldo** | ✅ |
| Vuelta tras un parón | **Zenkai** (sin regañinas; sugiere bajar carga) | ✅ |
| Onboarding | **Escaneo inicial** con el rastreador | 💭 |
| Isométricos | **Concentración de ki** | 💭 |

**Barra inferior:** Kame House · Radar · Poder · Ficha, con el botón de entrenar en el centro.

**Estilo visual:**
- Fondo «noche» `#0A0D1C`, naranja del gi para las acciones, dorado y azul del ki para el progreso, verde del rastreador para los datos.
- Las celebraciones cambian a estilo **papel de manga**.
- Tipografías: Dela Gothic One (titulares y kanji), Plus Jakarta Sans (texto) y Share Tech Mono (rastreador).

---

## 6. Sistemas de juego (reglas exactas)

### 6.1 Transformaciones (rangos)

Son los 8 niveles de rango de Machoke con nombre y color nuevos. Los umbrales de fuerza no cambian.

| Nivel | Forma | Color del aura |
|---|---|---|
| 1 | Saiyan (forma base) | Marrón tierra |
| 2 | Super Saiyan | Dorado clásico |
| 3 | Super Saiyan 2 | Oro eléctrico (con rayos) |
| 4 | Super Saiyan 3 | Ámbar intenso |
| 5 | Super Saiyan 4 | Granate |
| 6 | Super Saiyan God | Rojo brillante |
| 7 | Super Saiyan Blue | Azul |
| 8 | Ultra Instinto | Blanco brillante |

- Cada forma tiene **3 grados**, que se muestran con estrellas: «Super Saiyan 2 ★★».
- La **puntuación** de un rango va de 1 a 24 (nivel × 3 + grado).
- Subir de rango en un ejercicio abre la pantalla **¡Transformación!** con la imagen de esa forma.

### 6.2 Nivel de poder y forma general

- **Requisito previo:** el rastreador **no da lectura** hasta que tengas al menos un ejercicio con rango en **los 5 grupos principales**: brazos, piernas, espalda, pecho y hombros. Mientras tanto, la app te dice qué grupos faltan.
- **Media de todo el cuerpo:** se promedia cada músculo (la media de sus ejercicios) entre los **17 músculos**. Los que no tienen lectura cuentan como **Saiyan ★** (puntuación 1). Así, un solo ejercicio muy fuerte no te convierte en Super Saiyan Blue: tienes que serlo en todo el cuerpo.
- **Fórmula:** `nivel de poder = 1500 × 1,57 ^ (puntuación media)`. Está calibrada para que **pasar de 9.000 coincida con tu primer Super Saiyan**. El máximo ronda los 75 millones.
- **«¡Más de 9.000!»:** la primera vez que lo superas, el rastreador «estalla» con una animación. Solo pasa una vez.
- **Transformación general:** cuando tu media sube a una forma que **nunca habías alcanzado**, se reproduce a pantalla completa el **clip de vídeo** de esa forma, con sonido.
  - Se guarda la forma más alta alcanzada: si la media baja (por ejemplo, al añadir un ejercicio nuevo más flojo), no se repite ningún clip.
  - Si subes varias formas de golpe, se reproducen **todas en orden**.
  - La primera lectura reproduce todas las formas ya alcanzadas, desde SSJ.

### 6.3 Esferas del dragón y Shenlong

- **1 esfera por cada semana en la que cumples tu objetivo** de entrenamientos.
- Con **7 esferas** aparece **Shenlong** (pantalla con animación) y concede **un deseo** a elegir:
  - **Aura cosmética** para la ficha: Ultra Instinto, Super Saiyan Blue, Ki divino o Kaioken.
  - **Semana libre:** una semana cuenta como cumplida aunque no entrenes.
  - **Título** junto a tu nombre.
- Después las esferas se dispersan y empiezas a reunirlas de nuevo.
- La primera vez que reúnes las 7, **Kaio-sama te enseña la Genkidama** (ataque).

### 6.4 Genkidama

Una esfera de energía que se llena con el **volumen semanal** (kg totales). Está al 100 % cuando igualas tu **media de las últimas 4 semanas**.

### 6.5 Campaña semanal contra villanos (el núcleo de la fase 2)

**Un villano por semana.** El combate es contra el villano; los entrenamientos son entrenamientos.

**Cuándo se resuelve:** en el entrenamiento que completa tu objetivo semanal o, si no lo completas, el domingo por la noche. Ese resultado se ve el lunes en «Anteriormente en GymZ…».

**Daño**, en % de la vida máxima del villano, según la fracción del objetivo cumplida:

| Objetivo cumplido | Daño |
|---|---|
| 100 % | 100 % |
| 75 % | 75 % |
| 50 % | 40 % |
| 25 % | 15 % |
| 0 % | 0 % |

Para otros objetivos semanales (por ejemplo, 3 o 5 días) se interpola entre esos puntos.

- **Curación:** si el villano sobrevive, se cura un % de su vida máxima cada semana; ese % depende del villano. Así no se le gana solo con insistir.
- **Días extra:** cada entrenamiento por encima del objetivo **daña de antemano a la siguiente forma un 10 %**, hasta un máximo del 30 %.
- **Formas:** los villanos grandes se pelean en varias semanas, **una forma por semana**. El daño sobrante no pasa de una forma a la siguiente.
- **Sagas:** la saga cambia cuando cae la última forma de su último villano. Cada saga cambia el fondo de Kame House.
- **Inicio:** la campaña empieza en Raditz aunque importes historial antiguo. Los rangos y el poder sí se conservan.
- La vida es cosmética: la dificultad real la marca el **% de curación**.

**Tabla de la campaña** (31 combates, 17 villanos):

| Saga | Combate (forma) | Vida | Cura/semana | Recompensa al vencer |
|---|---|---|---|---|
| Saiyan | Raditz | 800 | 15 % | Ataque: Double Sunday |
| Saiyan | Nappa | 1.500 | 20 % | Ataque: Bomber DX |
| Saiyan | Vegeta (normal) | 3.000 | 25 % | — |
| Saiyan | Vegeta (Ozaru) | 4.000 | 35 % | Título: Rival del príncipe |
| Namek | Dodoria | 1.500 | 15 % | Título: Guerrero de Namek |
| Namek | Zarbon (normal) | 2.000 | 20 % | — |
| Namek | Zarbon (monstruo) | 2.500 | 25 % | Título: El más bello del universo |
| Namek | Ginyu | 3.500 | 25 % | Título: Fuerzas Especiales Ginyu |
| Namek | Freezer 1.ª forma | 4.000 | 25 % | — |
| Namek | Freezer 2.ª forma | 5.000 | 30 % | — |
| Namek | Freezer 3.ª forma | 6.000 | 35 % | — |
| Namek | Freezer forma final | 7.000 | 40 % | — |
| Namek | Freezer al 100 % | 9.000 | 50 % | Ataque: Rayo mortal + título: Superviviente de Namek |
| Androides | Androide 19 | 3.000 | 30 % | Título: Desguazador |
| Androides | Androide 18 | 4.500 | 30 % | Título: Cazador de androides |
| Androides | Androide 17 | 5.000 | 35 % | Ataque: Barrera explosiva |
| Androides | Cell imperfecto | 6.000 | 35 % | — |
| Androides | Cell semiperfecto | 7.000 | 40 % | — |
| Androides | Cell perfecto | 8.000 | 50 % | Ataque: Kamehameha de Cell |
| Androides | Cell superperfecto | 10.000 | 60 % | Título: Campeón de los Juegos de Cell |
| Buu | Dabura | 5.000 | 30 % | Título: Vencedor del Reino Demoníaco |
| Buu | Majin Vegeta | 7.000 | 35 % | Ataque: Explosión final |
| Buu | Majin Buu (gordo) | 7.000 | 40 % | — |
| Buu | Majin Buu (malo) | 8.000 | 45 % | — |
| Buu | Super Buu | 9.000 | 50 % | Ataque: Rayo chocolate |
| Buu | Kid Buu | 10.000 | 60 % | Título: Salvador del universo + aura Majin |
| Super | Freezer dorado | 9.000 | 20 % | Aura dorada |
| Super | Goku Black (normal) | 9.000 | 40 % | — |
| Super | Goku Black (Rosé) | 10.000 | 50 % | Ataque: Kamehameha Black |
| Super | Jiren (normal) | 11.000 | 45 % | — |
| Super | Jiren (máximo poder) | 12.000 | 60 % | Título: Campeón del Torneo del Poder |

**Dónde se ve:**
- **Kame House:** tarjeta del rival de la semana con su barra de vida y el texto «Te quedan 2 días para el combate contra Nappa».
- **Durante el entreno:** un banner.
- **Pantalla de combate:** cuando se resuelve, con el golpe final («K.O.») si cae.

### 6.6 Maestros (estilo Xenoverse)

Los maestros se **desbloquean con pruebas de entrenamiento reales**. Al desbloquearlos te enseñan su ataque.

| Maestro | Prueba para desbloquearlo | Ataque que enseña |
|---|---|---|
| Kaio-sama | Desde el principio | Genkidama (al reunir las primeras 7 esferas) |
| Roshi | Tus primeros 5 entrenamientos | Kamehameha |
| Krilin | 2 semanas seguidas cumplidas | Kienzan |
| Piccolo | 4 semanas seguidas cumplidas | Makankosappo |
| Gohan | Lectura en todos los grupos musculares | Masenko |
| Trunks | 25 entrenamientos | Burning Attack |
| Vegeta | 10 límites superados (récords) | Galick Gun |
| Goku | Tu media llega a Super Saiyan 3 | Kamehameha instantáneo |

- **Maestro principal:** se elige en la Ficha. Es quien te da los consejos diarios (con estados de ánimo: contento, serio, riendo, preocupado) y quien firma las notificaciones. Se asoma en Kame House con un consejo una vez al día.
- **Cameos:** los demás maestros aparecen en momentos grandes. Vegeta aparece cuando superas un récord; Goku, cuando te transformas.

### 6.7 Ataques

- Hay **17 ataques**: la Ráfaga de ki (inicial), los 8 de los maestros y los 8 de los villanos.
- **Son cosméticos:** solo cambian la animación, el color, el grito y el sonido del botón para terminar el entreno. Todos hacen el mismo daño.
- Se equipan en Ficha → Maestros y ataques.

### 6.8 Episodios

- **«¡En el próximo episodio de GymZ!»:** sale tras cada entrenamiento (unos 4 segundos, se puede saltar y desactivar en Ajustes). Es un avance generado con tus datos reales, por ejemplo: «¡Nappa entra en escena!» o «Te quedan 2 días para el combate contra Freezer».
- **«Anteriormente en GymZ…»:** la primera vez que abres la app cada semana. Son 4 páginas de resumen: cómo fue la semana, resultado del combate, maestros nuevos y lo que te espera.

### 6.9 Sonidos

Hay sonidos para: golpe al completar una serie, carga de ki, Kamehameha, transformación, subida de grado, pitido y explosión del rastreador, K.O., fin del descanso, esfera conseguida, invocación de Shenlong y deseo concedido. Todos vienen del pack: **sin pack, la app está en silencio**. Se pueden desactivar en Ajustes.

---

## 7. El pack de recursos

**Por qué existe:** el repositorio es público, así que las imágenes, vídeos y sonidos del anime **no pueden ir en el código**.

**Cómo funciona:**
- El usuario mete en un `.zip` archivos con **nombres fijos** («huecos»): por ejemplo `jefe_nappa.webp`, `forma_ssj.mp4` o `punch.mp3`.
- Lo importa en el móvil desde **Ficha → Pack de recursos → Importar**.
- Los archivos se guardan solo en ese móvil.
- Lo que falte se muestra con **fotos de stock** (incluidas en la app) o no suena.

**Detalles útiles:**
- **Recortes o capturas:** la app detecta sola si una imagen es un **recorte con fondo transparente** o una **captura**. Las capturas de maestros se muestran en una «ventana de telepatía». En los retratos redondos, la app localiza la cabeza del recorte y hace zoom en la cara.
- **Modo pruebas en web:** la versión web puede leer el pack copiado junto a ella (`tool/pack_to_web.sh`) para probar en el ordenador.
- **Fuentes:** cada archivo tiene su origen apuntado en `FUENTES.txt`, dentro de la carpeta del pack.

**Estado actual del pack** (76 archivos, unos 47 MB):

| Grupo | Huecos | Estado |
|---|---|---|
| Sonidos (12 + K.O.) | `punch`, `ki_charge`, `kamehameha`, `transform`, `level_up`, `scouter`, `scouter_explode`, `ko`, `rest_done`, `dragon_ball`, `summon`, `wish` | ✅ Efectos en inglés o japonés. **No hay voces en castellano.** |
| Villanos (31 formas) | `jefe_<forma>` | ✅ Recortes oficiales con fondo transparente (arte de *Sparking! Zero*) |
| Maestros | `maestro_<id>_<ánimo>` | ✅ 7 maestros con una pose cada uno (recorte). Kaio-sama: 4 capturas del anime (no existe recorte oficial). |
| Fondos de saga (5) | `saga_<saga>` | ✅ |
| Shenlong | `shenlong` | ✅ Imagen. 💭 Vídeo de invocación. |
| Transformación por ejercicio (8) | `transform_<forma>` | ✅ SSJ3, SSJ God y Ultra Instinto tienen **poca resolución** (335–415 px de ancho) y en el móvil se verán algo borrosas. |
| Transformación general (7 clips) | `forma_<forma>.mp4` | ✅ Clips verticales 608×1080 de 5 a 7 s con sonido, cortados de un vídeo de transformaciones en videojuegos. Llevan subtítulos en inglés del juego. |
| Ataques (17) | `ataque_<id>` (clip y grito) | 💭 Vacío |
| Escenas para episodios (20) | `escena_01`…`escena_20` | 💭 Vacío. Ya están localizadas muchas capturas de los tráilers de *Sparking! Zero* que encajarían. |
| Narrador (5 + 2) | `narrador_1…5`, `anteriormente`, `proximo_episodio` | 💭 Vacío. Se buscan voces en castellano. |
| Combate de entrenamiento con maestro | `maestro_<id>_combate` | 💭 Vacío |
| Personaje en pantallas vacías | `char_entrenando`, `char_record`, `char_zenkai` | 💭 Vacío (el código aún no los usa) |
| Villano: clip de aparición o transformación | vídeo en `jefe_<forma>` | 💭 Vacío |

---

## 8. Reglas que hay que respetar

1. **Los entrenamientos se llaman «entrenamientos» (o «entrenos»), nunca «combates».** «Combate» solo se usa para el combate semanal contra el villano y para el «combate de entrenamiento» con un maestro.
2. **Nombres reales del anime** (uso personal), en castellano de España cuando exista la traducción: Freezer, Krilin, Shenlong, Kaio-sama…
3. **La fuerza sigue siendo real.** Las transformaciones salen de los rangos calculados con tus marcas; nada se compra ni se regala. Las recompensas de villanos y deseos son **cosméticas o de constancia**.
4. **Nada del anime en el repositorio**: todo va por el pack.
5. **La app debe funcionar sin pack**, con fotos de stock y en silencio.
6. **Machoke no se toca.**
7. **Móvil primero:** cada pantalla se prueba en tamaños pequeños (360×740).
8. El usuario prefiere **funciones grandes entregadas de una vez** antes que muchas fases pequeñas, porque cada prueba en el móvil requiere compilar en la nube.

---

## 9. En qué estamos trabajando ahora

1. **Completar el pack de recursos.** En curso:
   - Escenas para los episodios (capturas de *Sparking! Zero* ya localizadas).
   - Clips y gritos de los ataques.
   - Narrador y voces, preferiblemente en castellano.
   - Versiones en alta resolución de 3 imágenes de transformación.
   - Recortes de Kaio-sama, si aparecen.
2. **Probar en el móvil real** todo lo de las últimas sesiones. Está verificado en la versión web y con tests, pero **aún no en el teléfono**: campaña, maestros, episodios, clips de transformación y regla de los 5 grupos.
3. **Ajustes de reglas a raíz del uso.** Los últimos:
   - Rangos renombrados.
   - Grados con estrellas.
   - Media de todo el cuerpo.
   - Requisito de los 5 grupos principales.
   - Clips de la transformación general.

---

## 10. Decisiones ya tomadas o descartadas (y por qué)

| Decisión | Motivo |
|---|---|
| Jefe **por semana**, no por entrenamiento ni por serie | Premia la **constancia** semanal, que es lo que más cuesta en el gimnasio. |
| Daño por % del objetivo, con curación semanal | Evita ganar «por repetición» y hace que cada semana cuente. |
| Formas de villano como combates separados | Conserva las transformaciones de Freezer, Cell y Buu sin complicar las reglas. |
| Sin selector de tema: conversión total | Es un experimento; Machoke sigue existiendo para el estilo normal. |
| Los ataques son cosméticos | No se puede «comprar» ventaja: la fuerza sale del gimnasio. |
| Maestros desbloqueados por pruebas reales (estilo Xenoverse) | Cada maestro premia un hábito distinto: constancia, volumen, récords, equilibrio muscular… |
| Antes: Terrícola, Guerrero Z y Kaioken como rangos | Sustituidos por la escalera Saiyan → Ultra Instinto, más reconocible. |
| La forma general solo cuenta con los 5 grupos principales y todo el cuerpo | Con pocos ejercicios, un solo levantamiento alto te convertía en Blue y te saltabas transformaciones. |
| Saga Super corta (Freezer dorado, Black, Jiren) | Se ampliará cuando la app esté terminada. |
| Creador de avatar propio | Aplazado: hay demasiadas transformaciones y razas para hacerlo bien ahora. |
| Repositorio aparte para GymZ | Aplazado: ahora es una rama del mismo repositorio; funciona y no afecta a Machoke. |
| Arte dibujado con código | Descartado: todo lo visual del anime lo pone el pack. |

---

## 11. Ideas futuras: dificultad y coste estimado

**Cómo leer las columnas:**
- **Dificultad:** baja (un ajuste), media (una pantalla o regla nueva), alta (un sistema nuevo o cambios en muchas partes).
- **Tokens:** coste aproximado de una sesión de IA programadora (Claude Code) para hacerlo **con pruebas incluidas**. Cuenta leer el código, escribirlo, ejecutar tests, compilar y revisar en el navegador. Es una **estimación orientativa**:
  - **Pequeño:** menos de 100.000 tokens.
  - **Medio:** 100.000–400.000.
  - **Grande:** 400.000–1.000.000.
  - **Muy grande:** más de 1.000.000.

### 11.1 Detalles y pulido (sobre lo que ya existe)

| Idea | Qué es | Dificultad | Tokens |
|---|---|---|---|
| Botón «volver a ver el resumen» | Revivir «Anteriormente en GymZ…» desde la Ficha. | Baja | Pequeño |
| El poder no se desploma | Si tu media baja, el número desciende como mucho un 2 % por semana (estaba en el concepto original). | Baja | Pequeño |
| Escaneo inicial | El onboarding como un escaneo del rastreador, con tu primer nivel de poder al final. | Media | Medio |
| Concentración de ki | Los isométricos con su propia animación de «aguantar el ki». | Baja | Pequeño |
| Onda de telepatía | Una onda al aparecer el maestro en Kame House. | Baja | Pequeño |
| Chispas de la Genkidama | Partículas que suben a la esfera con cada serie de la semana. | Media | Pequeño–Medio |
| Cameo de Piccolo | Aparece cuando pierdes la racha («levántate»). | Baja | Pequeño |
| Notificaciones con retrato | La notificación muestra la cara de tu maestro principal. | Media | Medio |
| Usar los huecos de personaje | `char_entrenando`, `char_record` y `char_zenkai` en las pantallas vacías y en la vuelta tras un parón. | Baja | Pequeño |
| Clip del villano al transformarse | Vídeo entre formas (Freezer pasa a su 2.ª forma…). El hueco existe, pero el código aún no lo reproduce. | Media | Medio |

### 11.2 Funciones nuevas

| Idea | Qué es | Dificultad | Tokens |
|---|---|---|---|
| Combate de entrenamiento con maestro | Al desbloquear un maestro, un mini combate con vídeo, como presentación. | Media | Medio |
| Androides 17 y 18 como maestros | Desbloqueables con pruebas propias, por ejemplo de cardio. | Media | Medio |
| Ampliar la Saga Super | Más villanos (Hit, Zamasu fusionado, Moro, Gas…) con sus formas. Requiere ampliar la tabla y el pack. | Media | Medio |
| Sagas GT y películas | Baby, Super 17, Broly, Cooler… como campañas extra tras terminar. | Media–Alta | Medio–Grande |
| Habitación del Tiempo | Un reto opcional (por ejemplo, 7 días seguidos o un bloque de volumen) con recompensa especial. | Media | Medio |
| Torneo de Artes Marciales | Evento mensual: compites contra tus propias marcas del mes anterior por rondas. | Alta | Grande |
| Creador de avatar | Tu propio guerrero (raza, pelo, ropa) que se transforma con tu rango real. | Alta | Muy grande |
| Repositorio propio para GymZ | Separar GymZ del repositorio de Machoke. | Media | Medio |
| Widget de pantalla de inicio | Nivel de poder y esferas en un widget de Android. | Media–Alta | Grande |

### 11.3 Contenido del pack (sin código, solo buscar y preparar material)

| Idea | Qué es | Dificultad | Tokens |
|---|---|---|---|
| Escenas de episodios | 20 capturas para «Anteriormente» y «Próximo episodio». | Baja | Pequeño–Medio |
| Clips de ataques | 17 clips cortos y sus gritos. | Media | Medio |
| Voces en castellano | Narrador y frases de los maestros con el doblaje de España. | Media (difícil de encontrar) | Medio |
| Mejores imágenes de transformación | SSJ3, God y Ultra Instinto en alta resolución. | Baja | Pequeño |
| Vídeo de Shenlong | Invocación del dragón en vertical. | Baja | Pequeño |

---

## 12. Preguntas abiertas en las que nos vendría bien ayuda

1. **Equilibrio de la campaña:** ¿las curaciones semanales (15 %–60 %) hacen que los villanos finales sean demasiado duros para alguien que entrena 3–4 días por semana?
2. **Músculos pequeños:** cuello, abductores, lumbar… cuentan como Saiyan ★ si no se entrenan. ¿Es justo o deberían pesar menos que los grandes en la media?
3. **Motivación a largo plazo:** cuando termines la campaña y tengas todos los maestros, ¿qué te hace seguir abriendo la app? (¿temporadas, campañas nuevas, prestigio…?)
4. **Momentos «wow»:** ¿qué otro momento del gimnasio merece una celebración del anime que todavía no tengamos?
5. **Simplicidad:** ¿hay algo que sobre o que pueda confundir en el día a día del entreno?
