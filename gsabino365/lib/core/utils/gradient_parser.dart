import 'package:flutter/material.dart';

/// ===================== GRADIENT PARSER =====================
/// Parses CSS-style linear-gradient strings into Flutter LinearGradient objects.
/// Useful when gradient values come from a backend/Firebase dynamic config.
class GradientParser {
  static Gradient parse(String? gradientString, {Gradient? fallback}) {
    if (gradientString == null || !gradientString.contains('linear-gradient')) {
      return fallback ??
          const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF0891B2)],
          );
    }

    try {
      // Extract hex colors
      final RegExp hexRegex = RegExp(r'#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})');
      final Iterable<Match> matches = hexRegex.allMatches(gradientString);

      final List<Color> colors = matches.map((m) {
        String hex = m.group(0)!;
        if (hex.length == 4) {
          // #RGB -> #RRGGBB
          hex = '#${hex[1] * 2}${hex[2] * 2}${hex[3] * 2}';
        }
        return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
      }).toList();

      if (colors.isEmpty) {
        return fallback ??
            const LinearGradient(colors: [Colors.blue, Colors.cyan]);
      }

      // Determine alignment based on keywords
      Alignment begin = Alignment.centerLeft;
      Alignment end = Alignment.centerRight;

      if (gradientString.contains('135deg')) {
        begin = Alignment.topLeft;
        end = Alignment.bottomRight;
      } else if (gradientString.contains('to top left')) {
        begin = Alignment.bottomRight;
        end = Alignment.topLeft;
      } else if (gradientString.contains('to bottom right')) {
        begin = Alignment.topLeft;
        end = Alignment.bottomRight;
      }

      return LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      );
    } catch (e) {
      return fallback ??
          const LinearGradient(colors: [Colors.blue, Colors.cyan]);
    }
  }
}
