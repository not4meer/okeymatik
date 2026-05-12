import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'sheet_widgets.dart';

class TileCalculatorSheet extends StatefulWidget {
  const TileCalculatorSheet({super.key});

  @override
  State<TileCalculatorSheet> createState() => _TileCalculatorSheetState();
}

class _TileCalculatorSheetState extends State<TileCalculatorSheet> {
  final List<int> _history = [];

  int get _total => _history.fold(0, (s, v) => s + v);

  _Status get _status {
    final t = _total;
    if (t < 101) return _Status.cantOpen;
    if (t < 151) return _Status.canOpen;
    return _Status.siler;
  }

  void _add(int val) => setState(() => _history.add(val));
  void _undo() => setState(() {
        if (_history.isNotEmpty) _history.removeLast();
      });
  void _reset() => setState(() => _history.clear());

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final status = _status;

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
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Taş Hesaplayıcı',
                style: TextStyle(
                    color: context.appTextMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: context.appHint),
                onPressed: _reset,
                tooltip: 'Sıfırla',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: status.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                total > 0
                    ? _YanDisplay(total: total, color: status.color)
                    : Text(
                        '0',
                        style: TextStyle(
                          color: status.color,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  '$total puan',
                  style: TextStyle(
                    color: status.color.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 13,
            itemBuilder: (_, i) {
              final val = i + 1;
              return GestureDetector(
                onTap: () => _add(val),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.appMuted),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: TextStyle(
                        color: context.appTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.penalty,
                side: BorderSide(color: context.appMuted),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _history.isEmpty ? null : _undo,
              icon: const Icon(Icons.backspace_outlined, size: 18),
              label: const Text('Geri Al'),
            ),
          ),
        ],
      ),
    );
  }
}

class _YanDisplay extends StatelessWidget {
  final int total;
  final Color color;
  const _YanDisplay({required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final q = total ~/ 3;
    final r = total % 3;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$q ',
            style: TextStyle(
              color: color,
              fontSize: 52,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          TextSpan(
            text: 'yan',
            style: TextStyle(
              color: color.withValues(alpha: 0.65),
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          if (r > 0)
            TextSpan(
              text: ' $r',
              style: TextStyle(
                color: color,
                fontSize: 52,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

enum _Status {
  cantOpen,
  canOpen,
  siler;

  String get label {
    switch (this) {
      case _Status.cantOpen:
        return 'EL AÇMAZ';
      case _Status.canOpen:
        return 'EL AÇAR';
      case _Status.siler:
        return 'SİLER';
    }
  }

  Color get color {
    switch (this) {
      case _Status.cantOpen:
        return AppColors.penalty;
      case _Status.canOpen:
        return AppColors.siler;
      case _Status.siler:
        return const Color(0xFFFFAB40);
    }
  }
}
