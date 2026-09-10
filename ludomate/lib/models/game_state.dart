import 'piece.dart';
import 'player_color.dart';

enum TurnPhase {
  awaitingRoll, // waiting for the current player to roll the dice
  awaitingSelection, // rolled — waiting for them to pick a movable piece
}

/// Why a turn was auto-passed without the player getting to move, so the UI
/// can show an appropriate one-off message before returning to normal play.
enum PassReason { noUsableMove, threeDoubles }

class GameState {
  const GameState({
    required this.pieces,
    required this.currentTurn,
    this.diceValues,
    this.remainingDice = const [],
    this.consecutiveDoubles = 0,
    this.phase = TurnPhase.awaitingRoll,
    this.winners = const [],
    this.justPassedColor,
    this.passReason,
  });

  final List<Piece> pieces; // all 16 pieces, 4 per color
  final PlayerColor currentTurn;

  /// The two dice as rolled this turn, for display (unchanged until the
  /// next roll). Null before the first roll of a turn.
  final List<int>? diceValues;

  /// Which die values are still available to spend this turn. A value is
  /// removed from here (not from [diceValues]) once used, so the UI can
  /// still show what was rolled while graying out the used one.
  final List<int> remainingDice;

  final int consecutiveDoubles;
  final TurnPhase phase;
  final List<PlayerColor> winners; // colors that finished, in order

  /// Set for exactly one state update when a turn was auto-passed without
  /// any move happening (no usable die, or three doubles in a row). The UI
  /// shows a brief explanation, then calls [GameNotifier.dismissPassNotice]
  /// to clear it. Null the rest of the time.
  final PlayerColor? justPassedColor;
  final PassReason? passReason;

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

  /// Pieces the current player could legally move with any remaining die.
  List<Piece> get movablePieces {
    if (remainingDice.isEmpty) return const [];
    return piecesOf(currentTurn)
        .where((p) => remainingDice.any((d) => p.canMove(d)))
        .toList();
  }

  /// True once all 4 of this color's pieces have reached home. Used to skip
  /// them when rotating turns so a finished player never gets asked to roll.
  bool isColorFinished(PlayerColor color) =>
      piecesOf(color).every((p) => p.isFinished);

  GameState copyWith({
    List<Piece>? pieces,
    PlayerColor? currentTurn,
    List<int>? diceValues,
    bool clearDice = false,
    List<int>? remainingDice,
    int? consecutiveDoubles,
    TurnPhase? phase,
    List<PlayerColor>? winners,
    PlayerColor? justPassedColor,
    PassReason? passReason,
    bool clearPassNotice = false,
  }) {
    return GameState(
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      diceValues: clearDice ? null : (diceValues ?? this.diceValues),
      remainingDice:
          clearDice ? const [] : (remainingDice ?? this.remainingDice),
      consecutiveDoubles: consecutiveDoubles ?? this.consecutiveDoubles,
      phase: phase ?? this.phase,
      winners: winners ?? this.winners,
      justPassedColor:
          clearPassNotice ? null : (justPassedColor ?? this.justPassedColor),
      passReason: clearPassNotice ? null : (passReason ?? this.passReason),
    );
  }
}
