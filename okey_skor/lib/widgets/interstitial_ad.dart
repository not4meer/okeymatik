import 'package:flutter/material.dart';
import '../core/theme.dart';

class InterstitialAd {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InterstitialDialog(),
    );
  }
}

class _InterstitialDialog extends StatefulWidget {
  const _InterstitialDialog();

  @override
  State<_InterstitialDialog> createState() => _InterstitialDialogState();
}

class _InterstitialDialogState extends State<_InterstitialDialog> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_countdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black87,
        child: Stack(
          children: [
            // Mock ad content
            Center(
              child: Container(
                width: 300,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Reklam', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.ad_units_rounded, color: Colors.white24, size: 60),
                    const SizedBox(height: 12),
                    const Text(
                      'Reklam Alanı',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    const Text(
                      '300×250',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: _countdown == 0 ? () => Navigator.pop(context) : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _countdown == 0 ? AppColors.primary : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _countdown > 0
                        ? Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : const Icon(Icons.close_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
