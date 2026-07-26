import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../data/services/ad_service.dart';
import '../../state/progress_controller.dart';

/// Renders a banner ad, or **nothing at all** when one is unavailable.
///
/// Collapsing to `SizedBox.shrink()` rather than reserving an empty grey strip
/// matters: premium players and offline players should see a layout with no
/// ad-shaped hole in it. The slot only takes up space once an ad has actually
/// loaded.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Deferred to post-frame so we can read providers safely.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted) return;
    final progress = context.read<ProgressController>();
    if (progress.isPremium) return;

    final ads = context.read<AdService>();
    final banner = ads.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
    if (banner == null) return;

    _banner = banner;
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild if the player buys premium mid-session.
    final isPremium = context.select<ProgressController, bool>(
      (p) => p.isPremium,
    );

    final banner = _banner;
    if (isPremium || banner == null || !_loaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
