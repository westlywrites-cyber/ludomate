import 'dart:math';
import 'package:flutter_riverpod/legacy.dart';
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

  /// Rolls both dice for the current player. Auto-passes the turn if
  /// neither die has a legal move.
  void rollDice() {
    if (state.phase != TurnPhase.awaitingRoll) return;

    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    final isDouble = d1 == d2;
    final isThirdDouble = isDouble && state.consecutiveDoubles == 2;

    if (isThirdDouble) {
      // Three doubles in a row: roll is voided, turn passes immediately.
      _advanceTurn(reason: PassReason.threeDoubles);
      return;
    }

    final withRoll = state.copyWith(
      diceValues: [d1, d2],
      remainingDice: [d1, d2],
      consecutiveDoubles: isDouble ? state.consecutiveDoubles + 1 : 0,
      phase: TurnPhase.awaitingSelection,
    );

    if (withRoll.movablePieces.isEmpty) {
      // Neither die can be used at all — pass the turn. (No bonus roll
      // here even on a double, since nothing was actually played.) We
      // advance from `withRoll` (not `state`) so the dice still briefly
      // show the rolled values behind the "no move" notice.
      _advanceTurnFrom(withRoll, reason: PassReason.noUsableMove);
      return;
    }

    state = withRoll;
  }

  /// Clears the one-off "turn passed" notice once the UI has shown it.
  void dismissPassNotice() {
    if (state.justPassedColor == null) return;
    state = state.copyWith(clearPassNotice: true);
  }

  /// Moves the given piece using whichever remaining die makes the move
  /// legal (a piece still in its yard always needs a 6).
  void selectPiece(Piece piece) {
    if (state.phase != TurnPhase.awaitingSelection) return;
    if (!state.movablePieces.contains(piece)) return;

    final dieUsed = state.remainingDice.firstWhere(piece.canMove);
    final moved = piece.isInYard ? piece.exited() : piece.movedBy(dieUsed);

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

    final remaining = [...state.remainingDice];
    remaining.remove(dieUsed); // removes one matching occurrence

    final afterMove = state.copyWith(
      pieces: updatedPieces,
      winners: newWinners,
      remainingDice: remaining,
    );

    final stillPlayable =
        remaining.isNotEmpty && afterMove.movablePieces.isNotEmpty;

    if (stillPlayable) {
      // Same player keeps going with whatever die(s) remain.
      state = afterMove;
      return;
    }

    // This turn's dice are spent (or nothing left is movable).
    final wasDouble = state.diceValues != null &&
        state.diceValues!.length == 2 &&
        state.diceValues![0] == state.diceValues![1];

    if (wasDouble) {
      // Bonus roll for the same player; consecutiveDoubles was already
      // incremented in rollDice(), so the 3-in-a-row check stays correct.
      state = afterMove.copyWith(clearDice: true, phase: TurnPhase.awaitingRoll);
      return;
    }

    _advanceTurnFrom(afterMove);
  }

  void _advanceTurn({PassReason? reason}) =>
      _advanceTurnFrom(state, reason: reason);

  /// Passes play to the next color, always resetting the double-streak
  /// counter (only relevant to whoever is currently rolling). Skips any
  /// color that has already finished all 4 pieces — a finished player
  /// should never be asked to roll, and (now that passed turns show a
  /// notice) never has one silently "pass" for them every cycle either.
  void _advanceTurnFrom(GameState base, {PassReason? reason}) {
    final order = PlayerColor.values;
    var nextIndex = order.indexOf(base.currentTurn);
    for (var i = 0; i < order.length; i++) {
      nextIndex = (nextIndex + 1) % order.length;
      if (!base.isColorFinished(order[nextIndex])) break;
    }
    final next = order[nextIndex];
    state = base.copyWith(
      currentTurn: next,
      clearDice: true,
      consecutiveDoubles: 0,
      phase: TurnPhase.awaitingRoll,
      justPassedColor: reason != null ? base.currentTurn : null,
      passReason: reason,
      clearPassNotice: reason == null,
    );
  }
}
