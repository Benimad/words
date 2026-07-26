# WordQuest

An original, production-ready word-search puzzle game built with Flutter.

240 handcrafted levels across 8 themed worlds, a daily challenge with streak
rewards, three hint types, achievements, and a complete offline-first
architecture. Every puzzle is generated on-device and verified solvable before
it is ever shown to a player.

**Live pages:** [Privacy Policy](https://benimad.github.io/words/privacy.html) ·
[Terms](https://benimad.github.io/words/terms.html) ·
[Support](https://benimad.github.io/words/support.html)

---

## Table of contents

- [Quick start](#quick-start)
- [Project structure](#project-structure)
- [How it works](#how-it-works)
- [Testing](#testing)
- [Building a release](#building-a-release)
- [Configuring ads](#configuring-ads)
- [Regenerating assets](#regenerating-assets)
- [Before you publish](#before-you-publish)

---

## Quick start

**Requirements:** Flutter 3.41+ (Dart 3.11+), Android SDK, JDK 17.

```bash
git clone https://github.com/Benimad/words.git
cd words
flutter pub get
flutter run
```

That is the whole setup — there is no backend, no API key required to play, and
no code generation step.

Verify the toolchain if `flutter run` fails:

```bash
flutter doctor -v
```

---

## Project structure

The codebase is split so that **game logic never imports Flutter widgets** and
**UI never contains game rules**. The entire puzzle engine runs in a plain Dart
test with no widget tree.

```
lib/
├── main.dart                    App entry: DI wiring, orientation, startup order
├── app.dart                     MaterialApp, theming, lifecycle → progress flush
│
├── core/                        Cross-cutting concerns, no business logic
│   ├── theme/                   Design tokens
│   │   ├── app_palette.dart       Colour ramps + gradients
│   │   ├── app_typography.dart    Type scale (2 families, one job each)
│   │   ├── app_motion.dart        Durations, curves, spacing, radii
│   │   └── app_theme.dart         Light/dark ThemeData assembly
│   └── router/app_router.dart   Named routes + custom page transitions
│
├── data/                        Models, content and platform services
│   ├── models/                    Immutable value types (Puzzle, Level, …)
│   ├── content/                   The game's actual content
│   │   ├── word_banks.dart          ~60 themed vocabulary lists
│   │   ├── difficulty_curve.dart    Global index → board size/words/directions
│   │   ├── level_catalog.dart       Builds all 240 levels deterministically
│   │   ├── daily_challenge.dart     Date-seeded daily puzzle
│   │   └── achievements.dart        Long-term goals + unlock predicates
│   ├── repositories/              Load/save with debouncing + corruption recovery
│   └── services/                  Storage, audio, haptics, ads
│
├── game/                        Pure logic — zero Flutter imports
│   ├── generator/puzzle_generator.dart   Backtracking placement engine
│   └── logic/scoring.dart                Stars, coins, XP
│
├── state/                       ChangeNotifier controllers
│   ├── progress_controller.dart     Coins, unlocks, streaks, achievements
│   ├── game_session_controller.dart In-level state: selection, hints, timer
│   └── settings_controller.dart     Preferences → services
│
├── features/                    One folder per screen
│   ├── splash/  onboarding/  home/  worlds/
│   └── game/    daily/       shop/  profile/  settings/
│
└── shared/widgets/              Reusable UI (buttons, cards, confetti, aurora)

test/                            54 tests — see "Testing"
tool/                            Asset generators (audio, icons)
docs/                            GitHub Pages site: privacy, terms, support
assets/                          Fonts (SIL OFL) + generated audio
```

---

## How it works

### The puzzle generator

`lib/game/generator/puzzle_generator.dart` is the heart of the game. It
guarantees that **every board it returns is solvable**.

1. **Normalise** the word pool — upper-case, strip non-letters, deduplicate,
   drop anything longer than the board.
2. **Sort longest-first.** Long words are hardest to place, so they go down
   while the grid is still empty. This single choice is what makes generation
   succeed on the first attempt for every shipped level.
3. **Backtracking placement.** Each word's legal slots are scored — overlaps on
   matching letters score highly, because overlaps are what make a word search
   feel handcrafted rather than a set of parallel lines. If a word cannot be
   placed, the search backtracks and retries earlier words elsewhere.
4. **Escape hatches.** A step budget prevents pathological hangs; a fresh seed
   is tried up to 12 times; finally the target word count is reduced. The
   generator can degrade, but it cannot hang or emit an invalid board.
5. **Filler** letters are sampled from the answers' own letter distribution
   blended with English frequencies — uniform A-Z filler is full of J/Q/X/Z,
   which makes real words pop out and the puzzle trivial.
6. **Verify.** The result is re-read off the grid and checked against
   `Puzzle.isSolvable` before being returned.

### Levels are described, not stored

A `Level` is a *recipe* (theme, seed, board size, allowed directions), not a
saved grid. The generator rebuilds an identical board from the seed every time,
so 240 levels cost a few kilobytes instead of megabytes of baked JSON — and
every player worldwide gets the same board for a given level.

### The difficulty curve

Staged rather than smooth, because players notice a *new mechanic* far more
than a board growing by one cell:

| Levels  | Board | Words | What's new                  |
|---------|-------|-------|-----------------------------|
| 1-15    | 7×7   | 4-5   | across & down only          |
| 16-40   | 8×8   | 5-6   | + downward diagonal         |
| 41-80   | 9×9   | 6-7   | + backwards words           |
| 81-130  | 10×10 | 7-8   | + all four diagonals        |
| 131-190 | 11×11 | 8-9   | longer words, denser boards |
| 191-240 | 12-13 | 9-10  | full difficulty             |

Every 8th level in a world is a timed sprint, to give the campaign a heartbeat.

### Selection handling

The swipe recomputes the selection as a straight line from the anchor cell to
the current cell, rather than tracking every cell the finger crossed. The
player only has to hit the first and last letter, a jittery finger cannot
corrupt the word, and fast diagonal swipes stay accurate. Off-axis positions
are ignored, leaving the last valid line on screen.

### Rendering

The board is a single `CustomPaint`, not 169 widgets. That keeps a drag at
60fps on low-end hardware and lets found-word ribbons be drawn *under* the
letters. `TextPainter` layouts are cached per (letter, size, colour).

---

## Testing

```bash
flutter test              # all 54 tests
flutter analyze           # zero issues expected
```

Coverage worth knowing about:

- **All 240 campaign levels** are generated and asserted solvable, with the
  advertised word count and no forbidden directions.
- **365 consecutive daily puzzles** are generated and asserted solvable.
- Selection: forwards, backwards, endpoints-only, off-axis rejection,
  already-found, single-tap, completion detection.
- Hints: each type's effect, and that "nothing to reveal" is reported rather
  than silently charging the player.
- Progression: unlock ordering, replay never regressing a best result, the
  world-unlock celebration firing exactly once, streak continuation and lapse.
- Persistence: round-trip, reset, and **corrupt-JSON recovery** (a mangled save
  falls back to defaults instead of crash-looping).

---

## Building a release

### Signing

Release signing reads `android/key.properties`, which is git-ignored:

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=<your key alias>
storeFile=../../<your-keystore-file>
```

`storeFile` is resolved relative to `android/app/`.

If that file is missing, the build falls back to the debug keystore so
`flutter build apk --release` still works locally — but the artifact cannot be
uploaded to Play. Check which key actually signed an artifact with:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

> **Never commit the keystore or `key.properties`.** They are the only proof
> you are the publisher. Both are already in `.gitignore`.

### Commands

```bash
# App Bundle — this is what you upload to Google Play
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# APK for direct install / sideloading
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Smaller APKs, one per CPU architecture
flutter build apk --release --split-per-abi
```

### A note on code shrinking

R8 (`isMinifyEnabled`) is currently **off** in `android/app/build.gradle.kts`.
This trades download size for a release build that behaves identically to
debug — R8 is the usual cause of "works in debug, crashes in release" bugs,
typically by stripping reflection targets in the ads SDK.

The rules in `android/app/proguard-rules.pro` are already written, so enabling
it later is a two-line change:

```kotlin
isMinifyEnabled = true
isShrinkResources = true
```

Test the release build thoroughly after flipping those.

---

## Configuring ads

The project ships with **Google's official test ad IDs**, which serve real test
creatives without risking a policy strike. Replace them before publishing:

1. `lib/data/services/ad_service.dart` → the `AdUnits` class (banner,
   interstitial and rewarded IDs, per platform).
2. `android/app/src/main/AndroidManifest.xml` → the
   `com.google.android.gms.ads.APPLICATION_ID` meta-data value.

Ads are wrapped so they can never break the game: every SDK call is guarded,
and if the SDK is unavailable, offline, or on an unsupported platform, the app
reports "no ad" and play continues. Interstitials are frequency-capped (at most
one per 3 minutes and one per 4 completed levels) and are shown **after** the
reward screen, never before it.

### In-app purchases

The shop's paid buttons currently call `_simulatePurchase`, which grants items
locally behind a clearly-labelled demo dialog. Before shipping, replace it with
the `in_app_purchase` plugin plus server-side receipt validation. Search for
`_simulatePurchase` in `lib/features/shop/shop_screen.dart`.

---

## Regenerating assets

All binary assets are generated from source, so nothing in this repo is an
opaque blob:

```bash
# 9 synthesised sound effects → assets/audio/*.wav
dart run tool/generate_audio.dart

# Launcher icons + Play Store graphics from assets/Puzzle.png
python tool/generate_icons_from_image.py assets/Puzzle.png
```

The icon script writes legacy mipmaps, adaptive-icon layers (artwork inset into
the 72dp safe zone so no launcher mask can clip it), a 512×512 listing icon and
a 1024×500 feature graphic.

**Fonts:** Baloo 2 and Plus Jakarta Sans, both under the SIL Open Font License.
Licence texts are bundled in `assets/fonts/`.

---

## Before you publish

- [ ] Replace the AdMob app ID and all ad unit IDs with your own
- [ ] Wire real in-app purchases (replace `_simulatePurchase`)
- [ ] Point the in-app Privacy/Terms links at your hosted pages
- [ ] Update the contact email in `docs/` and in `LegalScreen`
- [ ] Have the legal templates reviewed — they describe what this code does,
      but they are not legal advice
- [ ] Bump `version:` in `pubspec.yaml`
- [ ] Test the signed release build on a physical device
- [ ] Confirm `flutter test` and `flutter analyze` are clean

---

## Licence

Copyright © 2026. All rights reserved.

Bundled fonts are licensed separately under the SIL OFL — see
`assets/fonts/OFL-*.txt`.
