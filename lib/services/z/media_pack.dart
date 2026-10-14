import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../ranking_engine/rank_tier.dart';
import 'campaign.dart';
import 'masters.dart';

// GymZ's "pack de recursos": the anime images, clips and sounds live only on
// the phone, never in the (public) git repo. The user builds a .zip whose
// files are named after the slots below (shenlong.mp4, kaio.png,
// punch.mp3…), imports it once from Ajustes, and every screen that has a
// slot picks the file up. Anything missing falls back to a bundled stock
// photo (images) or simply isn't played (video/sound), so the app works the
// same without a pack. Native only — the web build always uses the stock
// fallbacks.
enum ZMediaKind { image, video, audio }

const _extensions = {
  ZMediaKind.image: {'jpg', 'jpeg', 'png', 'webp', 'gif'},
  ZMediaKind.video: {'mp4', 'webm', 'mov', 'm4v'},
  ZMediaKind.audio: {'mp3', 'ogg', 'wav', 'm4a', 'aac'},
};

ZMediaKind? kindForExtension(String extension) {
  final ext = extension.toLowerCase();
  for (final entry in _extensions.entries) {
    if (entry.value.contains(ext)) return entry.key;
  }
  return null;
}

class ZMediaSlot {
  const ZMediaSlot(this.name, this.kinds, this.description, {this.stockAsset, this.group = 'Imágenes'});

  final String name;
  final Set<ZMediaKind> kinds;
  final String description;
  final String? stockAsset;
  final String group;
}

const _stock = 'assets/z/stock';

