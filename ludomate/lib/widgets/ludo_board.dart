import 'package:flutter/material.dart';
import '../logic/grid_pos.dart';
import '../logic/ludo_path.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_color.dart';
import '../theme/app_colors.dart';
import 'ludo_board_painter.dart';

/// Responsive Ludo board that renders the real pieces from [gameState] and
/// reports taps via [onPieceTap]. Always renders as a perfect square sized
/// to the available width.
class LudoBoard extends StatelessWidget {
  const LudoBoard({
    super.key,
    required this.gameState,
    required this.onPieceTap,
    required this.onDiceTap,
  });

  final GameState gameState;
  final void Function(Piece piece) onPieceTap;
  final VoidCallback onDiceTap;

  static const int _grid = LudoPath.boardSize;

  Color _colorOf(PlayerColor c) {
    switch (c) {
      case PlayerColor.green:
        return AppColors.zoneGreen;
      case PlayerColor.yellow:
        return AppColors.zoneYellow;
      case PlayerColor.blue:
        return AppColors.zoneBlue;
      case PlayerColor.red:
        return AppColors.zoneRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;
        final double cell = boardSize / _grid;
        final movable = gameState.movablePieces.toSet();

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(boardSize, boardSize),
                painter: const LudoBoardPainter(),
              ),
              for (final piece in gameState.pieces)
                _pieceMarker(piece, cell, movable.contains(piece)),
              _diceTray(boardSize),
            ],
          ),
        );
      },
    );
  }

  Widget _pieceMarker(Piece piece, double cell, bool isMovable) {
    final GridPos pos = piece.isInYard
        ? LudoPath.yardSlot(piece.color, piece.id)
        : LudoPath.positionFor(piece.color, piece.steps)!;
    final double size = cell * 0.72;
    final double left = pos.col * cell + (cell - size) / 2;
    final double top = pos.row * cell + (cell - size) / 2;
    final color = _colorOf(piece.color);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: isMovable ? () => onPieceTap(piece) : null,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isMovable ? Colors.white : Colors.black26,
              width: isMovable ? size * 0.12 : size * 0.05,
            ),
            boxShadow: isMovable
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: size * 0.3,
                      spreadRadius: size * 0.05,
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _diceTray(double boardSize) {
    final double traySize = boardSize * 0.18;
    final roll = gameState.lastRoll;
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onDiceTap,
        child: Container(
          width: traySize,
          height: traySize,
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.circular(traySize * 0.18),
          ),
          alignment: Alignment.center,
          child: roll == null
              ? Icon(Icons.casino, color: Colors.white, size: traySize * 0.5)
              : Text(
                  '$roll',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: traySize * 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
