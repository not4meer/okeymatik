import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/game_enums.dart';
import '../providers/live_provider.dart';
import '../providers/settings_provider.dart';
import 'live_view_screen.dart';
import 'profile_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final s = ref.watch(stringsProvider);
    final username = settings.username;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appCard,
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Center(
                          child: username.isNotEmpty
                              ? Text(
                                  username
                                      .trim()
                                      .split(' ')
                                      .map((w) =>
                                          w.isNotEmpty ? w[0].toUpperCase() : '')
                                      .take(2)
                                      .join(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(Icons.person_rounded,
                                  color: context.appHint, size: 20),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.ios_share_rounded,
                          color: context.appHint, size: 22),
                      tooltip: s.shareAppText,
                      onPressed: () => Share.share(s.shareAppText, subject: 'Okeymatik'),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Okeymatik',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.appTextMain),
              ),
              const Spacer(),
              Text(
                s.selectGame,
                style: TextStyle(
                    color: context.appHint, fontSize: 13, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              _GameCard(
                title: s.classicOkey,
                iconWidget: const _TileIcon(
                  labels: ['6', '7'],
                  tileColors: [Color(0xFF111827), Color(0xFFDC2626)],
                ),
                color: AppColors.primary,
                onTap: () => _navigate(context, GameType.classicOkey),
              ),
              const SizedBox(height: 14),
              _GameCard(
                title: 'Okey 101',
                iconWidget: const _TileIcon(
                  labels: ['1', '0', '1'],
                  tileColors: [AppColors.primary, AppColors.primary, AppColors.primary],
                ),
                color: AppColors.primary,
                onTap: () => _navigate(context, GameType.okey101),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _joinLive(context, ref, s),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appMuted),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_rounded, color: context.appHint, size: 18),
                      const SizedBox(width: 10),
                      Text(s.joinLive,
                          style: TextStyle(
                              color: context.appSubtext,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                s.screenOnHint,
                style: TextStyle(color: context.appDim, fontSize: 11),
              ),
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

  void _joinLive(BuildContext context, WidgetRef ref, AppStrings s) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.joinLiveTitle,
                  style: TextStyle(
                      color: ctx.appTextMain, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: ctx.appTextMain),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                      color: ctx.appDim, fontSize: 28, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: ctx.appCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final code = ctrl.text.trim();
                    if (code.length != 6) return;
                    Navigator.pop(ctx);
                    final error =
                        await ref.read(liveProvider.notifier).joinRoom(code);
                    if (!context.mounted) return;
                    if (error != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(error)));
                    } else {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LiveViewScreen()));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(s.join),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final Widget iconWidget;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.iconWidget,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appTextMain,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, color: color, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Okey taşı ikonları — beyaz arka plan üzerine renkli sayı
class _TileIcon extends StatelessWidget {
  final List<String> labels;
  final List<Color> tileColors;

  const _TileIcon({required this.labels, required this.tileColors});

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    final tileW = count == 3 ? 13.0 : 17.0;
    final tileH = count == 3 ? 20.0 : 26.0;
    final fontSize = count == 3 ? 9.0 : 12.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 2.5),
          Container(
            width: tileW,
            height: tileH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: tileColors[i], width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: tileColors[i].withValues(alpha: 0.30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  color: tileColors[i],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
