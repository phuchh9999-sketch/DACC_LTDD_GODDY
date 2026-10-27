import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import '../../../services/game_save_service.dart';
import 'caro_ai_engine.dart';

class CaroScreen extends StatefulWidget {
  const CaroScreen({super.key});

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  static const int boardSize = 11;
  late List<List<int>> _board;

  bool _isPlayerTurn = true;
  bool _isGameOver = false;
  String _difficulty = 'Medium'; // Easy, Medium, Grandmaster
  int _movesCount = 0;
  int _mistakes = 0;
  int _totalSeconds = 0;
  Timer? _gameTimer;

  // 15-second turn countdown
  int _turnSeconds = 15;
  Timer? _turnTimer;

  // Cyber Skills
  int _quantumSwapCharges = 1;
  int _empFreezeCharges = 1;
  bool _isSwapSelectingFirst = false;
  CaroMove? _swapSelectedMove;
  bool _isEmpSelecting = false;

  @override
  void initState() {
    super.initState();
    final saved = GameSaveService.getSavedCaro();
    if (saved != null) {
      _resumeSavedGame(saved);
    } else {
      _initBoard();
      _startGameTimer();
      _startTurnTimer();
    }
  }

  void _resumeSavedGame(Map<String, dynamic> saved) {
    _difficulty = saved['difficulty'] as String? ?? 'Medium';
    _board = (saved['board'] as List)
        .map((r) => (r as List).map((c) => c as int).toList())
        .toList();
    _movesCount = saved['movesCount'] as int? ?? 0;
    _mistakes = saved['mistakes'] as int? ?? 0;
    _totalSeconds = saved['totalSeconds'] as int? ?? 0;
    _quantumSwapCharges = saved['quantumSwapCharges'] as int? ?? 1;
    _empFreezeCharges = saved['empFreezeCharges'] as int? ?? 1;
    _isPlayerTurn = true;
    _isGameOver = false;
    _turnSeconds = 15;
    _isSwapSelectingFirst = false;
    _swapSelectedMove = null;
    _isEmpSelecting = false;

    _startGameTimer();
    _startTurnTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📂 Đã tự động khôi phục bàn cờ Caro trước đó!'),
          backgroundColor: GoddyTheme.neonCyan,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _autoSave() {
    if (!_isGameOver) {
      GameSaveService.saveCaroProgress(
        board: _board,
        difficulty: _difficulty,
        movesCount: _movesCount,
        mistakes: _mistakes,
        totalSeconds: _totalSeconds,
        quantumSwapCharges: _quantumSwapCharges,
        empFreezeCharges: _empFreezeCharges,
      );
    }
  }

  void _initBoard() {
    GameSaveService.clearCaroSave();
    _board = List.generate(boardSize, (_) => List.filled(boardSize, CaroAiEngine.empty));
    _isPlayerTurn = true;
    _isGameOver = false;
    _movesCount = 0;
    _mistakes = 0;
    _totalSeconds = 0;
    _turnSeconds = 15;
    _quantumSwapCharges = 1;
    _empFreezeCharges = 1;
    _isSwapSelectingFirst = false;
    _swapSelectedMove = null;
    _isEmpSelecting = false;
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() => _totalSeconds++);
        if (_totalSeconds % 5 == 0) {
          _autoSave();
        }
      }
    });
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnSeconds = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver && _isPlayerTurn) {
        if (_turnSeconds > 0) {
          setState(() => _turnSeconds--);
        } else {
          // Time expired! Incur a mistake penalty and auto-skip or make a random move
          setState(() {
            _mistakes++;
            _turnSeconds = 15;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Quá 15 giây! Bị tính 1 Lỗi phạm (Mistake)!'),
              backgroundColor: GoddyTheme.neonRed,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _handleCellTap(int r, int c) {
    if (_isGameOver || !_isPlayerTurn) return;

    // Handling EMP Freeze skill
    if (_isEmpSelecting) {
      if (_board[r][c] == CaroAiEngine.empty) {
        setState(() {
          _board[r][c] = CaroAiEngine.frozen;
          _empFreezeCharges--;
          _isEmpSelecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Đã kích hoạt EMP Freeze khóa ô!')),
        );
      }
      return;
    }

    // Handling Quantum Swap skill
    if (_isSwapSelectingFirst) {
      if (_board[r][c] == CaroAiEngine.playerX) {
        _swapSelectedMove = CaroMove(r, c);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn tiếp 1 quân O của đối thủ để hoán đổi!')),
        );
      } else if (_swapSelectedMove != null && _board[r][c] == CaroAiEngine.playerO) {
        // Perform swap
        setState(() {
          _board[_swapSelectedMove!.r][_swapSelectedMove!.c] = CaroAiEngine.playerO;
          _board[r][c] = CaroAiEngine.playerX;
          _quantumSwapCharges--;
          _isSwapSelectingFirst = false;
          _swapSelectedMove = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌀 Đã Hoán Đổi Lượng Tử thành công!')),
        );
        _checkPostMove(r, c, CaroAiEngine.playerX);
      }
      return;
    }

    // Normal move
    if (_board[r][c] != CaroAiEngine.empty) return;

    setState(() {
      _board[r][c] = CaroAiEngine.playerX;
      _movesCount++;
      _turnSeconds = 15;
    });

    _checkPostMove(r, c, CaroAiEngine.playerX);
  }

  void _checkPostMove(int r, int c, int player) {
    if (CaroAiEngine.checkWin(_board, boardSize, r, c, player)) {
      _endGame(isPlayerWin: player == CaroAiEngine.playerX);
      return;
    }

    if (player == CaroAiEngine.playerX) {
      setState(() => _isPlayerTurn = false);
      _turnTimer?.cancel();
      // AI's Turn
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _isGameOver) return;
        final aiMove = CaroAiEngine.findBestMove(
          board: _board,
          size: boardSize,
          difficulty: _difficulty,
        );
        setState(() {
          _board[aiMove.r][aiMove.c] = CaroAiEngine.playerO;
          _isPlayerTurn = true;
          _startTurnTimer();
        });

        if (CaroAiEngine.checkWin(_board, boardSize, aiMove.r, aiMove.c, CaroAiEngine.playerO)) {
          _endGame(isPlayerWin: false);
        }
      });
    }
  }

  void _endGame({required bool isPlayerWin}) {
    _isGameOver = true;
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    GameSaveService.clearCaroSave();

    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    final score = isPlayerWin
        ? leaderboard.calculateScore(
            gameType: GameType.caro,
            timeSeconds: _totalSeconds,
            mistakes: _mistakes,
            difficulty: _difficulty,
          )
        : 50;

    final result = GameResult(
      id: 'caro_${DateTime.now().millisecondsSinceEpoch}',
      gameType: GameType.caro,
      score: score,
      timeSeconds: _totalSeconds,
      mistakes: _mistakes,
      isWin: isPlayerWin,
      difficulty: 'Quantum $_difficulty',
    );

    leaderboard.saveGameResult(result);
    auth.recordGameWin(
      isWin: isPlayerWin,
      expGained: isPlayerWin ? (score * 0.2).toInt() : 30,
      caroScore: score,
    );

    _showGameOverDialog(isPlayerWin, score);
  }

  void _showGameOverDialog(bool isWin, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonRed,
            width: 2,
          ),
        ),
        title: Center(
          child: Column(
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: isWin ? GoddyTheme.neonAmber : GoddyTheme.neonRed,
                size: 54,
              ),
              const SizedBox(height: 8),
              Text(
                isWin ? 'BẠN ĐÃ THẮNG VÁN ĐẤU!' : 'AI ĐÃ CHIẾN THẮNG!',
                style: GoogleFonts.orbitron(
                  color: isWin ? GoddyTheme.neonGreen : GoddyTheme.neonRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Thời gian:', '${_totalSeconds}s', GoddyTheme.neonGreen),
            _buildStatRow('Số nước đi:', '$_movesCount', GoddyTheme.neonBlue),
            _buildStatRow('Lỗi quá giờ:', '$_mistakes', GoddyTheme.neonRed),
            _buildStatRow('Cấp độ:', _difficulty, GoddyTheme.neonPurple),
            const Divider(color: Colors.white24, height: 24),
            _buildStatRow('Điểm thưởng:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _initBoard();
                _startGameTimer();
                _startTurnTimer();
              });
            },
            child: const Text('Đấu Ván Mới', style: TextStyle(color: GoddyTheme.neonCyan)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoddyTheme.neonCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Về Menu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: GoddyTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'QUANTUM CARO',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chọn cấp độ AI',
            icon: const Icon(Icons.tune, color: GoddyTheme.neonCyan),
            onSelected: (val) {
              setState(() {
                _difficulty = val;
                _initBoard();
                _startGameTimer();
                _startTurnTimer();
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'Easy', child: Text('Tập sự (Dễ)')),
              const PopupMenuItem(value: 'Medium', child: Text('Chiến thuật gia (Vừa)')),
              const PopupMenuItem(value: 'Grandmaster', child: Text('Đại kiện tướng AI (Khó)')),
            ],
          ),
          IconButton(
            tooltip: 'Làm mới bàn cờ',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
            onPressed: () {
              setState(() {
                _initBoard();
                _startGameTimer();
                _startTurnTimer();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              // HUD Duel Players Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: GoddyTheme.glowBox(
                  borderColor: _isPlayerTurn ? GoddyTheme.neonCyan : GoddyTheme.neonMagenta,
                  bgColor: GoddyTheme.bgCard,
                  radius: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Player X
                    Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BẠN (X)', style: TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold)),
                            Text(_isPlayerTurn ? 'Đang ra chiêu...' : 'Chờ đối thủ', style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),

                    // Turn Countdown Ring
                    Column(
                      children: [
                        Text(
                          '${_turnSeconds}s',
                          style: GoogleFonts.orbitron(
                            color: _turnSeconds <= 5 ? GoddyTheme.neonRed : GoddyTheme.neonAmber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('LƯỢT ĐI', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 10)),
                      ],
                    ),

                    // AI O
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('AI (O) - $_difficulty', style: const TextStyle(color: GoddyTheme.neonMagenta, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(!_isPlayerTurn ? 'Đang suy nghĩ...' : 'Phòng thủ', style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text('🤖', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Cyber Tactical Skills Panel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _quantumSwapCharges > 0 ? GoddyTheme.neonPurple : Colors.white12,
                        ),
                        backgroundColor: _isSwapSelectingFirst ? GoddyTheme.neonPurple.withValues(alpha: 0.3) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18, color: GoddyTheme.neonPurple),
                      label: Text(
                        'Quantum Swap ($_quantumSwapCharges)',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _quantumSwapCharges > 0 && _isPlayerTurn
                          ? () {
                              setState(() {
                                _isSwapSelectingFirst = !_isSwapSelectingFirst;
                                _isEmpSelecting = false;
                              });
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _empFreezeCharges > 0 ? GoddyTheme.neonAmber : Colors.white12,
                        ),
                        backgroundColor: _isEmpSelecting ? GoddyTheme.neonAmber.withValues(alpha: 0.3) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.ac_unit, size: 18, color: GoddyTheme.neonAmber),
                      label: Text(
                        'EMP Freeze ($_empFreezeCharges)',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _empFreezeCharges > 0 && _isPlayerTurn
                          ? () {
                              setState(() {
                                _isEmpSelecting = !_isEmpSelecting;
                                _isSwapSelectingFirst = false;
                              });
                            }
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Caro Interactive Grid Board
              Center(
                child: Container(
                  width: 340,
                  height: 340,
                  padding: const EdgeInsets.all(6),
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonCyan,
                    bgColor: const Color(0xFF0C1322),
                    radius: 16,
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: boardSize * boardSize,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: boardSize,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final r = index ~/ boardSize;
                      final c = index % boardSize;
                      final val = _board[r][c];

                      return InkWell(
                        onTap: () => _handleCellTap(r, c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF162035),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Center(
                            child: _buildCellContent(val),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mistakes and Total Time Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('⏱️ Tổng thời gian: ${_totalSeconds}s', style: const TextStyle(color: GoddyTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('⚠️ Lỗi vi phạm: $_mistakes', style: const TextStyle(color: GoddyTheme.neonRed, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('🎯 Nước đi: $_movesCount', style: const TextStyle(color: GoddyTheme.neonBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(int val) {
    if (val == CaroAiEngine.playerX) {
      return Text(
        'X',
        style: GoogleFonts.orbitron(
          color: GoddyTheme.neonCyan,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(color: GoddyTheme.neonCyan.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      );
    } else if (val == CaroAiEngine.playerO) {
      return Text(
        'O',
        style: GoogleFonts.orbitron(
          color: GoddyTheme.neonMagenta,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(color: GoddyTheme.neonMagenta.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      );
    } else if (val == CaroAiEngine.frozen) {
      return const Icon(Icons.lock, size: 14, color: GoddyTheme.neonAmber);
    }
    return const SizedBox();
  }
}
