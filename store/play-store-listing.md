# Google Play store listing — WordQuest

Copy-paste ready. Character counts are noted against Play's limits.

---

## App name

> Limit: 30 characters

```
WordQuest: Word Search
```
*(22 characters)*

**Alternatives if that name is taken:**
- `WordQuest — Word Puzzles` (24)
- `WordQuest: Puzzle Journey` (25)

---

## Short description

> Limit: 80 characters. This is what appears under the icon in search results,
> so it must sell the game on its own.

```
Swipe to find hidden words across 240 levels in 8 worlds. Free and offline.
```
*(74 characters)*

**Alternatives:**
- `240 word search levels, daily puzzles and streaks. Plays fully offline.` (70)
- `Relaxing word search with 240 levels, daily challenges and no wifi needed.` (73)

---

## Full description

> Limit: 4000 characters. The version below is ~2,450, which is the sweet spot:
> long enough for keyword coverage, short enough that people read it.

```
Find the words. Follow the map.

WordQuest is a relaxing word search puzzle game with a real sense of journey. Swipe across letters in any direction to uncover hidden words, and travel through eight beautiful worlds as the puzzles grow richer and more challenging.

🧩 240 HANDCRAFTED LEVELS
Eight themed worlds, thirty levels each. Wander through Verdant Vale, sail the Coral Coast, cross the Ember Dunes, climb Frostpeak Hollow, light up the Neon Nexus, relax in Blossom Bay, drift through the Starfall Rift, and finish your journey at Chronicle Keep.

📈 DIFFICULTY THAT ACTUALLY GROWS
Start gently with small 7x7 boards and simple across-and-down words. Diagonals arrive. Then backwards words. By the final worlds you are hunting ten hidden words across a packed 13x13 grid in all eight directions. Every step up is designed to be learnable, never unfair.

📅 A NEW PUZZLE EVERY DAY
The Daily Challenge gives you one special board each day — the same one for every player in the world. Play on consecutive days to build your streak and earn bigger and bigger coin bonuses. Miss a day and you start again, so keep it alive!

💡 HINTS WHEN YOU NEED THEM
Stuck on a stubborn board? Spend coins on three kinds of help:
• First Letter — shows you where a word begins
• Reveal Word — solves one word outright
• Clear Clutter — dims the letters that belong to no answer at all

Coins are earned by playing. You never have to pay to progress.

🏆 SOMETHING TO CHASE
Collect up to three stars per level for fast, hint-free solves. Unlock fourteen achievements. Climb the explorer ranks from Novice Explorer all the way to Grand Lexicographer. Track every word you have ever found.

✈️ PLAYS COMPLETELY OFFLINE
Every puzzle is created right on your device, so WordQuest works on a plane, on the metro, in a basement — anywhere. No account, no sign-up, no internet required. Your progress is saved on your phone and is never uploaded.

🎨 DESIGNED TO BE ENJOYED
• Smooth, satisfying swipe controls — just touch the first and last letter
• Beautiful light and dark themes
• Gentle sound effects and haptics you can switch off any time
• High-contrast board and large-letter options for easier reading
• Optional timer — hide it for a completely relaxed pace

🧠 GOOD FOR YOUR BRAIN
Word search puzzles are a great way to sharpen focus, widen your vocabulary and give your mind a calm few minutes. WordQuest covers animals, food, nature, travel, sports, countries, technology, space, history, science and much more.

Whether you have five minutes in a queue or an hour on the sofa, WordQuest is ready.

Download WordQuest and start your journey today.
```

---

## Graphics checklist

| Asset | Required size | File |
|-------|--------------|------|
| App icon | 512 × 512 PNG, no transparency | `store/play_store_icon_512.png` ✅ |
| Feature graphic | 1024 × 500 PNG/JPG | `store/feature_graphic_1024x500.png` ✅ |
| Phone screenshots | 2–8 images, min 320px, 16:9 or 9:16 | **still to capture** |

**Screenshots to capture** (run the app, use the device screenshot button).
Shoot these six, in this order — the first two carry most of the install
decision:

1. **Gameplay mid-swipe** — a word half-selected on a colourful board
2. **Level complete** — three stars and the confetti burst
3. **Journey map** — the eight worlds with progress bars
4. **Daily Challenge** — the streak flame and week strip
5. **Level select** — a grid of stars in one world
6. **Dark mode gameplay** — shows the theme support

Add a short caption band to each in any image editor, e.g.
*"Swipe in any direction"*, *"240 levels to explore"*, *"A new puzzle daily"*.

---

## Categorisation

| Field | Value |
|-------|-------|
| App type | Game |
| Category | **Word** |
| Tags | Word game, Puzzle, Brain game, Casual |
| Content rating | Everyone (no violence, no chat, no UGC) |
| Ads | **Yes** — contains ads |
| In-app purchases | **Yes** — $0.99 – $5.99 per item |
| Target audience | 13+ (avoids child-directed ad requirements) |

---

## Store settings

**Privacy policy URL** *(required by Play — paste this into the field)*:

```
https://benimad.github.io/words/privacy.html
```

**Terms of service URL:**
```
https://benimad.github.io/words/terms.html
```

**Support URL:**
```
https://benimad.github.io/words/support.html
```

**Support email:**
```
adamlaalami72@gmail.com
```

---

## Data safety form answers

Play's Data Safety questionnaire, answered to match what the app actually does:

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | **Yes** — via the ads SDK only |
| Data types collected | *Device or other IDs* → Advertising ID |
| | *Location* → Approximate location (derived from IP by AdMob) |
| | *App activity* → App interactions (ad impressions/clicks) |
| Purpose | Advertising or marketing; Fraud prevention |
| Is data shared with third parties? | **Yes** — with Google (AdMob) |
| Is collection optional? | No for ads; removable by purchasing the ad-free upgrade |
| Is data encrypted in transit? | **Yes** |
| Can users request deletion? | **Yes** — in-app reset, or uninstall |
| Does your app collect names, emails, photos, files, contacts, location precisely? | **No** |

> Game progress, coins and settings are stored **only on the device** and are
> never transmitted, so they are not "collected" under Play's definition and
> should not be declared.

---

## Release notes (first version)

```
Welcome to WordQuest!

• 240 levels across 8 themed worlds
• A brand new Daily Challenge every day, with streak rewards
• Three hint types for when a board gets stubborn
• 14 achievements and explorer ranks to climb
• Light and dark themes, plus accessibility options
• Plays completely offline

Thanks for playing. Let us know what you think!
```

---

## ⚠️ Before you submit

1. **Change the icon's sub-line.** The current artwork reads *"WORD SEARCH
   EXPLORER"*, which is the exact name of an existing app on Google Play. A
   matching name is the most common trigger for an impersonation takedown or a
   trademark complaint. Replacing that line with something original — e.g.
   *"PUZZLE JOURNEY"* or *"WORD PUZZLE ADVENTURE"* — removes the risk while
   keeping the artwork you like.
2. **Replace the AdMob IDs.** The build currently uses Google's public *test*
   ad IDs. Shipping those will get the app rejected. Update
   `lib/data/services/ad_service.dart` and the `APPLICATION_ID` in
   `AndroidManifest.xml`.
3. **Wire real billing.** The shop's paid buttons currently grant items locally
   behind a demo dialog. Integrate `in_app_purchase` before charging anyone.
4. **Enable GitHub Pages** so the privacy policy URL resolves — see below.
```
Repo → Settings → Pages → Source: "Deploy from a branch"
                        → Branch: main,  Folder: /docs  → Save
```
Wait ~1 minute, then confirm the URL loads before pasting it into Play.
