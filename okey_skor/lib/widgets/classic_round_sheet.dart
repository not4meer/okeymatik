import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../engines/classic_okey_engine.dart';
import '../models/round.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'sheet_widgets.dart';

class ClassicRoundSheet extends ConsumerStatefulWidget {
  const ClassicRoundSheet({super.key});

  @override
  ConsumerState<ClassicRoundSheet> createState() => _ClassicRoundSheetState();
}

class _ClassicRoundSheetState extends ConsumerState<ClassicRoundSheet> {
  String? _winnerId;
  int _penalty = 2;
  bool _gosterge = false;

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  static const _penalties = [2, 4, 6, 8];

  final _engine = ClassicOkeyEngine();

  RoundScore _buildRound(List<Player> players) {
    return _engine.calculate({
      'winnerId': _winnerId!,
      'penalty': _penalty,
      'gosterge': _gosterge,
    }, players);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider)!;
    final s = ref.watch(stringsProvider);
    final players = session.players;
    final preview = _winnerId != null ? _buildRound(players) : null;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text(
            s.roundResultClassic,
            style: TextStyle(
                color: context.appTextMain, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Player tiles
          Row(
            children: players.asMap().entries.map((e) {
              final p = e.value;
              final color = _colors[e.key % _colors.length];
              final isWinner = p.id == _winnerId;
              final delta = preview?.deltas[p.id];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _winnerId = isWinner ? null : p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : context.appCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isWinner ? AppColors.primary : color.withValues(alpha: 0.25),
                          width: isWinner ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                                color: color, fontSize: 11, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 22,
                            child: delta != null
                                ? Text(
                                    delta == 0 ? '—' : '$delta',
                                    style: TextStyle(
                                      color: delta < 0 ? AppColors.penalty : context.appHint,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isWinner ? '★ ${s.winnerLabel}' : '${s.winnerLabel}?',
                            style: TextStyle(
                              color: isWinner ? AppColors.primary : context.appDim,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Penalty buttons
          SheetSectionLabel(s.finishScore),
          const SizedBox(height: 10),
          Row(
            children: _penalties.map((p) {
              final sel = _penalty == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _penalty = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.penalty.withValues(alpha: 0.15) : context.appCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppColors.penalty : context.appMuted,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '-$p',
                      style: TextStyle(
                        color: sel ? AppColors.penalty : context.appSubtext,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          SheetCheckRow(
            label: s.gosterge,
            value: _gosterge,
            onChanged: (v) => setState(() => _gosterge = v),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _winnerId == null
                ? null
                : () => Navigator.pop(context, _buildRound(players)),
            child: Text(s.save),
          ),
        ],
      ),
    );
  }
}
