import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/game_enums.dart';
import '../core/config.dart';

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

  Future<String> answer(String question, GameType? activeGame) async {
    await init();

    final gameContext = activeGame == GameType.okey101
        ? 'Oyuncu şu an Okey 101 oynuyor.'
        : activeGame == GameType.classicOkey
            ? 'Oyuncu şu an Klasik Okey oynuyor.'
            : '';

    final systemPrompt = '''Sen Okeymatik uygulamasının Okey ve Okey 101 kural asistanısın.
Sadece Okey ve Okey 101 oyun kurallarıyla ilgili sorulara yanıt ver.
Yanıtlarını kısa, net ve Türkçe olarak ver. Maksimum 3-4 cümle.
$gameContext

Oyun kuralları:
${_rulesContext ?? ''}

Kural dışı sorularda sadece: "Yalnızca Okey kuralları hakkında yardımcı olabiliyorum." de.''';

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
              'temperature': 0.2,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] as String;
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
