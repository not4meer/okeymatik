import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/round.dart';
import '../providers/live_provider.dart';
import '../providers/settings_provider.dart';

class LiveViewScreen extends ConsumerWidget {
  const LiveViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveProvider);
    final s = ref.watch(stringsProvider);
    final session = live.viewerSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.liveTable)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const _LiveBadge(),
            const SizedBox(width: 10),
            Text(
              session.gameType == GameType.okey101 ? 'Okey 101' : s.classicOkey,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '${s.roomPrefix} ${live.roomCode}',
              style: TextStyle(fontSize: 12, color: context.appHint),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(liveProvider.notifier).leaveRoom();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(s.leave,
                style: const TextStyle(color: AppColors.penalty, fontSize: 13)),
          ),
        ],
      ),
      body: _LiveScoreTable(session: session, totalLabel: s.total),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.red, size: 7),
            SizedBox(width: 4),
            Text('CANLI',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _LiveScoreTable extends StatelessWidget {
  final GameSession session;
  final String totalLabel;

  const _LiveScoreTable({required this.session, required this.totalLabel});

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final players = session.players;
    final rounds = session.rounds;

    return Column(
      children: [
        Container(
          color: context.appCard,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 44),
              ...players.asMap().entries.map(
                    (e) => Expanded(
                  child: Text(
                    e.value.name,
                    style: TextStyle(
                      color: _colors[e.key % _colors.length],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.appMuted),
        Expanded(
          child: ListView.separated(
            itemCount: rounds.length + 1,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.appMuted),
            itemBuilder: (ctx, index) {
              if (index < rounds.length) {
                final round = rounds[index];
                final label = round.label.isNotEmpty ? round.label : '${index + 1}.';
                return _RoundRow(round: round, players: players, label: label);
              }
              return _TotalsRow(players: players, totalLabel: totalLabel);
            },
          ),
        ),
      ],
    );
  }
}

class _RoundRow extends StatelessWidget {
  final RoundScore round;
  final List players;
  final String label;

  const _RoundRow({required this.round, required this.players, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label,
                style: TextStyle(color: context.appHint, fontSize: 11)),
          ),
          ...players.asMap().entries.map((e) {
            final delta = round.deltas[e.value.id] ?? 0;
            final color = delta == 0
                ? context.appDim
                : (delta < 0 ? AppColors.siler : AppColors.penalty);
            return Expanded(
              child: Text(
                delta == 0 ? '—' : (delta > 0 ? '+$delta' : '$delta'),
                style:
                    TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final List players;
  final String totalLabel;

  const _TotalsRow({required this.players, required this.totalLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appCard,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              totalLabel.toUpperCase().substring(0, totalLabel.length.clamp(0, 3)),
              style: TextStyle(
                  color: context.appHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
          ),
          ...players.map((p) {
            final total = p.totalScore as int;
            return Expanded(
              child: Text(
                total.toString(),
                style: TextStyle(
                  color: total < 0 ? AppColors.siler : context.appTextMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}
