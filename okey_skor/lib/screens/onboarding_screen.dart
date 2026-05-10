import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _canContinue = false;

  late final AnimationController _introCtrl;
  late final AnimationController _formCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _introFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
        duration: const Duration(milliseconds: 750), vsync: this);
    _formCtrl = AnimationController(
        duration: const Duration(milliseconds: 550), vsync: this);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut),
    );
    _introFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _introCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _introCtrl,
          curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic)),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut),
    );
    _formSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic),
    );

    _introCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _formCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _introCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    ref.read(settingsProvider.notifier).setUsername(name);
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo + title block
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _introFade,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _introFade,
                  child: Column(
                    children: [
                      Text(
                        s.welcomeTitle,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.appTextMain,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.welcomeSubtitle,
                        style:
                            TextStyle(fontSize: 15, color: context.appSubtext),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Form block
              SlideTransition(
                position: _formSlide,
                child: FadeTransition(
                  opacity: _formFade,
                  child: Column(
                    children: [
                      TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appTextMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: s.yourName,
                          hintStyle:
                              TextStyle(color: context.appDim, fontSize: 22),
                          filled: true,
                          fillColor: context.appCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                        ),
                        onChanged: (v) =>
                            setState(() => _canContinue = v.trim().isNotEmpty),
                        onSubmitted: (_) => _continue(),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _canContinue ? _continue : null,
                        child: AnimatedOpacity(
                          opacity: _canContinue ? 1.0 : 0.35,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.start,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                s.noDataNeeded,
                style: TextStyle(color: context.appDim, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
