import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../engines/okey101_engine.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../providers/game_provider.dart';
import 'sheet_widgets.dart';

class Okey101RoundSheet extends ConsumerStatefulWidget {
  const Okey101RoundSheet({super.key});

  @override
  ConsumerState<Okey101RoundSheet> createState() => _Okey101RoundSheetState();
}

class _Okey101RoundSheetState extends ConsumerState<Okey101RoundSheet> {
  String? _winnerId;
  Okey101FinishType _finishType = Okey101FinishType.normal;
  final Map<String, _PlayerEntry> _data = {};

  final _engine = Okey101Engine();

  void _initData(List<Player> players) {
    for (final p in players) {
      _data.putIfAbsent(p.id, () => _PlayerEntry());
    }
  }

  bool get _isElden =>
      _finishType == Okey101FinishType.elden ||
      _finishType == Okey101FinishType.eldenOkey;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider)!;
    final players = session.players;
    _initData(players);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  SheetHandle(),
                  SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'El Sonucu - Okey 101',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SheetSectionLabel('Biten Oyuncu'),
                  const SizedBox(height: 10),
                  SheetPlayerGrid(
                    players: players,
                    selectedId: _winnerId,
                    onSelect: (id) => setState(() => _winnerId = id),
                  ),
                  const SizedBox(height: 20),

                  const SheetSectionLabel('Bitis Turu'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Okey101FinishType.values.map((t) {
                      return SheetTypeChip(
                        label: t.label,
                        selected: _finishType == t,
                        onTap: () => setState(() => _finishType = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Per-player inputs (skip in elden mode)
                  if (!_isElden && _winnerId != null) ...[
                    const SheetSectionLabel('Oyuncu Durumlari'),
                    const SizedBox(height: 12),
                    ...players
                        .where((p) => p.id != _winnerId)
                        .map((p) => _PlayerCard(
                              player: p,
                              entry: _data[p.id]!,
                              onChanged: (e) => setState(() => _data[p.id] = e),
                            )),
                  ],

                  // Winner islek penalty
                  if (_winnerId != null) ...[
                    const SizedBox(height: 8),
                    SheetCheckRow(
                      label: 'Biten oyuncu islek tas atti (+101)',
                      value: _data[_winnerId!]?.islikCeza ?? false,
                      onChanged: (v) => setState(() {
                        _data[_winnerId!] =
                            (_data[_winnerId!] ?? _PlayerEntry()).copyWith(islikCeza: v);
                      }),
                    ),
                  ],

                  // Elden: non-winner islek checkboxes
                  if (_isElden && _winnerId != null) ...[
                    const SizedBox(height: 4),
                    ...players.where((p) => p.id != _winnerId).map((p) => SheetCheckRow(
                          label: '${p.name} islek tas atti (+101)',
                          value: _data[p.id]!.islikCeza,
                          onChanged: (v) => setState(() {
                            _data[p.id] = _data[p.id]!.copyWith(islikCeza: v);
                          }),
                        )),
                  ],

                  // Elden warning
                  if (_isElden) ...[
                    const SizedBox(height: 12),
                    _EldenBanner(type: _finishType),
                  ],

                  // Live preview
                  if (_winnerId != null) ...[
                    const SizedBox(height: 16),
                    SheetPreviewBox(
                      round: _buildRound(session),
                      players: players,
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _winnerId == null ? null : _submit,
                    child: const Text('Kaydet'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  RoundScore _buildRound(GameSession session) {
    final playerData = <String, PlayerRoundData101>{};
    for (final p in session.players) {
      final d = _data[p.id] ?? _PlayerEntry();
      playerData[p.id] = PlayerRoundData101(
        remainingTiles: d.tiles,
        elAcmadi: d.elAcmadi,
        ciftActi: d.ciftActi,
        islikCeza: d.islikCeza,
        hasOkeyInHand: d.hasOkeyInHand,
      );
    }
    return _engine.calculate({
      'winnerId': _winnerId!,
      'finishType': _finishType,
      'playerData': playerData,
      'partnerId': session.partnerOf(_winnerId!),
    }, session.players);
  }

  void _submit() {
    final round = _buildRound(ref.read(gameSessionProvider)!);
    Navigator.pop(context, round);
  }
}

// ── Local state ─────────────────────────────────────────

class _PlayerEntry {
  final int tiles;
  final bool elAcmadi;
  final bool ciftActi;
  final bool islikCeza;
  final bool hasOkeyInHand;

  const _PlayerEntry({
    this.tiles = 0,
    this.elAcmadi = false,
    this.ciftActi = false,
    this.islikCeza = false,
    this.hasOkeyInHand = false,
  });

  _PlayerEntry copyWith({
    int? tiles,
    bool? elAcmadi,
    bool? ciftActi,
    bool? islikCeza,
    bool? hasOkeyInHand,
  }) =>
      _PlayerEntry(
        tiles: tiles ?? this.tiles,
        elAcmadi: elAcmadi ?? this.elAcmadi,
        ciftActi: ciftActi ?? this.ciftActi,
        islikCeza: islikCeza ?? this.islikCeza,
        hasOkeyInHand: hasOkeyInHand ?? this.hasOkeyInHand,
      );
}

// ── Player card ──────────────────────────────────────────

class _PlayerCard extends StatefulWidget {
  final Player player;
  final _PlayerEntry entry;
  final void Function(_PlayerEntry) onChanged;

  const _PlayerCard({
    required this.player,
    required this.entry,
    required this.onChanged,
  });

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  late final TextEditingController _tileCtrl;

  @override
  void initState() {
    super.initState();
    _tileCtrl = TextEditingController(
      text: widget.entry.tiles > 0 ? widget.entry.tiles.toString() : '',
    );
  }

  @override
  void dispose() {
    _tileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SheetCheckRow(
            label: 'El acmadi (+202)',
            value: e.elAcmadi,
            onChanged: (v) {
              if (v) _tileCtrl.clear();
              widget.onChanged(e.copyWith(elAcmadi: v, tiles: 0));
            },
          ),
          if (!e.elAcmadi) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Kalan tas:',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _tileCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      hintText: '0',
                    ),
                    onChanged: (v) =>
                        widget.onChanged(e.copyWith(tiles: int.tryParse(v) ?? 0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SheetCheckRow(
              label: 'Cift acti (kalan x2)',
              value: e.ciftActi,
              onChanged: (v) => widget.onChanged(e.copyWith(ciftActi: v)),
            ),
            SheetCheckRow(
              label: 'Elinde okey var (+101)',
              value: e.hasOkeyInHand,
              onChanged: (v) => widget.onChanged(e.copyWith(hasOkeyInHand: v)),
            ),
          ],
          SheetCheckRow(
            label: 'Islek tas atti (+101)',
            value: e.islikCeza,
            onChanged: (v) => widget.onChanged(e.copyWith(islikCeza: v)),
          ),
        ],
      ),
    );
  }
}

// ── Elden banner ─────────────────────────────────────────

class _EldenBanner extends StatelessWidget {
  final Okey101FinishType type;
  const _EldenBanner({required this.type});

  @override
  Widget build(BuildContext context) {
    final msg = type == Okey101FinishType.eldenOkey
        ? 'Elden+Okey: Bitiren -404 siler, diger oyuncular 808 ceza alir.'
        : 'Elden Bitme: Bitiren -202 siler, diger oyuncular 404 ceza alir.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.penalty.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.penalty.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.penalty, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: AppColors.penalty, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
