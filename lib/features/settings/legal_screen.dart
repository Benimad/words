import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/wq_button.dart';

enum LegalDocument { privacy, terms }

/// Renders the in-app legal documents.
///
/// > ⚠️ **These are templates, not legal advice.** They describe what this
/// > codebase actually does (local-only storage, AdMob, no accounts), which is
/// > a correct starting point — but you must have them reviewed and hosted at a
/// > public URL before submitting to Google Play, which requires a reachable
/// > privacy policy link in the store listing.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrivacy = document == LegalDocument.privacy;

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
                    Expanded(
                      child: Text(
                        isPrivacy ? 'Privacy Policy' : 'Terms of Service',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Template text — replace with your reviewed '
                              'policy before publishing.',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color:
                                    theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final section
                        in isPrivacy ? _privacySections : _termsSections) ...[
                      Text(section.$1, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(section.$2, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _privacySections = <(String, String)>[
    (
      'What we store',
      'WordQuest keeps your progress — completed levels, stars, coins, '
          'streaks and settings — in local storage on your device only. We do '
          'not operate an account system and we do not upload your progress '
          'to any server.',
    ),
    (
      'Advertising',
      'The free version displays ads supplied by Google AdMob. AdMob may '
          'collect and process device identifiers to serve and measure ads. '
          'Its handling of that data is governed by Google\'s privacy policy. '
          'Purchasing the ad-free upgrade stops all ad requests from this app.',
    ),
    (
      'Analytics',
      'This build ships with no third-party analytics SDK. If you add one, '
          'disclose it here and in your store listing.',
    ),
    (
      'Children',
      'The game contains no chat, user-generated content or social features. '
          'If you target it at children, configure AdMob for child-directed '
          'treatment and review the applicable regulations for your market.',
    ),
    (
      'Your choices',
      'You can erase everything the app has stored at any time using '
          'Settings → Reset progress. Uninstalling the app also removes all '
          'locally stored data.',
    ),
    (
      'Contact',
      'Questions about this policy: replace this line with your support '
          'email address before publishing.',
    ),
  ];

  static const _termsSections = <(String, String)>[
    (
      'Licence',
      'You are granted a personal, non-exclusive, non-transferable licence to '
          'use WordQuest for entertainment purposes.',
    ),
    (
      'Purchases',
      'Coins and the ad-free upgrade are digital items with no cash value. '
          'They cannot be exchanged, transferred between devices without a '
          'store account, or refunded except as required by the platform\'s '
          'own refund policy.',
    ),
    (
      'Acceptable use',
      'Do not attempt to modify, decompile or tamper with the game or its '
          'stored data in order to obtain items you have not earned.',
    ),
    (
      'Availability',
      'The core game works offline. Ads and store purchases require an '
          'internet connection and depend on third-party services that may be '
          'unavailable from time to time.',
    ),
    (
      'Content',
      'All puzzles, artwork, text, sound and code in WordQuest are original '
          'works owned by the developer.',
    ),
    (
      'Changes',
      'These terms may be updated alongside new releases. Continued use after '
          'an update constitutes acceptance of the revised terms.',
    ),
  ];
}
