import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_color.dart';
import '../providers/game_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/ludo_board.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

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

  String _nameOf(PlayerColor c) {
    final s = c.name;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LudoBoard(
                      gameState: state,
                      onDiceTap: notifier.rollDice,
                      onPieceTap: (Piece p) => notifier.selectPiece(p),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _turnBanner(state),
            const SizedBox(height: 16),
          ],
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
            color: AppColors.primary,
            onTap: () {},
          ),
          const Text(
            'LudoMate',
            style: TextStyle(
              color: AppColors.textDark,
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
    final label = state.phase == TurnPhase.awaitingRoll
        ? "$name's Turn — tap the dice"
        : "$name's Turn — tap a glowing piece";

    return _banner(label, color);
  }

  Widget _banner(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
