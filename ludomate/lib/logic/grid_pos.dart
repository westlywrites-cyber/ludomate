/// A simple immutable (row, col) grid position on the 15x15 board.
class GridPos {
  const GridPos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}
