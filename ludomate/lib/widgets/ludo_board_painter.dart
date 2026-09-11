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

    // Home-stretch columns/rows leading into the center. Each lane is the
    // full 6 cells from the outer entry point (where a piece turns off the
    // shared track) through to the cell just before the center — matching
    // LudoPath's homeStretches exactly (previously these were 1 cell short
    // at the outer end, leaving a stray uncolored gap right at the turn-in
    // point).
    _fillBlock(canvas, cell, 0, 7, 6, 1, AppColors.zoneYellow); // top arm
    _fillBlock(canvas, cell, 7, 9, 1, 6, AppColors.zoneBlue); // right arm
    _fillBlock(canvas, cell, 9, 7, 6, 1, AppColors.zoneRed); // bottom arm
    _fillBlock(canvas, cell, 7, 0, 1, 6, AppColors.zoneGreen); // left arm

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

    // Direction arrows inside each color's home-stretch lane, pointing
    // toward the center — placed on the exact lane cells from LudoPath's
    // homeStretches (previously these sat one column/row outside the
    // colored lane and pointed the wrong way for two of the four arms).
    _directionArrow(canvas, cell, 2, 7, Alignment.bottomCenter, AppColors.textDark); // yellow: down
    _directionArrow(canvas, cell, 7, 11, Alignment.centerLeft, AppColors.textDark); // blue: left
    _directionArrow(canvas, cell, 11, 7, Alignment.topCenter, AppColors.textDark); // red: up
    _directionArrow(canvas, cell, 7, 2, Alignment.centerRight, AppColors.textDark); // green: right

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
    // Inset half a cell from the 3x3 block's outer edge. The block's 4
    // corner cells — (6,6), (6,8), (8,6), (8,8) — are legitimate shared-
    // track cells (each color's path pivots there on its way around the
    // board), not part of anyone's home. Drawing the triangles all the way
    // out to those corners painted over those cells, so a piece merely
    // passing through looked like it had wandered into another color's
    // finish triangle. Insetting keeps the diamond entirely within the
    // true center and leaves the pivot cells plain white.
    final double left = 6.5 * cell;
    final double top = 6.5 * cell;
    final double right = 8.5 * cell;
    final double bottom = 8.5 * cell;
    final double mid = left + (right - left) / 2;
    final double midY = top + (bottom - top) / 2;

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
