import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/game_result.dart';
import '../../../services/auth_service.dart';
import '../../../services/leaderboard_service.dart';
import 'rubik_cube_widget.dart';
import 'rubik_solver_ai.dart';

enum RubikPlayPhase {
  cleanBase, // Khối sạch thuần 1 màu ở 6 mặt ban đầu
  scrambled, // Đã xáo trộn, chờ bấm Bắt đầu
  playing,   // Đang bấm giờ và chơi
  completed, // Đã hoàn thành về thuần 1 màu ở 6 mặt
}

class RubikScreen extends StatefulWidget {
  final int? duelSeed;
  final Function(int seconds, int moves)? onDuelFinish;

  const RubikScreen({super.key, this.duelSeed, this.onDuelFinish});

  @override
  State<RubikScreen> createState() => _RubikScreenState();
}

class _RubikScreenState extends State<RubikScreen> {
  final GlobalKey<RubikCubeWidgetState> _cubeKey = GlobalKey<RubikCubeWidgetState>();

  RubikPlayPhase _phase = RubikPlayPhase.cleanBase;
  Timer? _stopwatchTimer;
  int _millisecondsElapsed = 0;
  int _movesCount = 0;

  // AI Solver assistant tab
  bool _isAiHelpOpen = false;
  int _currentStepIndex = 0;
  List<SolverStep> _solverSteps = [];

