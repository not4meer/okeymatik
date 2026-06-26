import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/complaint_sheet.dart';
import 'history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(settingsProvider).username);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    ref.read(settingsProvider.notifier).setUsername(_nameCtrl.text);
    setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _AvatarSection(
            username: settings.username,
            playerId: settings.playerId,
            editing: _editingName,
            nameCtrl: _nameCtrl,
            nameHint: s.nameHint,
            idCopied: s.idCopied,
            onEditTap: () => setState(() {
              _editingName = true;
              Future.delayed(Duration.zero, () => _nameCtrl.selection =
                  TextSelection.collapsed(offset: _nameCtrl.text.length));
            }),
            onSave: _saveName,
            onCancel: () {
              _nameCtrl.text = settings.username;
              setState(() => _editingName = false);
            },
          ),
          const SizedBox(height: 24),

          _SectionHeader(s.pastGames),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.history_rounded,
            label: s.viewHistory,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(s.appearance),
          const SizedBox(height: 10),
          _ThemeSelector(
            current: settings.appTheme,
            darkLabel: s.darkTheme,
            lightLabel: s.lightTheme,
            girlsLabel: s.girlsMode,
            onSelect: (t) => ref.read(settingsProvider.notifier).setTheme(t),
          ),
          const SizedBox(height: 24),

          _SectionHeader(s.language),
          const SizedBox(height: 10),
          _LanguageTile(
            selected: settings.language,
            onSelect: (lang) => ref.read(settingsProvider.notifier).setLanguage(lang),
          ),
          const SizedBox(height: 24),

          _SectionHeader(s.premiumTitle),
          const SizedBox(height: 10),
          _PremiumTile(
            title: s.premiumTitle,
            subtitle: s.premiumSubtitle,
            cta: s.premiumCta,
            isPremium: ref.watch(premiumProvider),
            onTap: () async {
              AnalyticsService.logPremiumTapped();
              await ref.read(premiumProvider.notifier).activate();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium aktif! Reklamlar kaldırıldı.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          _SectionHeader(s.complaintSection),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.report_problem_rounded,
            label: s.complaintTitle,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ComplaintSheet(s: s),
            ),
          ),
          const SizedBox(height: 40),

          Center(
            child: Column(
              children: [
                Text(
                  'Made with ❤️ for Okey players',
                  style: TextStyle(color: context.appHint, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: context.appDim, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String username;
  final String playerId;
  final bool editing;
  final TextEditingController nameCtrl;
  final String nameHint;
  final String idCopied;
  final VoidCallback onEditTap;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AvatarSection({
    required this.username,
    required this.playerId,
    required this.editing,
    required this.nameCtrl,
    required this.nameHint,
    required this.idCopied,
    required this.onEditTap,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final initials = username.isNotEmpty
        ? username
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .take(2)
            .join()
        : '?';

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: context.isGirls
                  ? [const Color(0xFFFF66C4), const Color(0xFFFFAADD)]
                  : [AppColors.primary, const Color(0xFF00A478)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: context.appPrimary.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (editing)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appTextMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.appPrimary, width: 2),
                    ),
                    filled: true,
                    fillColor: context.appCard,
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.check_rounded, color: context.appPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded, color: context.appHint, size: 20),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: onEditTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username.isEmpty ? nameHint : username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: username.isEmpty ? context.appHint : context.appTextMain,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, size: 16, color: context.appHint),
              ],
            ),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: playerId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(idCopied),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appMuted),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag, size: 13, color: context.appPrimary),
                const SizedBox(width: 4),
                Text(
                  playerId,
                  style: TextStyle(
                    color: context.appPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 13, color: context.appHint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: context.appHint,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: context.appPrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.appTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing ??
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: context.appDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppTheme current;
  final String darkLabel;
  final String lightLabel;
  final String girlsLabel;
  final ValueChanged<AppTheme> onSelect;

  const _ThemeSelector({
    required this.current,
    required this.darkLabel,
    required this.lightLabel,
    required this.girlsLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      (AppTheme.dark, Icons.dark_mode_rounded, darkLabel),
      (AppTheme.light, Icons.light_mode_rounded, lightLabel),
      (AppTheme.girls, Icons.favorite_rounded, girlsLabel),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: themes.map((t) {
          final (theme, icon, label) = t;
          final sel = current == theme;
          final accent = theme == AppTheme.girls
              ? AppColors.girlsPrimary
              : context.appPrimary;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? accent.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: sel ? accent : context.appHint, size: 20),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: sel ? accent : context.appSubtext,
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _LanguageTile({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _LangBtn(
            label: '🇹🇷 Türkçe',
            selected: selected == 'tr',
            onTap: () => onSelect('tr'),
          ),
          Container(width: 1, height: 40, color: context.appMuted),
          _LangBtn(
            label: '🇬🇧 English',
            selected: selected == 'en',
            onTap: () => onSelect('en'),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? context.appPrimary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? context.appPrimary : context.appHint,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final bool isPremium;
  final VoidCallback onTap;

  const _PremiumTile({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPremium ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.appPrimary.withValues(alpha: isPremium ? 0.08 : 0.15),
              context.appPrimary.withValues(alpha: isPremium ? 0.04 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPremium ? Icons.check_circle_rounded : Icons.workspace_premium_rounded,
                color: context.appPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium Aktif' : title,
                    style: TextStyle(
                        color: context.appTextMain, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium ? 'Reklamlar kaldırıldı' : subtitle,
                    style: TextStyle(color: context.appHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: context.appPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cta,
                  style: const TextStyle(
                      color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            if (isPremium)
              GestureDetector(
                onTap: () {
                  final url = defaultTargetPlatform == TargetPlatform.iOS
                      ? 'https://apps.apple.com/account/subscriptions'
                      : 'https://play.google.com/store/account/subscriptions';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'İptal Et',
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
