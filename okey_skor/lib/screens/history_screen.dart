import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_history.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';

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

class _HistoryCard extends StatelessWidget {
  final GameHistoryEntry entry;
  final AppStrings s;

  const _HistoryCard({required this.entry, required this.s});

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
          const SizedBox(height: 2),
          Text(s.roundsPlayedText(entry.roundCount),
              style: TextStyle(color: context.appDim, fontSize: 11)),
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
