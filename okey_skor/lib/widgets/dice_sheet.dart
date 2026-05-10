import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import 'sheet_widgets.dart';

class DiceSheet extends ConsumerStatefulWidget {
  const DiceSheet({super.key});

  @override
  ConsumerState<DiceSheet> createState() => _DiceSheetState();
}

class _DiceSheetState extends ConsumerState<DiceSheet> {
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
    final s = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Text(
            s.diceTitle,
            style: TextStyle(
                color: context.appTextMain, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _roll,
            child: AnimatedScale(
              scale: _rolling ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 80),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _rolling
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : context.appMuted,
                    width: 2,
                  ),
                  boxShadow: _rolling
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _emoji(_value),
                    style: TextStyle(
                      fontSize: 60,
                      color: _rolling ? AppColors.primary : context.appTextMain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _rolling ? s.rolling : s.tapToRoll,
            style: TextStyle(
              color: _rolling ? AppColors.primary : context.appHint,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _rolling ? null : _roll,
            icon: const Icon(Icons.casino_rounded, size: 20),
            label: Text(s.rollAgain),
          ),
        ],
      ),
    );
  }

  String _emoji(int v) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[(v - 1).clamp(0, 5)];
  }
}
