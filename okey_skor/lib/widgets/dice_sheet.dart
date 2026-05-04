import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'sheet_widgets.dart';

class DiceSheet extends StatefulWidget {
  const DiceSheet({super.key});

  @override
  State<DiceSheet> createState() => _DiceSheetState();
}

class _DiceSheetState extends State<DiceSheet> {
  int _value = 1;
  bool _rolling = false;
  final _rng = Random();

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    for (int i = 0; i < 12; i++) {
      await Future.delayed(Duration(milliseconds: 40 + i * 8));
      if (!mounted) return;
      setState(() => _value = _rng.nextInt(6) + 1);
    }
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          const Text(
            'Zar At',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _roll,
            child: AnimatedScale(
              scale: _rolling ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 80),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _rolling ? AppColors.primary.withOpacity(0.6) : Colors.white12,
                    width: 2,
                  ),
                  boxShadow: _rolling
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]
                      : [],
                ),
                child: Center(
                  child: _DiceFace(value: _value, rolling: _rolling),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _rolling ? 'Atılıyor...' : 'Zara dokunarak at',
            style: TextStyle(
              color: _rolling ? AppColors.primary : Colors.white38,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _rolling ? null : _roll,
            icon: const Icon(Icons.casino_rounded, size: 20),
            label: const Text('Tekrar At'),
          ),
        ],
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int value;
  final bool rolling;

  const _DiceFace({required this.value, required this.rolling});

  @override
  Widget build(BuildContext context) {
    final color = rolling ? AppColors.primary : Colors.white;
    return Text(
      _emoji(value),
      style: TextStyle(fontSize: 72, color: color),
    );
  }

  String _emoji(int v) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[(v - 1).clamp(0, 5)];
  }
}
