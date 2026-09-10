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

/// A real dice tray: two chunky pip-faced dice that sit snug in a recessed
/// well at rest, and visibly tumble — rotating and jostling — while rolling
/// before bouncing to a settled stop on the final values.
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
  // Drives the overall "pop up out of the tray" lift/scale while rolling.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _pop = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: Curves.elasticOut))
      .animate(_controller);

  final Random _rand = Random();
  List<int> _display = const [1, 1];

  // Per-die tumble state: a little independent rotation + jitter so the two
  // dice don't move as a single rigid block, like real thrown dice.
  List<double> _angle = const [0, 0];
  List<Offset> _jitter = const [Offset.zero, Offset.zero];
  bool _settling = false;

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
    setState(() => _settling = false);

    var ticks = 0;
    const totalTicks = 9;
    _shuffle = Timer.periodic(const Duration(milliseconds: 65), (t) {
      ticks++;
      if (ticks >= totalTicks) {
        t.cancel();
        setState(() {
          _display = finalValues;
          _angle = const [0, 0];
          _jitter = const [Offset.zero, Offset.zero];
          _settling = true; // next change eases in, instead of snapping
        });
        return;
      }
      setState(() {
        _settling = false;
        _display = [_rand.nextInt(6) + 1, _rand.nextInt(6) + 1];
        // Wide random tumble early on, narrowing as the roll settles down.
        final progress = ticks / totalTicks;
        final wobble = (1 - progress) * 0.9 + 0.15;
        _angle = [
          (_rand.nextDouble() * 2 - 1) * wobble,
          (_rand.nextDouble() * 2 - 1) * wobble,
        ];
        final maxShift = widget.size * 0.05 * wobble;
        _jitter = [
          Offset(
            (_rand.nextDouble() * 2 - 1) * maxShift,
            (_rand.nextDouble() * 2 - 1) * maxShift,
          ),
          Offset(
            (_rand.nextDouble() * 2 - 1) * maxShift,
            (_rand.nextDouble() * 2 - 1) * maxShift,
          ),
        ];
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
    final isRolling = _shuffle?.isActive ?? false;

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

    final trayHeight = widget.size * 0.66;
    final wellInset = widget.size * 0.05;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: trayHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer tray shell.
            Container(
              width: widget.size,
              height: trayHeight,
              decoration: BoxDecoration(
                color: AppColors.trayShell,
                borderRadius: BorderRadius.circular(widget.size * 0.18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Recessed inner well, so the dice read as sitting *in* the
            // tray rather than floating on top of a flat card.
            Positioned(
              left: wellInset,
              right: wellInset,
              top: wellInset,
              bottom: wellInset,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.trayWell,
                  borderRadius: BorderRadius.circular(widget.size * 0.14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pop,
              builder: (context, child) {
                // At rest: a touch smaller (0.82x), sitting flat and low
                // in the well. Mid-roll: pops up bigger (1.0x) and lifts,
                // then settles back down with a bounce.
                final scale = 0.82 + (_pop.value * 0.18);
                final lift = sin(_pop.value * pi) * widget.size * 0.1;
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tumblingDie(values[0], active[0], _angle[0], _jitter[0]),
                  SizedBox(width: widget.size * 0.035),
                  _tumblingDie(values[1], active[1], _angle[1], _jitter[1]),
                ],
              ),
            ),
            if (!isRolling && widget.diceValues == null)
              IgnorePointer(
                child: _IdlePulse(size: widget.size),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tumblingDie(int value, bool active, double angle, Offset jitter) {
    // AnimatedSlide's offset is a fraction of the die's OWN size, not the
    // tray's — dividing by the die's edge length (not widget.size) is what
    // makes the jitter magnitude computed in _playRoll actually visible.
    final double dieEdge = widget.size * 0.42;
    return AnimatedRotation(
      turns: angle / (2 * pi),
      duration: Duration(milliseconds: _settling ? 260 : 65),
      curve: _settling ? Curves.easeOutBack : Curves.linear,
      child: AnimatedSlide(
        offset: Offset(
          jitter.dx / dieEdge,
          jitter.dy / dieEdge,
        ),
        duration: Duration(milliseconds: _settling ? 260 : 65),
        curve: _settling ? Curves.easeOutBack : Curves.linear,
        child: _die(value, active),
      ),
    );
  }

  Widget _die(int value, bool active) {
    final double s = widget.size * 0.42;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [AppColors.diceRed, AppColors.diceRedDark]
              : [
                  AppColors.diceRed.withValues(alpha: 0.35),
                  AppColors.diceRedDark.withValues(alpha: 0.35),
                ],
        ),
        borderRadius: BorderRadius.circular(s * 0.24),
        border: Border.all(
          color: Colors.white.withValues(alpha: active ? 0.85 : 0.3),
          width: s * 0.045,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.35 : 0.15),
            blurRadius: s * 0.18,
            offset: Offset(0, s * 0.08),
          ),
        ],
      ),
      padding: EdgeInsets.all(s * 0.15),
      child: _PipFace(value: value),
    );
  }
}

/// A subtle, slow breathing glow on the tray while it's waiting to be
/// tapped, so an idle board doesn't look inert.
class _IdlePulse extends StatefulWidget {
  const _IdlePulse({required this.size});
  final double size;

  @override
  State<_IdlePulse> createState() => _IdlePulseState();
}

class _IdlePulseState extends State<_IdlePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.size,
          height: widget.size * 0.66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.18),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15 + t * 0.25),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

class _PipFace extends StatelessWidget {
  const _PipFace({required this.value});
  final int value;

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
                ? const _Pip()
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.72,
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 1,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
