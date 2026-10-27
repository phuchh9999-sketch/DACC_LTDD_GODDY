class SudokuHint {
  final int row;
  final int col;
  final int number;
  final String logicReasonVi;

  SudokuHint({
    required this.row,
    required this.col,
    required this.number,
    required this.logicReasonVi,
  });
}

class SudokuSolverAi {
  static SudokuHint? findNextLogicHint(List<List<int>> currentBoard, List<List<int>> solution) {
    // 1. Look for a Naked Single: only 1 legal candidate in this cell
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0) {
          final candidates = _getCandidates(currentBoard, r, c);
          if (candidates.length == 1) {
            final num = candidates.first;
            return SudokuHint(
              row: r,
              col: c,
              number: num,
              logicReasonVi: 'Tại ô [Hàng ${r + 1}, Cột ${c + 1}]: Các số khác đã xuất hiện trong cùng hàng, cột và khối 3x3. Do đó chỉ có duy nhất số $num là hợp lệ!',
            );
          }
        }
      }
    }

    // 2. If no single candidate found, fallback to solution clue with reasoning
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (currentBoard[r][c] == 0) {
          final solNum = solution[r][c];
          return SudokuHint(
            row: r,
            col: c,
            number: solNum,
            logicReasonVi: 'Gợi ý AI nâng cao: Tại ô [Hàng ${r + 1}, Cột ${c + 1}], số chính xác là $solNum theo cấu trúc ma trận chuẩn.',
          );
        }
      }
    }
    return null;
  }

  static Set<int> _getCandidates(List<List<int>> board, int r, int c) {
    final possible = {1, 2, 3, 4, 5, 6, 7, 8, 9};

    // Eliminate row & col
    for (int i = 0; i < 9; i++) {
      possible.remove(board[r][i]);
      possible.remove(board[i][c]);
    }

    // Eliminate 3x3 block
    final boxR = (r ~/ 3) * 3;
    final boxC = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        possible.remove(board[boxR + i][boxC + j]);
      }
    }

    return possible;
  }
}
