import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'score_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final GameType gameType;
  const SetupScreen({super.key, required this.gameType});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _playerCtrls = List.generate(4, (_) => TextEditingController());
  final _teamCtrls = List.generate(2, (_) => TextEditingController());
  final _roundCtrl = TextEditingController();
  GameMode _mode = GameMode.solo;

  @override
  void dispose() {
    for (final c in _playerCtrls) {
      c.dispose();
    }
    for (final c in _teamCtrls) {
      c.dispose();
    }
    _roundCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final is101 = widget.gameType == GameType.okey101;
    final isPaired = is101 && _mode == GameMode.paired;

    return Scaffold(
      appBar: AppBar(title: Text(is101 ? 'Okey 101' : s.classicOkey)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (is101) ...[
                _Label(s.gameMode),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Chip(
                        label: s.soloMode,
                        selected: _mode == GameMode.solo,
                        onTap: () => setState(() => _mode = GameMode.solo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Chip(
                        label: s.pairedMode,
                        selected: _mode == GameMode.paired,
                        onTap: () => setState(() => _mode = GameMode.paired),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _Label(isPaired ? s.teamNamesLabel : s.playerNamesLabel),
              const SizedBox(height: 12),
              Expanded(
                child: isPaired ? _teamInputs(s) : _playerInputs(s),
              ),
              const SizedBox(height: 16),
              _Label(s.totalRoundsLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _roundCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: s.roundsHint,
                  prefixIcon:
                      Icon(Icons.loop_rounded, color: context.appHint, size: 20),
                ),
                style: TextStyle(fontSize: 16, color: context.appTextMain),
              ),
              const SizedBox(height: 16),
              // GestureDetector — ElevatedButton bazı iOS/keyboard senaryolarında
              // tıklamayı yakalamıyor, complaint_sheet ile aynı pattern kullanılıyor
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _start(s),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.startGame,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerInputs(s) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63)
    ];
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => TextField(
        controller: _playerCtrls[i],
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          hintText: s.playerHints[i],
          prefixIcon: Icon(Icons.person_outline, color: colors[i], size: 20),
        ),
        style: TextStyle(fontSize: 16, color: ctx.appTextMain),
      ),
    );
  }

  Widget _teamInputs(s) {
    const colors = [Color(0xFF4CAF50), Color(0xFF2196F3)];
    return ListView.separated(
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => TextField(
        controller: _teamCtrls[i],
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          hintText: s.teamHints[i],
          prefixIcon: Icon(Icons.group_outlined, color: colors[i], size: 20),
        ),
        style: TextStyle(fontSize: 16, color: ctx.appTextMain),
      ),
    );
  }

  void _start(s) {
    final List<String> names;
    if (_mode == GameMode.paired) {
      final a = _teamCtrls[0].text.trim().isEmpty
          ? s.defaultTeamA
          : _teamCtrls[0].text.trim();
      final b = _teamCtrls[1].text.trim().isEmpty
          ? s.defaultTeamB
          : _teamCtrls[1].text.trim();
      names = ['$a 1', '$b 1', '$a 2', '$b 2'];
    } else {
      names = _playerCtrls.map((c) => c.text).toList();
    }

    final pairs = _mode == GameMode.paired ? [[0, 2], [1, 3]] : <List<int>>[];
    final totalRounds = int.tryParse(_roundCtrl.text);

    ref.read(gameSessionProvider.notifier).startGame(
          gameType: widget.gameType,
          gameMode: _mode,
          playerNames: names,
          pairs: pairs,
          totalRounds: totalRounds,
        );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ScoreScreen()),
      (r) => r.isFirst,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            color: context.appHint,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? context.appPrimary.withValues(alpha: 0.2)
              : context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? context.appPrimary : context.appMuted, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? context.appPrimary : context.appSubtext,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
