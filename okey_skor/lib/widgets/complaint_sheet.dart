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

    // Firebase (background)
    if (Firebase.apps.isNotEmpty) {
      FirebaseDatabase.instance.ref('complaints').push().set({
        'text': text,
        'timestamp': ServerValue.timestamp,
      }).catchError((_) {});
    }

    // EmailJS
    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': AppConfig.emailjsServiceId,
          'template_id': AppConfig.emailjsTemplateId,
          'user_id': AppConfig.emailjsPublicKey,
          'template_params': {'message': text},
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              // GestureDetector button — bypasses ElevatedButton web issues
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _send,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _sending
                        ? AppColors.penalty.withValues(alpha: 0.5)
                        : AppColors.penalty,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
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
            ],
          ],
        ),
      ),
    );
  }
}
