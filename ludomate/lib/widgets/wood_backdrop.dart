import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A warm wooden "table" surface the board sits on, matching the reference
/// video's vibe. Drawn procedurally (radial bands + a soft vignette) so it
/// needs no image asset and stays crisp at any size.
class WoodBackdrop extends StatelessWidget {
  const WoodBackdrop({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _WoodGrainPainter()),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.woodLight, AppColors.woodBase, AppColors.woodDark],
        ).createShader(rect),
    );

    // Soft concentric grain rings, subtly off-center like real wood grain.
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.woodDark.withValues(alpha: 0.18)
      ..strokeWidth = size.shortestSide * 0.004;
    final center = Offset(size.width * 0.32, size.height * 0.22);
    final maxRadius = size.longestSide * 1.1;
    for (double r = size.shortestSide * 0.08; r < maxRadius; r += size.shortestSide * 0.065) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2, height: r * 2.3),
        grainPaint,
      );
    }

    // Vignette so the framed board pops against the edges.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
