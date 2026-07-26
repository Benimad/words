import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import 'legal_screen.dart';

/// Settings.
///
/// Every toggle applies instantly and persists immediately — there is no
/// "Save" button, because a settings screen that can be got wrong is a
/// settings screen that will be got wrong.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final s = settings.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    WqIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Settings', style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.huge,
                  ),
                  children: [
                    // --- Audio & feedback -----------------------------
                    FadeSlideIn(
                      child: _Group(
                        title: 'Sound & feedback',
                        icon: Icons.volume_up_rounded,
                        children: [
                          _SwitchRow(
                            title: 'Sound effects',
                            subtitle: 'Taps, discoveries and celebrations',
                            value: s.soundEnabled,
                            icon: Icons.graphic_eq_rounded,
                            onChanged: (v) {
                              settings.setSound(v);
                              // Play a confirmation *after* enabling, so the
                              // change is audible immediately.
                              if (v) {
                                context.read<AudioService>().play(Sfx.button);
                              }
                            },
                          ),
                          _SwitchRow(
                            title: 'Music',
                            subtitle: 'Ambient background audio',
                            value: s.musicEnabled,
                            icon: Icons.music_note_rounded,
                            onChanged: settings.setMusic,
                          ),
                          _SwitchRow(
                            title: 'Haptic feedback',
                            subtitle: 'Vibration on selections and rewards',
                            value: s.hapticsEnabled,
                            icon: Icons.vibration_rounded,
                            onChanged: (v) {
                              settings.setHaptics(v);
                              if (v) context.read<HapticService>().success();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Appearance -----------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: _Group(
                        title: 'Appearance',
                        icon: Icons.palette_rounded,
                        children: [
                          _ThemeSelector(
                            value: s.themeMode,
                            onChanged: settings.setThemeMode,
                          ),
                          const Divider(height: AppSpacing.xl),
                          _SwitchRow(
                            title: 'High contrast board',
                            subtitle: 'Stronger colours on the puzzle grid',
                            value: s.highContrastGrid,
                            icon: Icons.contrast_rounded,
                            onChanged: settings.setHighContrastGrid,
                          ),
                          _SwitchRow(
                            title: 'Large letters',
                            subtitle: 'Bigger type inside each grid cell',
                            value: s.largeLetters,
                            icon: Icons.format_size_rounded,
                            onChanged: settings.setLargeLetters,
                          ),
                          _SwitchRow(
                            title: 'Show timer',
                            subtitle: 'Hide it for a calmer, untimed feel',
                            value: s.showTimer,
                            icon: Icons.timer_rounded,
                            onChanged: settings.setShowTimer,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Account / purchases --------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _Group(
                        title: 'Purchases',
                        icon: Icons.shopping_bag_rounded,
                        children: [
                          _TapRow(
                            title: progress.isPremium
                                ? 'Premium active'
                                : 'Remove ads',
                            subtitle: progress.isPremium
                                ? 'Thank you for supporting WordQuest'
                                : 'One-time purchase, no subscriptions',
                            icon: Icons.workspace_premium_rounded,
                            onTap: () =>
                                Navigator.of(context).pushNamed(Routes.shop),
                          ),
                          _TapRow(
                            title: 'Restore purchases',
                            subtitle: 'Recover a previous purchase',
                            icon: Icons.restore_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Connect a billing plugin to enable '
                                      'restore. See README.',
                                    ),
                                  ),
                                );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Legal ----------------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: _Group(
                        title: 'About',
                        icon: Icons.info_rounded,
                        children: [
                          _TapRow(
                            title: 'Privacy Policy',
                            icon: Icons.privacy_tip_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalScreen(
                                  document: LegalDocument.privacy,
                                ),
                              ),
                            ),
                          ),
                          _TapRow(
                            title: 'Terms of Service',
                            icon: Icons.gavel_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalScreen(
                                  document: LegalDocument.terms,
                                ),
                              ),
                            ),
                          ),
                          _TapRow(
                            title: 'Open source licences',
                            icon: Icons.description_rounded,
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: 'WordQuest',
                              applicationVersion: '1.0.0',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Danger zone ----------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: WqCard(
                        borderColor:
                            theme.colorScheme.error.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: theme.colorScheme.error,
                                  size: 19,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Reset progress',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Permanently deletes your levels, stars, coins '
                              'and streaks. This cannot be undone.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              onPressed: () => _confirmReset(context),
                              child: const Text('Reset everything'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Text(
                        'WordQuest 1.0.0',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two-step confirmation: the dialog names exactly what will be lost, and the
  /// destructive action is not the default-styled button.
  Future<void> _confirmReset(BuildContext context) async {
    final progress = context.read<ProgressController>();
    final player = progress.progress;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Reset all progress?'),
        content: Text(
          'You will lose ${player.levelsCompleted} completed levels, '
          '${player.totalStars} stars, ${player.coins} coins and a '
          '${player.longestStreak}-day best streak.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await progress.resetProgress();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Progress reset. A fresh start!')),
      );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        WqCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented light / dark / system selector.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_6_rounded,
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Theme', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final mode in ThemeMode.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: mode == ThemeMode.values.last ? 0 : AppSpacing.sm,
                    ),
                    child: GestureDetector(
                      onTap: () => onChanged(mode),
                      child: AnimatedContainer(
                        duration: AppDurations.normal,
                        curve: AppCurves.enter,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient:
                              value == mode ? AppGradients.brand : null,
                          color: value == mode
                              ? null
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              switch (mode) {
                                ThemeMode.light => Icons.light_mode_rounded,
                                ThemeMode.dark => Icons.dark_mode_rounded,
                                ThemeMode.system => Icons.settings_suggest_rounded,
                              },
                              size: 18,
                              color: value == mode
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              switch (mode) {
                                ThemeMode.light => 'Light',
                                ThemeMode.dark => 'Dark',
                                ThemeMode.system => 'System',
                              },
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: value == mode
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: value == mode
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
