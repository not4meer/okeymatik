import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_history.dart';
import '../models/game_session.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import 'score_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.gameHistoryTitle),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: s.clearHistoryTooltip,
              onPressed: () => _confirmClear(context, ref, s),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 56, color: context.appDim),
                  const SizedBox(height: 12),
                  Text(s.noGamesYet,
                      style: TextStyle(color: context.appHint, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(s.noGamesYetSub,
                      style: TextStyle(color: context.appDim, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _HistoryCard(entry: history[i], s: s),
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(s.clearHistoryTitle,
            style: TextStyle(color: ctx.appTextMain)),
        content: Text(s.clearHistoryContent,
            style: TextStyle(color: ctx.appSubtext)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.penalty)),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) ref.read(historyProvider.notifier).clear();
    });
  }
}

class _HistoryCard extends StatefulWidget {
  final GameHistoryEntry entry;
  final AppStrings s;

  const _HistoryCard({required this.entry, required this.s});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  final _screenshotCtrl = ScreenshotController();
  bool _sharing = false;

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final sessionData = widget.entry.sessionData;
      final Widget card = sessionData != null
          ? ResultCard(session: GameSession.fromJson(sessionData))
          : _HistoryReceiptCard(entry: widget.entry);
      final bytes = await _screenshotCtrl.captureFromLongWidget(
        card,
        pixelRatio: 2.0,
        context: context,
        constraints: const BoxConstraints(maxWidth: 360),
      );
      final XFile xFile;
      if (kIsWeb) {
        xFile = XFile.fromData(bytes,
            name: 'oyun_${widget.entry.id}.png', mimeType: 'image/png');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/oyun_${widget.entry.id}.png');
        await file.writeAsBytes(bytes);
        xFile = XFile(file.path, mimeType: 'image/png');
      }
      await Share.shareXFiles([xFile], text: 'Okeymatik oyun özeti');
    } catch (_) {} finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final s = widget.s;
    final gameLabel = entry.gameType == GameType.okey101
        ? (entry.gameMode == GameMode.paired
            ? 'Okey 101 · ${s.pairedSuffix}'
            : 'Okey 101 · ${s.soloSuffix}')
        : s.classicOkey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(gameLabel,
                  style: TextStyle(
                      color: context.appSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_formatDate(entry.playedAt, s),
                  style: TextStyle(color: context.appHint, fontSize: 11)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _share,
                child: _sharing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Icon(Icons.share_rounded, size: 16, color: context.appHint),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(s.roundsPlayedText(entry.roundCount),
                  style: TextStyle(color: context.appDim, fontSize: 11)),
              if (entry.durationMinutes != null) ...[
                Text('  ·  ', style: TextStyle(color: context.appDim, fontSize: 11)),
                Text('${entry.durationMinutes} dk',
                    style: TextStyle(color: context.appDim, fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...entry.results.asMap().entries.map((e) {
            final rank = e.key + 1;
            final r = e.value;
            final color = _colors[e.key % _colors.length];
            final isWinner = rank == 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('$rank.',
                        style: TextStyle(color: context.appHint, fontSize: 12)),
                  ),
                  if (isWinner) ...[
                    Icon(Icons.emoji_events_rounded,
                        size: 14, color: context.appPrimary),
                    const SizedBox(width: 4),
                  ] else
                    const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      r.name,
                      style: TextStyle(
                        color: isWinner ? context.appPrimary : color,
                        fontSize: 13,
                        fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    r.score.toString(),
                    style: TextStyle(
                      color: r.score < 0 ? AppColors.siler : context.appSubtext,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inMinutes < 60) return s.minutesAgoText(diff.inMinutes);
    if (diff.inHours < 24) return s.hoursAgoText(diff.inHours);
    if (diff.inDays == 1) return s.yesterday;
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── History receipt card (for PNG share) ─────────────────

class _HistoryReceiptCard extends StatelessWidget {
  final GameHistoryEntry entry;
  const _HistoryReceiptCard({required this.entry});

  static const _woodA    = Color(0xFF100A04);
  static const _woodB    = Color(0xFF1E1108);
  static const _woodC    = Color(0xFF2E1A0A);
  static const _paperTop = Color(0xFFFCF6E4);
  static const _paperMid = Color(0xFFF5ECCC);
  static const _paperBot = Color(0xFFEDE0B0);
  static const _ink      = Color(0xFF1A1008);
  static const _inkMid   = Color(0xFF5A4525);
  static const _inkFaint = Color(0xFFBBAA88);
  static const _border   = Color(0xFF8B7040);
  static const _blue     = Color(0xFF1B3A6E);
  static const _red      = Color(0xFF8B0F0F);
  static const _hdrBg    = Color(0xFFEDE0B8);

  @override
  Widget build(BuildContext context) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final dt = entry.playedAt;
    final dateStr = '${pad(dt.day)}.${pad(dt.month)}.${dt.year}';
    final timeStr = '${pad(dt.hour)}:${pad(dt.minute)}';
    final gameLabel = entry.gameType == GameType.okey101
        ? (entry.gameMode == GameMode.paired ? 'Okey 101 · Eşli' : 'Okey 101')
        : 'Klasik Okey';

    return SizedBox(
      width: 360,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_woodC, _woodB, _woodA, _woodB, _woodC],
            stops: [0.0, 0.3, 0.55, 0.75, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_paperTop, _paperMid, _paperBot],
              ),
              borderRadius: BorderRadius.all(Radius.circular(1)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xBB000000),
                  blurRadius: 28,
                  spreadRadius: 3,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.035,
                      child: Text(
                        'OKEYMATİK',
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      color: _hdrBg,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.casino_rounded, color: _inkMid, size: 12),
                            const SizedBox(width: 5),
                            const Text('OKEYMATİK',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.5,
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('— $gameLabel —',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1,
                            )),
                        const SizedBox(height: 10),
                        Row(children: [
                          Text('Tarih: $dateStr',
                              style: const TextStyle(color: _inkMid, fontSize: 12)),
                          const Spacer(),
                          Text('Saat: $timeStr',
                              style: const TextStyle(color: _inkMid, fontSize: 12)),
                        ]),
                      ]),
                    ),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Divider(color: _border, thickness: 0.5),
                    ),
                    // Players
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('SIRАЛАМА',
                              style: TextStyle(
                                color: _inkMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              )),
                          const SizedBox(height: 8),
                          ...entry.results.asMap().entries.map((e) {
                            final rank = e.key + 1;
                            final r = e.value;
                            final isWinner = rank == 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _border, width: 0.8),
                                    color: isWinner ? _ink : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text('$rank',
                                        style: TextStyle(
                                          color: isWinner ? _paperTop : _inkMid,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isWinner)
                                  const Icon(Icons.emoji_events_rounded,
                                      size: 14, color: _blue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(r.name,
                                      style: TextStyle(
                                        color: isWinner ? _ink : _inkMid,
                                        fontSize: 15,
                                        fontWeight: isWinner
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      )),
                                ),
                                Text(
                                  r.score >= 0 ? '+${r.score}' : '${r.score}',
                                  style: TextStyle(
                                    color: r.score < 0 ? _red : _blue,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ]),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Divider(color: _border, thickness: 0.5),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                      child: Row(children: [
                        Text('${entry.roundCount} el oynandı',
                            style: const TextStyle(color: _inkMid, fontSize: 12)),
                        if (entry.durationMinutes != null) ...[
                          const Text('  ·  ',
                              style: TextStyle(color: _inkFaint, fontSize: 12)),
                          Text('${entry.durationMinutes} dk',
                              style: const TextStyle(color: _inkMid, fontSize: 12)),
                        ],
                        const Spacer(),
                        const Text('okeymatik.app',
                            style: TextStyle(
                              color: _inkFaint,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            )),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
