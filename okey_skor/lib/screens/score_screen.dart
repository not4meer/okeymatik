import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
import '../providers/history_provider.dart';
import '../providers/live_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/home_screen.dart';
import '../services/analytics_service.dart';
import '../widgets/banner_ad.dart';
import '../widgets/classic_round_sheet.dart';
import '../widgets/dice_sheet.dart';
import '../widgets/interstitial_ad.dart';
import '../widgets/okey101_round_sheet.dart';
import '../widgets/tile_calculator_sheet.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  static const _playerColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    if (session == null) return const HomeScreen();

    final hidden = ref.watch(scoresHiddenProvider);
    final live = ref.watch(liveProvider);
    final s = ref.watch(stringsProvider);

    ref.listen<GameSession?>(gameSessionProvider, (_, next) {
      if (next != null && ref.read(liveProvider).role == LiveRole.host) {
        ref.read(liveProvider.notifier).pushUpdate(next);
      }
    });

    final dealer = _getDealerInfo(session);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.gameType == GameType.okey101 ? 'Okey 101' : s.classicOkey),
        leading: TextButton(
          onPressed: () => _confirmEnd(context, ref, s),
          child: Text(
            s.endGame,
            style: const TextStyle(color: AppColors.penalty, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.wifi_rounded,
              color: live.role == LiveRole.host ? Colors.greenAccent : context.appHint,
              size: 22,
            ),
            tooltip: s.liveTable,
            onPressed: () => _showLiveSheet(context, ref, session, s),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _RoundHistoryTable(
              session: session,
              hidden: hidden,
              colors: _playerColors,
              s: s,
              dealerColIdx: dealer.colIdx,
              onEditRound: (i) => _editRound(context, ref, session, i),
            ),
          ),
          Divider(height: 1, color: context.appMuted),
          _PenaltyRow(
            session: session,
            colors: _playerColors,
            s: s,
            showSiler: session.gameType == GameType.okey101,
            onPenalty: (id, amt) => ref.read(gameSessionProvider.notifier).addPenalty(id, amt),
          ),
          Divider(height: 1, color: context.appMuted),
          _BottomBar(
            session: session,
            hidden: hidden,
            s: s,
            dealerName: dealer.name,
            onEnterScore: () => _addRound(context, ref, session.gameType),
            onDice: () => _openDice(context),
            onCalc: () => _openCalc(context),
            onChat: () => _openChat(context),
            onToggleHide: () {
              final newHidden = !hidden;
              ref.read(scoresHiddenProvider.notifier).state = newHidden;
              if (ref.read(liveProvider).role == LiveRole.host) {
                ref.read(liveProvider.notifier).pushHidden(newHidden);
              }
            },
            onUndo: session.rounds.isNotEmpty ? () => _undo(context, ref, s) : null,
          ),
          const SafeArea(
            top: false,
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }

  void _addRound(BuildContext context, WidgetRef ref, GameType type) {
    final sheet = type == GameType.okey101
        ? const Okey101RoundSheet()
        : const ClassicRoundSheet();

    showModalBottomSheet<RoundScore>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    ).then((round) {
      if (round != null && context.mounted) {
        final session = ref.read(gameSessionProvider)!;
        final elsBefore =
            session.rounds.where((r) => r.label != 'Ceza').length;
        final roundsBefore = session.rounds.length;
        ref.read(gameSessionProvider.notifier).addRound(round);

        final newElCount =
            elsBefore + (round.label != 'Ceza' ? 1 : 0);
        final limit = session.totalRounds;

        if (limit != null && newElCount == limit && context.mounted) {
          _showRoundLimitReached(context, ref);
        } else if ((roundsBefore + 1) % 2 == 0 && context.mounted) {
          final isPremium = ref.read(premiumProvider);
          if (!isPremium) InterstitialAd.show(context);
        }
      }
    });
  }

  void _showRoundLimitReached(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(s.roundLimitTitle,
            style: TextStyle(color: ctx.appTextMain, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.roundLimitContent, style: TextStyle(color: ctx.appSubtext)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.roundLimitYes),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.roundLimitNo),
            ),
          ],
        ),
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      _finishGame(context, ref);
    });
  }

  void _finishGame(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    final session = ref.read(gameSessionProvider)!;
    final roundCount = session.rounds.where((r) => r.label != 'Ceza').length;
    ref.read(historyProvider.notifier).saveGame(session);
    ref.read(settingsProvider.notifier).incrementCompletedGames();
    AnalyticsService.logGameCompleted(session.gameType.name, roundCount);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SummaryDialog(session: session, s: s),
    ).then((_) async {
      if (!context.mounted) return;
      ref.read(scoresHiddenProvider.notifier).state = false;
      ref.read(gameSessionProvider.notifier).endGame();
      final settings = ref.read(settingsProvider);
      if (settings.shouldShowRating && context.mounted) {
        ref.read(settingsProvider.notifier).markRatingShown();
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      }
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    });
  }

  void _editRound(BuildContext context, WidgetRef ref, GameSession session, int index) {
    final sheet = session.gameType == GameType.okey101
        ? const Okey101RoundSheet()
        : const ClassicRoundSheet();

    showModalBottomSheet<RoundScore>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    ).then((round) {
      if (round != null && context.mounted) {
        ref.read(gameSessionProvider.notifier).replaceRound(index, round);
      }
    });
  }

  void _openDice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiceSheet(),
    );
  }

  void _openCalc(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TileCalculatorSheet(),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  void _undo(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(s.undoTitle, style: TextStyle(color: ctx.appTextMain)),
        content: Text(s.undoContent, style: TextStyle(color: ctx.appSubtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              ref.read(gameSessionProvider.notifier).undoLastRound();
              Navigator.pop(ctx);
            },
            child: Text(s.undo, style: const TextStyle(color: AppColors.penalty)),
          ),
        ],
      ),
    );
  }

  void _showLiveSheet(BuildContext context, WidgetRef ref, GameSession session, AppStrings s) {
    final live = ref.read(liveProvider);

    if (live.role == LiveRole.host) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.appSurface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _LiveHostSheet(
          roomCode: live.roomCode!,
          s: s,
          onStop: () async {
            await ref.read(liveProvider.notifier).leaveRoom();
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.appSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _LiveStartSheet(
          s: s,
          onStart: () async {
            Navigator.pop(ctx);
            final code = await ref.read(liveProvider.notifier).createRoom(session);
            if (!context.mounted) return;
            if (code == null) {
              final err = ref.read(liveProvider).error ?? 'Bağlantı hatası';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: context.appSurface,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx2) => _LiveHostSheet(
                roomCode: code,
                s: s,
                onStop: () async {
                  await ref.read(liveProvider.notifier).leaveRoom();
                  if (ctx2.mounted) Navigator.pop(ctx2);
                },
              ),
            );
          },
        ),
      );
    }
  }

  void _confirmEnd(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(s.endGameTitle, style: TextStyle(color: ctx.appTextMain)),
        content: Text(s.endGameContent, style: TextStyle(color: ctx.appSubtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.endGame, style: const TextStyle(color: AppColors.penalty)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      _finishGame(context, ref);
    });
  }
}

