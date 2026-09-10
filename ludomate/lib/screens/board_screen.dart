import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_color.dart';
import '../providers/game_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/dice_readout.dart';
import '../widgets/ludo_board.dart';
import '../widgets/wood_backdrop.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  // A purely local, ephemeral hint for an invalid tap (wrong color's piece,
  // a piece that can't use the current roll, or tapping the dice again
  // before picking a piece). This never touches game state/history — it's
  // just UI feedback, cleared on its own after a beat.
  String? _hint;
  Timer? _hintTimer;

  static Color _colorOf(PlayerColor c) {
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

  static String _nameOf(PlayerColor c) {
    final s = c.name;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _showHint(String message) {
    _hintTimer?.cancel();
    setState(() => _hint = message);
    _hintTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _handleDiceTap(GameState state, GameNotifier notifier) {
    if (state.phase != TurnPhase.awaitingRoll) {
      _showHint('Pick a piece to move first');
      return;
    }
    notifier.rollDice();
  }

  void _handlePieceTap(GameState state, GameNotifier notifier, Piece piece) {
    if (piece.color != state.currentTurn) {
      _showHint('Not Your Turn');
      return;
    }
    if (!state.movablePieces.contains(piece)) {
      _showHint("That piece can't move right now");
      return;
    }
    notifier.selectPiece(piece);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // When a turn gets auto-passed (no usable move, or three doubles),
    // show a brief explanation, then clear it after a beat. This is a
    // fire-once side effect, not something to compute during build.
    ref.listen<GameState>(gameProvider, (previous, next) {
      final justStartedShowing = next.justPassedColor != null &&
          previous?.justPassedColor != next.justPassedColor;
      if (justStartedShowing) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          ref.read(gameProvider.notifier).dismissPassNotice();
        });
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkNavy, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    WoodBackdrop(
                      padding: 16,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: LudoBoard(
                          gameState: state,
                          onDiceTap: () => _handleDiceTap(state, notifier),
                          onPieceTap: (Piece p) =>
                              _handlePieceTap(state, notifier, p),
                        ),
                      ),
                    ),
                    if (state.justPassedColor != null)
                      _passToast(state.justPassedColor!, state.passReason!)
                    else if (_hint != null)
                      _passToast(null, null, overrideText: _hint),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              DiceReadout(
                diceValues: state.diceValues,
                remainingDice: state.remainingDice,
              ),
              const SizedBox(height: 4),
              _turnBanner(state),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passToast(PlayerColor? color, PassReason? reason,
      {String? overrideText}) {
    final message = overrideText ??
        (reason == PassReason.threeDoubles
            ? '${_nameOf(color!)} rolled 3 doubles in a row — turn forfeited!'
            : "${_nameOf(color!)} had no usable move — turn passes");

    return TweenAnimationBuilder<double>(
      key: ValueKey(overrideText ?? '$color-$reason'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.9 + (t * 0.1), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.toastBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundIconButton(
            icon: Icons.menu,
            color: AppColors.secondary,
            onTap: () {},
          ),
          const Text(
            'LudoMate',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          _roundIconButton(
            icon: Icons.close,
            color: AppColors.error,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _turnBanner(GameState state) {
    if (state.winners.isNotEmpty) {
      final winnerNames = state.winners.map(_nameOf).join(', ');
      return _banner('$winnerNames finished!', AppColors.success);
    }

    final color = _colorOf(state.currentTurn);
    final name = _nameOf(state.currentTurn);
    // Big, terse status first — like the reference game's "Your Turn" — with
    // a smaller instructional line underneath instead of cramming both into
    // one long sentence.
    final sub = state.phase == TurnPhase.awaitingRoll
        ? 'Tap the dice to roll'
        : 'Tap a glowing piece to move it';

    return _banner("YOUR TURN", color, sub: '$name · $sub');
  }

  Widget _banner(String text, Color color, {String? sub}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
