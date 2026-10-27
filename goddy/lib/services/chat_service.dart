import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ChatService extends ChangeNotifier {
  static const String _keyGlobalChat = 'goddy_global_chat_v1';

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  static const List<String> quickStickers = [
    '⚔️ Solo Caro không?',
    '🔥 Quá đỉnh!',
    '🧩 Cần gợi ý Rubik!',
    '😎 GG! Trận hay lắm!',
    '🚀 Sắp phá kỷ lục!',
    '💀 Toang rồi ông giáo ơi!',
    '⏳ Chờ tí sắp xong!',
    '🏆 Bảng vàng vẫy gọi!',
  ];

  ChatService() {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await StorageService.init();
    final raw = StorageService.getStringList(_keyGlobalChat) ?? [];
    _messages.clear();

    if (raw.isEmpty) {
      // Seed default active cyber community chat
      _messages.addAll([
        ChatMessage(
          id: 'init_1',
          senderId: 'bot_admin',
          senderName: 'GoddySystem 🤖',
          senderAvatar: '🛡️',
          text: 'Chào mừng tất cả game thủ đến với Goddy Gaming Hub! Đua top nhận danh hiệu Huyền Thoại!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        ChatMessage(
          id: 'init_2',
          senderId: 'player_viper',
          senderName: 'ViperCyber',
          senderAvatar: '⚡',
          text: 'Ai giải Rubik 3D dưới 25s không? Mình vừa lập kỷ lục 19s nè!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        ChatMessage(
          id: 'init_3',
          senderId: 'player_caro',
          senderName: 'TacticalCaro',
          senderAvatar: '🥷',
          text: 'Chế độ Quantum Caro dùng skill Đảo Cờ lật kèo phê thật sự!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
      ]);
      _saveMessages();
    } else {
      for (final item in raw) {
        try {
          _messages.add(ChatMessage.fromJson(jsonDecode(item)));
        } catch (e) {
          debugPrint('Error decoding chat message: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final raw = _messages.map((e) => jsonEncode(e.toJson())).toList();
    await StorageService.setStringList(_keyGlobalChat, raw);
  }

  Future<void> sendMessage({
    required UserModel sender,
    required String text,
    String roomId = 'global',
    bool isSticker = false,
  }) async {
    if (text.trim().isEmpty) return;

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: sender.id,
      senderName: sender.username,
      senderAvatar: sender.avatar,
      text: text.trim(),
      isSticker: isSticker,
      timestamp: DateTime.now(),
    );

    _messages.add(msg);
    await _saveMessages();
    notifyListeners();

    // Occasional simulated AI gamer reply
    if (text.contains('?') || text.contains('Solo') || text.contains('Caro')) {
      Future.delayed(const Duration(seconds: 2), () {
        _messages.add(ChatMessage(
          id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
          roomId: roomId,
          senderId: 'rival_bot_chat',
          senderName: 'QuantumGhost 👻',
          senderAvatar: '👻',
          text: 'Vào phòng thách đấu nhập mã PIN hoặc tạo phòng đi bạn ơi, mình nhận kèo ngay!',
          timestamp: DateTime.now(),
        ));
        _saveMessages();
        notifyListeners();
      });
    }
  }

  List<ChatMessage> getMessagesForRoom(String roomId) {
    return _messages.where((m) => m.roomId == roomId).toList();
  }
}
