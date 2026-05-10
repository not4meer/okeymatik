import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
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
    final isDark = settings.themeMode == ThemeMode.dark;

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
          _ThemeTile(
            isDark: isDark,
            darkLabel: s.darkTheme,
            lightLabel: s.lightTheme,
            onToggle: (v) {
              ref.read(settingsProvider.notifier).setThemeMode(
                    v ? ThemeMode.dark : ThemeMode.light,
                  );
            },
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
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF00A478)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
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
                const Icon(Icons.tag, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  playerId,
                  style: const TextStyle(
                    color: AppColors.primary,
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
              Icon(icon, color: AppColors.primary, size: 20),
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

class _ThemeTile extends StatelessWidget {
  final bool isDark;
  final String darkLabel;
  final String lightLabel;
  final ValueChanged<bool> onToggle;

  const _ThemeTile({
    required this.isDark,
    required this.darkLabel,
    required this.lightLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      label: isDark ? darkLabel : lightLabel,
      trailing: Switch(
        value: isDark,
        onChanged: onToggle,
        activeThumbColor: AppColors.primary,
      ),
      onTap: () => onToggle(!isDark),
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
            color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : context.appHint,
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

  const _PremiumTile({
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            const Color(0xFF7B2FBE).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: context.appTextMain, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: context.appHint, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cta,
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
