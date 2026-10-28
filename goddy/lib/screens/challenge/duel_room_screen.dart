import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/challenge_room.dart';
import '../../services/challenge_service.dart';
import '../../services/auth_service.dart';
import '../games/rubik/rubik_screen.dart';
import '../games/caro/caro_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../games/slide_puzzle/slide_puzzle_screen.dart';

class DuelRoomScreen extends StatefulWidget {
  final String roomCode;

  const DuelRoomScreen({super.key, required this.roomCode});

  @override
  State<DuelRoomScreen> createState() => _DuelRoomScreenState();
}

class _DuelRoomScreenState extends State<DuelRoomScreen> {
  bool _hasLaunchedGame = false;

  Future<void> _launchGame(BuildContext context, GameType gameType) async {
    final challenge = context.read<ChallengeService>();
    final room = challenge.currentRoom;
    final seed = room?.seed ?? 4242;

    Widget screen;
    switch (gameType) {
      case GameType.rubik:
        screen = RubikScreen(
          duelSeed: seed,
          onDuelFinish: (seconds, moves) {
            final auth = context.read<AuthService>();
            final myUser = auth.currentUser;
            if (myUser != null) {
              challenge.submitResult(
                userId: myUser.id,
                username: myUser.username,
                timeSeconds: seconds,
                mistakes: 0,
                score: (3000 - seconds * 15).clamp(100, 5000),
              );
            }
          },
        );
        break;
      case GameType.caro:
        screen = const CaroScreen();
        break;
      case GameType.sudoku:
        screen = const SudokuScreen();
        break;
      case GameType.slidePuzzle:
        screen = const SlidePuzzleScreen();
        break;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      setState(() {
        _hasLaunchedGame = false;
      });
    }
  }

