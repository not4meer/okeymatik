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

class _DiceSheetState extends ConsumerState<DiceSheet>
    with TickerProviderStateMixin {
  int _value = 1;
  bool _rolling = false;
  final _rng = Random();

  late final AnimationController _shakeCtrl;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.22)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.22, end: 0.91)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 0.91, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 40),
    ]).animate(_bounceCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    _shakeCtrl.repeat(reverse: true);

    for (int i = 0; i < 14; i++) {
      await Future.delayed(Duration(milliseconds: 35 + i * 9));
      if (!mounted) return;
      setState(() => _value = _rng.nextInt(6) + 1);
    }

    _shakeCtrl.stop();
    _shakeCtrl.reset();
    if (!mounted) return;
    setState(() => _rolling = false);
    _bounceCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 14),
          Text(
            s.diceTitle,
            style: TextStyle(
                color: context.appTextMain,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          // Dice face
          GestureDetector(
            onTap: _roll,
            child: AnimatedBuilder(
              animation: Listenable.merge([_shakeCtrl, _bounceCtrl]),
              builder: (_, child) {
                final shake = _rolling
                    ? sin(_shakeCtrl.value * pi) * 0.28
                    : 0.0;
                final scale = _rolling ? 1.0 : _bounceAnim.value;
                return Transform.rotate(
                  angle: shake,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252040) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _rolling
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    width: _rolling ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                          alpha: _rolling ? 0.35 : 0.12),
                      blurRadius: _rolling ? 32 : 14,
                      spreadRadius: _rolling ? 4 : 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _DiceFace(
                    value: _value,
                    dotColor: _rolling
                        ? AppColors.primary
                        : (isDark
                            ? const Color(0xFFF0F4FF)
                            : const Color(0xFF0D1F3C)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _rolling ? s.rolling : s.tapToRoll,
              key: ValueKey(_rolling),
              style: TextStyle(
                color: _rolling ? AppColors.primary : context.appHint,
                fontSize: 13,
                fontWeight: _rolling ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _rolling ? null : _roll,
            icon: const Icon(Icons.casino_rounded, size: 20),
            label: Text(s.rollAgain),
          ),
        ],
      ),
    );
  }
}

// Widget-based dice face — no CustomPainter, no pixel issues
class _DiceFace extends StatelessWidget {
  final int value;
  final Color dotColor;

  const _DiceFace({required this.value, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final s = constraints.maxWidth;
      final d = s * 0.24; // dot diameter
      final q = s * 0.15; // edge offset

      Widget dot() => Container(
            width: d,
            height: d,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          );

      Widget at(double x, double y) => Positioned(
            left: x - d / 2,
            top: y - d / 2,
            child: dot(),
          );

      final m = s / 2;
      final r = s - q;

      final positioned = switch (value) {
        1 => [at(m, m)],
        2 => [at(r, q), at(q, r)],
        3 => [at(r, q), at(m, m), at(q, r)],
        4 => [at(q, q), at(r, q), at(q, r), at(r, r)],
        5 => [at(q, q), at(r, q), at(m, m), at(q, r), at(r, r)],
        6 => [at(q, q), at(q, m), at(q, r), at(r, q), at(r, m), at(r, r)],
        _ => <Widget>[],
      };

      return Stack(children: positioned);
    });
  }
}
