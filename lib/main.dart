import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/ad_service.dart';
import 'data/services/audio_service.dart';
import 'data/services/haptic_service.dart';
import 'data/services/storage_service.dart';
import 'state/progress_controller.dart';
import 'state/settings_controller.dart';

/// Entry point.
///
/// Startup order matters here:
///  1. Bind the engine and lock orientation *before* anything renders.
///  2. Load persisted data with a single `await` so the first frame already
///     knows whether to show onboarding — no flash of the wrong screen.
///  3. Fire ad + audio initialisation **without awaiting** them; neither may
///     delay the splash screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The board is designed for portrait; rotating would force either a cramped
  // grid or a second layout with no gameplay benefit.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Draw behind the system bars so the aurora runs edge to edge.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await StorageService.create();

  final audio = AudioService();
  final haptics = HapticService();
  final ads = AdService();

  // Intentionally not awaited — see the doc comment above.
  _fireAndForget(audio.init());
  _fireAndForget(ads.init());

  final settingsController = SettingsController(
    repository: SettingsRepository(storage),
    audio: audio,
    haptics: haptics,
  );

  final progressController = ProgressController(
    repository: ProgressRepository(storage),
    ads: ads,
  );

  runApp(
    MultiProvider(
      providers: [
        // Services are plain values — they hold no rebuildable state.
        Provider<StorageService>.value(value: storage),
        Provider<AudioService>.value(value: audio),
        Provider<HapticService>.value(value: haptics),
        Provider<AdService>.value(value: ads),

        // Controllers drive rebuilds.
        ChangeNotifierProvider<SettingsController>.value(
          value: settingsController,
        ),
        ChangeNotifierProvider<ProgressController>.value(
          value: progressController,
        ),
      ],
      child: const WordQuestApp(),
    ),
  );
}

void _fireAndForget(Future<void> future) {
  future.catchError((Object error) {
    debugPrint('Startup task failed: $error');
  });
}
