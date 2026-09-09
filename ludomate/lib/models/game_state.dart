import 'piece.dart';
import 'player_color.dart';

enum TurnPhase {
  awaitingRoll, // waiting for the current player to roll the dice
  awaitingSelection, // rolled — waiting for them to pick a movable piece
}

class GameState {
  const GameState({
    required this.pieces,
    required this.currentTurn,
    this.lastRoll,
    this.consecutiveSixes = 0,
    this.phase = TurnPhase.awaitingRoll,
    this.winners = const [],
  });

  final List<Piece> pieces; // all 16 pieces, 4 per color
  final PlayerColor currentTurn;
  final int? lastRoll;
  final int consecutiveSixes;
  final TurnPhase phase;
  final List<PlayerColor> winners; // colors that finished, in order

  factory GameState.initial() {
    return GameState(
      pieces: [
        for (final color in PlayerColor.values)
          for (var i = 0; i < 4; i++) Piece(color: color, id: i),
      ],
      currentTurn: PlayerColor.green,
    );
  }

  List<Piece> piecesOf(PlayerColor color) =>
      pieces.where((p) => p.color == color).toList();

  /// Pieces the current player could legally move with [lastRoll].
  List<Piece> get movablePieces {
    final roll = lastRoll;
    if (roll == null) return const [];
    return piecesOf(currentTurn).where((p) => p.canMove(roll)).toList();
  }

  GameState copyWith({
    List<Piece>? pieces,
    PlayerColor? currentTurn,
    int? lastRoll,
    bool clearLastRoll = false,
    int? consecutiveSixes,
    TurnPhase? phase,
    List<PlayerColor>? winners,
  }) {
    return GameState(
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      lastRoll: clearLastRoll ? null : (lastRoll ?? this.lastRoll),
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      phase: phase ?? this.phase,
      winners: winners ?? this.winners,
    );
  }
}
