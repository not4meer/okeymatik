import 'package:flutter/material.dart';
import '../core/theme.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      color: const Color(0xFF111111),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('Reklam', style: TextStyle(color: Colors.white24, fontSize: 9)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Center(
              child: Text(
                'Reklam Alanı — 320×50',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
