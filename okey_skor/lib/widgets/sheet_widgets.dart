// Shared widgets used by both Classic and Okey101 round entry sheets
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/round.dart';

class SheetSectionLabel extends StatelessWidget {
  final String text;
  const SheetSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      );
}

class SheetPlayerGrid extends StatelessWidget {
  final List players;
  final String? selectedId;
  final void Function(String) onSelect;

  const SheetPlayerGrid({
    super.key,
    required this.players,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
    ];
    return Row(
      children: players.asMap().entries.map((e) {
        final p = e.value;
        final color = colors[e.key % colors.length];
        final sel = selectedId == p.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(p.id as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.2) : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? color : Colors.transparent, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_rounded, color: sel ? color : Colors.white38, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    p.name as String,
                    style: TextStyle(
                      color: sel ? color : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SheetTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SheetTypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SheetCheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const SheetCheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class SheetPreviewBox extends StatelessWidget {
  final RoundScore round;
  final List players;

  const SheetPreviewBox({super.key, required this.round, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onizleme: ${round.label}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: players.map((p) {
              final delta = round.deltas[p.id as String] ?? 0;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      p.name as String,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delta == 0 ? '-' : (delta > 0 ? '+$delta' : '$delta'),
                      style: TextStyle(
                        color: delta < 0
                            ? AppColors.siler
                            : delta == 0
                                ? Colors.white24
                                : AppColors.penalty,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}
