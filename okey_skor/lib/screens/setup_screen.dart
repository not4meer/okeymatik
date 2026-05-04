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
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _roundCtrl = TextEditingController();
  GameMode _mode = GameMode.solo;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    _roundCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final is101 = widget.gameType == GameType.okey101;

    return Scaffold(
      appBar: AppBar(title: Text(is101 ? 'Okey 101' : 'Klasik Okey')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Mode toggle — only for 101
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
              // Player names
              const _Label('Oyuncu İsimleri'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final isPaired = is101 && _mode == GameMode.paired;
                    final hints = isPaired
                        ? ['Oyuncu 1 (Takım A)', 'Oyuncu 2 (Takım B)', 'Oyuncu 3 (Takım A)', 'Oyuncu 4 (Takım B)']
                        : ['Oyuncu 1', 'Oyuncu 2', 'Oyuncu 3', 'Oyuncu 4'];
                    const colors = [Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFFE91E63)];
                    return TextField(
                      controller: _controllers[i],
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        hintText: hints[i],
                        prefixIcon: Icon(Icons.person_outline, color: colors[i], size: 20),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    );
                  },
                ),
              ),
              // Round count
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
              if (is101 && _mode == GameMode.paired)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Takım A: Oyuncu 1 & 3  ·  Takım B: Oyuncu 2 & 4',
                    style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
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

  void _start() {
    final names = _controllers.map((c) => c.text).toList();
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
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
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
