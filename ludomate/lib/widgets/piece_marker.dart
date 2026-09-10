import 'package:flutter/material.dart';
import '../logic/grid_pos.dart';
import '../logic/ludo_path.dart';
import '../models/piece.dart';

/// Renders one piece and animates it between positions.
///
/// Movement matches how the reference game actually counts squares:
/// - Exiting the yard (steps 0 -> 1) is a single hop straight onto the
///   start square. The yard isn't part of the 52-cell track, so there is
///   nothing to "count through" for that hop — it must NOT be animated as
///   a multi-step crawl.
/// - Any other forward move animates through every intermediate square
///   one at a time (steps N -> N+1 -> N+2 ...), so the piece visibly
///   walks the path instead of sliding straight to the destination.
/// - Being sent home (captured) relocates instantly — there's no path to
///   crawl backward along.
class PieceMarker extends StatefulWidget {
  const PieceMarker({
    super.key,
    required this.piece,
    required this.cell,
    required this.isMovable,
    required this.color,
    required this.onTap,
  });

  final Piece piece;
  final double cell;
  final bool isMovable;
  final Color color;
  final void Function(Piece piece) onTap;

  @override
  State<PieceMarker> createState() => _PieceMarkerState();
}

class _PieceMarkerState extends State<PieceMarker>
    with TickerProviderStateMixin {
  late int _displaySteps = widget.piece.steps;
  int _animationRun = 0;

  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isMovable) _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PieceMarker old) {
    super.didUpdateWidget(old);

    if (widget.isMovable != old.isMovable) {
      if (widget.isMovable) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.value = 0;
      }
    }

    final oldSteps = old.piece.steps;
    final newSteps = widget.piece.steps;
    if (oldSteps == newSteps) return;

    if (newSteps == 0) {
      // Captured / sent home — no path to crawl backward along.
      setState(() => _displaySteps = 0);
      return;
    }
    if (oldSteps == 0 && newSteps == 1) {
      // Leaving the yard: one direct hop onto the start square, not a
      // 6-square crawl — the yard has no path cells to step through.
      setState(() => _displaySteps = 1);
      return;
    }
    _animateThrough(oldSteps, newSteps);
  }

  Future<void> _animateThrough(int from, int to) async {
    final myRun = ++_animationRun;
    final step = to > from ? 1 : -1;
    for (int s = from + step; s != to + step; s += step) {
      await Future.delayed(const Duration(milliseconds: 170));
      if (!mounted || myRun != _animationRun) return; // superseded by a newer move
      setState(() => _displaySteps = s);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GridPos pos = _displaySteps <= 0
        ? LudoPath.yardSlot(widget.piece.color, widget.piece.id)
        : (LudoPath.positionFor(widget.piece.color, _displaySteps) ??
            LudoPath.yardSlot(widget.piece.color, widget.piece.id));

    final double size = widget.cell * 0.72;
    final double left = pos.col * widget.cell + (widget.cell - size) / 2;
    final double top = pos.row * widget.cell + (widget.cell - size) / 2;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeInOut,
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.piece),
        child: widget.isMovable
            ? AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => _body(size, glow: _glowController.value),
              )
            : _body(size, glow: 0),
      ),
    );
  }

  Widget _body(double size, {required double glow}) {
    // A bright, clearly-pulsing glow for movable pieces — a wide soft halo
    // plus a tight bright core, both breathing between `glow` 0 and 1,
    // instead of a single faint fixed-opacity shadow.
    final List<BoxShadow> shadows = widget.isMovable
        ? [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.25 + glow * 0.35),
              blurRadius: size * (0.55 + glow * 0.45),
              spreadRadius: size * (0.12 + glow * 0.16),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35 + glow * 0.35),
              blurRadius: size * 0.22,
              spreadRadius: size * 0.02,
            ),
          ]
        : const [
            BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ];

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        border: Border.all(
          color: widget.isMovable
              ? Color.lerp(Colors.white, Colors.yellowAccent, glow)!
              : Colors.black26,
          width: widget.isMovable ? size * 0.14 : size * 0.05,
        ),
        boxShadow: shadows,
      ),
    );
  }
}
