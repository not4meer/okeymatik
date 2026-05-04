import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../providers/chat_provider.dart';
import '../providers/game_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Kural Asistani'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sohbeti temizle',
            onPressed: () => ref.read(chatProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
            ),
          ),
          _QuickQuestions(
            onTap: _send,
            gameType: ref.watch(gameSessionProvider)?.gameType,
          ),
          _InputBar(
            controller: _controller,
            sending: _sending,
            onSend: () => _send(_controller.text),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);

    final session = ref.read(gameSessionProvider);
    await ref.read(chatProvider.notifier).send(text, activeGame: session?.gameType);

    setState(() => _sending = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? AppColors.primary : Colors.white,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final void Function(String) onTap;
  final GameType? gameType;
  const _QuickQuestions({required this.onTap, this.gameType});

  static const _okey101Questions = [
    '101 siler kac puan dusuruyor?',
    'El acmayan kac ceza alir?',
    'Okey atarak bitis ne olur?',
    'Islek tas cezasi nedir?',
    'Elden bitis kac ceza?',
    'Esli modda partner ceza siliyor mu?',
  ];

  static const _classicQuestions = [
    'Normal bitis kac puan?',
    'Okey ile bitis kac puan?',
    'Ciftten bitis kac puan?',
    'Gosterge nedir?',
    'Okey ve ciftten kac puan?',
    'Okey ıskat nedir?',
  ];

  static const _mixedQuestions = [
    'Normal bitis kac puan?',
    '101 siler kac duser?',
    'El acmayan kac ceza alir?',
    'Okey ile bitince ne olur?',
    'Ciftten bitis kac puan?',
    'Islek tas cezasi nedir?',
  ];

  List<String> get _questions {
    if (gameType == GameType.okey101) return _okey101Questions;
    if (gameType == GameType.classicOkey) return _classicQuestions;
    return _mixedQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(questions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Text(
                questions[i],
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Kural sorun...',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: sending ? Colors.white12 : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20, color: Colors.black),
              onPressed: sending ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
