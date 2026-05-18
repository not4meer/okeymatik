import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'sheet_widgets.dart';

class Okey101RoundSheet extends ConsumerStatefulWidget {
  const Okey101RoundSheet({super.key});

  @override
  ConsumerState<Okey101RoundSheet> createState() => _Okey101RoundSheetState();
}

class _Okey101RoundSheetState extends ConsumerState<Okey101RoundSheet> {
  String? _activeId;
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, FocusNode> _nodes = {};

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _init(List<Player> players) {
    for (final p in players) {
      _ctrls.putIfAbsent(p.id, () => TextEditingController());
      _nodes.putIfAbsent(p.id, () => FocusNode());
    }
  }

  int? _scoreFor(String id) => int.tryParse(_ctrls[id]?.text.trim() ?? '');

  void _setQuick(String id, int value) {
    setState(() {
      final ctrl = _ctrls[id];
      if (ctrl == null) return;
      ctrl.text = value.toString();
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    });
  }

  RoundScore _buildRound(GameSession session) {
    final isPaired = session.gameMode == GameMode.paired && session.pairs.length == 2;
    final deltas = <String, int>{};
    if (isPaired) {
      for (final pair in session.pairs) {
        final score = _scoreFor(session.players[pair[0]].id) ?? 0;
        deltas[session.players[pair[0]].id] = score;
      }
    } else {
      for (final p in session.players) {
        deltas[p.id] = _scoreFor(p.id) ?? 0;
      }
    }
    String? winnerId;
    if (deltas.isNotEmpty) {
      final minEntry = deltas.entries.reduce((a, b) => a.value < b.value ? a : b);
      if (minEntry.value < 0) winnerId = minEntry.key;
    }
    return RoundScore(deltas: deltas, winnerId: winnerId, label: '');
  }

  bool get _canSave => _ctrls.values.any((c) => c.text.trim().isNotEmpty);

  void _submit() => Navigator.pop(context, _buildRound(ref.read(gameSessionProvider)!));

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider)!;
    final s = ref.watch(stringsProvider);
    _init(session.players);

    final isPaired = session.gameMode == GameMode.paired && session.pairs.length == 2;

    final List<({String id, String name, Color color})> tiles;
    if (isPaired) {
      tiles = [
        for (int i = 0; i < session.pairs.length; i++)
          () {
            final pair = session.pairs[i];
            final first = session.players[pair[0]];
            String name = first.name;
            if (name.endsWith(' 1') || name.endsWith(' 2')) {
              name = name.substring(0, name.length - 2).trim();
            }
            return (id: first.id, name: name, color: _colors[pair[0] % _colors.length]);
          }(),
      ];
    } else {
      tiles = [
        for (int i = 0; i < session.players.length; i++)
          (
            id: session.players[i].id,
            name: session.players[i].name,
            color: _colors[i % _colors.length],
          ),
      ];
    }

    final activeId = _activeId;
    final activeTile = activeId != null
        ? tiles.where((t) => t.id == activeId).firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SheetHandle(),
                        const SizedBox(height: 14),
                        Text(
                          s.roundResultOkey101,
                          style: TextStyle(
                            color: context.appTextMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player / team tiles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: tiles.map((tile) {
                        final score = _scoreFor(tile.id);
                        final isActive = tile.id == activeId;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeId = tile.id);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _nodes[tile.id]?.requestFocus();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? tile.color.withValues(alpha: 0.15)
                                      : context.appCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isActive ? tile.color : context.appMuted,
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      tile.name,
                                      style: TextStyle(
                                        color: isActive
                                            ? tile.color
                                            : context.appSubtext,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      score == null
                                          ? '—'
                                          : score < 0
                                              ? '$score'
                                              : '+$score',
                                      style: TextStyle(
                                        color: score == null
                                            ? context.appDim
                                            : score < 0
                                                ? AppColors.siler
                                                : AppColors.penalty,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score input + quick buttons
                  if (activeTile != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _ctrls[activeTile.id],
                            focusNode: _nodes[activeTile.id],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: activeTile.color,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle:
                                  TextStyle(color: context.appDim, fontSize: 40),
                              filled: true,
                              fillColor: context.appCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: activeTile.color, width: 2),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [-101, -202, -404, -808].map((v) {
                              final current = _scoreFor(activeTile.id);
                              final sel = current == v;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _setQuick(activeTile.id, v),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.siler.withValues(alpha: 0.2)
                                          : context.appCard,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.siler
                                            : context.appMuted,
                                      ),
                                    ),
                                    child: Text(
                                      '$v',
                                      style: TextStyle(
                                        color: sel
                                            ? AppColors.siler
                                            : context.appHint,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: ElevatedButton(
                      onPressed: _canSave ? _submit : null,
                      child: Text(s.save),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

