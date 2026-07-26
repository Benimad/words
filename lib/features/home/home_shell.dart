import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_motion.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/banner_ad_slot.dart';
import '../../state/progress_controller.dart';
import '../daily/daily_screen.dart';
import '../profile/profile_screen.dart';
import '../worlds/journey_screen.dart';
import 'home_screen.dart';
import 'widgets/wq_nav_bar.dart';

/// The persistent shell that hosts the four main tabs.
///
/// Tabs live in an [IndexedStack] so their scroll position and animation state
/// survive switching — flipping to Daily and back should not reset the home
/// screen's scroll or replay its entrance animations.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    context.read<AudioService>().play(Sfx.button);
    context.read<HapticService>().light();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    // A dot on the Daily tab whenever today's puzzle is still unplayed — the
    // single most effective retention nudge in the whole app.
    final dailyPending = context.select<ProgressController, bool>(
      (p) => !p.hasCompletedTodaysDaily,
    );

    return Scaffold(
      // Let the aurora inside each tab run under the nav bar.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavigate: _select),
          const JourneyScreen(),
          const DailyScreen(embedded: true),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner sits above the nav bar so it never overlaps a tap target.
          const BannerAdSlot(
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
          ),
          WqNavBar(
            currentIndex: _index,
            onSelected: _select,
            items: [
              const NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              const NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Journey',
              ),
              NavItem(
                icon: Icons.today_outlined,
                activeIcon: Icons.today_rounded,
                label: 'Daily',
                badgeCount: dailyPending ? 1 : 0,
              ),
              const NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
