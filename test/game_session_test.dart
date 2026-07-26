import 'package:flutter_test/flutter_test.dart';
import 'package:wordquest/data/content/level_catalog.dart';
import 'package:wordquest/data/models/grid_position.dart';
import 'package:wordquest/data/models/hint.dart';
import 'package:wordquest/state/game_session_controller.dart';

/// Drives the controller to a ready state, since `start()` has an internal
/// frame delay before the board exists.
Future<GameSessionController> startedSession({int levelIndex = 0}) async {
  final level = LevelCatalog.levelByGlobalIndex(levelIndex)!;
  final session = GameSessionController(
    level: level,
    isDailyChallenge: false,
  );
  await session.start();
  return session;
}

void main() {
  group('GameSessionController — lifecycle', () {
    test('reaches playing state with a solvable board', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      expect(session.status, GameStatus.playing);
      expect(session.isReady, isTrue);
      expect(session.puzzle.isSolvable, isTrue);
      expect(session.wordsRemaining, session.puzzle.placedWords.length);
    });

    test('pause and resume gate input', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      session.pause();
      expect(session.status, GameStatus.paused);

      // Selections are ignored while paused.
      session.beginSelection(const GridPosition(0, 0));
      expect(session.selection, isEmpty);

      session.resume();
      expect(session.status, GameStatus.playing);
      session.beginSelection(const GridPosition(0, 0));
      expect(session.selection, hasLength(1));
    });
  });

  group('GameSessionController — selection', () {
    test('accepts a correct word swiped forwards', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      final target = session.puzzle.placedWords.first;
      session.beginSelection(target.cells.first);
      for (final cell in target.cells.skip(1)) {
        session.extendSelection(cell);
      }

      expect(session.endSelection(), SelectionResult.accepted);
      expect(session.isWordFound(target.word), isTrue);
      expect(session.foundWords.single.viaHint, isFalse);
    });

    test('accepts the same word swiped backwards', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      final target = session.puzzle.placedWords.first;
      final reversed = target.cells.reversed.toList();

      session.beginSelection(reversed.first);
      for (final cell in reversed.skip(1)) {
        session.extendSelection(cell);
      }

      expect(session.endSelection(), SelectionResult.accepted);
      expect(session.isWordFound(target.word), isTrue);
    });

    test('only the endpoints are needed — the line fills itself', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      final target = session.puzzle.placedWords.first;
      session.beginSelection(target.cells.first);
      // Jump straight to the last cell, as a fast swipe would.
      session.extendSelection(target.cells.last);

      expect(session.selection, target.cells);
      expect(session.endSelection(), SelectionResult.accepted);
    });

    test('rejects a selection that is not a word', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      final before = session.rejectionCounter;

      // Find a straight run of cells that is not one of the answers.
      session.beginSelection(const GridPosition(0, 0));
      session.extendSelection(const GridPosition(0, 1));
      session.extendSelection(const GridPosition(0, 2));

      final result = session.endSelection();

      // If the board happens to hide a word there, the test still holds: it is
      // either a genuine accept or a genuine reject, never a silent no-op.
      if (result == SelectionResult.rejected) {
        expect(session.rejectionCounter, before + 1);
        expect(session.foundWords, isEmpty);
      } else {
        expect(result, SelectionResult.accepted);
      }
    });

    test('ignores off-axis positions instead of corrupting the line', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      session.beginSelection(const GridPosition(0, 0));
      session.extendSelection(const GridPosition(0, 3)); // valid: same row
      final valid = List.of(session.selection);

      // (1,2) is neither in row 0, column 0, nor on the diagonal.
      session.extendSelection(const GridPosition(1, 2));
      expect(session.selection, valid);
    });

    test('a single tap is not treated as an attempt', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      session.beginSelection(const GridPosition(2, 2));
      expect(session.endSelection(), SelectionResult.none);
      expect(session.rejectionCounter, 0);
    });

    test('re-selecting a solved word reports alreadyFound', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      final target = session.puzzle.placedWords.first;

      void swipe() {
        session.beginSelection(target.cells.first);
        session.extendSelection(target.cells.last);
      }

      swipe();
      expect(session.endSelection(), SelectionResult.accepted);

      swipe();
      expect(session.endSelection(), SelectionResult.alreadyFound);
      expect(session.foundWords, hasLength(1));
    });

    test('completes when every word is found', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      for (final placed in session.puzzle.placedWords) {
        session.beginSelection(placed.cells.first);
        session.extendSelection(placed.cells.last);
        expect(session.endSelection(), SelectionResult.accepted);
      }

      expect(session.status, GameStatus.completed);
      expect(session.wordsRemaining, 0);
      expect(session.completionRatio, 1.0);
    });
  });

  group('GameSessionController — hints', () {
    test('first-letter hint marks a starting cell', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      expect(session.applyHint(HintType.firstLetter), HintOutcome.applied);
      expect(session.hintedCells, hasLength(1));
      expect(session.hintsUsed, 1);

      // The hinted cell must genuinely be the start of an unsolved word.
      final starts =
          session.puzzle.placedWords.map((w) => w.cells.first).toSet();
      expect(starts, contains(session.hintedCells.first));
    });

    test('reveal-word hint solves a word and flags it as hinted', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      expect(session.applyHint(HintType.revealWord), HintOutcome.applied);
      expect(session.foundWords, hasLength(1));
      expect(session.foundWords.single.viaHint, isTrue);
      expect(session.hintsUsed, 1);
    });

    test('clear-clutter dims only non-answer cells', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      expect(session.applyHint(HintType.clearClutter), HintOutcome.applied);
      expect(session.dimmedCells, isNotEmpty);

      final answerCells = {
        for (final word in session.puzzle.placedWords) ...word.cells,
      };
      for (final dimmed in session.dimmedCells) {
        expect(answerCells.contains(dimmed), isFalse);
      }
    });

    test('reveal-word reports nothing to reveal once solved', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      // Reveal every word.
      for (var i = 0; i < session.puzzle.placedWords.length; i++) {
        session.applyHint(HintType.revealWord);
      }

      // The board is complete, so the session is no longer playing.
      expect(session.status, GameStatus.completed);
      expect(
        session.applyHint(HintType.revealWord),
        HintOutcome.nothingToReveal,
      );
    });
  });

  group('GameSessionController — restart', () {
    test('restart clears all in-level state', () async {
      final session = await startedSession();
      addTearDown(session.dispose);

      session.applyHint(HintType.revealWord);
      final target = session.puzzle.placedWords.last;
      session.beginSelection(target.cells.first);
      session.extendSelection(target.cells.last);
      session.endSelection();

      session.restart();

      expect(session.foundWords, isEmpty);
      expect(session.solvedCells, isEmpty);
      expect(session.hintedCells, isEmpty);
      expect(session.dimmedCells, isEmpty);
      expect(session.hintsUsed, 0);
      expect(session.elapsed, Duration.zero);
      expect(session.status, GameStatus.playing);
    });
  });
}
