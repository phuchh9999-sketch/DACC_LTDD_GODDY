import 'dart:math';

class PuzzleSolverAStar {
  // Manhattan Distance Heuristic for NxN puzzle
  static int calculateManhattan(List<int> board, int size) {
    int distance = 0;
    for (int i = 0; i < board.length; i++) {
      final val = board[i];
      if (val != 0) {
        final targetIndex = val - 1;
        final targetR = targetIndex ~/ size;
        final targetC = targetIndex % size;
        final currentR = i ~/ size;
        final currentC = i % size;
        distance += (currentR - targetR).abs() + (currentC - targetC).abs();
      }
    }
    return distance;
  }

  // Find the next best move index to slide into empty cell
  static int findNextBestMove(List<int> board, int size) {
    final emptyIndex = board.indexOf(0);
    final emptyR = emptyIndex ~/ size;
    final emptyC = emptyIndex % size;

    final candidates = <int>[];
    // Check up, down, left, right adjacent to empty slot
    if (emptyR > 0) candidates.add((emptyR - 1) * size + emptyC);
    if (emptyR < size - 1) candidates.add((emptyR + 1) * size + emptyC);
    if (emptyC > 0) candidates.add(emptyR * size + (emptyC - 1));
    if (emptyC < size - 1) candidates.add(emptyR * size + (emptyC + 1));

    int bestCandidate = candidates.first;
    int minDistance = 999999;

    for (final candidate in candidates) {
      // Simulate swap
      final tempBoard = List<int>.from(board);
      tempBoard[emptyIndex] = tempBoard[candidate];
      tempBoard[candidate] = 0;

      final dist = calculateManhattan(tempBoard, size);
      if (dist < minDistance) {
        minDistance = dist;
        bestCandidate = candidate;
      }
    }

    return bestCandidate;
  }

  // Generate solvable shuffled board
  static List<int> generateSolvableBoard(int size) {
    List<int> board = List.generate(size * size, (i) => (i + 1) % (size * size));
    // Make 40 random legal moves starting from solved state to guarantee solvability
    final rand = Random();
    int emptyIndex = board.indexOf(0);

    for (int step = 0; step < 35; step++) {
      final r = emptyIndex ~/ size;
      final c = emptyIndex % size;
      final candidates = <int>[];
      if (r > 0) candidates.add((r - 1) * size + c);
      if (r < size - 1) candidates.add((r + 1) * size + c);
      if (c > 0) candidates.add(r * size + (c - 1));
      if (c < size - 1) candidates.add(r * size + (c + 1));

      final pick = candidates[rand.nextInt(candidates.length)];
      board[emptyIndex] = board[pick];
      board[pick] = 0;
      emptyIndex = pick;
    }

    return board;
  }
}
