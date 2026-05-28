import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/live_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/dice_sheet.dart';
import '../widgets/tile_calculator_sheet.dart';
import 'chat_screen.dart';

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
      body: _LiveScoreTable(session: session, totalLabel: s.total, scoresHidden: live.scoresHidden),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: context.appSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ViewerBtn(
                icon: Icons.casino_rounded,
                label: 'Zar',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const DiceSheet(),
                ),
              ),
              _ViewerBtn(
                icon: Icons.calculate_rounded,
                label: 'Hesap',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const TileCalculatorSheet(),
                ),
              ),
              _ViewerBtn(
                icon: Icons.gavel_rounded,
                label: 'Hakem',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ViewerBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 42,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.appPrimary, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.appHint, fontSize: 11)),
        ],
      ),
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

// Display column: handles both individual and paired mode
class _LiveCol {
  final String name;
  final Color color;
  final List<String> playerIds;
  const _LiveCol({required this.name, required this.color, required this.playerIds});

  int deltaFor(RoundScore round) =>
      playerIds.fold(0, (sum, id) => sum + (round.deltas[id] ?? 0));

  int totalFor(GameSession s) => playerIds.fold(0, (sum, id) {
        final p = s.players.firstWhere((pl) => pl.id == id,
            orElse: () => const Player(id: '', name: '', totalScore: 0));
        return sum + p.totalScore;
      });
}

List<_LiveCol> _buildLiveCols(GameSession session) {
  const colors = [Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFFE91E63)];
  if (session.gameMode == GameMode.paired && session.pairs.length == 2) {
    return session.pairs.asMap().entries.map((e) {
      final pair = e.value;
      String name = session.players[pair[0]].name;
      if (name.endsWith(' 1') || name.endsWith(' 2')) {
        name = name.substring(0, name.length - 2).trim();
      }
      return _LiveCol(
        name: name,
        color: colors[pair[0] % colors.length],
        playerIds: pair.map((i) => session.players[i].id).toList(),
      );
    }).toList();
  }
  return session.players.asMap().entries.map((e) => _LiveCol(
        name: e.value.name,
        color: colors[e.key % colors.length],
        playerIds: [e.value.id],
      )).toList();
}

class _LiveScoreTable extends StatelessWidget {
  final GameSession session;
  final String totalLabel;
  final bool scoresHidden;

  const _LiveScoreTable({required this.session, required this.totalLabel, required this.scoresHidden});

  @override
  Widget build(BuildContext context) {
    final cols = _buildLiveCols(session);
    final rounds = session.rounds;
    int elCounter = 0;

    return Column(
      children: [
        Container(
          color: context.appCard,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 44),
              ...cols.map((c) => Expanded(
                    child: Text(
                      c.name,
                      style: TextStyle(
                          color: c.color, fontSize: 13, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
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
                final String label;
                if (round.label == 'Ceza') {
                  label = 'Ceza';
                } else {
                  elCounter++;
                  label = 'El $elCounter';
                }
                return _LiveRoundRow(round: round, cols: cols, label: label);
              }
              if (scoresHidden) return const SizedBox.shrink();
              return _LiveTotalsRow(cols: cols, session: session, totalLabel: totalLabel);
            },
          ),
        ),
      ],
    );
  }
}

class _LiveRoundRow extends StatelessWidget {
  final RoundScore round;
  final List<_LiveCol> cols;
  final String label;

  const _LiveRoundRow({required this.round, required this.cols, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label, style: TextStyle(color: context.appHint, fontSize: 11)),
          ),
          ...cols.map((c) {
            final delta = c.deltaFor(round);
            final color = delta == 0
                ? context.appDim
                : (delta < 0 ? AppColors.siler : AppColors.penalty);
            return Expanded(
              child: Text(
                delta == 0 ? '—' : (delta > 0 ? '+$delta' : '$delta'),
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LiveTotalsRow extends StatelessWidget {
  final List<_LiveCol> cols;
  final GameSession session;
  final String totalLabel;

  const _LiveTotalsRow(
      {required this.cols, required this.session, required this.totalLabel});

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
          ...cols.map((c) {
            final total = c.totalFor(session);
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
