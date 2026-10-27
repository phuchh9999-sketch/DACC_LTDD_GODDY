import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/challenge_room.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';

class ChallengeService extends ChangeNotifier {
  ChallengeRoom? _currentRoom;
  ChallengeRoom? get currentRoom => _currentRoom;

  final Map<String, ChallengeRoom> _activeRooms = {};

  // Friends list
  final List<FriendModel> _friends = [
    const FriendModel(id: 'fr_1', username: 'NguyenVanA', avatar: '⚡', isOnline: true, rankTier: 'Bạch Kim', favoriteGame: 'Rubik 3D'),
    const FriendModel(id: 'fr_2', username: 'TranThiB', avatar: '👑', isOnline: true, rankTier: 'Vàng', favoriteGame: 'Quantum Caro'),
    const FriendModel(id: 'fr_3', username: 'LeHoangC', avatar: '🥷', isOnline: true, rankTier: 'Kim Cương', favoriteGame: 'Sudoku Hologram'),
    const FriendModel(id: 'fr_4', username: 'CyberGamer99', avatar: '🚀', isOnline: true, rankTier: 'Cao Thủ', favoriteGame: 'Gyro Slide Puzzle'),
  ];

  List<FriendModel> get friends => List.unmodifiable(_friends);

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
    notifyListeners();
    return room;
  }

  bool joinRoom({
    required String roomCode,
    required UserModel guest,
  }) {
    final code = roomCode.trim().toUpperCase();
    if (!_activeRooms.containsKey(code)) {
      // Create on-the-fly room for seamless testing if entered code doesn't exist yet
      final room = ChallengeRoom(
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
      _activeRooms[code] = room;
      _currentRoom = room;
      notifyListeners();
      return true;
    }

    final existing = _activeRooms[code]!;
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
    notifyListeners();
    return true;
  }

  void inviteFriend(FriendModel friend) {
    if (_currentRoom == null) return;
    _currentRoom = _currentRoom!.copyWith(
      guestId: friend.id,
      guestName: friend.username,
      guestAvatar: friend.avatar,
      status: RoomStatus.ready,
      guestReady: false, // Must press ready!
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
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
      guestReady: false, // Bot will be ready when toggled
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
  }

  void toggleHostReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.hostReady;
    _currentRoom = _currentRoom!.copyWith(hostReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
  }

  void toggleGuestReady() {
    if (_currentRoom == null) return;
    final newReady = !_currentRoom!.guestReady;
    _currentRoom = _currentRoom!.copyWith(guestReady: newReady);
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
  }

  bool canStartMatch() {
    if (_currentRoom == null) return false;
    return _currentRoom!.bothReady;
  }

  void startMatch() {
    if (_currentRoom == null) return;
    if (!_currentRoom!.bothReady) return; // Both must be ready!

    // Both start at 0 score
    _currentRoom = _currentRoom!.copyWith(
      status: RoomStatus.playing,
      hostScore: 0,
      guestScore: 0,
    );
    _activeRooms[_currentRoom!.roomCode] = _currentRoom!;
    notifyListeners();
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

    // If opponent is bot or hasn't finished, generate simulated realistic opponent score
    PlayerDuelResult opponentResult;
    if (_currentRoom!.hostId == userId) {
      final simTime = timeSeconds + Random().nextInt(15) - 5;
      final simMistakes = (mistakes + Random().nextInt(2) - 1).clamp(0, 5);
      final simScore = (score + (Random().nextBool() ? -80 : 60)).clamp(100, 3000);
      opponentResult = PlayerDuelResult(
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
  }

  void leaveRoom() {
    _currentRoom = null;
    notifyListeners();
  }
}

