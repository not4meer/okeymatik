import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_enums.dart';

class ChatService {
  List<Map<String, dynamic>>? _okeyRules;
  List<Map<String, dynamic>>? _okey101Rules;

  Future<void> init() async {
    if (_okeyRules != null) return;
    try {
      final okeyJson = await rootBundle.loadString('assets/rules/okey_rules.json');
      final okey101Json = await rootBundle.loadString('assets/rules/okey101_rules.json');
      final okeyData = jsonDecode(okeyJson) as Map<String, dynamic>;
      final okey101Data = jsonDecode(okey101Json) as Map<String, dynamic>;
      _okeyRules = List<Map<String, dynamic>>.from(okeyData['rules'] as List);
      _okey101Rules = List<Map<String, dynamic>>.from(okey101Data['rules'] as List);
    } catch (_) {
      _okeyRules = [];
      _okey101Rules = [];
    }
  }

  String answer(String question, GameType? activeGame) {
    final q = _normalize(question);

    // Detect which game the question is about (use normalized strings)
    GameType? detected = activeGame;
    if (q.contains('101') || q.contains('siler') || q.contains('acma esigi') || q.contains('el acmayan')) {
      detected = GameType.okey101;
    } else if (q.contains('gosterge') && !q.contains('101')) {
      detected = GameType.classicOkey;
    }

    final rules = detected == GameType.okey101 ? (_okey101Rules ?? []) : (_okeyRules ?? []);

    // Score each rule by keyword match count
    Map<String, dynamic>? bestRule;
    int bestScore = 0;

    for (final rule in rules) {
      final keywords = List<String>.from(rule['keywords'] as List? ?? []);
      int score = 0;
      for (final kw in keywords) {
        if (q.contains(_normalize(kw))) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestRule = rule;
      }
    }

    if (bestScore == 0) {
      // Also try the other game's rules as fallback
      final fallback = detected == GameType.okey101 ? (_okeyRules ?? []) : (_okey101Rules ?? []);
      for (final rule in fallback) {
        final keywords = List<String>.from(rule['keywords'] as List? ?? []);
        int score = 0;
        for (final kw in keywords) {
          if (q.contains(_normalize(kw))) score++;
        }
        if (score > bestScore) {
          bestScore = score;
          bestRule = rule;
        }
      }
    }

    if (bestRule == null || bestScore == 0) {
      return 'Bu soruya tam olarak cevap veremiyorum. Okey veya 101 kurallarıyla ilgili daha spesifik bir soru sorabilirsiniz.';
    }

    final gamePrefix = detected == GameType.okey101 ? '🟡 Okey 101: ' : '🟢 Klasik Okey: ';
    return '$gamePrefix${bestRule['answer']}';
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('İ', 'i')
      .replaceAll('Ğ', 'g')
      .replaceAll('Ü', 'u')
      .replaceAll('Ş', 's')
      .replaceAll('Ö', 'o')
      .replaceAll('Ç', 'c');
}
