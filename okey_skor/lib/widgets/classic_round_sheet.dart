import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../engines/classic_okey_engine.dart';
import '../models/game_enums.dart';
import '../models/round.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import 'sheet_widgets.dart';

class ClassicRoundSheet extends ConsumerStatefulWidget {
  const ClassicRoundSheet({super.key});

  @override
  ConsumerState<ClassicRoundSheet> createState() => _ClassicRoundSheetState();
}

class _ClassicRoundSheetState extends ConsumerState<ClassicRoundSheet> {
  String? _winnerId;
  ClassicFinishType _finishType = ClassicFinishType.normal;
  bool _gosterge = false;

  static const _colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  final _engine = ClassicOkeyEngine();

  RoundScore _buildRound(List<Player> players) {
    return _engine.calculate({
      'winnerId': _winnerId!,
      'finishType': _finishType,
      'gosterge': _gosterge,
    }, players);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider)!;
    final players = session.players;
    final preview = _winnerId != null ? _buildRound(players) : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          const Text(
            'El Sonucu — Klasik Okey',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Player tiles row — tap to select winner
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
                            : AppColors.card,
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
                                    delta == 0 ? '—' : delta > 0 ? '+$delta' : '$delta',
                                    style: TextStyle(
                                      color: delta < 0 ? AppColors.siler : AppColors.penalty,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : const SizedBox(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isWinner ? '★ Biten' : 'Biten?',
                            style: TextStyle(
                              color: isWinner ? AppColors.primary : Colors.white24,
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

          // Finish type
          const SheetSectionLabel('Bitiş Türü'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClassicFinishType.values
                .map((t) => SheetTypeChip(
                      label: t.label,
                      selected: _finishType == t,
                      onTap: () => setState(() => _finishType = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          SheetCheckRow(
            label: 'Gösterge taşı gösterildi (+1 ceza diğerlerine)',
            value: _gosterge,
            onChanged: (v) => setState(() => _gosterge = v),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _winnerId == null ? null : () => Navigator.pop(context, _buildRound(players)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
