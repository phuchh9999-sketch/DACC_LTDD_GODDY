import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/challenge_service.dart';
import 'duel_room_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _pinController = TextEditingController();
  GameType _selectedGame = GameType.caro;
  final String _selectedDifficulty = 'Normal';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleCreateRoom() {
    final auth = context.read<AuthService>();
    final challenge = context.read<ChallengeService>();
    final user = auth.currentUser;

    if (user == null) return;

    final room = challenge.createRoom(
      host: user,
      gameType: _selectedGame,
      difficulty: _selectedDifficulty,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DuelRoomScreen(roomCode: room.roomCode)),
    );
  }

  void _handleJoinRoom() {
    final code = _pinController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã PIN phòng 6 ký tự!')),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final challenge = context.read<ChallengeService>();
    final user = auth.currentUser;

    if (user == null) return;

    final success = challenge.joinRoom(roomCode: code, guest: user);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DuelRoomScreen(roomCode: code.toUpperCase())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phòng thách đấu đã đầy hoặc không tồn tại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'THÁCH ĐẤU ĐỐI KHÁNG',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Duel Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: GoddyTheme.glowBox(
                borderColor: GoddyTheme.neonMagenta,
                bgColor: GoddyTheme.bgCard,
                radius: 18,
                glowOpacity: 0.2,
              ),
              child: Row(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 44)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐẤU TRƯỜNG 1v1 REAL-TIME',
                          style: GoogleFonts.orbitron(
                            color: GoddyTheme.neonMagenta,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cùng giải một đề bài / thế cờ để so tài thời gian và độ chính xác!',
                          style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Create Room
            Text(
              'TẠO PHÒNG THÁCH ĐẤU MỚI',
              style: GoogleFonts.orbitron(color: GoddyTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoddyTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn game so tài:', style: TextStyle(color: GoddyTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GameType>(
                    initialValue: _selectedGame,
                    dropdownColor: GoddyTheme.bgCard,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    items: GameType.values.map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(g.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGame = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonMagenta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        'TẠO PHÒNG & LẤY MÃ QR / PIN',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _handleCreateRoom,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Join Room with PIN
            Text(
              'THAM GIA PHÒNG ĐẤU ĐÃ CÓ',
              style: GoogleFonts.orbitron(color: GoddyTheme.neonAmber, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoddyTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _pinController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.orbitron(
                      color: GoddyTheme.neonCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'NHẬP MÃ PIN (VD: GD8899)',
                      hintStyle: TextStyle(letterSpacing: 1, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.login),
                      label: Text(
                        'VÀO PHÒNG TRANH TÀI',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _handleJoinRoom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
