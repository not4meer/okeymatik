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
  void _undo() => setState(() { if (_history.isNotEmpty) _history.removeLast(); });
  void _reset() => setState(() => _history.clear());

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final status = _status;

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
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Taş Hesaplayıcı',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
                onPressed: _reset,
                tooltip: 'Sıfırla',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: status.color.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Text(
                  total.toString(),
                  style: TextStyle(
                    color: status.color,
                    fontSize: 60,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tile buttons 1–13
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: const TextStyle(
                        color: Colors.white,
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
                side: const BorderSide(color: Colors.white12),
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

enum _Status {
  cantOpen,
  canOpen,
  siler;

  String get label {
    switch (this) {
      case _Status.cantOpen: return 'EL AÇMAZ';
      case _Status.canOpen:  return 'EL AÇAR';
      case _Status.siler:    return 'SİLER';
    }
  }

  Color get color {
    switch (this) {
      case _Status.cantOpen: return AppColors.penalty;
      case _Status.canOpen:  return AppColors.siler;
      case _Status.siler:    return const Color(0xFFFFAB40);
    }
  }
}
