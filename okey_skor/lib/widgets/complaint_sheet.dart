import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
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
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_sending) return;

    setState(() => _sending = true);

    // Firebase backup
    bool firebaseSaved = false;
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseDatabase.instance.ref('complaints').push().set({
          'text': text,
          'timestamp': ServerValue.timestamp,
        });
        firebaseSaved = true;
      } catch (_) {}
    }

    // EmailJS
    bool emailSent = false;
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': AppConfig.emailjsServiceId,
          'template_id': AppConfig.emailjsTemplateId,
          'user_id': AppConfig.emailjsPublicKey,
          if (AppConfig.emailjsPrivateKey.isNotEmpty)
            'accessToken': AppConfig.emailjsPrivateKey,
          'template_params': {
            'message': text,
            'to_email': 'ameerkhn86@gmail.com',
          },
        }),
      ).timeout(const Duration(seconds: 15));
      emailSent = response.statusCode == 200;
      debugPrint('EmailJS: status=${response.statusCode} body=${response.body}');
    } catch (e) {
      debugPrint('EmailJS exception: $e');
    }

    final success = firebaseSaved || emailSent;

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = success;
    });
    if (success) {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardHeight + 24),
        child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.appMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (_sent) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 52),
              const SizedBox(height: 12),
              Text(s.complaintSuccess,
                  style: TextStyle(
                      color: context.appTextMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
            ] else ...[
              Row(children: [
                const Icon(Icons.report_problem_rounded,
                    color: AppColors.penalty, size: 22),
                const SizedBox(width: 10),
                Text(s.complaintTitle,
                    style: TextStyle(
                        color: context.appTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                maxLength: 500,
                maxLines: 4,
                style: TextStyle(color: context.appTextMain, fontSize: 14),
                decoration: InputDecoration(
                  hintText: s.complaintHints.first,
                  hintStyle: TextStyle(color: context.appHint, fontSize: 14),
                  filled: true,
                  fillColor: context.appCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              // Material + InkWell iPad/iOS uyumu için
              Material(
                color: _sending
                    ? AppColors.penalty.withValues(alpha: 0.5)
                    : AppColors.penalty,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _sending ? null : _send,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(s.complaintSend,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
