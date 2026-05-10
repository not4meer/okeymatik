import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/strings.dart';
import '../core/theme.dart';

class ComplaintSheet extends StatefulWidget {
  final AppStrings s;
  const ComplaintSheet({super.key, required this.s});

  @override
  State<ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<ComplaintSheet> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  int _hintIndex = 0;
  bool _sending = false;
  bool _sent = false;
  Timer? _hintTimer;

  static const _targetEmail = 'ameerkhn86@gmail.com';

  List<String> get _hints => widget.s.complaintHints;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _ctrl.text.isEmpty) {
        setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length < 5) return;
    setState(() => _sending = true);

    // Save to Firebase
    try {
      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        await FirebaseDatabase.instance.ref('complaints').push().set({
          'text': text,
          'timestamp': ServerValue.timestamp,
        });
      }
    } catch (_) {}

    // Open email client
    try {
      final subject = Uri.encodeComponent('Okeymatik Şikayet');
      final body = Uri.encodeComponent(text);
      final uri = Uri.parse('mailto:$_targetEmail?subject=$subject&body=$body');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_sent)
            _SuccessView(message: s.complaintSuccess)
          else
            _FormView(
              s: s,
              ctrl: _ctrl,
              focusNode: _focusNode,
              hintIndex: _hintIndex,
              hints: _hints,
              sending: _sending,
              onSend: _send,
            ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String message;
  const _SuccessView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.siler.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.siler, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: context.appTextMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final AppStrings s;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final int hintIndex;
  final List<String> hints;
  final bool sending;
  final VoidCallback onSend;

  const _FormView({
    required this.s,
    required this.ctrl,
    required this.focusNode,
    required this.hintIndex,
    required this.hints,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.penalty.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.report_problem_rounded,
                  color: AppColors.penalty, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.complaintTitle,
                  style: TextStyle(
                    color: context.appTextMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  s.complaintSubtitle,
                  style: TextStyle(color: context.appHint, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: TextField(
            key: ValueKey(hintIndex),
            controller: ctrl,
            focusNode: focusNode,
            maxLength: 500,
            maxLines: 4,
            style: TextStyle(color: context.appTextMain, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: hints[hintIndex],
              hintStyle: TextStyle(color: context.appDim, fontSize: 14),
              counterStyle: TextStyle(color: context.appDim, fontSize: 11),
              filled: true,
              fillColor: context.appCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.penalty,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: sending ? null : onSend,
            child: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    s.complaintSend,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
