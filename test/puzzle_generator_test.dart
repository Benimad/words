import 'package:flutter_test/flutter_test.dart';
import 'package:wordquest/data/content/level_catalog.dart';
import 'package:wordquest/data/models/grid_position.dart';
import 'package:wordquest/game/generator/puzzle_generator.dart';

void main() {
  const generator = PuzzleGenerator();

  group('PuzzleGenerator — contract', () {
    test('places the requested number of words', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 10,
          cols: 10,
          wordPool: const [
            'FOREST', 'RIVER', 'STONE', 'MEADOW', 'CANOPY', 'BRANCH',
            'PETAL', 'ACORN', 'FERN', 'MOSS',
          ],
          wordCount: 7,
          allowedDirections: WordDirection.values,
          seed: 42,
        ),
      );

      expect(puzzle.placedWords, hasLength(7));
      expect(puzzle.isSolvable, isTrue);
    });

    test('every placed word is actually readable in the grid', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 9,
          cols: 9,
          wordPool: const [
            'CORAL', 'WAVE', 'SHELL', 'TIDE', 'REEF', 'SAND', 'DUNE',
            'OCEAN', 'SURF',
          ],
          wordCount: 6,
          allowedDirections: WordDirection.values,
          seed: 7,
        ),
      );

      for (final placed in puzzle.placedWords) {
        final read = placed.cells
            .map((c) => puzzle.grid[c.row][c.col])
            .join();
        expect(read, placed.word, reason: '${placed.word} misplaced');
      }
    });

    test('grid is completely filled — no blank cells', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 8,
          cols: 8,
          wordPool: const ['ATOM', 'ORBIT', 'STAR', 'COMET', 'NOVA', 'MOON'],
          wordCount: 5,
          allowedDirections: WordDirection.values,
          seed: 99,
        ),
      );

      for (final row in puzzle.grid) {
        for (final letter in row) {
          expect(letter, matches(RegExp(r'^[A-Z]$')));
        }
      }
    });

    test('never contains duplicate answers', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 10,
          cols: 10,
          // Deliberately seeded with duplicates and case/format noise.
          wordPool: const ['STAR', 'star', 'St-ar', 'MOON', 'MOON ', 'COMET'],
          wordCount: 3,
          allowedDirections: WordDirection.values,
          seed: 5,
        ),
      );

      final words = puzzle.words;
      expect(words.toSet(), hasLength(words.length));
    });

    test('respects the allowed direction list', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 9,
          cols: 9,
          wordPool: const ['ALPHA', 'BRAVO', 'DELTA', 'ECHO', 'GOLF', 'HOTEL'],
          wordCount: 5,
          allowedDirections: const [WordDirection.east, WordDirection.south],
          seed: 11,
        ),
      );

      for (final placed in puzzle.placedWords) {
        expect(
          const [WordDirection.east, WordDirection.south],
          contains(placed.direction),
        );
      }
    });

    test('is deterministic for a given seed', () {
      PuzzleRequest request() => PuzzleRequest(
            rows: 10,
            cols: 10,
            wordPool: const [
              'ANCHOR', 'HARBOR', 'VOYAGE', 'CAPTAIN', 'COMPASS', 'MAST',
              'SAIL', 'DECK',
            ],
            wordCount: 6,
            allowedDirections: WordDirection.values,
            seed: 2024,
          );

      final a = generator.generate(request());
      final b = generator.generate(request());

      expect(
        a.grid.map((r) => r.join()).join('|'),
        b.grid.map((r) => r.join()).join('|'),
      );
      expect(a.words, b.words);
    });

    test('all words stay inside the board bounds', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 7,
          cols: 7,
          wordPool: const ['FOX', 'OWL', 'DEER', 'WOLF', 'BEAR', 'HARE'],
          wordCount: 5,
          allowedDirections: WordDirection.values,
          seed: 3,
        ),
      );

      for (final placed in puzzle.placedWords) {
        for (final cell in placed.cells) {
          expect(puzzle.contains(cell), isTrue);
        }
      }
    });
  });

  group('PuzzleGenerator — edge cases', () {
    test('rejects boards that are too small', () {
      expect(
        () => generator.generate(
          PuzzleRequest(
            rows: 2,
            cols: 2,
            wordPool: const ['HI'],
            wordCount: 1,
            allowedDirections: WordDirection.values,
            seed: 1,
          ),
        ),
        throwsA(isA<PuzzleGenerationException>()),
      );
    });

    test('rejects an empty direction list', () {
      expect(
        () => generator.generate(
          PuzzleRequest(
            rows: 8,
            cols: 8,
            wordPool: const ['WORD'],
            wordCount: 1,
            allowedDirections: const [],
            seed: 1,
          ),
        ),
        throwsA(isA<PuzzleGenerationException>()),
      );
    });

    test('throws when no word can possibly fit', () {
      expect(
        () => generator.generate(
          PuzzleRequest(
            rows: 4,
            cols: 4,
            // Every candidate is longer than the board.
            wordPool: const ['ELEPHANTINE', 'EXTRAORDINARY'],
            wordCount: 2,
            allowedDirections: WordDirection.values,
            seed: 1,
          ),
        ),
        throwsA(isA<PuzzleGenerationException>()),
      );
    });

    test('degrades gracefully when the board is over-subscribed', () {
      // Eight board-spanning words crammed onto a 7x7 grid. Each one *fits*
      // individually, but they cannot all coexist. The generator must return a
      // smaller, still-valid puzzle rather than throwing or hanging.
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 7,
          cols: 7,
          wordPool: const [
            'MOUNTS', 'PLANTS', 'STORMY', 'BRIDGE', 'CANDLE', 'FROSTY',
            'WANDER', 'SILVER',
          ],
          wordCount: 8,
          allowedDirections: WordDirection.values,
          seed: 4,
        ),
      );

      expect(puzzle.placedWords, isNotEmpty);
      expect(puzzle.placedWords.length, lessThanOrEqualTo(8));
      expect(puzzle.isSolvable, isTrue);
    });

    test('filters out words shorter than the minimum length', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 9,
          cols: 9,
          wordPool: const ['A', 'AN', 'CAT', 'HOUSE', 'GARDEN', 'PLANET'],
          wordCount: 4,
          allowedDirections: WordDirection.values,
          seed: 8,
          minWordLength: 3,
        ),
      );

      for (final word in puzzle.words) {
        expect(word.length, greaterThanOrEqualTo(3));
      }
    });
  });

  group('Puzzle — selection matching', () {
    test('matches a selection in both reading directions', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 9,
          cols: 9,
          wordPool: const ['RIVER', 'STONE', 'CLOUD', 'FIELD'],
          wordCount: 3,
          allowedDirections: WordDirection.values,
          seed: 13,
        ),
      );

      final target = puzzle.placedWords.first;

      expect(puzzle.matchSelection(target.cells)?.word, target.word);
      expect(
        puzzle.matchSelection(target.cells.reversed.toList())?.word,
        target.word,
      );
    });

    test('rejects a selection that is not an answer', () {
      final puzzle = generator.generate(
        PuzzleRequest(
          rows: 9,
          cols: 9,
          wordPool: const ['RIVER', 'STONE', 'CLOUD', 'FIELD'],
          wordCount: 3,
          allowedDirections: WordDirection.values,
          seed: 13,
        ),
      );

      // A selection of the wrong length can never be an answer.
      expect(puzzle.matchSelection(const [GridPosition(0, 0)]), isNull);
      expect(puzzle.matchSelection(const []), isNull);
    });
  });

  group('Campaign — every shipped level is solvable', () {
    test('all 240 levels generate valid, solvable puzzles', () {
      final levels = LevelCatalog.allLevels;
      expect(levels, hasLength(240));

      for (final level in levels) {
        final puzzle = generator.generate(
          PuzzleRequest(
            rows: level.rows,
            cols: level.cols,
            wordPool: level.wordPool,
            wordCount: level.wordCount,
            allowedDirections: level.allowedDirections,
            seed: level.seed,
          ),
        );

        expect(
          puzzle.isSolvable,
          isTrue,
          reason: '${level.id} (${level.theme}) produced an invalid puzzle',
        );

        // Content promise: a level must deliver the word count it advertises.
        expect(
          puzzle.placedWords.length,
          level.wordCount,
          reason: '${level.id} placed ${puzzle.placedWords.length} words, '
              'expected ${level.wordCount}',
        );

        // And it must respect its band's direction restrictions.
        for (final placed in puzzle.placedWords) {
          expect(
            level.allowedDirections,
            contains(placed.direction),
            reason: '${level.id} used a forbidden direction',
          );
        }
      }
    });

    test('level ids are unique and worlds are well formed', () {
      final ids = LevelCatalog.allLevels.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));

      expect(LevelCatalog.worlds, hasLength(8));
      for (final world in LevelCatalog.worlds) {
        expect(world.levels, hasLength(30));
        expect(world.levels.first.globalIndex, world.order * 30);
      }
    });

    test('difficulty increases monotonically across the campaign', () {
      var previousArea = 0;
      for (final level in LevelCatalog.allLevels) {
        final area = level.rows * level.cols;
        expect(area, greaterThanOrEqualTo(previousArea));
        previousArea = area;
      }
    });
  });
}
