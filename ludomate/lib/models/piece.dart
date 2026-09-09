import 'player_color.dart';

/// One of a player's 4 tokens. [steps] is the single source of truth for
/// where it is:
///   0        -> still in the yard, not yet exited
///   1 - 51   -> on the shared 52-cell track
///   52 - 57  -> in this color's private home stretch (57 = finished)
class Piece {
  const Piece({
    required this.color,
    required this.id,
    this.steps = 0,
  });

  final PlayerColor color;
  final int id; // 0-3, which of this color's 4 tokens
  final int steps;

  bool get isInYard => steps == 0;
  bool get isFinished => steps >= 57;
  bool get isOnSharedTrack => steps >= 1 && steps <= 51;
  bool get isInHomeStretch => steps >= 52;

  /// Whether this piece can legally move given a dice roll.
  bool canMove(int roll) {
    if (isFinished) return false;
    if (isInYard) return roll == 6;
    return steps + roll <= 57; // must not overshoot the final cell
  }

  Piece movedBy(int roll) => Piece(color: color, id: id, steps: steps + roll);

  Piece sentHome() => Piece(color: color, id: id, steps: 0);

  Piece exited() => Piece(color: color, id: id, steps: 1);

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.id == id;

  @override
  int get hashCode => Object.hash(color, id);
}
