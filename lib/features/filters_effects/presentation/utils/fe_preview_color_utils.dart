import 'package:flutter/material.dart';

/// Preset preview color with a gradient swatch; [hex] is stored in the API.
class FePreviewColorOption {
  const FePreviewColorOption({
    required this.hex,
    required this.colors,
    required this.label,
  });

  final String hex;
  final List<Color> colors;
  final String label;
}

/// Curated filter/effect preview palettes (no manual hex typing required).
const kFePreviewColorPalette = <FePreviewColorOption>[
  FePreviewColorOption(
    hex: '#FF6B6B',
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
    label: 'Sunset',
  ),
  FePreviewColorOption(
    hex: '#4FACFE',
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    label: 'Ocean',
  ),
  FePreviewColorOption(
    hex: '#11998E',
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    label: 'Forest',
  ),
  FePreviewColorOption(
    hex: '#667EEA',
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    label: 'Lavender',
  ),
  FePreviewColorOption(
    hex: '#FF9A56',
    colors: [Color(0xFFFF9A56), Color(0xFFFFCC80)],
    label: 'Peach',
  ),
  FePreviewColorOption(
    hex: '#F5576C',
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    label: 'Rose',
  ),
  FePreviewColorOption(
    hex: '#232526',
    colors: [Color(0xFF232526), Color(0xFF414345)],
    label: 'Midnight',
  ),
  FePreviewColorOption(
    hex: '#F7971E',
    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    label: 'Golden',
  ),
  FePreviewColorOption(
    hex: '#56AB2F',
    colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
    label: 'Mint',
  ),
  FePreviewColorOption(
    hex: '#FF7E5F',
    colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
    label: 'Coral',
  ),
  FePreviewColorOption(
    hex: '#E0EAFC',
    colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
    label: 'Arctic',
  ),
  FePreviewColorOption(
    hex: '#8E0E00',
    colors: [Color(0xFF8E0E00), Color(0xFF1F1C18)],
    label: 'Wine',
  ),
  FePreviewColorOption(
    hex: '#F5F7FA',
    colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
    label: 'Cream',
  ),
  FePreviewColorOption(
    hex: '#00DBDE',
    colors: [Color(0xFFFC00FF), Color(0xFF00DBDE)],
    label: 'Neon',
  ),
  FePreviewColorOption(
    hex: '#C79081',
    colors: [Color(0xFFC79081), Color(0xFFDFA579)],
    label: 'Sepia',
  ),
  FePreviewColorOption(
    hex: '#FFFFFF',
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
    label: 'White',
  ),
];

Color? parsePreviewColorHex(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var value = hex.trim().toUpperCase();
  if (!value.startsWith('#')) value = '#$value';
  if (value.length == 7) {
    return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
  }
  if (value.length == 9) {
    return Color(int.parse(value.substring(1), radix: 16));
  }
  return null;
}

String formatPreviewColorHex(Color color) {
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

FePreviewColorOption? findPreviewColorOption(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  final normalized = hex.trim().toUpperCase();
  for (final option in kFePreviewColorPalette) {
    if (option.hex.toUpperCase() == normalized ||
        option.hex.toUpperCase() == '#${normalized.replaceFirst('#', '')}') {
      return option;
    }
  }
  return null;
}

List<Color> previewGradientForHex(String? hex) {
  final match = findPreviewColorOption(hex);
  if (match != null) return match.colors;
  final parsed = parsePreviewColorHex(hex);
  if (parsed != null) {
    return [parsed, parsed.withValues(alpha: 0.72)];
  }
  return const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)];
}

FePreviewColorOption resolvePreviewColorOption(String? hex) {
  return findPreviewColorOption(hex) ??
      FePreviewColorOption(
        hex: hex?.trim().isNotEmpty == true
            ? hex!.trim()
            : kFePreviewColorPalette.first.hex,
        colors: previewGradientForHex(hex),
        label: 'Custom',
      );
}

String defaultPreviewColorHex({bool required = false}) {
  return required
      ? kFePreviewColorPalette.first.hex
      : kFePreviewColorPalette.first.hex;
}

bool isValidFePreviewHex(String? hex) => parsePreviewColorHex(hex) != null;
