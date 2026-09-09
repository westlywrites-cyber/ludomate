import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ludo_board_painter.dart';

/// Self-contained, responsive Ludo board. Always renders as a perfect square
/// sized to the available width, so it scales correctly on any screen.
class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;
        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(boardSize, boardSize),
                painter: const LudoBoardPainter(),
              ),
              _playerMarker(
                boardSize,
                alignment: const Alignment(-0.62, -0.62),
                color: AppColors.zoneGreen,
              ),
              _playerMarker(
                boardSize,
                alignment: const Alignment(0.62, -0.62),
                color: AppColors.zoneYellow,
              ),
              _playerMarker(
                boardSize,
                alignment: const Alignment(-0.62, 0.62),
                color: AppColors.zoneRed,
              ),
              _playerMarker(
                boardSize,
                alignment: const Alignment(0.62, 0.62),
                color: AppColors.zoneBlue,
              ),
              _diceTray(boardSize),
            ],
          ),
        );
      },
    );
  }

  Widget _playerMarker(
    double boardSize, {
    required Alignment alignment,
    required Color color,
  }) {
    final double markerSize = boardSize * 0.14;
    return Align(
      alignment: alignment,
      child: Container(
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color, width: markerSize * 0.09),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Icon(Icons.person, color: color, size: markerSize * 0.55),
      ),
    );
  }

  Widget _diceTray(double boardSize) {
    final double traySize = boardSize * 0.18;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: traySize,
        height: traySize,
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.circular(traySize * 0.18),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, color: Colors.white, size: traySize * 0.32),
            SizedBox(width: traySize * 0.08),
            Icon(Icons.casino, color: Colors.white, size: traySize * 0.32),
          ],
        ),
      ),
    );
  }
}
