import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../providers/game_provider.dart';
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
    for (final c in _playerCtrls) { c.dispose(); }
    for (final c in _teamCtrls) { c.dispose(); }
    _roundCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final is101 = widget.gameType == GameType.okey101;
    final isPaired = is101 && _mode == GameMode.paired;

    return Scaffold(
      appBar: AppBar(title: Text(is101 ? 'Okey 101' : 'Klasik Okey')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (is101) ...[
                const _Label('Oyun Modu'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Chip(
                        label: 'Tekli',
                        selected: _mode == GameMode.solo,
                        onTap: () => setState(() => _mode = GameMode.solo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Chip(
                        label: 'Eşli (2v2)',
                        selected: _mode == GameMode.paired,
                        onTap: () => setState(() => _mode = GameMode.paired),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _Label(isPaired ? 'Takım İsimleri' : 'Oyuncu İsimleri'),
              const SizedBox(height: 12),
              Expanded(
                child: isPaired ? _teamInputs() : _playerInputs(),
              ),
              const SizedBox(height: 16),
              const _Label('Tur Sayısı (isteğe bağlı)'),
              const SizedBox(height: 8),
              TextField(
                controller: _roundCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Boş bırakılabilir',
                  prefixIcon: Icon(Icons.loop_rounded, color: Colors.white38, size: 20),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _start, child: const Text('Oyunu Başlat')),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerInputs() {
    const colors = [Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFFE91E63)];
    const hints = ['Oyuncu 1', 'Oyuncu 2', 'Oyuncu 3', 'Oyuncu 4'];
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => TextField(
        controller: _playerCtrls[i],
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          hintText: hints[i],
          prefixIcon: Icon(Icons.person_outline, color: colors[i], size: 20),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _teamInputs() {
    const colors = [Color(0xFF4CAF50), Color(0xFF2196F3)];
    const hints = ['Takım A', 'Takım B'];
    return ListView.separated(
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => TextField(
        controller: _teamCtrls[i],
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          hintText: hints[i],
          prefixIcon: Icon(Icons.group_outlined, color: colors[i], size: 20),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  void _start() {
    final List<String> names;
    if (_mode == GameMode.paired) {
      final a = _teamCtrls[0].text.trim().isEmpty ? 'Takım A' : _teamCtrls[0].text.trim();
      final b = _teamCtrls[1].text.trim().isEmpty ? 'Takım B' : _teamCtrls[1].text.trim();
      // players[0,2] = Team A, players[1,3] = Team B
      // Suffix helps distinguish in winner picker
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
        style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
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
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.white12, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : Colors.white54,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
