import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/game_enums.dart';
import '../core/config.dart';
import 'analytics_service.dart';

/// Tek bir sohbet turu — takip sorularının bağlamı için modele geri gönderilir.
class ChatTurn {
  final String text;
  final bool isUser;
  const ChatTurn(this.text, this.isUser);
}

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

  String _gameContext(GameType? activeGame, bool isEn) {
    if (isEn) {
      return switch (activeGame) {
        GameType.okey101 =>
          'The user is currently playing OKEY 101. Default to Okey 101 rules unless they ask about Classic Okey.',
        GameType.classicOkey =>
          'The user is currently playing CLASSIC OKEY. Default to Classic Okey rules unless they ask about Okey 101.',
        _ =>
          'The game is unknown. If the answer differs between the two variants, give both briefly: "In Classic Okey ... , in Okey 101 ... ".',
      };
    }
    return switch (activeGame) {
      GameType.okey101 =>
        'Kullanıcı şu an OKEY 101 oynuyor. Aksini sormadıkça Okey 101 kurallarına göre karar ver.',
      GameType.classicOkey =>
        'Kullanıcı şu an KLASİK OKEY oynuyor. Aksini sormadıkça Klasik Okey kurallarına göre karar ver.',
      _ =>
        'Hangi oyun oynandığı bilinmiyor. Cevap iki türde farklıysa ikisini de kısaca ver: "Klasik Okey\'de ... , Okey 101\'de ... ".',
    };
  }

  String _systemPrompt(GameType? activeGame, bool isEn) {
    final gameContext = _gameContext(activeGame, isEn);
    final rules = _rulesContext ?? '';

    if (isEn) {
      return '''You are "The Referee" — the Okey and Okey 101 rules arbiter inside the Okeymatik app. People open you mid-game when an argument breaks out at the table. You are decisive, specific and brief.

HOW YOU ANSWER
1. Lead with the VERDICT in one short sentence. Then at most two sentences of justification.
2. Whenever points or penalties are involved, state the number explicitly (e.g. "The penalty is 101 points.").
3. If the question is vague, state your assumption and still rule on it. Never answer with a question alone.
4. The RULE DATABASE below is your primary source. If it does not explicitly cover the situation, rule according to standard, widely accepted Okey practice and mark it with "(common practice)".
5. Only say "that is a house rule, your group decides" for things that genuinely vary table to table. Do NOT use this as an escape hatch — it must be rare.
6. Write in plain prose. No bullet lists, no markdown asterisks, no headings.
7. For anything unrelated to Okey: "I can only help with Okey rules."
8. CRITICAL: respond ONLY in English. The rule database is in Turkish — translate the concepts. Never output Turkish words.

HOW TO READ THE DATABASE
Each rule entry has "keywords" (helps you match the question to a topic) and "answer" (the authoritative ruling for that topic), plus numeric fields like "penalty", "siler" (the reward deduction) and "multiplier". Match the question to the right entry via its keywords, then convey that entry's "answer" in your own words, preserving every number exactly. Never alter or round a number. If the question touches several entries, combine them into one ruling.

$gameContext

RULE DATABASE
$rules''';
    }

    return '''Sen "Hakem"sin — Okeymatik uygulamasının Okey ve Okey 101 kural hakemi. Masada tartışma çıktığında insanlar seni açar. Kararlı, somut ve kısa konuşursun.

NASIL YANIT VERİRSİN
1. Önce KARARI tek kısa cümleyle söyle. Sonra en fazla iki cümle gerekçe.
2. Puan veya ceza geçen her soruda sayıyı net yaz (örn. "Ceza 101 puandır.").
3. Soru belirsizse varsayımını belirt ama yine de karar ver. Sadece soru sorarak geçiştirme.
4. Aşağıdaki KURAL VERİTABANI birincil kaynağındır. Veritabanı durumu açıkça kapsamıyorsa, Türkiye'de yaygın kabul görmüş standart Okey uygulamasına göre karar ver ve sonuna "(yaygın uygulama)" ekle.
5. "Bu masa kuralı, grubunuz karar verir" cevabını yalnızca gerçekten masadan masaya değişen konularda ver. Bunu kaçış kapısı olarak KULLANMA — nadir olmalı.
6. Düz cümlelerle yaz. Madde listesi, markdown yıldızı veya başlık kullanma.
7. Okey ile ilgisi olmayan sorulara: "Yalnızca Okey kuralları hakkında yardımcı olabiliyorum."
8. Türkçe yanıt ver.

VERİTABANI NASIL OKUNUR
Her kural kaydında "keywords" (sorunun hangi konuya denk geldiğini bulmana yardım eder) ve "answer" (o konudaki yetkili cevap) alanları var. Ayrıca "penalty", "siler", "multiplier" gibi sayısal alanlar bulunabilir. Soruyu keywords üzerinden doğru kayda eşle, sonra o kaydın "answer" metnindeki bilgiyi ve sayıları koruyarak kendi cümlelerinle, kısa biçimde aktar. Sayıları asla değiştirme veya yuvarlama. Soru birden fazla kaydı ilgilendiriyorsa ikisini birleştirip tek karar ver.

$gameContext

KURAL VERİTABANI
$rules''';
  }

  static final _endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent');

  Future<http.Response> _post(String body) {
    return http
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConfig.geminiApiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 25));
  }

  Future<String> answer(
    String question,
    GameType? activeGame, {
    String language = 'tr',
    List<ChatTurn> history = const [],
  }) async {
    await init();

    if (isFeedback(question)) {
      await _saveFeedback(question);
      return feedbackResponse();
    }

    AnalyticsService.logHakemQueried();

    final isEn = language == 'en';

    // Son turlar bağlam olarak gider — "peki ya ...?" tipi takip soruları için.
    final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
    final contents = <Map<String, dynamic>>[
      for (final turn in recent)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    try {
      final body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt(activeGame, isEn)},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.3,
          'topP': 0.95,
          'maxOutputTokens': 800,
          // gemini-2.5-flash bir "thinking" modeli. Bütçe kapatılmazsa
          // düşünme token'ları maxOutputTokens'ı tüketir ve metin boş
          // döner — Hakem'in boş/kesik yanıt vermesinin asıl nedeni buydu.
          'thinkingConfig': {'thinkingBudget': 0},
        },
      });

      var response = await _post(body);

      // Kota dar (ücretsiz katman dakikada 5 istek) — eşzamanlı
      // kullanıcılar çakıştığında bir kez geri çekilip tekrar dene.
      if (response.statusCode == 429) {
        await Future<void>.delayed(const Duration(seconds: 3));
        response = await _post(body);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Güvenlik filtresi tüm istemi blokladıysa candidates hiç gelmez.
        final blockReason =
            (data['promptFeedback'] as Map<String, dynamic>?)?['blockReason'];
        if (blockReason != null) {
          return isEn
              ? 'I could not answer that one. Try rephrasing the question.'
              : 'Bu soruya yanıt veremedim. Soruyu biraz farklı sorabilir misiniz?';
        }

        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          return isEn ? 'Response empty. Please try again.' : 'Yanıt alınamadı. Tekrar deneyin.';
        }

        final candidate = candidates.first as Map<String, dynamic>;
        final parts = (candidate['content'] as Map<String, dynamic>?)?['parts'] as List?;
        final text = parts
            ?.map((p) => (p as Map<String, dynamic>)['text'] as String?)
            .whereType<String>()
            .join()
            .trim();

        if (text != null && text.isNotEmpty) return text;

        // Metin yok: nedenini ayırt et, sessizce "yanıt alınamadı" deme.
        final finish = candidate['finishReason'] as String?;
        if (finish == 'MAX_TOKENS') {
          return isEn
              ? 'The answer got cut off. Try asking a narrower question.'
              : 'Yanıt çok uzadığı için kesildi. Soruyu biraz daraltıp tekrar sorun.';
        }
        if (finish == 'SAFETY' || finish == 'PROHIBITED_CONTENT') {
          return isEn
              ? 'I could not answer that one. Try rephrasing the question.'
              : 'Bu soruya yanıt veremedim. Soruyu biraz farklı sorabilir misiniz?';
        }
        return isEn ? 'Response empty. Please try again.' : 'Yanıt alınamadı. Tekrar deneyin.';
      } else if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        return isEn ? 'API key invalid.' : 'API anahtarı geçersiz.';
      } else if (response.statusCode == 429) {
        return isEn ? 'Too many requests. Try again later.' : 'Çok fazla istek. Biraz sonra tekrar deneyin.';
      } else if (response.statusCode >= 500) {
        return isEn
            ? 'The rules service is busy. Try again in a moment.'
            : 'Kural servisi şu an yoğun. Birazdan tekrar deneyin.';
      } else {
        return isEn
            ? 'Server error (${response.statusCode}). Try again.'
            : 'Sunucu hatası (${response.statusCode}). Tekrar deneyin.';
      }
    } catch (_) {
      return isEn ? 'Connection error. Check your internet.' : 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
    }
  }
}
