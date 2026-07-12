import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../providers/chat_provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _offline) setState(() => _offline = offline);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_rounded, color: context.appPrimary, size: 18),
            const SizedBox(width: 8),
            Text(s.chatTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: s.clearChat,
            onPressed: () => ref.read(chatProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'İnternet bağlantısı yok',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
            ),
          ),
          _QuickQuestions(
            s: s,
            onTap: _send,
            gameType: ref.watch(gameSessionProvider)?.gameType,
          ),
          _InputBar(
            controller: _controller,
            sending: _sending,
            hint: s.chatHint,
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
          color: isUser
              ? context.appPrimary.withValues(alpha: 0.2)
              : context.appCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? Border.all(color: context.appPrimary.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? context.appPrimary : context.appTextMain,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final AppStrings s;
  final void Function(String) onTap;
  final GameType? gameType;

  const _QuickQuestions({required this.s, required this.onTap, this.gameType});

  List<String> _questions(AppStrings s) {
    if (gameType == GameType.okey101) return s.okey101Questions;
    if (gameType == GameType.classicOkey) return s.classicOkeyQuestions;
    return s.mixedQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions(s);
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
              color: context.appCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appMuted),
            ),
            child: Center(
              child: Text(
                questions[i],
                style: TextStyle(color: context.appSubtext, fontSize: 12),
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
  final String hint;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface,
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
              maxLength: 300,
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: TextStyle(color: context.appTextMain, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: sending ? context.appMuted : context.appPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appSubtext,
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