  @override
  void initState() {
    super.initState();
    _solverSteps = RubikSolverAi.generateSolutionSteps([]);
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer?.cancel();
    _millisecondsElapsed = 0;
    _movesCount = 0;
    _phase = RubikPlayPhase.playing;

    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _phase == RubikPlayPhase.playing) {
        setState(() {
          _millisecondsElapsed += 100;
        });
      }
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
  }

  void _handleScramble() {
    _stopStopwatch();
    _cubeKey.currentState?.scramble();
    setState(() {
      _phase = RubikPlayPhase.scrambled;
      _millisecondsElapsed = 0;
      _movesCount = 0;
      _currentStepIndex = 0;
      _solverSteps = RubikSolverAi.generateSolutionSteps(RubikSolverAi.generateScramble());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎲 Khối Rubik đã được xáo trộn logic ngẫu nhiên! Hãy nhấn Bắt Đầu để tính giờ!'),
        backgroundColor: GoddyTheme.neonAmber,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleResetToCleanBase() {
    _stopStopwatch();
    _cubeKey.currentState?.resetCube();
    setState(() {
      _phase = RubikPlayPhase.cleanBase;
      _millisecondsElapsed = 0;
      _movesCount = 0;
      _isAiHelpOpen = false;
      _currentStepIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Đã đặt lại khối Rubik về trạng thái gốc thuần 1 màu ở 6 mặt!'),
        backgroundColor: GoddyTheme.neonCyan,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onMoveExecuted() {
    setState(() {
      _movesCount++;
    });

    // Check if player solved the cube back to pure base state
    if (_phase == RubikPlayPhase.playing) {
      final isSolved = _cubeKey.currentState?.isSolved() ?? false;
      if (isSolved) {
        _handleVictory();
      }
    }
  }

  void _handleVictory() {
    _stopStopwatch();
    setState(() {
      _phase = RubikPlayPhase.completed;
    });

    final totalSeconds = (_millisecondsElapsed / 1000).ceil();
    final auth = context.read<AuthService>();
    final leaderboard = context.read<LeaderboardService>();

    // Calculate score based strictly on seconds (less seconds = higher score & rank)
    final score = (2000 - totalSeconds * 12).clamp(100, 5000);

    final result = GameResult(
      id: 'rubik_${DateTime.now().millisecondsSinceEpoch}',
      gameType: GameType.rubik,
      score: score,
      timeSeconds: totalSeconds,
      mistakes: 0,
      isWin: true,
      difficulty: '3D Simulation Speedcube',
    );

    leaderboard.saveGameResult(result);
    auth.recordGameWin(
      isWin: true,
      expGained: (score * 0.15).toInt(),
      rubikSecs: totalSeconds,
    );

    widget.onDuelFinish?.call(totalSeconds, _movesCount);

    _showVictoryDialog(totalSeconds, score);
  }

  void _showVictoryDialog(int seconds, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GoddyTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: GoddyTheme.neonGreen, width: 2),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: GoddyTheme.neonAmber, size: 54),
              const SizedBox(height: 8),
              Text(
                'CHIẾN THẮNG VINH QUANG!',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Khối Rubik đã về lại thuần 1 màu ở cả 6 mặt!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Thời gian giải:', '${seconds}s', GoddyTheme.neonGreen, isBold: true),
            _buildStatRow('Số lượt xoay:', '$_movesCount', GoddyTheme.neonBlue),
            const Divider(color: Colors.white24, height: 20),
            _buildStatRow('Điểm Rank đạt được:', '+$score PTS', GoddyTheme.neonAmber, isBold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleResetToCleanBase();
            },
            child: const Text('Bắt Đầu Lại', style: TextStyle(color: GoddyTheme.neonCyan)),
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
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final totalSecs = _millisecondsElapsed ~/ 1000;
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    final tenths = (_millisecondsElapsed % 1000) ~/ 100;
    return '$mins:$secs.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'GIẢ LẬP RUBIK 3D',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Đặt lại khối thuần màu',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonRed),
            onPressed: _handleResetToCleanBase,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              // HUD Time & Phase Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: GoddyTheme.glowBox(
                  borderColor: _phase == RubikPlayPhase.playing ? GoddyTheme.neonGreen : GoddyTheme.neonCyan,
                  bgColor: GoddyTheme.bgCard,
                  radius: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Stopwatch Timer
                    Column(
                      children: [
                        Text(
                          _formattedTime,
                          style: GoogleFonts.orbitron(
                            color: _phase == RubikPlayPhase.playing ? GoddyTheme.neonGreen : GoddyTheme.neonAmber,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text('THỜI GIAN GIẢI (GIÂY)', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 10)),
                      ],
                    ),

                    // Moves Count
                    Column(
                      children: [
                        Text(
                          '$_movesCount',
                          style: GoogleFonts.orbitron(
                            color: GoddyTheme.neonBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('SỐ LƯỢT XOAY', style: TextStyle(color: GoddyTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Action Buttons: Xáo Trộn / Bắt Đầu / Bắt Đầu Lại
              _buildControlActionButtons(),

              const SizedBox(height: 10),

              // 3D Rubik Interactive Cube View
              RubikCubeWidget(
                key: _cubeKey,
                onMoveExecuted: _onMoveExecuted,
              ),

              const Text(
                'Vuốt màn hình để xoay góc nhìn 3D 360° xung quanh khối',
                style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
              ),

              const SizedBox(height: 12),

              // Real-life Rubik Rotation Buttons Panel
              _buildRealLifeRotationControls(),

              const SizedBox(height: 14),

              // AI Step-by-Step Guidance Toggle (Optional helper)
              _buildAiAssistantSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlActionButtons() {
    if (_phase == RubikPlayPhase.cleanBase) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: GoddyTheme.neonAmber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.shuffle, fontWeight: FontWeight.bold),
          label: Text(
            '1. XÁO TRỘN KHỐI RUBIK',
            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: _handleScramble,
        ),
      );
    } else if (_phase == RubikPlayPhase.scrambled) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoddyTheme.neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow, size: 26),
                label: Text(
                  '2. BẮT ĐẦU TÍNH GIỜ',
                  style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _startStopwatch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GoddyTheme.neonRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleResetToCleanBase,
                child: const Text('Bắt Đầu Lại', style: TextStyle(color: GoddyTheme.neonRed, fontSize: 12)),
              ),
            ),
          ),
        ],
      );
    } else {
      // Playing or completed
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: GoddyTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GoddyTheme.neonGreen),
              ),
              child: Center(
                child: Text(
                  '⏱️ ĐANG TÍNH GIỜ... HÃY XOAY VỀ 6 MẶT ĐỒNG MÀU!',
                  style: GoogleFonts.orbitron(
                    color: GoddyTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: GoddyTheme.neonRed),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: _handleResetToCleanBase,
            child: const Text('Bắt Đầu Lại', style: TextStyle(color: GoddyTheme.neonRed, fontSize: 11)),
          ),
        ],
      );
    }
  }

  Widget _buildRealLifeRotationControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GoddyTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ĐIỀU KHIỂN XOAY Y NHƯ NGOÀI ĐỜI:',
                style: GoogleFonts.orbitron(
                  color: GoddyTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Icon(Icons.touch_app, size: 16, color: GoddyTheme.neonCyan),
            ],
          ),
          const SizedBox(height: 10),

          // Row 1: Xoay Hàng Ngang Trên (Top Row)
          _buildDirectionRow(
            title: 'Hàng Ngang Trên (Top):',
            btn1Text: '⬅️ Ngang Trái',
            btn1Move: 'U',
            btn2Text: 'Ngang Phải ➡️',
            btn2Move: "U'",
          ),
          const SizedBox(height: 8),

          // Row 2: Xoay Hàng Ngang Giữa (Middle Row)
          _buildDirectionRow(
            title: 'Hàng Ngang Giữa (Equator):',
            btn1Text: '⬅️ Ngang Trái',
            btn1Move: "E'",
            btn2Text: 'Ngang Phải ➡️',
            btn2Move: 'E',
          ),
          const SizedBox(height: 8),

          // Row 3: Xoay Hàng Ngang Dưới (Bottom Row)
          _buildDirectionRow(
            title: 'Hàng Ngang Dưới (Bottom):',
            btn1Text: '⬅️ Ngang Trái',
            btn1Move: "D'",
            btn2Text: 'Ngang Phải ➡️',
            btn2Move: 'D',
          ),
          const SizedBox(height: 8),

          // Row 4: Xoay Cột Dọc Trái (Left Column)
          _buildDirectionRow(
            title: 'Cột Dọc Trái (Left):',
            btn1Text: '⬆️ Dọc Lên',
            btn1Move: "L'",
            btn2Text: 'Dọc Xuống ⬇️',
            btn2Move: 'L',
          ),
          const SizedBox(height: 8),

          // Row 5: Xoay Cột Dọc Giữa (Middle Column)
          _buildDirectionRow(
            title: 'Cột Dọc Giữa (Middle):',
            btn1Text: '⬆️ Dọc Lên',
            btn1Move: "M'",
            btn2Text: 'Dọc Xuống ⬇️',
            btn2Move: 'M',
          ),
          const SizedBox(height: 8),

          // Row 6: Xoay Cột Dọc Phải (Right Column)
          _buildDirectionRow(
            title: 'Cột Dọc Phải (Right):',
            btn1Text: '⬆️ Dọc Lên',
            btn1Move: 'R',
            btn2Text: 'Dọc Xuống ⬇️',
            btn2Move: "R'",
          ),
          const SizedBox(height: 8),

          // Row 7: Xoay Mặt Trước (Front Face)
          _buildDirectionRow(
            title: 'Mặt Trước (Front):',
            btn1Text: '🔄 Xoay Thuận',
            btn1Move: 'F',
            btn2Text: '↩️ Xoay Nghịch',
            btn2Move: "F'",
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionRow({
    required String title,
    required String btn1Text,
    required String btn1Move,
    required String btn2Text,
    required String btn2Move,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: GoddyTheme.neonCyan,
                        padding: EdgeInsets.zero,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      onPressed: () => _cubeKey.currentState?.executeMove(btn1Move),
                      child: Text(
                        btn1Text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: GoddyTheme.neonCyan,
                        padding: EdgeInsets.zero,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      onPressed: () => _cubeKey.currentState?.executeMove(btn2Move),
                      child: Text(
                        btn2Text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantSection() {
    return Container(
      decoration: BoxDecoration(
        color: GoddyTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.smart_toy_outlined, color: GoddyTheme.neonMagenta),
            title: const Text(
              'GỢI Ý TỪNG BƯỚC AI (NẾU BỊ BÍ)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            trailing: Icon(
              _isAiHelpOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: GoddyTheme.neonMagenta,
            ),
            onTap: () => setState(() => _isAiHelpOpen = !_isAiHelpOpen),
          ),
          if (_isAiHelpOpen) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStepIndex < _solverSteps.length
                        ? _solverSteps[_currentStepIndex].stageName
                        : 'Đã hoàn tất tất cả hướng dẫn!',
                    style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentStepIndex < _solverSteps.length
                        ? _solverSteps[_currentStepIndex].descriptionVi
                        : '',
                    style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonMagenta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('Thực hiện bước này', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        if (_currentStepIndex < _solverSteps.length) {
                          final step = _solverSteps[_currentStepIndex];
                          if (step.algorithm.isNotEmpty) {
                            _cubeKey.currentState?.executeMove(step.algorithm[0]);
                          }
                          setState(() {
                            _currentStepIndex++;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