// ── Penalty row ──────────────────────────────────────────

class _PenaltyRow extends StatelessWidget {
  final GameSession session;
  final List<Color> colors;
  final AppStrings s;
  final bool showSiler;
  final void Function(String playerId, int amount) onPenalty;

  const _PenaltyRow({
    required this.session,
    required this.colors,
    required this.s,
    required this.showSiler,
    required this.onPenalty,
  });

  @override
  Widget build(BuildContext context) {
    final isPaired = session.gameMode == GameMode.paired && session.pairs.length == 2;

    Widget button(Player player, Color color, String displayName) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => _showPenaltyDialog(context, player, color, displayName),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 14, color: color),
                  const SizedBox(width: 3),
                  Text(
                    isPaired ? '$displayName ${s.penalty}' : s.penalty,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> buttons;
    if (isPaired) {
      buttons = session.pairs.map((pair) {
        final first = session.players[pair[0]];
        String name = first.name;
        if (name.endsWith(' 1') || name.endsWith(' 2')) {
          name = name.substring(0, name.length - 2).trim();
        }
        final color = colors[pair[0] % colors.length];
        return button(Player(id: first.id, name: name, totalScore: 0), color, name);
      }).toList();
    } else {
      buttons = session.players.asMap().entries.map((e) {
        return button(e.value, colors[e.key % colors.length], e.value.name);
      }).toList();
    }

    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: buttons),
    );
  }

  Future<void> _showPenaltyDialog(
    BuildContext context,
    Player player,
    Color color,
    String displayName,
  ) async {
    final result = await showDialog<({int amount, bool isSiler})>(
      context: context,
      builder: (_) => _PenaltyDialog(player: player, color: color, displayName: displayName, s: s, showSiler: showSiler),
    );
    if (result != null && context.mounted) {
      final amt = result.isSiler ? -result.amount : result.amount;
      if (amt != 0) onPenalty(player.id, amt);
    }
  }
}

