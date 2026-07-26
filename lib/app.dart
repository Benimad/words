import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/progress_controller.dart';
import 'state/settings_controller.dart';

/// Root widget.
///
/// Also acts as the app-lifecycle listener: when the OS pauses the app we flush
/// progress to disk immediately rather than relying on the repository's
/// debounce, which is the difference between "closed the app and kept my
/// coins" and a support ticket.
class WordQuestApp extends StatefulWidget {
  const WordQuestApp({super.key});

  @override
  State<WordQuestApp> createState() => _WordQuestAppState();
}

class _WordQuestAppState extends State<WordQuestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      context.read<ProgressController>().flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsController, ThemeMode>(
      (s) => s.themeMode,
    );

    return MaterialApp(
      title: 'WordQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        // Clamp text scaling: the puzzle grid is a fixed-geometry layout, and
        // beyond ~1.3x the letters stop fitting their cells. Accessibility is
        // served instead by the dedicated "Large letters" setting.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
