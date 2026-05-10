import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_enums.dart';
import '../providers/settings_provider.dart';
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
  final language = ref.watch(settingsProvider).language;
  return ChatNotifier(ref.watch(chatServiceProvider), language: language);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService _svc;
  final String _language;

  ChatNotifier(this._svc, {String language = 'tr'})
      : _language = language,
        super([
          ChatMessage(
            text: language == 'en'
                ? 'Hi! You can ask about Okey or Okey 101 rules.\n\nTell me which game you\'re playing for more accurate answers.'
                : 'Merhaba! Okey veya Okey 101 kurallarını sorabilirsiniz.\n\nHangi oyunu oynadığınızı belirtirseniz daha doğru yanıt verebilirim.',
            isUser: false,
          ),
        ]) {
    _svc.init();
  }

  Future<void> send(String question, {GameType? activeGame}) async {
    if (question.trim().isEmpty) return;

    state = [...state, ChatMessage(text: question, isUser: true)];

    final answer = await _svc.answer(question, activeGame, language: _language);
    state = [...state, ChatMessage(text: answer, isUser: false)];
  }

  void clear() {
    state = [];
  }
}
