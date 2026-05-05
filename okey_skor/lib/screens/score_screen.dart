import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(session.gameType == GameType.okey101 ? 'Okey 101' : 'Klasik Okey'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => _confirmEnd(context, ref),
        ),
        actions: [
          if (session.rounds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Son eli geri al',
              onPressed: () => _undo(context, ref),
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
              onEditRound: (i) => _editRound(context, ref, session, i),
            ),
          ),
          const Divider(height: 1),
          _PenaltyRow(
            session: session,
            colors: _playerColors,
            onPenalty: (id, amt) => ref.read(gameSessionProvider.notifier).addPenalty(id, amt),
          ),
          const Divider(height: 1),
          _BottomBar(
            session: session,
            hidden: hidden,
            onEnterScore: () => _addRound(context, ref, session.gameType),
            onDice: () => _openDice(context),
            onCalc: () => _openCalc(context),
            onChat: () => _openChat(context),
            onToggleHide: () => ref.read(scoresHiddenProvider.notifier).state = !hidden,
          ),
          const BannerAdWidget(),
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
        ref.read(gameSessionProvider.notifier).addRound(round);
        InterstitialAd.show(context);
      }
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

  void _undo(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Son eli geri al?', style: TextStyle(color: Colors.white)),
        content: const Text('Son elin skorları silinecek.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              ref.read(gameSessionProvider.notifier).undoLastRound();
              Navigator.pop(context);
            },
            child: const Text('Geri Al', style: TextStyle(color: AppColors.penalty)),
          ),
        ],
      ),
    );
  }

  void _confirmEnd(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Oyunu bitir?', style: TextStyle(color: Colors.white)),
        content: const Text('Skorlar kaydedilmeyecek.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bitir', style: TextStyle(color: AppColors.penalty)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      final session = ref.read(gameSessionProvider)!;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SummaryDialog(session: session),
      ).then((_) {
        if (!context.mounted) return;
        ref.read(scoresHiddenProvider.notifier).state = false;
        ref.read(gameSessionProvider.notifier).endGame();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      });
    });
  }
}

// ── Penalty row ──────────────────────────────────────────

class _PenaltyRow extends StatelessWidget {
  final GameSession session;
  final List<Color> colors;
  final void Function(String playerId, int amount) onPenalty;

  const _PenaltyRow({required this.session, required this.colors, required this.onPenalty});

  @override
  Widget build(BuildContext context) {
    final isPaired = session.gameMode == GameMode.paired && session.pairs.length == 2;

    Widget button(Player player, Color color) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => _showPenaltyDialog(context, player, color),
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
                    isPaired ? '${player.name} Ceza' : 'Ceza',
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
        return button(Player(id: first.id, name: name, totalScore: 0), color);
      }).toList();
    } else {
      buttons = session.players.asMap().entries.map((e) {
        return button(e.value, colors[e.key % colors.length]);
      }).toList();
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: buttons),
    );
  }

  Future<void> _showPenaltyDialog(BuildContext context, Player player, Color color) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '${player.name} — Ceza',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(vertical: 12)),
          onSubmitted: (v) => Navigator.pop(context, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0 && context.mounted) {
      onPenalty(player.id, amount);
    }
  }
}

// ── Display column (player or team) ──────────────────────

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
      // Strip " 1" / " 2" suffix added during setup
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
  final void Function(int index) onEditRound;

  const _RoundHistoryTable({
    required this.session,
    required this.hidden,
    required this.colors,
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
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: rounds.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz el girilmedi',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: rounds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (_, i) => _RoundRow(
                    elNo: elNos[i],
                    round: rounds[i],
                    columns: columns,
                    onEdit: () => onEditRound(i),
                  ),
                ),
        ),
        const Divider(height: 1, color: Colors.white10),
        _TotalRow(
          columns: columns,
          players: session.players,
          hidden: hidden,
          gameType: session.gameType,
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
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 58),
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
  final VoidCallback onEdit;

  const _RoundRow({
    required this.elNo,
    required this.round,
    required this.columns,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (elNo != null)
                  Text(
                    'El $elNo',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  round.label,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
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
                    : Colors.white24;
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
              color: Colors.white24,
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

  const _TotalRow({
    required this.columns,
    required this.players,
    required this.hidden,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 58,
            child: Text(
              'Toplam',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          ...columns.map((c) {
            final total = c.totalFor(players);
            Color scoreColor;
            if (hidden) {
              scoreColor = Colors.white38;
            } else if (gameType == GameType.okey101) {
              scoreColor = total < 0
                  ? AppColors.siler
                  : total >= 100
                      ? AppColors.penalty
                      : Colors.white;
            } else {
              scoreColor = total < 0 ? AppColors.siler : Colors.white;
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
          }),
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
  final VoidCallback onEnterScore;
  final VoidCallback onDice;
  final VoidCallback onCalc;
  final VoidCallback onChat;
  final VoidCallback onToggleHide;

  const _BottomBar({
    required this.session,
    required this.hidden,
    required this.onEnterScore,
    required this.onDice,
    required this.onCalc,
    required this.onChat,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    final roundCount = session.rounds.where((r) => r.label != 'Ceza').length;
    final totalRounds = session.totalRounds;
    final roundLabel = totalRounds != null ? 'El $roundCount / $totalRounds' : 'El $roundCount';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(roundLabel, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              const Spacer(),
              _IconBtn(
                icon: hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                onTap: onToggleHide,
                tooltip: hidden ? 'Skorları Göster' : 'Skorları Gizle',
              ),
              const SizedBox(width: 4),
              _IconBtn(icon: Icons.calculate_outlined, onTap: onCalc, tooltip: 'Taş Hesaplayıcı'),
              const SizedBox(width: 4),
              _IconBtn(icon: Icons.casino_outlined, onTap: onDice, tooltip: 'Zar At'),
              const SizedBox(width: 4),
              _IconBtn(icon: Icons.chat_bubble_outline_rounded, onTap: onChat, tooltip: 'Kural Asistanı'),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onEnterScore,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('El Ekle'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

// ── Game summary dialog ──────────────────────────────────

class _SummaryDialog extends StatelessWidget {
  final GameSession session;
  const _SummaryDialog({required this.session});

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = [...session.players]..sort((a, b) => a.totalScore.compareTo(b.totalScore));
    final winner = sorted.first;
    final roundCount = session.rounds.where((r) => r.label != 'Ceza').length;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Oyun Bitti', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
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
                  '${winner.name} Kazandı!',
                  style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((e) {
            final rank = e.key + 1;
            final p = e.value;
            final origIdx = session.players.indexOf(p);
            final color = _colors[origIdx % _colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 22, child: Text('$rank.', style: const TextStyle(color: Colors.white38, fontSize: 13))),
                  Expanded(
                    child: Text(p.name, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    p.totalScore.toString(),
                    style: TextStyle(
                      color: p.totalScore < 0 ? AppColors.siler : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text('$roundCount el oynandı', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ana Menüye Dön'),
        ),
      ],
    );
  }
}
