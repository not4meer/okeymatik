import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.casino_outlined, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Okey Skor',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masa çevresinde skor & kural asistanı',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const Spacer(),
              const Text(
                'OYUN SEÇİN',
                style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              _GameCard(
                title: 'Klasik Okey',
                subtitle: 'Normal bitiş · Okey ile · Çiftten',
                icon: Icons.grid_view_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () => _navigate(context, GameType.classicOkey),
              ),
              const SizedBox(height: 14),
              _GameCard(
                title: 'Okey 101',
                subtitle: 'Siler · El açma · Eşli / Tekli',
                icon: Icons.looks_one_rounded,
                color: AppColors.primary,
                onTap: () => _navigate(context, GameType.okey101),
              ),
              const Spacer(),
              const _Footer(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, GameType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetupScreen(gameType: type)),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Ekran sürekli açık kalır · Düşük pil tüketimi',
      style: TextStyle(color: Colors.white24, fontSize: 11),
    );
  }
}
