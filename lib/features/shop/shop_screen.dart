import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/coin_chip.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// Coin shop and the "remove ads" upgrade.
///
/// ## On monetisation
///
/// The free rewarded-ad option sits at the **top**, above every paid pack.
/// That is deliberate: a player who never spends money can still earn every
/// hint in the game, which keeps the design honest about not being
/// pay-to-win — coin packs buy convenience, never exclusive capability.
///
/// ## On the purchase flow
///
/// The paid buttons here are wired to [_simulatePurchase], which grants the
/// goods locally. **Before shipping**, replace it with a real billing
/// integration (`in_app_purchase`) and server-side receipt validation — see
/// the "Monetisation" section of README.md for the exact steps.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;

  static const _packs = <_CoinPack>[
    _CoinPack(
      coins: 500,
      price: r'$0.99',
      label: 'Pouch',
      icon: Icons.savings_rounded,
    ),
    _CoinPack(
      coins: 1500,
      price: r'$2.99',
      label: 'Satchel',
      icon: Icons.account_balance_wallet_rounded,
      bonus: 'Most popular',
    ),
    _CoinPack(
      coins: 4000,
      price: r'$5.99',
      label: 'Treasure chest',
      icon: Icons.inventory_2_rounded,
      bonus: 'Best value',
    ),
  ];

  Future<void> _watchAd() async {
    final ads = context.read<AdService>();
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioService>();

    setState(() => _busy = true);
    final earned = await ads.showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);

    if (earned) {
      progress.addCoins(75);
      audio.play(Sfx.coin);
      context.read<HapticService>().celebrate();
      _toast('+75 coins added.');
    } else {
      _toast('No ad available right now — please try again soon.');
    }
  }

  /// Stand-in for a real store purchase. See the class doc.
  Future<void> _simulatePurchase({int? coins, bool premium = false}) async {
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioService>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo purchase'),
        content: const Text(
          'This build is not connected to a store. Confirm to grant the item '
          'locally so you can try the flow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (coins != null) progress.addCoins(coins);
    if (premium) progress.setPremium(true);

    audio.play(premium ? Sfx.unlock : Sfx.coin);
    context.read<HapticService>().celebrate();
    _toast(premium ? 'Ads removed. Enjoy!' : '+$coins coins added.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final ads = context.watch<AdService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                // Drag handle.
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: Text('Shop', style: theme.textTheme.displaySmall),
                    ),
                    CoinChip(coins: progress.coins),
                    const SizedBox(width: AppSpacing.sm),
                    WqIconButton(
                      icon: Icons.close_rounded,
                      size: 38,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // --- Free coins -------------------------------------------
                FadeSlideIn(
                  child: WqCard(
                    gradient: AppGradients.reward,
                    borderColor: Colors.transparent,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free coins',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ads.isRewardedReady
                                    ? 'Watch a short video for 75 coins'
                                    : 'No video available right now',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppPalette.amberDark,
                            minimumSize: const Size(74, 42),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed:
                              ads.isRewardedReady && !_busy ? _watchAd : null,
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Watch'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // --- Remove ads -------------------------------------------
                if (!progress.isPremium) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: WqCard(
                      elevated: true,
                      borderColor: AppPalette.violet.withValues(alpha: 0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppPalette.violet,
                                size: 26,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'WordQuest Premium',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                r'$4.99',
                                style: AppTypography.numeric(
                                  17,
                                  theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _Perk('Removes all banner and full-screen ads'),
                          const _Perk('300 bonus coins right away'),
                          const _Perk('Supports future level packs'),
                          const SizedBox(height: AppSpacing.lg),
                          WqButton(
                            label: 'Remove ads',
                            icon: Icons.block_rounded,
                            onPressed: () => _simulatePurchase(
                              coins: 300,
                              premium: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ] else
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: WqCard(
                      borderColor: AppPalette.mint.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppPalette.mint,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Premium active — thank you for supporting '
                              'WordQuest.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),
                const SectionHeader(
                  title: 'Coin packs',
                  subtitle: 'Coins only buy hints — never levels or advantages',
                  icon: Icons.monetization_on_rounded,
                ),
                const SizedBox(height: AppSpacing.md),

                for (var i = 0; i < _packs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 140 + i * 60),
                      child: _CoinPackCard(
                        pack: _packs[i],
                        onBuy: () => _simulatePurchase(coins: _packs[i].coins),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinPack {
  const _CoinPack({
    required this.coins,
    required this.price,
    required this.label,
    required this.icon,
    this.bonus,
  });

  final int coins;
  final String price;
  final String label;
  final IconData icon;
  final String? bonus;
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({required this.pack, required this.onBuy});

  final _CoinPack pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WqCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.reward,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(pack.icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${pack.coins} coins',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (pack.bonus != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.mint.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          pack.bonus!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppPalette.mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(pack.label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              minimumSize: const Size(76, 40),
              padding: EdgeInsets.zero,
            ),
            child: Text(pack.price),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: AppPalette.mint,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
