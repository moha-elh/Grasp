import 'package:flutter/material.dart';

/// The Dropbox brand glyph (five parallelograms), drawn from the official
/// 24x24 path so we don't pull in an SVG dependency. Brand blue by default.
class DropboxLogo extends StatelessWidget {
  final double size;
  final Color color;
  const DropboxLogo({super.key, this.size = 64, this.color = const Color(0xFF0061FF)});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _DropboxPainter(color));
}

class _DropboxPainter extends CustomPainter {
  final Color color;
  const _DropboxPainter(this.color);

  // Five parallelograms in a 24x24 box (Dropbox brand geometry).
  static const _quads = <List<Offset>>[
    [Offset(6, 1.807), Offset(0, 5.629), Offset(6, 9.451), Offset(12.001, 5.629)],
    [Offset(18, 1.807), Offset(12, 5.629), Offset(18, 9.451), Offset(24, 5.629)],
    [Offset(0, 13.274), Offset(6, 17.096), Offset(12.001, 13.274), Offset(6, 9.452)],
    [Offset(18, 9.452), Offset(12, 13.274), Offset(18, 17.096), Offset(24, 13.274)],
    [Offset(6, 18.371), Offset(12.001, 22.193), Offset(18.001, 18.371), Offset(12.001, 14.549)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()..color = color..isAntiAlias = true;
    for (final quad in _quads) {
      final path = Path()..moveTo(quad[0].dx * s, quad[0].dy * s);
      for (var i = 1; i < quad.length; i++) {
        path.lineTo(quad[i].dx * s, quad[i].dy * s);
      }
      canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_DropboxPainter old) => old.color != color;
}
