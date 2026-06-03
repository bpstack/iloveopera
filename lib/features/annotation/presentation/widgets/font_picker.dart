import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/annotation_providers.dart';

/// Dropdown to pick a font family from the curated set.
class FontPicker extends ConsumerWidget {
  const FontPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(textStyleProvider);
    final fonts = ref.watch(curadoFontsProvider);
    final hasTextTool = ref.watch(annotationToolProvider) == AnnotationTool.addText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<String>(
        value: current.fontFamily,
        onChanged: hasTextTool
            ? (v) {
                if (v != null) {
                  ref.read(textStyleProvider.notifier).setFontFamily(v);
                }
              }
            : null,
        items: fonts
            .map(
              (f) => DropdownMenuItem<String>(
                value: f.family,
                child: Text(
                  f.family,
                  style: TextStyle(fontFamily: f.family),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Compact numeric field to set the font size (in points).
class FontSizeField extends ConsumerWidget {
  const FontSizeField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(textStyleProvider);
    final hasTextTool = ref.watch(annotationToolProvider) == AnnotationTool.addText;
    final controller = TextEditingController(text: current.fontSize.round().toString());
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    return SizedBox(
      width: 56,
      child: TextField(
        controller: controller,
        enabled: hasTextTool,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (raw) {
          final v = double.tryParse(raw);
          if (v != null && v > 0) {
            ref.read(textStyleProvider.notifier).setFontSize(v);
          }
        },
      ),
    );
  }
}

/// Compact color swatch that opens a picker dialog.
///
/// Uses a hand-rolled dialog (no extra dependency) with a fixed grid of
/// common colors. Sufficient for Fase 2; can be swapped for
/// `flutter_colorpicker` later without touching the domain.
class ColorSwatchButton extends ConsumerWidget {
  const ColorSwatchButton({super.key, required this.isText});

  final bool isText;

  static const List<int> palette = <int>[
    0xFF000000, // black
    0xFFFFFFFF, // white
    0xFFE53935, // red
    0xFFFB8C00, // orange
    0xFFFDD835, // yellow
    0xFF43A047, // green
    0xFF1E88E5, // blue
    0xFF5E35B1, // purple
    0xFF6D4C41, // brown
    0xFF424242, // grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = isText
        ? ref.watch(textStyleProvider).colorArgb
        : ref.watch(rectStyleProvider).colorArgb;
    return InkWell(
      onTap: () => _open(context, ref),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(color),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isText ? 'Color del texto' : 'Color del rect (tipp-ex)'),
          content: SizedBox(
            width: 240,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: palette
                  .map(
                    (c) => InkWell(
                      onTap: () => Navigator.of(ctx).pop(c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          border: Border.all(
                            color: Theme.of(ctx).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    if (picked != null) {
      if (isText) {
        ref.read(textStyleProvider.notifier).setColor(picked);
      } else {
        ref.read(rectStyleProvider.notifier).setColor(picked);
      }
    }
  }
}
