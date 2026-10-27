import '../core/constants.dart';

enum RoomStatus {
  waiting,
  ready,
  playing,
  finished,
}

class PlayerDuelResult {
  final String userId;
  final String username;
  final int timeSeconds;
  final int mistakes;
  final int score;
  final bool isCompleted;

  const PlayerDuelResult({
    required this.userId,
    required this.username,
    required this.timeSeconds,
    required this.mistakes,
    required this.score,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'timeSeconds': timeSeconds,
    'mistakes': mistakes,
    'score': score,
    'isCompleted': isCompleted,
  };

  factory PlayerDuelResult.fromJson(Map<String, dynamic> json) => PlayerDuelResult(
    userId: json['userId'] as String? ?? '',
    username: json['username'] as String? ?? '',
    timeSeconds: json['timeSeconds'] as int? ?? 0,
    mistakes: json['mistakes'] as int? ?? 0,
    score: json['score'] as int? ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class ChallengeRoom {
  final String roomCode;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String? guestId;
  final String? guestName;
  final String? guestAvatar;
  final GameType gameType;
  final String difficulty;
  final int seed;
  final RoomStatus status;
  final bool hostReady;
  final bool guestReady;
  final int hostScore;
  final int guestScore;
  final PlayerDuelResult? hostResult;
  final PlayerDuelResult? guestResult;
  final String? winnerId;

  const ChallengeRoom({
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.guestId,
    this.guestName,
    this.guestAvatar,
    required this.gameType,
    this.difficulty = 'Normal',
    required this.seed,
    this.status = RoomStatus.waiting,
    this.hostReady = false,
    this.guestReady = false,
    this.hostScore = 0,
    this.guestScore = 0,
    this.hostResult,
    this.guestResult,
    this.winnerId,
  });

  bool get isFull => guestId != null;
  bool get bothReady => hostReady && guestReady && guestId != null;

  ChallengeRoom copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    String? guestId,
    String? guestName,
    String? guestAvatar,
    GameType? gameType,
    String? difficulty,
    int? seed,
    RoomStatus? status,
    bool? hostReady,
    bool? guestReady,
    int? hostScore,
    int? guestScore,
    PlayerDuelResult? hostResult,
    PlayerDuelResult? guestResult,
    String? winnerId,
  }) {
    return ChallengeRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestAvatar: guestAvatar ?? this.guestAvatar,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      seed: seed ?? this.seed,
      status: status ?? this.status,
      hostReady: hostReady ?? this.hostReady,
      guestReady: guestReady ?? this.guestReady,
      hostScore: hostScore ?? this.hostScore,
      guestScore: guestScore ?? this.guestScore,
      hostResult: hostResult ?? this.hostResult,
      guestResult: guestResult ?? this.guestResult,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}

