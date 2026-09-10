import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A row of three plain-numeral chips sitting below the board:
/// [Die 1] [Total still usable] [Die 2]. This is a legibility aid on top
/// of the pip-faced dice in the tray — you can read the values here
/// without having to peer closely at the dice themselves, and the total
/// chip shows what's left to spend this turn (shrinks as dice get used,
/// blank before the first roll of a turn).
class DiceReadout extends StatelessWidget {
  const DiceReadout({
    super.key,
    required this.diceValues,
    required this.remainingDice,
  });

  final List<int>? diceValues;
  final List<int> remainingDice;

  @override
  Widget build(BuildContext context) {
    final values = diceValues;
    final pool = [...remainingDice];

    bool isUsed(int v) {
      if (pool.contains(v)) {
        pool.remove(v);
        return false;
      }
      return true;
    }

    final die1Used = values != null && isUsed(values[0]);
    final die2Used = values != null && isUsed(values[1]);
    final total = remainingDice.isEmpty
        ? null
        : remainingDice.reduce((a, b) => a + b);

    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _chip(
            value: values?[0],
            label: 'DIE 1',
            color: AppColors.zoneBlue,
            dim: die1Used,
          ),
          const SizedBox(width: 14),
          _chip(
            value: total,
            label: 'TOTAL LEFT',
            color: AppColors.secondary,
            dim: false,
            big: true,
          ),
          const SizedBox(width: 14),
          _chip(
            value: values?[1],
            label: 'DIE 2',
            color: AppColors.zoneGreen,
            dim: die2Used,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required int? value,
    required String label,
    required Color color,
    required bool dim,
    bool big = false,
  }) {
    final double d = big ? 40 : 34;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: dim
                  ? [Colors.grey.shade500, Colors.grey.shade700]
                  : [color.withValues(alpha: 0.85), color],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            value?.toString() ?? '–',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: big ? 18 : 15,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 8.5,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
