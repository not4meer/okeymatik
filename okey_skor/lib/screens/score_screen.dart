import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../providers/settings_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/home_screen.dart';
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
              onEditRound: (i) => _editRound(context, ref, session, i),
            ),
          ),
          Divider(height: 1, color: context.appMuted),
          _PenaltyRow(
            session: session,
            colors: _playerColors,
            s: s,
            onPenalty: (id, amt) => ref.read(gameSessionProvider.notifier).addPenalty(id, amt),
          ),
          Divider(height: 1, color: context.appMuted),
          _BottomBar(
            session: session,
            hidden: hidden,
            s: s,
            onEnterScore: () => _addRound(context, ref, session.gameType),
            onDice: () => _openDice(context),
            onCalc: () => _openCalc(context),
            onChat: () => _openChat(context),
            onToggleHide: () => ref.read(scoresHiddenProvider.notifier).state = !hidden,
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
          InterstitialAd.show(context);
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
        content: Text(s.roundLimitContent,
            style: TextStyle(color: ctx.appSubtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.roundLimitNo,
                style: TextStyle(color: ctx.appHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.roundLimitYes),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      _finishGame(context, ref);
    });
  }

  void _finishGame(BuildContext context, WidgetRef ref) {
    final s = ref.read(stringsProvider);
    final session = ref.read(gameSessionProvider)!;
    ref.read(historyProvider.notifier).saveGame(session);
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
        await showDialog<void>(
          context: context,
          builder: (_) => _RatingDialog(s: s),
        );
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
            if (context.mounted) {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: context.appSurface,
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
            }
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
  final void Function(String playerId, int amount) onPenalty;

  const _PenaltyRow({
    required this.session,
    required this.colors,
    required this.s,
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
      builder: (_) => _PenaltyDialog(player: player, color: color, displayName: displayName, s: s),
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

  const _PenaltyDialog({
    required this.player,
    required this.color,
    required this.displayName,
    required this.s,
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
    _tab = TabController(length: 2, vsync: this);
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

// ── Round history table ───────────────────────────────────

class _RoundHistoryTable extends StatelessWidget {
  final GameSession session;
  final bool hidden;
  final List<Color> colors;
  final AppStrings s;
  final void Function(int index) onEditRound;

  const _RoundHistoryTable({
    required this.session,
    required this.hidden,
    required this.colors,
    required this.s,
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
        _TableHeader(columns: columns),
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

  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 52),
          ...columns.map((c) => Expanded(
                child: Text(
                  c.name,
                  style: TextStyle(
                    color: c.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
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
            final minTotal = totals.isEmpty ? 0 : totals.reduce((a, b) => a < b ? a : b);
            return columns.map((c) {
              final total = c.totalFor(players);
              Color scoreColor;
              if (hidden) {
                scoreColor = context.appHint;
              } else if (total == minTotal) {
                scoreColor = const Color(0xFF2E7D32);
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

    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(roundLabel,
                  style: TextStyle(color: context.appHint, fontSize: 13)),
              const Spacer(),
              if (onUndo != null) ...[
                _IconBtn(
                  icon: Icons.undo_rounded,
                  label: s.undoTitle,
                  onTap: onUndo!,
                  color: AppColors.penalty,
                ),
                const SizedBox(width: 6),
              ],
              _IconBtn(
                icon: hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                label: hidden ? 'Göster' : 'Gizle',
                onTap: onToggleHide,
              ),
              const SizedBox(width: 6),
              if (session.gameType == GameType.okey101) ...[
                _IconBtn(
                    icon: Icons.calculate_rounded,
                    label: 'Hesap',
                    onTap: onCalc),
                const SizedBox(width: 6),
              ],
              _IconBtn(
                  icon: Icons.casino_rounded,
                  label: 'Zar',
                  onTap: onDice),
              const SizedBox(width: 6),
              _IconBtn(
                  icon: Icons.gavel_rounded,
                  label: 'Hakem',
                  onTap: onChat),
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

  const _IconBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 22),
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

// ── Rating dialog ─────────────────────────────────────────

class _RatingDialog extends StatelessWidget {
  final AppStrings s;
  const _RatingDialog({required this.s});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
          Text(
            s.ratingQuestion,
            style: TextStyle(color: context.appTextMain, fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s.ratingSubtext,
            style: TextStyle(color: context.appSubtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.later, style: TextStyle(color: context.appHint)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.rate,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
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
        _ResultCard(session: widget.session),
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
    final winner = sorted.first;
    final roundCount = widget.session.rounds.where((r) => r.label != 'Ceza').length;

    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(s.gameSummaryTitle,
          style: TextStyle(color: context.appTextMain, fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  s.won(winner.name),
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
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
          Text(s.roundsPlayedText(roundCount),
              style: TextStyle(color: context.appHint, fontSize: 12)),
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

class _ResultCard extends StatelessWidget {
  final GameSession session;
  const _ResultCard({required this.session});

  // Parchment / adisyon palette — all hardcoded for screenshot isolation
  static const _bg = Color(0xFFF5F0E8);
  static const _border = Color(0xFF8B7355);
  static const _ink = Color(0xFF1C1209);
  static const _inkMid = Color(0xFF6B5840);
  static const _inkFaint = Color(0xFFAA9C85);
  static const _red = Color(0xFFAA1818);
  static const _green = Color(0xFF1A6B3A);
  static const _headerBg = Color(0xFFEDE4D0);
  static const _stripeBg = Color(0xFFF0EAD8);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${p(now.day)}.${p(now.month)}.${now.year}';
    final timeStr = '${p(now.hour)}:${p(now.minute)}';

    final n = session.players.length;
    final cols = _buildColumns(session, List.filled(n < 2 ? 2 : n, _ink));

    // Separate el rounds and ceza rounds
    final elRounds = <(int, RoundScore)>[];
    final cezaDeltas = <String, int>{};
    int elNo = 0;
    for (final r in session.rounds) {
      if (r.label == 'Ceza') {
        for (final e in r.deltas.entries) {
          cezaDeltas[e.key] = (cezaDeltas[e.key] ?? 0) + e.value;
        }
      } else {
        elNo++;
        elRounds.add((elNo, r));
      }
    }
    final hasCeza = cezaDeltas.values.any((v) => v != 0);

    final sorted = [...cols]
      ..sort((a, b) =>
          a.totalFor(session.players).compareTo(b.totalFor(session.players)));
    final winner = sorted.first;
    final gameLabel =
        session.gameType == GameType.okey101 ? 'Okey 101' : 'Klasik Okey';

    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        color: _bg,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 340,
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: _border, width: 1.5)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // ── Header ──
              Container(
                color: _headerBg,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: Column(children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.casino_rounded, color: _inkMid, size: 14),
                    SizedBox(width: 7),
                    Text('OKEYMATİK',
                        style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5)),
                  ]),
                  const SizedBox(height: 5),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tarih: $dateStr',
                            style: TextStyle(fontFamily: 'Caveat',
                                color: _inkMid, fontSize: 13)),
                        Text('Saat: $timeStr',
                            style: TextStyle(fontFamily: 'Caveat',
                                color: _inkMid, fontSize: 13)),
                      ]),
                ]),
              ),
              _hRule(),

              // ── Game type ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text('— $gameLabel —',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Caveat',
                        color: _ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5)),
              ),
              _hRule(),

              // ── Player summary ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Text('OYUNCULAR / TAKIMLAR',
                            style: TextStyle(fontFamily: 'Caveat',
                                color: _inkMid,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2))),
                    Text('TOPLAM',
                        style: TextStyle(fontFamily: 'Caveat',
                            color: _inkMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                  ]),
                  const SizedBox(height: 4),
                  ...sorted.asMap().entries.map((e) {
                    final rank = e.key + 1;
                    final col = e.value;
                    final total = col.totalFor(session.players);
                    final isWinner = col.name == winner.name;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        _RankCircle(rank: rank),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Row(children: [
                            Text(col.name,
                                style: TextStyle(fontFamily: 'Caveat',
                                    color: isWinner ? _ink : _inkMid,
                                    fontSize: 15,
                                    fontWeight: isWinner
                                        ? FontWeight.w700
                                        : FontWeight.w400)),
                            const Expanded(
                                child: Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 4),
                              child: CustomPaint(
                                  painter: _DotLinePainter(color: _inkFaint),
                                  child: SizedBox(height: 16)),
                            )),
                          ]),
                        ),
                        Text(total >= 0 ? '+$total' : '$total',
                            style: TextStyle(fontFamily: 'Caveat',
                                color: total < 0 ? _red : _green,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ]),
                    );
                  }),
                ]),
              ),
              _hRule(),

              // ── Column header ──
              _tableRow(
                label: 'ELLER',
                cells: cols
                    .map((c) => _shortName(c.name))
                    .toList(),
                isHeader: true,
              ),

              // ── El rows ──
              ...elRounds.asMap().entries.map((e) {
                final idx = e.key;
                final (no, round) = e.value;
                return _tableRow(
                  label: 'El $no',
                  cells: cols
                      .map((c) {
                        final d = c.deltaFor(round);
                        return d == 0 ? '—' : (d > 0 ? '+$d' : '$d');
                      })
                      .toList(),
                  deltas: cols.map((c) => c.deltaFor(round)).toList(),
                  stripe: idx.isOdd,
                );
              }),

              // ── Ceza total ──
              if (hasCeza) ...[
                _hRule(),
                _tableRow(
                  label: 'CEZA',
                  cells: cols
                      .map((c) {
                        final v = c.playerIds
                            .fold(0, (s, id) => s + (cezaDeltas[id] ?? 0));
                        return v == 0 ? '—' : '$v';
                      })
                      .toList(),
                  deltas: cols
                      .map((c) => c.playerIds
                          .fold(0, (s, id) => s + (cezaDeltas[id] ?? 0)))
                      .toList(),
                  isBold: true,
                ),
              ],
              _hRule(),

              // ── Final score ──
              _tableRow(
                label: 'FİNAL',
                cells: cols.map((c) {
                  final t = c.totalFor(session.players);
                  return t >= 0 ? '+$t' : '$t';
                }).toList(),
                deltas: cols
                    .map((c) => c.totalFor(session.players))
                    .toList(),
                isBold: true,
                isHeader: true,
              ),
              _hRule(),

              // ── Winner ──
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 1.2),
                ),
                child: Column(children: [
                  const Text('— KAZANAN —',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _inkMid,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('👑 ', style: TextStyle(fontSize: 18)),
                    Text(winner.name,
                        style: TextStyle(fontFamily: 'Caveat',
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic)),
                  ]),
                ]),
              ),

              // ── Footer ──
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                child: Column(children: [
                  const Divider(color: _inkFaint, height: 1),
                  const SizedBox(height: 5),
                  Text(
                    'Okeymatik  ·  Masa çevresinde skor & kural asistanı',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Caveat',
                        color: _inkFaint,
                        fontSize: 12,
                        letterSpacing: 0.5),
                  ),
                  ]),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hRule() =>
      Container(height: 1, color: _inkFaint.withValues(alpha: 0.5));

  Widget _tableRow({
    required String label,
    required List<String> cells,
    List<int>? deltas,
    bool isHeader = false,
    bool isBold = false,
    bool stripe = false,
  }) {
    return Container(
      color: isHeader
          ? _headerBg
          : stripe
              ? _stripeBg
              : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: TextStyle(fontFamily: 'Caveat',
                  color: isHeader || isBold ? _inkMid : _ink,
                  fontSize: isHeader ? 13 : 14,
                  fontWeight: isHeader || isBold ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isHeader ? 0.8 : 0)),
        ),
        ...cells.asMap().entries.map((e) {
          final i = e.key;
          final val = e.value;
          final delta = deltas != null && i < deltas.length ? deltas[i] : 0;
          final textColor = isHeader
              ? _inkMid
              : val == '—'
                  ? _inkFaint
                  : delta < 0
                      ? _red
                      : delta > 0
                          ? _green
                          : _ink;
          return Expanded(
            child: Text(val,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Caveat',
                    color: textColor,
                    fontSize: isHeader ? 13 : 14,
                    fontWeight: isHeader || isBold ? FontWeight.w700 : FontWeight.w500)),
          );
        }),
      ]),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    final first = parts.first;
    return first.length > 6 ? first.substring(0, 6) : first;
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
                  backgroundColor: AppColors.primary,
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
                Text(s.liveActive,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.roomCodeLabel,
                style: TextStyle(color: context.appHint, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
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
            const SizedBox(height: 8),
            Text(s.shareRoomCode, style: TextStyle(color: context.appHint, fontSize: 12)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.penalty),
                label: Text(s.stopLive, style: const TextStyle(color: AppColors.penalty)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.penalty.withValues(alpha: 0.4)),
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

class _RankCircle extends StatelessWidget {
  final int rank;
  const _RankCircle({required this.rank});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6B5840);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text('$rank',
            style: TextStyle(fontFamily: 'Caveat',
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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
