import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/z/media_pack.dart';

// "Pack de recursos": import the .zip with the anime images, clips and
// sounds, and see which slots are filled. The files stay on this phone only.
class MediaPackScreen extends StatefulWidget {
  const MediaPackScreen({super.key});

  @override
  State<MediaPackScreen> createState() => _MediaPackScreenState();
}

class _MediaPackScreenState extends State<MediaPackScreen> {
  bool _busy = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['zip']);
      if (file == null) return;
      final path = file.path;
      final result = path != null
          ? await MediaPack.importZip(path: path)
          : await MediaPack.importZip(bytes: await file.readAsBytes());
      if (!mounted) return;
      _message(
        result.imported == 0
            ? 'El .zip no tenía ningún archivo con un nombre del pack. Revisa los nombres de la lista.'
            : '${result.imported} archivo${result.imported == 1 ? '' : 's'} importado${result.imported == 1 ? '' : 's'}'
                '${result.ignored.isEmpty ? '' : ' · ${result.ignored.length} ignorado${result.ignored.length == 1 ? '' : 's'} (nombre no reconocido)'}.',
      );
    } catch (e) {
      if (mounted) _message('No se ha podido importar el pack: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar el pack?'),
        content: const Text('Se quitarán del móvil todas las imágenes, vídeos y sonidos importados. '
            'La app volverá a usar las fotos de stock. Tus entrenos no se tocan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await MediaPack.clear();
    if (mounted) _message('Pack borrado.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<ZMediaSlot>>{};
    for (final slot in zMediaSlots) {
      groups.putIfAbsent(slot.group, () => []).add(slot);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pack de recursos')),
      body: ValueListenableBuilder<int>(
        valueListenable: MediaPack.revision,
        builder: (context, _, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${MediaPack.installedCount} archivos instalados', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Mete en un .zip las imágenes, vídeos y sonidos con los nombres de la lista '
                    '(por ejemplo shenlong.mp4, kaio.png o punch.mp3) e impórtalo aquí. '
                    'Se guardan solo en este móvil. Lo que falte se ve con fotos de stock o no suena.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: ZColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!MediaPack.supported)
                    Text('El pack solo funciona en la app de Android.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: ZColors.kaioken))
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _import,
                        icon: _busy
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.unarchive_outlined),
                        label: Text(_busy ? 'Importando…' : 'Importar pack (.zip)'),
                      ),
                    ),
                    if (MediaPack.installedCount > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: _busy ? null : _clear, child: const Text('Borrar pack')),
                      ),
                  ],
                ],
              ),
            ),
            for (final MapEntry(key: group, value: slots) in groups.entries) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
                child: Text(group.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < slots.length; i++) ...[
                      _SlotRow(slot: slots[i]),
                      if (i != slots.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});

  final ZMediaSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final installed = [for (final kind in slot.kinds) if (MediaPack.has(slot.name, kind)) kind];
    final kinds = slot.kinds.map((k) => switch (k) {
          ZMediaKind.image => 'imagen',
          ZMediaKind.video => 'vídeo',
          ZMediaKind.audio => 'sonido',
        });
    return ListTile(
      dense: true,
      leading: Icon(
        installed.isNotEmpty ? Icons.check_circle : Icons.radio_button_unchecked,
        color: installed.isNotEmpty ? ZColors.scouter : ZColors.muted,
        size: 20,
      ),
      title: Text(slot.name, style: ZText.hud(size: 14, color: ZColors.ink, spacing: 0.5)),
      subtitle: Text(
        '${slot.description} · ${kinds.join(' o ')}'
        '${installed.isEmpty && slot.stockAsset != null ? ' · ahora: foto de stock' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted),
      ),
    );
  }
}
