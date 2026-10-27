import 'dart:math';

class CaroMove {
  final int r;
  final int c;
  const CaroMove(this.r, this.c);
}

class CaroAiEngine {
  static const int empty = 0;
  static const int playerX = 1;
  static const int playerO = 2; // AI
  static const int frozen = -1;

  // Board evaluation constants
  static const int winScore = 1000000;
  static const int fourScore = 50000;
  static const int openThreeScore = 5000;
  static const int threeScore = 800;
  static const int openTwoScore = 200;

  // Check 5 in a row win condition
  static bool checkWin(List<List<int>> board, int size, int r, int c, int player) {
    const directions = [
      [0, 1],  // Horizontal
      [1, 0],  // Vertical
      [1, 1],  // Diagonal \
      [1, -1], // Diagonal /
    ];

    for (final dir in directions) {
      int count = 1;
      // forward
      int nr = r + dir[0];
      int nc = c + dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr += dir[0];
        nc += dir[1];
      }
      // backward
      nr = r - dir[0];
      nc = c - dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr -= dir[0];
        nc -= dir[1];
      }

      if (count >= 5) return true;
    }
    return false;
  }

  // Find optimal move for AI based on difficulty
  static CaroMove findBestMove({
    required List<List<int>> board,
    required int size,
    required String difficulty,
  }) {
    final candidateMoves = <CaroMove>[];

    // Collect moves adjacent to existing stones (radius 2)
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == empty) {
          if (_hasNeighbor(board, size, r, c)) {
            candidateMoves.add(CaroMove(r, c));
          }
        }
      }
    }

    // If board is empty, pick center
    if (candidateMoves.isEmpty) {
      return CaroMove(size ~/ 2, size ~/ 2);
    }

    if (difficulty == 'Easy') {
      final rand = Random();
      // 40% optimal, 60% random candidate
      if (rand.nextDouble() > 0.4) {
        return candidateMoves[rand.nextInt(candidateMoves.length)];
      }
    }

    // Advanced heuristic evaluation
    CaroMove bestMove = candidateMoves[0];
    int maxScore = -99999999;

    for (final move in candidateMoves) {
      // 1. Check if AI can win immediately
      board[move.r][move.c] = playerO;
      if (checkWin(board, size, move.r, move.c, playerO)) {
        board[move.r][move.c] = empty;
        return move;
      }
      board[move.r][move.c] = empty;

      // 2. Check if Human could win immediately next turn, MUST block
      board[move.r][move.c] = playerX;
      if (checkWin(board, size, move.r, move.c, playerX)) {
        board[move.r][move.c] = empty;
        return move;
      }
      board[move.r][move.c] = empty;

      // Score move heuristically (attack + defense)
      int scoreO = _evaluatePosition(board, size, move.r, move.c, playerO);
      int scoreX = _evaluatePosition(board, size, move.r, move.c, playerX);

      // Defense weight higher for grandmaster
      int totalScore = (scoreO * 1.2).toInt() + scoreX;
      if (difficulty == 'Grandmaster') {
        totalScore = (scoreO * 1.4).toInt() + (scoreX * 1.3).toInt();
      }

      if (totalScore > maxScore) {
        maxScore = totalScore;
        bestMove = move;
      }
    }

    return bestMove;
  }

  static bool _hasNeighbor(List<List<int>> board, int size, int r, int c) {
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        int nr = r + dr;
        int nc = c + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          if (board[nr][nc] == playerX || board[nr][nc] == playerO) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static int _evaluatePosition(List<List<int>> board, int size, int r, int c, int player) {
    board[r][c] = player;
    int score = 0;

    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (final dir in directions) {
      int count = 1;
      int openEnds = 0;

      // forward
      int nr = r + dir[0];
      int nc = c + dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr += dir[0];
        nc += dir[1];
      }
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == empty) {
        openEnds++;
      }

      // backward
      nr = r - dir[0];
      nc = c - dir[1];
      while (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == player) {
        count++;
        nr -= dir[0];
        nc -= dir[1];
      }
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == empty) {
        openEnds++;
      }

      if (count >= 5) {
        score += winScore;
      } else if (count == 4 && openEnds >= 1) {
        score += fourScore;
      } else if (count == 3 && openEnds == 2) {
        score += openThreeScore;
      } else if (count == 3 && openEnds == 1) {
        score += threeScore;
      } else if (count == 2 && openEnds == 2) {
        score += openTwoScore;
      }
    }

    board[r][c] = empty;
    return score;
  }
}
