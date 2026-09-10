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

  /// Two dice, side by side — matching the reference gameplay. Each shows
  /// its rolled value; a die already spent this turn is greyed out.
  Widget _diceTray(double boardSize) {
    final double traySize = boardSize * 0.28;
    final values = gameState.diceValues;

    // Figure out, left-to-right, whether each rolled die is still usable
    // (handles duplicate values like [3,3] correctly, one box at a time).
    final remainingPool = [...gameState.remainingDice];
    final activeFlags = <bool>[];
    if (values != null) {
      for (final v in values) {
        if (remainingPool.contains(v)) {
          activeFlags.add(true);
          remainingPool.remove(v);
        } else {
          activeFlags.add(false);
        }
      }
    }

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onDiceTap,
        child: SizedBox(
          width: traySize,
          height: traySize * 0.55,
          child: values == null
              ? _dieFace(traySize * 0.45, null, true)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _dieFace(traySize * 0.45, values[0], activeFlags[0]),
                    _dieFace(traySize * 0.45, values[1], activeFlags[1]),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _dieFace(double size, int? value, bool active) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.darkNavy : AppColors.darkNavy.withOpacity(0.35),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: value == null
          ? Icon(Icons.casino, color: Colors.white, size: size * 0.6)
          : Text(
              '$value',
              style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.55,
              ),
            ),
    );
  }
}
