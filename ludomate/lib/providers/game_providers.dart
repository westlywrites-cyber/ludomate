import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/ludo_path.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_color.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier({Random? random})
      : _random = random ?? Random(),
        super(GameState.initial());

  final Random _random;

  /// Rolls the dice for the current player. Auto-passes the turn if
  /// nothing is legally movable with this roll.
  void rollDice() {
    if (state.phase != TurnPhase.awaitingRoll) return;

    final roll = _random.nextInt(6) + 1;
    final isThirdSix = roll == 6 && state.consecutiveSixes == 2;

    if (isThirdSix) {
      // Three 6s in a row: roll is voided, turn passes immediately.
      _advanceTurn();
      return;
    }

    final nextSixCount = roll == 6 ? state.consecutiveSixes + 1 : 0;
    final withRoll = state.copyWith(
      lastRoll: roll,
      consecutiveSixes: nextSixCount,
      phase: TurnPhase.awaitingSelection,
    );

    if (withRoll.movablePieces.isEmpty) {
      // Nothing can move with this roll — pass turn (a 6 still ends the
      // turn here since there was no legal move to make with it).
      state = withRoll;
      _advanceTurn();
      return;
    }

    state = withRoll;
  }

  /// Moves the given piece using the current [GameState.lastRoll].
  void selectPiece(Piece piece) {
    final roll = state.lastRoll;
    if (roll == null) return;
    if (state.phase != TurnPhase.awaitingSelection) return;
    if (!state.movablePieces.contains(piece)) return;

    final moved = piece.isInYard ? piece.exited() : piece.movedBy(roll);

    var updatedPieces = [
      for (final p in state.pieces) p == piece ? moved : p,
    ];

    // Capture check: only on the shared track, and never on a safe cell.
    if (moved.isOnSharedTrack) {
      final landedOn = LudoPath.positionFor(moved.color, moved.steps);
      final isSafe = landedOn != null && LudoPath.safeCells.contains(landedOn);
      if (!isSafe) {
        updatedPieces = [
          for (final p in updatedPieces)
            if (p.color != moved.color &&
                p.isOnSharedTrack &&
                LudoPath.positionFor(p.color, p.steps) == landedOn)
              p.sentHome()
            else
              p,
        ];
      }
    }

    final newWinners = [...state.winners];
    if (moved.isFinished && !newWinners.contains(moved.color)) {
      final allFourFinished = updatedPieces
          .where((p) => p.color == moved.color)
          .every((p) => p.isFinished);
      if (allFourFinished) newWinners.add(moved.color);
    }

    state = state.copyWith(
      pieces: updatedPieces,
      winners: newWinners,
      clearLastRoll: true,
      phase: TurnPhase.awaitingRoll,
    );

    // Rolling a 6 grants another roll for the same player; otherwise the
    // turn passes to the next color.
    if (roll == 6) {
      // consecutiveSixes was already incremented in rollDice(); just stay
      // on the same player.
      return;
    }
    _advanceTurn();
  }

  /// Passes play to the next color. Always resets the 6-streak counter,
  /// since it's only ever called when the current player is changing.
  void _advanceTurn() {
    final order = PlayerColor.values;
    final currentIndex = order.indexOf(state.currentTurn);
    final next = order[(currentIndex + 1) % order.length];
    state = state.copyWith(
      currentTurn: next,
      clearLastRoll: true,
      consecutiveSixes: 0,
      phase: TurnPhase.awaitingRoll,
    );
  }
}
