import 'package:flutter/material.dart';

import '../../data/models/level.dart';
import '../../data/models/world.dart';
import '../../features/daily/daily_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/achievements_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/worlds/world_levels_screen.dart';
import '../theme/app_motion.dart';

/// Route names, kept as constants so typos become compile errors at the call
/// sites that use [AppRouter.push].
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const worldLevels = '/world';
  static const game = '/game';
  static const daily = '/daily';
  static const shop = '/shop';
  static const settings = '/settings';
  static const achievements = '/achievements';
}

/// Arguments for the game route.
class GameArgs {
  const GameArgs({required this.level, this.isDaily = false});
  final Level level;
  final bool isDaily;
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _fade(const SplashScreen(), settings);

      case Routes.onboarding:
        return _fade(const OnboardingScreen(), settings);

      case Routes.home:
        return _fade(const HomeShell(), settings);

      case Routes.worldLevels:
        final world = settings.arguments as World;
        return _sharedAxis(WorldLevelsScreen(world: world), settings);

      case Routes.game:
        final args = settings.arguments as GameArgs;
        // The game gets a scale-through transition: it should feel like
        // *entering* the board, not sliding to a sibling page.
        return _zoom(
          GameScreen(level: args.level, isDaily: args.isDaily),
          settings,
        );

      case Routes.daily:
        return _sharedAxis(const DailyScreen(), settings);

      case Routes.shop:
        return _sheet(const ShopScreen(), settings);

      case Routes.settings:
        return _sharedAxis(const SettingsScreen(), settings);

      case Routes.achievements:
        return _sharedAxis(const AchievementsScreen(), settings);

      default:
        // Unknown route: fall back to home rather than showing a red screen.
        return _fade(const HomeShell(), settings);
    }
  }

  // --- Transitions ------------------------------------------------------

  static Route<T> _fade<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: AppDurations.page,
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppCurves.enter),
          child: child,
        ),
      );

  /// Horizontal shared-axis: the incoming page slides in while the outgoing one
  /// slides slightly the other way. Reads as "forward" in a hierarchy.
  static Route<T> _sharedAxis<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: AppDurations.page,
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, secondary, child) {
          final enter = CurvedAnimation(
            parent: animation,
            curve: AppCurves.emphasised,
          );
          final exit = CurvedAnimation(
            parent: secondary,
            curve: AppCurves.emphasised,
          );
          return SlideTransition(
            position: Tween(
              begin: const Offset(0.18, 0),
              end: Offset.zero,
            ).animate(enter),
            child: FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween(
                  begin: Offset.zero,
                  end: const Offset(-0.10, 0),
                ).animate(exit),
                child: child,
              ),
            ),
          );
        },
      );

  /// Scale + fade — used for entering gameplay.
  static Route<T> _zoom<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: AppDurations.page,
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppCurves.emphasised,
            reverseCurve: AppCurves.exit,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

  /// Bottom-up modal, for the shop.
  static Route<T> _sheet<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: AppDurations.page,
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppCurves.emphasised,
              reverseCurve: AppCurves.exit,
            ),
          ),
          child: child,
        ),
      );
}
