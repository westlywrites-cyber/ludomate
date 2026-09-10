import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Which of a 3x3 grid's 9 cells are filled for each classic dice face.
const Map<int, Set<int>> _pipLayout = {
  1: {4},
  2: {0, 8},
  3: {0, 4, 8},
  4: {0, 2, 6, 8},
  5: {0, 2, 4, 6, 8},
  6: {0, 2, 3, 5, 6, 8},
};

/// A real dice tray: two pip-faced dice that sit small and centered inside
/// a dark box at rest, and pop up larger with a quick shuffling animation
/// while rolling before settling on the final values.
class DiceTray extends StatefulWidget {
  const DiceTray({
    super.key,
    required this.diceValues,
    required this.remainingDice,
    required this.onTap,
    required this.size,
  });

  final List<int>? diceValues;
  final List<int> remainingDice;
  final VoidCallback onTap;
  final double size;

  @override
  State<DiceTray> createState() => _DiceTrayState();
}

class _DiceTrayState extends State<DiceTray>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _pop = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: Curves.elasticOut))
      .animate(_controller);

  final Random _rand = Random();
  List<int> _display = const [1, 1];
  Timer? _shuffle;

  @override
  void didUpdateWidget(covariant DiceTray old) {
    super.didUpdateWidget(old);
    final rolled = widget.diceValues != null &&
        !listEquals(widget.diceValues, old.diceValues);
    if (rolled) _playRoll(widget.diceValues!);
  }

  void _playRoll(List<int> finalValues) {
    _shuffle?.cancel();
    _controller.forward(from: 0);
    var ticks = 0;
    _shuffle = Timer.periodic(const Duration(milliseconds: 65), (t) {
      ticks++;
      if (ticks >= 8) {
        t.cancel();
        setState(() => _display = finalValues);
        return;
      }
      setState(() {
        _display = [_rand.nextInt(6) + 1, _rand.nextInt(6) + 1];
      });
    });
  }

  @override
  void dispose() {
    _shuffle?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.diceValues ?? _display;

    // Which displayed die (left-to-right) is still usable this turn —
    // handles duplicate values correctly, one box at a time.
    final pool = [...widget.remainingDice];
    final active = <bool>[];
    if (widget.diceValues == null) {
      active.addAll([true, true]);
    } else {
      for (final v in values) {
        if (pool.contains(v)) {
          active.add(true);
          pool.remove(v);
        } else {
          active.add(false);
        }
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size * 0.62,
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          borderRadius: BorderRadius.circular(widget.size * 0.16),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) {
            // At rest: small (0.55x). Mid-roll: pops up larger (1.0x) and
            // lifts slightly, then settles back down — "comes out of the
            // box only while rolling".
            final scale = 0.55 + (_pop.value * 0.45);
            final lift = sin(_pop.value * pi) * widget.size * 0.14;
            return Transform.translate(
              offset: Offset(0, -lift),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _die(values[0], active[0]),
              SizedBox(width: widget.size * 0.06),
              _die(values[1], active[1]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _die(int value, bool active) {
    final double s = widget.size * 0.36;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(s * 0.2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.7),
                  blurRadius: s * 0.25,
                  spreadRadius: s * 0.03,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(s * 0.14),
      child: _PipFace(value: value, dim: !active),
    );
  }
}

class _PipFace extends StatelessWidget {
  const _PipFace({required this.value, required this.dim});
  final int value;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final filled = _pipLayout[value] ?? const {};
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 9; i++)
          Center(
            child: filled.contains(i)
                ? _Pip(dim: dim)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.dim});
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.7,
      heightFactor: 0.7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dim ? AppColors.textDark.withOpacity(0.4) : AppColors.textDark,
        ),
      ),
    );
  }
}
