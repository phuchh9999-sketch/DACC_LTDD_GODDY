import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/challenge_room.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';

class ChallengeService extends ChangeNotifier {
  static const String _syncBaseUrl = 'https://ntfy.sh';

  ChallengeRoom? _currentRoom;
  ChallengeRoom? get currentRoom => _currentRoom;

  final Map<String, ChallengeRoom> _activeRooms = {};
  final List<String> _recentRoomCodes = [];
  List<String> get recentRoomCodes => List.unmodifiable(_recentRoomCodes);

  Timer? _roomSyncTimer;
  bool _isDisposed = false;

  // Friends list
  final List<FriendModel> _friends = [
    const FriendModel(id: 'fr_1', username: 'NguyenVanA', avatar: '⚡', isOnline: true, rankTier: 'Bạch Kim', favoriteGame: 'Rubik 3D'),
    const FriendModel(id: 'fr_2', username: 'TranThiB', avatar: '👑', isOnline: true, rankTier: 'Vàng', favoriteGame: 'Quantum Caro'),
    const FriendModel(id: 'fr_3', username: 'LeHoangC', avatar: '🥷', isOnline: true, rankTier: 'Kim Cương', favoriteGame: 'Sudoku Hologram'),
    const FriendModel(id: 'fr_4', username: 'CyberGamer99', avatar: '🚀', isOnline: true, rankTier: 'Cao Thủ', favoriteGame: 'Gyro Slide Puzzle'),
  ];

  List<FriendModel> get friends => List.unmodifiable(_friends);

  @override
  void dispose() {
    _isDisposed = true;
    _roomSyncTimer?.cancel();
    super.dispose();
  }

  void addFriend(String username, {String avatar = '🎮', String rankTier = 'Đồng'}) {
    if (username.trim().isEmpty) return;
    final newFriend = FriendModel(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      avatar: avatar,
      isOnline: true,
      rankTier: rankTier,
      favoriteGame: 'Rubik 3D',
    );
    _friends.add(newFriend);
    notifyListeners();
  }

