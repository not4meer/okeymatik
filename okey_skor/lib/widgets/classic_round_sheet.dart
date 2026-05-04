import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../engines/classic_okey_engine.dart';
import '../models/game_enums.dart';
import '../models/round.dart';
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

  final _engine = ClassicOkeyEngine();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider)!;
    final players = session.players;

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

          const SheetSectionLabel('Biten Oyuncu'),
          const SizedBox(height: 10),
          SheetPlayerGrid(
            players: players,
            selectedId: _winnerId,
            onSelect: (id) => setState(() => _winnerId = id),
          ),
          const SizedBox(height: 20),

          const SheetSectionLabel('Bitiş Türü'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClassicFinishType.values.map((t) {
              return SheetTypeChip(
                label: t.label,
                selected: _finishType == t,
                onTap: () => setState(() => _finishType = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          SheetCheckRow(
            label: 'Gösterge Gösterildi (+1 diğerlerine)',
            value: _gosterge,
            onChanged: (v) => setState(() => _gosterge = v),
          ),

          if (_winnerId != null) ...[
            const SizedBox(height: 14),
            SheetPreviewBox(
              round: _buildRound(players),
              players: players,
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _winnerId == null ? null : _submit,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  RoundScore _buildRound(List players) {
    return _engine.calculate({
      'winnerId': _winnerId!,
      'finishType': _finishType,
      'gosterge': _gosterge,
    }, players.cast());
  }

  void _submit() {
    final session = ref.read(gameSessionProvider)!;
    final round = _buildRound(session.players);
    Navigator.pop(context, round);
  }
}