  void _showFriendsInviteSheet(BuildContext context, ChallengeService challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GoddyTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final friends = challenge.friends;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MỜI BẠN BÈ THÁCH ĐẤU',
                    style: GoogleFonts.orbitron(
                      color: GoddyTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Chọn một người bạn đang online để gửi lời mời vào phòng:',
                style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ...friends.map((f) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(f.avatar, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Rank: ${f.rankTier} • Sở trường: ${f.favoriteGame}', style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoddyTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        challenge.inviteFriend(f);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã mời ${f.username} vào phòng! Chờ bạn ấy bấm SẴN SÀNG.'),
                            backgroundColor: GoddyTheme.neonCyan,
                          ),
                        );
                      },
                      child: const Text('Mời Đấu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = context.watch<ChallengeService>();
    final room = challenge.currentRoom;

    // Auto-launch match when both are ready and status changes to playing on any phone
    if (room != null && room.status == RoomStatus.playing && !_hasLaunchedGame) {
      _hasLaunchedGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchGame(context, room.gameType);
      });
    }

    if (room == null) {
      return Scaffold(
        backgroundColor: GoddyTheme.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Phòng không tồn tại hoặc đã đóng!', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          challenge.leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: GoddyTheme.bgDark,
        appBar: AppBar(
          title: Text(
            'PHÒNG TRANH TÀI: ${widget.roomCode}',
            style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: 'Sao chép mã phòng',
              icon: const Icon(Icons.copy, color: GoddyTheme.neonCyan),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã phòng!')),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Game Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: GoddyTheme.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GoddyTheme.neonCyan, width: 1),
                ),
                child: Text(
                  'MÔN THI ĐẤU: ${room.gameType.title.toUpperCase()}',
                  style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Duel Matchup Banner (Host vs Guest)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GoddyTheme.glowBox(
                  borderColor: room.bothReady ? GoddyTheme.neonGreen : GoddyTheme.neonMagenta,
                  bgColor: GoddyTheme.bgCard,
                  radius: 18,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Host Card
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: GoddyTheme.neonCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: GoddyTheme.neonCyan, width: 1.5),
                                ),
                                child: Center(child: Text(room.hostAvatar, style: const TextStyle(fontSize: 32))),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                room.hostName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('Chủ Phòng (Player 1)', style: TextStyle(color: GoddyTheme.neonCyan, fontSize: 10)),
                              const SizedBox(height: 4),
                              // Score display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ĐIỂM: ${room.hostScore}',
                                  style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Host Ready Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: room.hostReady ? GoddyTheme.neonGreen.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: room.hostReady ? GoddyTheme.neonGreen : Colors.red, width: 1),
                                ),
                                child: Text(
                                  room.hostReady ? '✅ ĐÃ SẴN SÀNG' : '⏳ CHƯA SẴN SÀNG',
                                  style: TextStyle(
                                    color: room.hostReady ? GoddyTheme.neonGreen : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: room.hostReady ? Colors.white12 : GoddyTheme.neonCyan,
                                    foregroundColor: room.hostReady ? Colors.white70 : Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () => challenge.toggleHostReady(),
                                  child: Text(
                                    room.hostReady ? 'Hủy Sẵn Sàng' : 'Bấm Sẵn Sàng',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VS Badge
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'VS',
                            style: GoogleFonts.orbitron(
                              color: GoddyTheme.neonMagenta,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: GoddyTheme.neonMagenta.withValues(alpha: 0.8), blurRadius: 10),
                              ],
                            ),
                          ),
                        ),

                        // Guest Card
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: room.isFull ? GoddyTheme.neonAmber.withValues(alpha: 0.2) : Colors.white10,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: room.isFull ? GoddyTheme.neonAmber : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(room.guestAvatar ?? '❓', style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                room.guestName ?? 'Đang chờ...',
                                style: TextStyle(
                                  color: room.isFull ? Colors.white : GoddyTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                room.isFull ? 'Đối Thủ (Player 2)' : 'Chưa vào',
                                style: TextStyle(
                                  color: room.isFull ? GoddyTheme.neonAmber : GoddyTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Score display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ĐIỂM: ${room.guestScore}',
                                  style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Guest Ready Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: room.guestReady ? GoddyTheme.neonGreen.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: room.guestReady ? GoddyTheme.neonGreen : Colors.red, width: 1),
                                ),
                                child: Text(
                                  !room.isFull
                                      ? '⏳ ĐANG CHỜ VÀO'
                                      : (room.guestReady ? '✅ ĐÃ SẴN SÀNG' : '⏳ CHƯA SẴN SÀNG'),
                                  style: TextStyle(
                                    color: room.guestReady ? GoddyTheme.neonGreen : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (room.isFull)
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: room.guestReady ? Colors.white12 : GoddyTheme.neonAmber,
                                      foregroundColor: room.guestReady ? Colors.white70 : Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () => challenge.toggleGuestReady(),
                                    child: Text(
                                      room.guestReady ? 'Hủy Sẵn Sàng' : 'Bấm Sẵn Sàng',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Ready Check Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: room.bothReady
                            ? GoddyTheme.neonGreen.withValues(alpha: 0.15)
                            : GoddyTheme.neonAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: room.bothReady ? GoddyTheme.neonGreen : GoddyTheme.neonAmber,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        room.bothReady
                            ? '🔥 CẢ 2 ĐÃ SẴN SÀNG! ĐIỂM BẮT ĐẦU Ở 0 ĐIỂM!'
                            : '⚠️ CHƯA THỂ BẮT ĐẦU: CẢ 2 NGƯỜI PHẢI BẤM "SẴN SÀNG" MỚI ĐƯỢC VÀO TRẬN!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: room.bothReady ? GoddyTheme.neonGreen : GoddyTheme.neonAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Friend Invite & Bot Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: GoddyTheme.neonCyan,
                        side: const BorderSide(color: GoddyTheme.neonCyan, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Mời Bạn Bè', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showFriendsInviteSheet(context, challenge),
                    ),
                  ),
                  if (!room.isFull) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: GoddyTheme.neonAmber,
                          side: const BorderSide(color: GoddyTheme.neonAmber, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.smart_toy, size: 16),
                        label: const Text('Triệu Hồi AI Bot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => challenge.addAiChallenger(),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Room Code & QR Code display for Host & Guest
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GoddyTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: room.roomCode,
                        version: QrVersions.auto,
                        size: 150,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quét mã QR hoặc nhập PIN: ${room.roomCode}',
                      style: const TextStyle(color: GoddyTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              if (room.status == RoomStatus.finished) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: GoddyTheme.glowBox(
                    borderColor: GoddyTheme.neonGreen,
                    bgColor: GoddyTheme.bgCard,
                    radius: 14,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, color: GoddyTheme.neonAmber, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'KẾT QUẢ TRANH TÀI',
                        style: GoogleFonts.orbitron(color: GoddyTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🏆 Người chiến thắng: ${room.winnerId == room.hostId ? room.hostName : (room.guestName ?? "Đối thủ")}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('${room.hostName}: ${room.hostResult?.timeSeconds ?? 0}s (${room.hostScore}đ)', style: const TextStyle(color: GoddyTheme.neonCyan, fontWeight: FontWeight.bold)),
                          Text('${room.guestName}: ${room.guestResult?.timeSeconds ?? 0}s (${room.guestScore}đ)', style: const TextStyle(color: GoddyTheme.neonAmber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tiêu chí: Người hoàn thành ít giây hơn hoặc điểm cao hơn sẽ chiến thắng!',
                        style: TextStyle(color: GoddyTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Start Match Button (Only enabled when BOTH are ready)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: room.bothReady ? GoddyTheme.neonGreen : Colors.white12,
                    foregroundColor: room.bothReady ? Colors.black : Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: room.bothReady ? 6 : 0,
                  ),
                  icon: Icon(
                    room.bothReady ? Icons.play_arrow : Icons.lock_clock,
                    size: 26,
                  ),
                  label: Text(
                    room.status == RoomStatus.finished
                        ? 'TÁI ĐẤU TRANH TÀI'
                        : (room.bothReady
                            ? 'BẮT ĐẦU TRANH TÀI (0 ĐIỂM)'
                            : 'CHỜ CẢ 2 SẴN SÀNG...'),
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: room.bothReady
                      ? () {
                          challenge.startMatch();
                          _launchGame(context, room.gameType);
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Trận đấu chưa thể xảy ra! Cần cả 2 người chơi cùng bấm "SẴN SÀNG"!'),
                              backgroundColor: GoddyTheme.neonRed,
                            ),
                          );
                        },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