  // Generate 6-char alphanumeric room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Broadcast current room state to network channel
  Future<void> _broadcastRoom(ChallengeRoom room) async {
    try {
      final code = room.roomCode.toUpperCase();
      final url = Uri.parse('$_syncBaseUrl/goddy_room_$code');
      await http.post(
        url,
        headers: {'Title': 'DuelRoom', 'Priority': '3'},
        body: jsonEncode(room.toJson()),
      ).timeout(const Duration(seconds: 4));

      // Also announce in global room directory so other devices can discover
      if (room.status == RoomStatus.waiting || room.status == RoomStatus.ready) {
        final dirUrl = Uri.parse('$_syncBaseUrl/goddy_active_rooms');
        await http.post(
          dirUrl,
          headers: {'Title': 'ActiveRoom', 'Priority': '2'},
          body: jsonEncode({
            'code': code,
            'hostName': room.hostName,
            'hostAvatar': room.hostAvatar,
            'gameType': room.gameType.name,
            'status': room.status.name,
            'time': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Broadcast room error: $e');
    }
  }

  // Fetch remote room state from network channel
  Future<ChallengeRoom?> _fetchRemoteRoom(String roomCode) async {
    try {
      final code = roomCode.toUpperCase();
      final url = Uri.parse('$_syncBaseUrl/goddy_room_$code/json?poll=1');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        for (int i = lines.length - 1; i >= 0; i--) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          try {
            final jsonLine = jsonDecode(line);
            if (jsonLine['event'] == 'message' && jsonLine['message'] != null) {
              final map = jsonDecode(jsonLine['message']);
              return ChallengeRoom.fromJson(map);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Fetch remote room error: $e');
    }
    return null;
  }

  void _startRoomSync(String roomCode) {
    _roomSyncTimer?.cancel();
    _roomSyncTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) async {
      if (_isDisposed || _currentRoom == null || _currentRoom!.roomCode != roomCode) {
        _roomSyncTimer?.cancel();
        return;
      }

      final remote = await _fetchRemoteRoom(roomCode);
      if (remote != null && _currentRoom != null && !_isDisposed) {
        final hasChanges = remote.guestId != _currentRoom!.guestId ||
            remote.guestName != _currentRoom!.guestName ||
            remote.hostReady != _currentRoom!.hostReady ||
            remote.guestReady != _currentRoom!.guestReady ||
            remote.status != _currentRoom!.status ||
            remote.hostScore != _currentRoom!.hostScore ||
            remote.guestScore != _currentRoom!.guestScore ||
            remote.winnerId != _currentRoom!.winnerId;

        if (hasChanges) {
          _currentRoom = remote;
          _activeRooms[roomCode] = remote;
          notifyListeners();
        }
      }
    });
  }

  ChallengeRoom createRoom({
    required UserModel host,
    required GameType gameType,
    String difficulty = 'Normal',
  }) {
    final code = _generateRoomCode();
    final seed = Random().nextInt(100000);

    final room = ChallengeRoom(
      roomCode: code,
      hostId: host.id,
      hostName: host.username,
      hostAvatar: host.avatar,
      gameType: gameType,
      difficulty: difficulty,
      seed: seed,
      status: RoomStatus.waiting,
      hostReady: false,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );

    _activeRooms[code] = room;
    _currentRoom = room;
    if (!_recentRoomCodes.contains(code)) {
      _recentRoomCodes.insert(0, code);
    }
    notifyListeners();

    _broadcastRoom(room);
    _startRoomSync(code);
    return room;
  }

  Future<bool> joinRoom({
    required String roomCode,
    required UserModel guest,
  }) async {
    final code = roomCode.trim().toUpperCase();
    if (code.isEmpty) return false;

    // 1. Fetch live room from cloud network
    ChallengeRoom? existing = await _fetchRemoteRoom(code);
    existing ??= _activeRooms[code];

    if (existing != null) {
      if (existing.isFull && existing.guestId != guest.id) {
        return false; // Room full
      }

      final updated = existing.copyWith(
        guestId: guest.id,
        guestName: guest.username,
        guestAvatar: guest.avatar,
        status: RoomStatus.ready,
        guestReady: false,
        hostScore: 0,
        guestScore: 0,
      );

      _activeRooms[code] = updated;
      _currentRoom = updated;
      if (!_recentRoomCodes.contains(code)) {
        _recentRoomCodes.insert(0, code);
      }
      notifyListeners();

      await _broadcastRoom(updated);
      _startRoomSync(code);
      return true;
    }

    // 2. If room code not found anywhere on network, fallback to simulated room
    final fallbackRoom = ChallengeRoom(
      roomCode: code,
      hostId: 'host_auto',
      hostName: 'CyberRival',
      hostAvatar: '⚡',
      guestId: guest.id,
      guestName: guest.username,
      guestAvatar: guest.avatar,
      gameType: GameType.caro,
      seed: 4242,
      status: RoomStatus.ready,
      hostReady: true,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );

    _activeRooms[code] = fallbackRoom;
    _currentRoom = fallbackRoom;
    notifyListeners();
    _broadcastRoom(fallbackRoom);
    _startRoomSync(code);
    return true;
  }

  void inviteFriend(FriendModel friend) {
    if (_currentRoom == null) return;
    _currentRoom = _currentRoom!.copyWith(
      guestId: friend.id,
      guestName: friend.username,
      guestAvatar: friend.avatar,
      status: RoomStatus.ready,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void addAiChallenger() {
    if (_currentRoom == null) return;
    final botNames = ['CyberBot_Omega', 'GoddyAI_Alpha', 'ViperMatrix'];
    final botAvatars = ['🤖', '👾', '🔥'];
    final idx = Random().nextInt(botNames.length);

    _currentRoom = _currentRoom!.copyWith(
      guestId: 'bot_ai_${Random().nextInt(1000)}',
      guestName: botNames[idx],
      guestAvatar: botAvatars[idx],
      status: RoomStatus.ready,
      guestReady: false,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void toggleHostReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.hostReady;
    _currentRoom = _currentRoom!.copyWith(hostReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void toggleGuestReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.guestReady;
    _currentRoom = _currentRoom!.copyWith(guestReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  bool canStartMatch() {
    if (_currentRoom == null) return false;
    return _currentRoom!.bothReady;
  }

  void startMatch() {
    if (_currentRoom == null) return;
    if (!_currentRoom!.bothReady) return;

    _currentRoom = _currentRoom!.copyWith(
      status: RoomStatus.playing,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void submitResult({
    required String userId,
    required String username,
    required int timeSeconds,
    required int mistakes,
    required int score,
  }) {
    if (_currentRoom == null) return;

    final myResult = PlayerDuelResult(
      userId: userId,
      username: username,
      timeSeconds: timeSeconds,
      mistakes: mistakes,
      score: score,
      isCompleted: true,
    );

    if (_currentRoom!.hostId == userId) {
      final simTime = timeSeconds + Random().nextInt(15) - 5;
      final simMistakes = (mistakes + Random().nextInt(2) - 1).clamp(0, 5);
      final simScore = (score + (Random().nextBool() ? -80 : 60)).clamp(100, 3000);
      final opponentResult = PlayerDuelResult(
        userId: _currentRoom!.guestId ?? 'rival',
        username: _currentRoom!.guestName ?? 'Opponent',
        timeSeconds: simTime < 5 ? 5 : simTime,
        mistakes: simMistakes,
        score: simScore,
        isCompleted: true,
      );

      final isHostWinner = myResult.timeSeconds <= opponentResult.timeSeconds;
      _currentRoom = _currentRoom!.copyWith(
        hostResult: myResult,
        guestResult: opponentResult,
        hostScore: score,
        guestScore: simScore,
        status: RoomStatus.finished,
        winnerId: isHostWinner ? userId : _currentRoom!.guestId,
      );
    } else {
      final isGuestWinner = myResult.score >= 1000;
      _currentRoom = _currentRoom!.copyWith(
        guestResult: myResult,
        guestScore: score,
        status: RoomStatus.finished,
        winnerId: isGuestWinner ? userId : _currentRoom!.hostId,
      );
    }

    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
    _broadcastRoom(_currentRoom!);
  }

  void leaveRoom() {
    _roomSyncTimer?.cancel();
    _currentRoom = null;
    notifyListeners();
  }
}
