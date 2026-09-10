import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Draws a classic 15x15 Ludo board scaled entirely off [size], so it stays
/// correct at any board size passed in by the parent LayoutBuilder.
class LudoBoardPainter extends CustomPainter {
  const LudoBoardPainter();

  static const int gridCount = 15;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / gridCount;
    final Rect fullRect = Offset.zero & size;

    // Base board.
    canvas.drawRect(fullRect, Paint()..color = Colors.white);

    // Four home yards (6x6 corners).
    _fillBlock(canvas, cell, 0, 0, 6, 6, AppColors.zoneGreen);
    _fillBlock(canvas, cell, 0, 9, 6, 6, AppColors.zoneYellow);
    _fillBlock(canvas, cell, 9, 0, 6, 6, AppColors.zoneRed);
    _fillBlock(canvas, cell, 9, 9, 6, 6, AppColors.zoneBlue);

    // Home-stretch columns/rows leading into the center.
    _fillBlock(canvas, cell, 1, 7, 5, 1, AppColors.zoneYellow); // top arm
    _fillBlock(canvas, cell, 7, 9, 1, 5, AppColors.zoneBlue); // right arm
    _fillBlock(canvas, cell, 9, 7, 5, 1, AppColors.zoneRed); // bottom arm
    _fillBlock(canvas, cell, 7, 1, 1, 5, AppColors.zoneGreen); // left arm

    // Starting squares.
    _fillBlock(canvas, cell, 6, 1, 1, 1, AppColors.zoneGreen);
    _fillBlock(canvas, cell, 1, 8, 1, 1, AppColors.zoneYellow);
    _fillBlock(canvas, cell, 8, 13, 1, 1, AppColors.zoneBlue);
    _fillBlock(canvas, cell, 13, 6, 1, 1, AppColors.zoneRed);

    // Center home triangles.
    _drawCenterTriangles(canvas, cell);

    // Grid lines across the path/cross area only (not the solid corners).
    final Paint gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _strokeGrid(canvas, cell, 0, 6, 6, 3, gridPaint); // top arm
    _strokeGrid(canvas, cell, 9, 6, 6, 3, gridPaint); // bottom arm
    _strokeGrid(canvas, cell, 6, 0, 3, 6, gridPaint); // left arm
    _strokeGrid(canvas, cell, 6, 9, 3, 6, gridPaint); // right arm

    // Small direction arrows on the entry cell of each arm, echoing the
    // reference board's "which way to walk" hints.
    _directionArrow(canvas, cell, 1, 6, Alignment.topCenter, AppColors.textDark);
    _directionArrow(canvas, cell, 13, 8, Alignment.bottomCenter, AppColors.textDark);
    _directionArrow(canvas, cell, 6, 13, Alignment.centerRight, AppColors.textDark);
    _directionArrow(canvas, cell, 8, 1, Alignment.centerLeft, AppColors.textDark);

    // Outer border.
    canvas.drawRect(
      fullRect,
      Paint()
        ..color = AppColors.textDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _directionArrow(
    Canvas canvas,
    double cell,
    int row,
    int col,
    Alignment pointing,
    Color color,
  ) {
    final center = Offset((col + 0.5) * cell, (row + 0.5) * cell);
    final double r = cell * 0.28;
    final Offset tip = center + Offset(pointing.x * r, pointing.y * r);
    final Offset baseA = center +
        Offset(-pointing.y * r * 0.6, pointing.x * r * 0.6) -
        Offset(pointing.x * r * 0.4, pointing.y * r * 0.4);
    final Offset baseB = center +
        Offset(pointing.y * r * 0.6, -pointing.x * r * 0.6) -
        Offset(pointing.x * r * 0.4, pointing.y * r * 0.4);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseA.dx, baseA.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.55));
  }

  void _fillBlock(
    Canvas canvas,
    double cell,
    int row,
    int col,
    int rowSpan,
    int colSpan,
    Color color,
  ) {
    final Rect rect = Rect.fromLTWH(
      col * cell,
      row * cell,
      colSpan * cell,
      rowSpan * cell,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _strokeGrid(
    Canvas canvas,
    double cell,
    int row,
    int col,
    int rowSpan,
    int colSpan,
    Paint paint,
  ) {
    for (int r = 0; r <= rowSpan; r++) {
      final double y = (row + r) * cell;
      canvas.drawLine(
        Offset(col * cell, y),
        Offset((col + colSpan) * cell, y),
        paint,
      );
    }
    for (int c = 0; c <= colSpan; c++) {
      final double x = (col + c) * cell;
      canvas.drawLine(
        Offset(x, row * cell),
        Offset(x, (row + rowSpan) * cell),
        paint,
      );
    }
  }

  void _drawCenterTriangles(Canvas canvas, double cell) {
    final double left = 6 * cell;
    final double top = 6 * cell;
    final double mid = left + 1.5 * cell;
    final double midY = top + 1.5 * cell;
    final double right = 9 * cell;
    final double bottom = 9 * cell;

    final Offset topLeft = Offset(left, top);
    final Offset topRight = Offset(right, top);
    final Offset bottomLeft = Offset(left, bottom);
    final Offset bottomRight = Offset(right, bottom);
    final Offset center = Offset(mid, midY);

    void tri(Offset a, Offset b, Color color) {
      final Path path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Each triangle matches the color of the home-stretch arm feeding it.
    tri(topLeft, topRight, AppColors.zoneYellow); // top triangle
    tri(topRight, bottomRight, AppColors.zoneBlue); // right triangle
    tri(bottomRight, bottomLeft, AppColors.zoneRed); // bottom triangle
    tri(bottomLeft, topLeft, AppColors.zoneGreen); // left triangle
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