class _PenaltyDialog extends StatefulWidget {
  final Player player;
  final Color color;
  final String displayName;
  final AppStrings s;
  final bool showSiler;

  const _PenaltyDialog({
    required this.player,
    required this.color,
    required this.displayName,
    required this.s,
    required this.showSiler,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.showSiler ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(_ctrl.text);
    if (v == null || v <= 0) return;
    Navigator.pop(context, (amount: v, isSiler: _tab.index == 1));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(
        widget.displayName,
        style: TextStyle(color: widget.color, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showSiler)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.appBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: context.appTextMain,
                unselectedLabelColor: context.appHint,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: [Tab(text: s.penalty), Tab(text: s.siler)],
              ),
            ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _tab,
            builder: (_, __) => Text(
              _tab.index == 0 ? s.penaltyHint : s.silerHint,
              style: TextStyle(
                color: _tab.index == 1 ? AppColors.siler : context.appSubtext,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appTextMain, fontSize: 28, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        AnimatedBuilder(
          animation: _tab,
          builder: (_, __) => TextButton(
            onPressed: _submit,
            child: Text(
              _tab.index == 0 ? s.addPenalty : s.addSiler,
              style: TextStyle(
                color: _tab.index == 1 ? AppColors.siler : widget.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Display column ────────────────────────────────────────

class _DisplayColumn {
  final String name;
  final Color color;
  final List<String> playerIds;

  const _DisplayColumn({required this.name, required this.color, required this.playerIds});

  int deltaFor(RoundScore round) =>
      playerIds.fold(0, (sum, id) => sum + (round.deltas[id] ?? 0));

  int totalFor(List<Player> players) => playerIds.fold(0, (sum, id) {
        final p = players.firstWhere((pl) => pl.id == id,
            orElse: () => const Player(id: '', name: '', totalScore: 0));
        return sum + p.totalScore;
      });
}

List<_DisplayColumn> _buildColumns(GameSession session, List<Color> colors) {
  if (session.gameMode == GameMode.paired && session.pairs.length == 2) {
    return session.pairs.asMap().entries.map((e) {
      final pair = e.value;
      String name = session.players[pair[0]].name;
      if (name.endsWith(' 1') || name.endsWith(' 2')) {
        name = name.substring(0, name.length - 2).trim();
      }
      return _DisplayColumn(
        name: name,
        color: colors[pair[0] % colors.length],
        playerIds: pair.map((i) => session.players[i].id).toList(),
      );
    }).toList();
  }
  return session.players.asMap().entries.map((e) => _DisplayColumn(
        name: e.value.name,
        color: colors[e.key % colors.length],
        playerIds: [e.value.id],
      )).toList();
}

// Returns the current dealer's display name and their column index.
// Advances automatically as rounds are added (derived, no extra state).
({String name, int colIdx}) _getDealerInfo(GameSession session) {
  final elCount =
      session.rounds.where((r) => r.label != 'Ceza').length;
  final isPaired =
      session.gameMode == GameMode.paired && session.pairs.length == 2;

  if (isPaired) {
    final pA = session.pairs[0];
    final pB = session.pairs[1];
    // Interleaved seating: A[0] → B[0] → A[1] → B[1]
    final order = <({int playerIdx, int colIdx})>[];
    if (pA.isNotEmpty) order.add((playerIdx: pA[0], colIdx: 0));
    if (pB.isNotEmpty) order.add((playerIdx: pB[0], colIdx: 1));
    if (pA.length > 1) order.add((playerIdx: pA[1], colIdx: 0));
    if (pB.length > 1) order.add((playerIdx: pB[1], colIdx: 1));
    if (order.isEmpty) return (name: '', colIdx: 0);
    final d = order[elCount % order.length];
    return (name: session.players[d.playerIdx].name, colIdx: d.colIdx);
  }

  final n = session.players.length;
  if (n == 0) return (name: '', colIdx: 0);
  final idx = elCount % n;
  return (name: session.players[idx].name, colIdx: idx);
}

// ── Round history table ───────────────────────────────────

class _RoundHistoryTable extends StatelessWidget {
  final GameSession session;
  final bool hidden;
  final List<Color> colors;
  final AppStrings s;
  final int dealerColIdx;
  final void Function(int index) onEditRound;

  const _RoundHistoryTable({
    required this.session,
    required this.hidden,
    required this.colors,
    required this.s,
    required this.dealerColIdx,
    required this.onEditRound,
  });

  @override
  Widget build(BuildContext context) {
    final columns = _buildColumns(session, colors);
    final rounds = session.rounds;

    int elCounter = 0;
    final elNos = rounds.map((r) {
      if (r.label != 'Ceza') elCounter++;
      return r.label != 'Ceza' ? elCounter : null;
    }).toList();

    return Column(
      children: [
        _TableHeader(columns: columns, dealerColIdx: dealerColIdx),
        Divider(height: 1, color: context.appMuted),
        Expanded(
          child: rounds.isEmpty
              ? Center(
                  child: Text(
                    s.noRoundsYet,
                    style: TextStyle(color: context.appHint, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: rounds.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: context.appMuted),
                  itemBuilder: (_, i) => _RoundRow(
                    elNo: elNos[i],
                    round: rounds[i],
                    columns: columns,
                    roundPrefix: s.roundPrefix,
                    penaltyLabel: s.penalty,
                    onEdit: () => onEditRound(i),
                  ),
                ),
        ),
        Divider(height: 1, color: context.appMuted),
        _TotalRow(
          columns: columns,
          players: session.players,
          hidden: hidden,
          gameType: session.gameType,
          s: s,
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<_DisplayColumn> columns;
  final int dealerColIdx;

  const _TableHeader({required this.columns, required this.dealerColIdx});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 52),
          ...columns.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            final isDealer = i == dealerColIdx;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.name,
                    style: TextStyle(
                      color: c.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  AnimatedOpacity(
                    opacity: isDealer ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 350),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  final int? elNo;
  final RoundScore round;
  final List<_DisplayColumn> columns;
  final String roundPrefix;
  final String penaltyLabel;
  final VoidCallback onEdit;

  const _RoundRow({
    required this.elNo,
    required this.round,
    required this.columns,
    required this.roundPrefix,
    required this.penaltyLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = round.label == 'Ceza' ? penaltyLabel : round.label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (elNo != null)
                  Text(
                    '$roundPrefix $elNo',
                    style: TextStyle(
                      color: context.appHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  displayLabel,
                  style: TextStyle(color: context.appDim, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ...columns.map((c) {
            final d = c.deltaFor(round);
            final color = d < 0
                ? AppColors.siler
                : d > 0
                    ? AppColors.penalty
                    : context.appDim;
            return Expanded(
              child: Text(
                d == 0 ? '—' : d > 0 ? '+$d' : '$d',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            );
          }),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 15),
              color: context.appDim,
              padding: EdgeInsets.zero,
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final List<_DisplayColumn> columns;
  final List<Player> players;
  final bool hidden;
  final GameType gameType;
  final AppStrings s;

  const _TotalRow({
    required this.columns,
    required this.players,
    required this.hidden,
    required this.gameType,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              s.total,
              style: TextStyle(color: context.appSubtext, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          ...() {
            final totals = columns.map((c) => c.totalFor(players)).toList();
            final isClassic = gameType == GameType.classicOkey;
            final leaderTotal = totals.isEmpty ? null : isClassic
                ? totals.reduce((a, b) => a > b ? a : b)
                : totals.reduce((a, b) => a < b ? a : b);
            final hasUniqueLeader = leaderTotal != null &&
                totals.where((t) => t == leaderTotal).length == 1;
            return columns.map((c) {
              final total = c.totalFor(players);
              Color scoreColor;
              if (hidden) {
                scoreColor = context.appHint;
              } else if (hasUniqueLeader && total == leaderTotal) {
                scoreColor = AppColors.siler;
              } else {
                scoreColor = context.appTextMain;
              }
              return Expanded(
                child: Text(
                  hidden ? '***' : total.toString(),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            });
          }(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final GameSession session;
  final bool hidden;
  final AppStrings s;
  final String dealerName;
  final VoidCallback onEnterScore;
  final VoidCallback onDice;
  final VoidCallback onCalc;
  final VoidCallback onChat;
  final VoidCallback onToggleHide;
  final VoidCallback? onUndo;

  const _BottomBar({
    required this.session,
    required this.hidden,
    required this.s,
    required this.dealerName,
    required this.onEnterScore,
    required this.onDice,
    required this.onCalc,
    required this.onChat,
    required this.onToggleHide,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final roundCount = session.rounds.where((r) => r.label != 'Ceza').length;
    final totalRounds = session.totalRounds;
    final roundLabel = s.roundLabel(roundCount, totalRounds);
    final screenW = MediaQuery.sizeOf(context).width;
    final compact = screenW < 360;
    final btnGap = compact ? 4.0 : 6.0;

    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(roundLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: context.appHint, fontSize: 13)),
                        ),
                        if (dealerName.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                  color: context.appDim, fontSize: 11)),
                          Text('Dağıtan:',
                              style: TextStyle(
                                  color: context.appHint, fontSize: 11)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                          child: child,
                        ),
                      ),
                      child: dealerName.isEmpty
                          ? const SizedBox(key: ValueKey('empty'), height: 15)
                          : Text(
                              dealerName,
                              key: ValueKey(dealerName),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appPrimary
                                    .withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: btnGap),
              if (onUndo != null) ...[
                _IconBtn(
                  icon: Icons.undo_rounded,
                  label: 'Geri Al',
                  onTap: onUndo!,
                  color: AppColors.penalty,
                  compact: compact,
                ),
                SizedBox(width: btnGap),
              ],
              _IconBtn(
                icon: hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                label: hidden ? 'Göster' : 'Gizle',
                onTap: onToggleHide,
                compact: compact,
              ),
              SizedBox(width: btnGap),
              if (session.gameType == GameType.okey101) ...[
                _IconBtn(
                    icon: Icons.calculate_rounded,
                    label: 'Hesap',
                    onTap: onCalc,
                    compact: compact),
                SizedBox(width: btnGap),
              ],
              _IconBtn(
                  icon: Icons.casino_rounded,
                  label: 'Zar',
                  onTap: onDice,
                  compact: compact),
              SizedBox(width: btnGap),
              _IconBtn(
                  icon: Icons.gavel_rounded,
                  label: 'Hakem',
                  onTap: onChat,
                  compact: compact),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onEnterScore,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(s.addRound),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool compact;

  const _IconBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final w = compact ? 38.0 : 44.0;
    final h = compact ? 33.0 : 38.0;
    final iconSz = compact ? 19.0 : 22.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? context.appPrimary, size: iconSz),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: context.appHint, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}


// ── Game summary dialog ──────────────────────────────────

class _SummaryDialog extends StatefulWidget {
  final GameSession session;
  final AppStrings s;
  const _SummaryDialog({required this.session, required this.s});

  @override
  State<_SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<_SummaryDialog> {
  final _screenshotCtrl = ScreenshotController();
  bool _sharing = false;

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  Future<void> _shareImage(BuildContext context) async {
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imageBytes = await _screenshotCtrl.captureFromLongWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ResultCard(session: widget.session),
        ),
        pixelRatio: 2.0,
        context: context,
        constraints: const BoxConstraints(maxWidth: 360),
      );
      final XFile xFile;
      if (kIsWeb) {
        xFile = XFile.fromData(
          imageBytes,
          name: 'okeymatik_result.png',
          mimeType: 'image/png',
        );
      } else {
        final tmpDir = await getTemporaryDirectory();
        final file = File('${tmpDir.path}/okeymatik_result.png');
        await file.writeAsBytes(imageBytes);
        xFile = XFile(file.path);
      }
      await Share.shareXFiles([xFile], text: 'Okeymatik');
      AnalyticsService.logScreenshotTaken();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Paylaşım başarısız')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final columns = _buildColumns(widget.session, _colors);
    final sorted = [...columns]
      ..sort((a, b) => a.totalFor(widget.session.players).compareTo(b.totalFor(widget.session.players)));
    final isClassic = widget.session.gameType == GameType.classicOkey;
    final winner = isClassic ? sorted.last : sorted.first;
    final roundCount = widget.session.rounds.where((r) => r.label != 'Ceza').length;

    return AlertDialog(
      backgroundColor: context.appSurface,
      actionsOverflowButtonSpacing: 8,
      title: Text(s.gameSummaryTitle,
          style: TextStyle(color: context.appTextMain, fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded, color: context.appPrimary, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.won(winner.name),
                    style: TextStyle(
                        color: context.appPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((e) {
            final rank = e.key + 1;
            final col = e.value;
            final total = col.totalFor(widget.session.players);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                      width: 22,
                      child: Text('$rank.',
                          style: TextStyle(color: context.appHint, fontSize: 13))),
                  Expanded(
                    child: Text(col.name,
                        style: TextStyle(
                            color: col.color, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    total.toString(),
                    style: TextStyle(
                      color: total < 0 ? AppColors.siler : context.appTextMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.roundsPlayedText(roundCount),
                  style: TextStyle(color: context.appHint, fontSize: 12)),
              if (widget.session.startedAt != null) ...[
                Text('  ·  ', style: TextStyle(color: context.appHint, fontSize: 12)),
                Text(
                  '${((DateTime.now().millisecondsSinceEpoch - widget.session.startedAt!) / 60000).round().clamp(1, 9999)} dk',
                  style: TextStyle(color: context.appHint, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        if (_sharing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          TextButton.icon(
            onPressed: () => _shareImage(context),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: Text(s.shareImage),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.backToHome),
        ),
      ],
    );
  }
}

// ── Result card (rendered off-screen for PNG share) ──────

class ResultCard extends StatelessWidget {
  final GameSession session;
  const ResultCard({super.key, required this.session});

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
  static const _rowAlt   = Color(0xFFF0E8CC);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${pad(now.day)}.${pad(now.month)}.${now.year}';
    final timeStr = '${pad(now.hour)}:${pad(now.minute)}';

    final n = session.players.length;
    final cols = _buildColumns(session, List.filled(n < 2 ? 2 : n, _ink));

    final elRounds = <(int, RoundScore)>[];
    // addPenalty stores: Ceza → +amount (positive), Siler → -amount (negative)
    final cezaAmounts = <String, int>{};   // positive 'Ceza' deltas
    final silerAmounts = <String, int>{};  // abs of negative 'Ceza' deltas
    int elNo = 0;
    for (final r in session.rounds) {
      if (r.label == 'Ceza') {
        for (final e in r.deltas.entries) {
          if (e.value > 0) {
            cezaAmounts[e.key] = (cezaAmounts[e.key] ?? 0) + e.value;
          } else if (e.value < 0) {
            silerAmounts[e.key] = (silerAmounts[e.key] ?? 0) + (-e.value);
          }
        }
      } else {
        elNo++;
        elRounds.add((elNo, r));
      }
    }
    final hasCeza = cezaAmounts.values.any((v) => v != 0);
    final hasSiler = silerAmounts.values.any((v) => v != 0);

    final sorted = [...cols]
      ..sort((a, b) =>
          a.totalFor(session.players).compareTo(b.totalFor(session.players)));
    final isClassicReceipt = session.gameType == GameType.classicOkey;
    final winner = isClassicReceipt ? sorted.last : sorted.first;
    final gameLabel =
        session.gameType == GameType.okey101 ? 'Okey 101' : 'Klasik Okey';
    final masaNo =
        ((session.players.length * 7 + elRounds.length * 3) % 14) + 1;

    return SizedBox(
      width: 360,
      height: 640, // locked 9:16
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
          child: LayoutBuilder(
            builder: (_, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_paperTop, _paperMid, _paperBot],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(1)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xBB000000),
                        blurRadius: 28,
                        spreadRadius: 3,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 10,
                        offset: Offset(-3, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Watermark
                      Positioned.fill(
                        child: Center(
                          child: Opacity(
                            opacity: 0.035,
                            child: Text(
                              'OKEYMATİK',
                              style: const TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 50,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                letterSpacing: 3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(gameLabel, dateStr, timeStr, masaNo),
                          _rule(),
                          _buildPlayers(cols, sorted, winner),
                          _rule(),
                          _buildTable(cols, elRounds),
                          _rule(),
                          _buildTotals(cols, hasCeza, cezaAmounts, hasSiler, silerAmounts),
                          _doubleRule(),
                          _buildFinal(cols),
                          _rule(),
                          _buildWinner(winner),
                          _buildFooter(),
                        ],
                      ),
                      // Corner marks
                      Positioned(top: 7, left: 7, child: _corner()),
                      Positioned(top: 7, right: 7, child: _corner(flipH: true)),
                      Positioned(bottom: 7, left: 7, child: _corner(flipV: true)),
                      Positioned(
                          bottom: 7,
                          right: 7,
                          child: _corner(flipH: true, flipV: true)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      String game, String date, String time, int masaNo) {
    return Container(
      color: _hdrBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino_rounded, color: _inkMid, size: 12),
            const SizedBox(width: 5),
            const Text(
              'OKEYMATİK',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '— $game —',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Caveat',
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('Masa No: $masaNo',
              style: const TextStyle(
                  fontFamily: 'Caveat', color: _inkMid, fontSize: 12)),
          const Spacer(),
          Text('Tarih: $date',
              style: const TextStyle(
                  fontFamily: 'Caveat', color: _inkMid, fontSize: 12)),
          const Spacer(),
          Text('Saat: $time',
              style: const TextStyle(
                  fontFamily: 'Caveat', color: _inkMid, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildPlayers(
    List<_DisplayColumn> cols,
    List<_DisplayColumn> sorted,
    _DisplayColumn winner,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(children: [
        Row(children: [
          const Expanded(
            child: Text(
              'OYUNCULAR / TAKIMLAR',
              style: TextStyle(
                fontFamily: 'Caveat',
                color: _inkMid,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Text(
            'TOPLAM',
            style: TextStyle(
              fontFamily: 'Caveat',
              color: _inkMid,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ]),
        const SizedBox(height: 5),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final col = e.value;
          final total = col.totalFor(session.players);
          final isW = col.name == winner.name;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(children: [
              _RankCircle(rank: rank),
              const SizedBox(width: 6),
              Expanded(
                child: Row(children: [
                  Text(col.name,
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        color: isW ? _ink : _inkMid,
                        fontSize: 15,
                        fontWeight:
                            isW ? FontWeight.w700 : FontWeight.w400,
                      )),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: CustomPaint(
                        painter: _DotLinePainter(color: _inkFaint),
                        child: SizedBox(height: 16),
                      ),
                    ),
                  ),
                ]),
              ),
              Text(
                total >= 0 ? '+$total' : '$total',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  color: total < 0 ? _red : _blue,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildTable(
      List<_DisplayColumn> cols, List<(int, RoundScore)> elRounds) {
    return Column(children: [
      _tRow(
        label: 'ELLER',
        cells: cols.map((c) => _shortName(c.name)).toList(),
        acik: 'AÇIKLAMA',
        isHeader: true,
      ),
      Container(height: 0.5, color: _inkFaint.withValues(alpha: 0.5)),
      ...elRounds.asMap().entries.map((e) {
        final idx = e.key;
        final (no, round) = e.value;
        return _tRow(
          label: 'El $no',
          cells: cols.map((c) {
            final d = c.deltaFor(round);
            return d == 0 ? '—' : (d > 0 ? '+$d' : '$d');
          }).toList(),
          deltas: cols.map((c) => c.deltaFor(round)).toList(),
          acik: round.label,
          stripe: idx.isOdd,
        );
      }),
    ]);
  }

  Widget _buildTotals(
    List<_DisplayColumn> cols,
    bool hasCeza,
    Map<String, int> cezaAmounts,
    bool hasSiler,
    Map<String, int> silerAmounts,
  ) {
    return Column(children: [
      if (hasCeza)
        _tRow(
          label: 'TOPLAM\nCEZA',
          cells: cols.map((c) {
            final v = c.playerIds
                .fold(0, (s, id) => s + (cezaAmounts[id] ?? 0));
            return v == 0 ? '—' : '+$v';
          }).toList(),
          deltas: cols
              .map((c) => c.playerIds
                  .fold(0, (s, id) => s + (cezaAmounts[id] ?? 0)))
              .toList(),
          acik: '',
          isBold: true,
        ),
      if (hasSiler)
        _tRow(
          label: 'TOPLAM\nSİLER',
          cells: cols.map((c) {
            final v = c.playerIds
                .fold(0, (s, id) => s + (silerAmounts[id] ?? 0));
            return v == 0 ? '—' : '-$v';
          }).toList(),
          deltas: cols
              .map((c) => -(c.playerIds
                  .fold(0, (s, id) => s + (silerAmounts[id] ?? 0))))
              .toList(),
          acik: '',
          isBold: true,
        ),
    ]);
  }

  Widget _buildFinal(List<_DisplayColumn> cols) {
    return Container(
      color: _hdrBg,
      child: _tRow(
        label: 'FİNAL\nSKORU',
        cells: cols.map((c) {
          final t = c.totalFor(session.players);
          return t >= 0 ? '+$t' : '$t';
        }).toList(),
        deltas: cols.map((c) => c.totalFor(session.players)).toList(),
        acik: '',
        isBold: true,
        isHeader: true,
        bigCells: true,
      ),
    );
  }

  Widget _buildWinner(_DisplayColumn winner) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10, 30, 8),
      child: Column(children: [
        const Text(
          '— KAZANAN —',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _inkMid,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: _ink, size: 22),
            Text(
              winner.name,
              style: const TextStyle(
                fontFamily: 'Caveat',
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 1.5,
          color: _ink,
        ),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: _hdrBg,
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 14),
      child: Row(children: [
        const Expanded(
          child: Text(
            'Okeymatik',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Caveat',
              color: _inkFaint,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const _StampWidget(),
      ]),
    );
  }

  Widget _tRow({
    required String label,
    required List<String> cells,
    String acik = '',
    List<int>? deltas,
    bool isHeader = false,
    bool isBold = false,
    bool stripe = false,
    bool bigCells = false,
  }) {
    final bg =
        (isHeader && !bigCells) ? _hdrBg : stripe ? _rowAlt : null;
    final labelTs = TextStyle(
      fontFamily: 'Caveat',
      color: isHeader || isBold ? _inkMid : _ink,
      fontSize: isHeader ? 10 : 11,
      fontWeight:
          isHeader || isBold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: isHeader ? 0.5 : 0,
      height: 1.2,
    );

    return Container(
      color: bg,
      padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isHeader ? 5 : (isBold ? 5 : 4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 42, child: Text(label, style: labelTs)),
          ...cells.asMap().entries.map((e) {
            final i = e.key;
            final val = e.value;
            final delta =
                deltas != null && i < deltas.length ? deltas[i] : 0;
            final Color tc;
            if (isHeader) {
              tc = _inkMid;
            } else if (val == '—') {
              tc = _inkFaint;
            } else if (delta < 0) {
              tc = _red;
            } else if (delta > 0) {
              tc = _blue;
            } else {
              tc = _ink;
            }
            return Expanded(
              child: Text(
                val,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  color: tc,
                  fontSize: bigCells ? 19 : (isHeader ? 12 : 14),
                  fontWeight: isHeader || isBold || bigCells
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            );
          }),
          SizedBox(
            width: 52,
            child: acik.isNotEmpty
                ? Text(
                    acik,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      color: _inkMid,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.right,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _rule() =>
      Container(height: 0.8, color: _inkFaint.withValues(alpha: 0.6));

  Widget _doubleRule() => Column(children: [
        Container(height: 0.8, color: _inkFaint.withValues(alpha: 0.8)),
        const SizedBox(height: 2.5),
        Container(height: 0.8, color: _inkFaint.withValues(alpha: 0.8)),
      ]);

  Widget _corner({bool flipH = false, bool flipV = false}) {
    return Transform.scale(
      scaleX: flipH ? -1.0 : 1.0,
      scaleY: flipV ? -1.0 : 1.0,
      child: SizedBox(
        width: 12,
        height: 12,
        child: CustomPaint(painter: _CornerPainter(color: _border)),
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    final first = parts.first;
    return first.length > 7 ? first.substring(0, 7) : first;
  }
}

// ── Live room bottom sheets ───────────────────────────────

class _LiveStartSheet extends StatelessWidget {
  final VoidCallback onStart;
  final AppStrings s;
  const _LiveStartSheet({required this.onStart, required this.s});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.liveTable,
                style: TextStyle(
                    color: context.appTextMain, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(s.liveDescription, style: TextStyle(color: context.appSubtext, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.wifi_rounded, size: 18),
                label: Text(s.startLive),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHostSheet extends StatelessWidget {
  final String roomCode;
  final VoidCallback onStop;
  final AppStrings s;
  const _LiveHostSheet({required this.roomCode, required this.onStop, required this.s});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.liveActive,
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.appHint, size: 22),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Kapat',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.roomCodeLabel,
                style: TextStyle(color: context.appHint, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Copy code on tap
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  roomCode,
                  style: TextStyle(
                    color: context.appTextMain,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(s.shareRoomCode, style: TextStyle(color: context.appHint, fontSize: 12)),
            const SizedBox(height: 16),
            Text(
              'Ekranı kapatsan da canlı masa aktif kalır. Wifi ikonuna tekrar basarak kodu görebilirsin.',
              style: TextStyle(color: context.appDim, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.appMuted),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Kapat', style: TextStyle(color: context.appSubtext)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onStop,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.penalty.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.penalty),
                        const SizedBox(width: 6),
                        Text(s.stopLive, style: const TextStyle(color: AppColors.penalty)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCircle extends StatelessWidget {
  final int rank;
  const _RankCircle({required this.rank});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF5A4525);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text('$rank',
            style: const TextStyle(
                fontFamily: 'Caveat',
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _DotLinePainter extends CustomPainter {
  final Color color;
  const _DotLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var x = 0.0;
    final y = size.height * 0.75;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, y), 0.8, paint);
      x += 4.5;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StampWidget extends StatelessWidget {
  const _StampWidget();

  static const _c = Color(0xFF8B7040);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _c.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _c.withValues(alpha: 0.2), width: 0.7),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OKEYMATİK',
              style: TextStyle(
                fontFamily: 'Caveat',
                color: _c.withValues(alpha: 0.45),
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Icon(Icons.emoji_events_rounded, color: _c.withValues(alpha: 0.45), size: 14),
            Text(
              'TEBRİKLER!',
              style: TextStyle(
                fontFamily: 'Caveat',
                color: _c.withValues(alpha: 0.45),
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
