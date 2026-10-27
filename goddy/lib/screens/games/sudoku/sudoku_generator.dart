import 'dart:math';

class SudokuBoardData {
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  SudokuBoardData({required this.puzzle, required this.solution});
}

class SudokuGenerator {
  static const int size = 9;

  static SudokuBoardData generate(String difficulty) {
    // 1. Generate full solved valid 9x9 board
    final solution = List.generate(size, (_) => List.filled(size, 0));
    _fillDiagonalBlocks(solution);
    _solveSudoku(solution);

    // 2. Clone solution and remove numbers based on difficulty
    final puzzle = List.generate(size, (r) => List<int>.from(solution[r]));

    int cluesToRemove;
    switch (difficulty) {
      case 'Easy':
        cluesToRemove = 38; // 43 remaining
        break;
      case 'Hard':
        cluesToRemove = 54; // 27 remaining
        break;
      case 'Nightmare':
        cluesToRemove = 60; // 21 remaining
        break;
      case 'Medium':
      default:
        cluesToRemove = 48; // 33 remaining
        break;
    }

    final rand = Random();
    int removed = 0;
    while (removed < cluesToRemove) {
      final r = rand.nextInt(size);
      final c = rand.nextInt(size);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0;
        removed++;
      }
    }

    return SudokuBoardData(puzzle: puzzle, solution: solution);
  }

  static void _fillDiagonalBlocks(List<List<int>> board) {
    for (int i = 0; i < size; i += 3) {
      _fillBox(board, i, i);
    }
  }

  static void _fillBox(List<List<int>> board, int row, int col) {
    final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
    int idx = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        board[row + r][col + c] = numbers[idx++];
      }
    }
  }

  static bool _isValid(List<List<int>> board, int r, int c, int num) {
    // Check row & col
    for (int i = 0; i < size; i++) {
      if (board[r][i] == num) return false;
      if (board[i][c] == num) return false;
    }
    // Check 3x3 box
    final startRow = (r ~/ 3) * 3;
    final startCol = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[startRow + i][startCol + j] == num) return false;
      }
    }
    return true;
  }

  static bool _solveSudoku(List<List<int>> board) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) {
          final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (final num in numbers) {
            if (_isValid(board, r, c, num)) {
              board[r][c] = num;
              if (_solveSudoku(board)) return true;
              board[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
}