// Every slot the app knows about — also the checklist shown on the
// "Pack de recursos" screen and in docs/dragon-ball/pack-de-recursos.md.
const _baseSlots = <ZMediaSlot>[
  ZMediaSlot('saga_saiyan', {ZMediaKind.image}, 'Cielo de la Kame House en la Saga Saiyan', stockAsset: '$_stock/saga_saiyan.jpg'),
  ZMediaSlot('saga_namek', {ZMediaKind.image}, 'Cielo en la Saga de Namek', stockAsset: '$_stock/saga_namek.jpg'),
  ZMediaSlot('saga_androides', {ZMediaKind.image}, 'Cielo en la Saga de los Androides', stockAsset: '$_stock/saga_androides.jpg'),
  ZMediaSlot('saga_buu', {ZMediaKind.image}, 'Cielo en la Saga de Buu', stockAsset: '$_stock/saga_buu.jpg'),
  ZMediaSlot('saga_super', {ZMediaKind.image}, 'Cielo en la Saga Super', stockAsset: '$_stock/saga_super.jpg'),
  ZMediaSlot('kaio', {ZMediaKind.image}, 'Retrato de Kaio-sama para sus consejos'),
  ZMediaSlot('shenlong', {ZMediaKind.image, ZMediaKind.video}, 'Shenlong apareciendo (vídeo) o su imagen', stockAsset: '$_stock/shenlong.jpg'),
  ZMediaSlot('transform', {ZMediaKind.image, ZMediaKind.video}, 'Transformación genérica (si falta la de una forma)', stockAsset: '$_stock/transform.jpg'),
  ZMediaSlot('transform_saiyan', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Saiyan (forma base)'),
  ZMediaSlot('transform_ssj', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan'),
  ZMediaSlot('transform_ssj2', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan 2'),
  ZMediaSlot('transform_ssj3', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan 3'),
  ZMediaSlot('transform_ssj4', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan 4'),
  ZMediaSlot('transform_ssj_god', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan God'),
  ZMediaSlot('transform_ssj_blue', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Super Saiyan Blue'),
  ZMediaSlot('transform_ultra_instinto', {ZMediaKind.image, ZMediaKind.video}, 'Transformación: Ultra Instinto'),
  ZMediaSlot('kamehameha', {ZMediaKind.video}, 'Clip del Kamehameha al terminar el entreno'),
  ZMediaSlot('char_entrenando', {ZMediaKind.image}, 'Personaje entrenando (pantallas vacías)'),
  ZMediaSlot('char_record', {ZMediaKind.image}, 'Personaje orgulloso (récords)'),
  ZMediaSlot('char_zenkai', {ZMediaKind.image}, 'Personaje para la vuelta tras un parón'),
  ZMediaSlot('ki_charge', {ZMediaKind.audio}, 'Cargar ki (mantener pulsado)', group: 'Sonidos'),
  ZMediaSlot('kamehameha', {ZMediaKind.audio}, 'Kamehameha al terminar', group: 'Sonidos'),
  ZMediaSlot('punch', {ZMediaKind.audio}, 'Golpe al completar una serie', group: 'Sonidos'),
  ZMediaSlot('rest_done', {ZMediaKind.audio}, 'Fin del descanso', group: 'Sonidos'),
  ZMediaSlot('transform', {ZMediaKind.audio}, 'Transformación', group: 'Sonidos'),
  ZMediaSlot('level_up', {ZMediaKind.audio}, 'Subir de grado', group: 'Sonidos'),
  ZMediaSlot('scouter', {ZMediaKind.audio}, 'Pitido del rastreador', group: 'Sonidos'),
  ZMediaSlot('scouter_explode', {ZMediaKind.audio}, 'El rastreador explota (más de 9.000)', group: 'Sonidos'),
  ZMediaSlot('dragon_ball', {ZMediaKind.audio}, 'Esfera conseguida', group: 'Sonidos'),
  ZMediaSlot('summon', {ZMediaKind.audio}, 'Invocación de Shenlong', group: 'Sonidos'),
  ZMediaSlot('wish', {ZMediaKind.audio}, 'Deseo concedido', group: 'Sonidos'),
];

// Fase 2: villains, masters, attacks, scenes and the narrator.
final zMediaSlots = <ZMediaSlot>[
  ..._baseSlots,
  ZMediaSlot('ko', {ZMediaKind.audio}, 'Golpe final del combate semanal', group: 'Sonidos'),
  for (final tier in RankTier.values.skip(1))
    ZMediaSlot('forma_${tier.slug}', {ZMediaKind.video}, 'Transformación general: ${tier.label} (clip con sonido)',
        group: 'Transformaciones'),
  for (final fight in campaignFights)
    ZMediaSlot('jefe_${fight.id}', {ZMediaKind.image, ZMediaKind.video}, '${fight.displayName} (recorte; vídeo = su aparición o transformación)', group: 'Villanos'),
  for (final villain in {for (final f in campaignFights) f.villainId})
    ZMediaSlot('jefe_$villain', {ZMediaKind.image}, 'Imagen genérica del villano si falta la de una forma', group: 'Villanos'),
  for (final master in masters) ...[
    for (final mood in const ['contento', 'serio', 'riendo', 'preocupado'])
      ZMediaSlot('maestro_${master.id}_$mood', {ZMediaKind.image}, '${master.name}, cara $mood (recorte)', group: 'Maestros'),
    ZMediaSlot('maestro_${master.id}_combate', {ZMediaKind.image, ZMediaKind.video}, 'Combate de entrenamiento con ${master.name}', group: 'Maestros'),
  ],
  for (final attack in zAttacks)
    ZMediaSlot('ataque_${attack.id}', {ZMediaKind.video, ZMediaKind.audio}, '${attack.name} (clip y grito)', group: 'Ataques'),
  for (var i = 1; i <= 20; i++)
    ZMediaSlot('escena_${i.toString().padLeft(2, '0')}', {ZMediaKind.image}, 'Escena del anime para los episodios', group: 'Episodios'),
  for (var i = 1; i <= 5; i++)
    ZMediaSlot('narrador_$i', {ZMediaKind.audio}, 'Voz del narrador (se alternan)', group: 'Episodios'),
  ZMediaSlot('anteriormente', {ZMediaKind.audio}, 'Narrador: «Anteriormente en…»', group: 'Episodios'),
  ZMediaSlot('proximo_episodio', {ZMediaKind.audio}, 'Narrador: «En el próximo episodio…»', group: 'Episodios'),
];

final _knownNames = {for (final slot in zMediaSlots) slot.name};

// Pack slots of a kind that are filled, e.g. every escena_XX image.
List<String> filledSlots(String prefix, ZMediaKind kind) =>
    [for (final slot in zMediaSlots) if (slot.name.startsWith(prefix) && MediaPack.has(slot.name, kind)) slot.name];

String? stockAssetFor(String slot) =>
    zMediaSlots.where((s) => s.name == slot && s.stockAsset != null).firstOrNull?.stockAsset;

class PackImportResult {
  const PackImportResult({required this.imported, required this.ignored});

  final int imported;
  // File names in the zip that don't match any slot.
  final List<String> ignored;
}

class MediaPack {
  MediaPack._();

  static Directory? _dir;
  static final Map<String, File> _files = {};

  // Bumped after every import/clear so widgets showing pack media rebuild.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static bool get supported => !kIsWeb;

  static Future<void> init() async {
    if (kIsWeb) return _loadWebTestPack();
    try {
      final base = await getApplicationSupportDirectory();
      _dir = Directory('${base.path}/gymz_pack');
      await _scan();
    } catch (_) {
      // No pack directory = stock fallbacks everywhere; never block startup.
    }
  }

  // Tests point the pack at a folder of their own.
  @visibleForTesting
  static Future<void> initWithDirectory(Directory dir) async {
    _dir = dir;
    await _scan();
    revision.value++;
  }

  static String _key(String name, ZMediaKind kind) => '$name.${kind.name}';

  static Future<void> _scan() async {
    _files.clear();
    final dir = _dir;
    if (dir == null || !await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final parsed = _parse(entity.uri.pathSegments.last);
      if (parsed == null) continue;
      _files[_key(parsed.name, parsed.kind)] = entity;
    }
  }

  static ({String name, ZMediaKind kind, String ext})? _parse(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return null;
    final name = fileName.substring(0, dot).toLowerCase().trim();
    final ext = fileName.substring(dot + 1).toLowerCase();
    final kind = kindForExtension(ext);
    if (kind == null || !_knownNames.contains(name)) return null;
    return (name: name, kind: kind, ext: ext);
  }

  // Web test build only: a pack copied next to the app (build/web/assets/
  // gymz_pack/ plus an index.json listing its files) is used as if it had
  // been imported, so the pack can be tried on localhost. Never deployed.
  static final Map<String, String> _webFiles = {};

  static Future<void> _loadWebTestPack() async {
    try {
      final names = (jsonDecode(await rootBundle.loadString('gymz_pack/index.json')) as List).cast<String>();
      for (final fileName in names) {
        final parsed = _parse(fileName);
        if (parsed != null) _webFiles[_key(parsed.name, parsed.kind)] = fileName;
      }
    } catch (_) {
      // No test pack next to the app: stock fallbacks, as without a pack.
    }
  }

  static String? _webAssetKey(String name, ZMediaKind kind) {
    final fileName = _webFiles[_key(name, kind)];
    return fileName == null ? null : 'gymz_pack/$fileName';
  }

  // URL of a pack file in the web test build (relative to the app).
  static String? webUrl(String name, ZMediaKind kind) {
    final key = _webAssetKey(name, kind);
    return key == null ? null : 'assets/$key';
  }

  static File? file(String name, ZMediaKind kind) => _files[_key(name, kind)];

  static bool has(String name, ZMediaKind kind) =>
      _files.containsKey(_key(name, kind)) || _webFiles.containsKey(_key(name, kind));

  static Future<Uint8List?> bytes(String name, ZMediaKind kind) async {
    final file = MediaPack.file(name, kind);
    if (file != null) return file.readAsBytes();
    final key = _webAssetKey(name, kind);
    if (key == null) return null;
    return (await rootBundle.load(key)).buffer.asUint8List();
  }

  static int get installedCount => _files.length + _webFiles.length;

  // Pass [path] when the picker gives one (streams big zips from disk
  // instead of loading the whole thing into memory), [bytes] otherwise.
  static Future<PackImportResult> importZip({String? path, Uint8List? bytes}) async {
    final dir = _dir;
    if (dir == null) throw StateError('El pack solo se puede importar en la app de Android.');
    await dir.create(recursive: true);

    final InputStream input = path != null ? InputFileStream(path) : InputMemoryStream(bytes!);
    final archive = ZipDecoder().decodeStream(input);
    var imported = 0;
    final ignored = <String>[];
    try {
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final fileName = entry.name.split('/').last;
        if (fileName.startsWith('.') || fileName.isEmpty) continue;
        final parsed = _parse(fileName);
        if (parsed == null) {
          ignored.add(fileName);
          continue;
        }
        // Replaces any earlier file for the same slot and kind, even with a
        // different extension (shenlong.webm after shenlong.mp4).
        final previous = _files.remove(_key(parsed.name, parsed.kind));
        if (previous != null && await previous.exists()) await previous.delete();
        final output = OutputFileStream('${dir.path}/${parsed.name}.${parsed.ext}');
        entry.writeContent(output);
        await output.close();
        imported++;
      }
    } finally {
      await input.close();
    }
    await _scan();
    revision.value++;
    return PackImportResult(imported: imported, ignored: ignored);
  }

  static Future<void> clear() async {
    final dir = _dir;
    if (dir != null && await dir.exists()) await dir.delete(recursive: true);
    _files.clear();
    revision.value++;
  }
}
