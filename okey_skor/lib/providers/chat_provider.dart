import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_enums.dart';
import '../services/chat_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

final chatServiceProvider = Provider<ChatService>((_) => ChatService());

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(chatServiceProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService _svc;

  ChatNotifier(this._svc) : super([
    ChatMessage(
      text: 'Merhaba! Okey veya Okey 101 kurallarını sorabilirsiniz. Örnek: "101\'de siler kaç puan?" veya "Okeyde çiftten bitiş kaç puan?"',
      isUser: false,
    ),
  ]) {
    _svc.init(); // preload rules on startup
  }

  Future<void> send(String question, {GameType? activeGame}) async {
    if (question.trim().isEmpty) return;

    state = [...state, ChatMessage(text: question, isUser: true)];

    final answer = await _svc.answer(question, activeGame);
    state = [...state, ChatMessage(text: answer, isUser: false)];
  }

  void clear() {
    state = [];
  }
}
