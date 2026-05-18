import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/game_enums.dart';
import '../core/config.dart';
import 'analytics_service.dart';

class ChatService {
  String? _rulesContext;

  Future<void> init() async {
    if (_rulesContext != null) return;
    try {
      final okeyJson = await rootBundle.loadString('assets/rules/okey_rules.json');
      final okey101Json = await rootBundle.loadString('assets/rules/okey101_rules.json');
      _rulesContext = 'OKEY 101 KURALLARI:\n$okey101Json\n\nKLASİK OKEY KURALLARI:\n$okeyJson';
    } catch (_) {
      _rulesContext = '';
    }
  }

  bool isFeedback(String question) {
    final q = question.toLowerCase();
    return q.contains('önerim var') ||
        q.contains('öneri') ||
        q.contains('geri bildirim') ||
        q.contains('feedback') ||
        q.contains('şikayet') ||
        q.contains('hata var') ||
        q.contains('bug var');
  }

  String feedbackResponse() {
    return 'Geri bildiriminiz alındı, teşekkürler! Önerileriniz uygulamayı geliştirmemize yardımcı oluyor. 🙏';
  }

  Future<void> _saveFeedback(String text) async {
    if (kIsWeb || Firebase.apps.isEmpty) return;
    if (text.length > 500) return;
    try {
      await FirebaseDatabase.instance.ref('feedback').push().set({
        'text': text,
        'timestamp': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  Future<String> answer(String question, GameType? activeGame, {String language = 'tr'}) async {
    await init();

    if (isFeedback(question)) {
      await _saveFeedback(question);
      return feedbackResponse();
    }

    AnalyticsService.logHakemQueried();

    final isEn = language == 'en';

    final gameContext = isEn
        ? (activeGame == GameType.okey101
            ? 'The user is playing Okey 101. Only answer from Okey 101 rules.'
            : activeGame == GameType.classicOkey
                ? 'The user is playing Classic Okey. Only answer from Classic Okey rules.'
                : 'The user has not specified a game. Ask which one they are playing (Classic Okey or Okey 101).')
        : (activeGame == GameType.okey101
            ? 'Kullanıcı şu an Okey 101 oynuyor. Yalnızca Okey 101 kurallarından yanıt ver.'
            : activeGame == GameType.classicOkey
                ? 'Kullanıcı şu an Klasik Okey oynuyor. Yalnızca Klasik Okey kurallarından yanıt ver.'
                : 'Kullanıcı hangi oyunu oynadığını belirtmedi. Hangi oyunu oynadığını sor (Klasik Okey mi, Okey 101 mi).');

    final systemPrompt = isEn ? '''You are the Okey rules referee for the Okeymatik app. Only provide verified rule information.

RULES:
1. Only respond based on the rule database below.
2. Do not speculate on anything not found in the database.
3. If no information found: "No clear rule found for this — play by your group's house rules."
4. Maximum 2-3 sentences. Short, clear, direct.
5. CRITICAL: Respond ONLY in English. The rule database may be in Turkish — translate to English. Never use Turkish words.
6. For non-Okey questions: "I can only help with Okey rules."

$gameContext

RULE DATABASE:
${_rulesContext ?? ''}''' : '''Sen Okeymatik uygulamasının Okey kural hakemisin. Görevin yalnızca doğrulanmış kural bilgisi vermek.

KURALLAR:
1. Sadece aşağıdaki kural veritabanındaki bilgilere dayanarak yanıt ver.
2. Veritabanında karşılığı olmayan hiçbir konuda tahmin yürütme.
3. Bilgi bulamazsan: "Bu kural için net bilgi bulunamadı, grubunuzun kurallarına göre oynayın." de.
4. Maksimum 2-3 cümle. Kısa, net, doğrudan.
5. Türkçe yanıt ver.
6. Okey kuralları dışındaki sorulara: "Yalnızca Okey kuralları hakkında yardımcı olabiliyorum." de.

$gameContext

KURAL VERİTABANI:
${_rulesContext ?? ''}''';

    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': question},
              ],
              'temperature': 0.1,
              'max_tokens': 150,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return (choices[0]['message']['content'] as String).trim();
        }
        return 'Yanıt alınamadı. Tekrar deneyin.';
      } else if (response.statusCode == 401) {
        return 'API anahtarı geçersiz.';
      } else {
        return 'Sunucu hatası (${response.statusCode}). Tekrar deneyin.';
      }
    } catch (_) {
      return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
    }
  }
}
