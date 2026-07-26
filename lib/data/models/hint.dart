import 'package:flutter/material.dart';

/// The three ways a player can spend coins to make a board easier.
///
/// Prices rise with how much of the puzzle each hint solves, and none of them
/// can be bought with real money directly — coins are earned by playing, which
/// keeps the game from being pay-to-win.
enum HintType {
  /// Flashes the first letter of a random unsolved word.
  firstLetter(
    label: 'First Letter',
    description: 'Reveals where one unfound word begins.',
    cost: 25,
    icon: Icons.lightbulb_outline_rounded,
  ),

  /// Permanently reveals one whole unsolved word.
  revealWord(
    label: 'Reveal Word',
    description: 'Solves one unfound word for you.',
    cost: 75,
    icon: Icons.auto_fix_high_rounded,
  ),

  /// Fades out a batch of letters that belong to no answer.
  clearClutter(
    label: 'Clear Clutter',
    description: 'Dims a batch of letters that are not part of any word.',
    cost: 50,
    icon: Icons.cleaning_services_rounded,
  );

  const HintType({
    required this.label,
    required this.description,
    required this.cost,
    required this.icon,
  });

  final String label;
  final String description;
  final int cost;
  final IconData icon;
}

/// Outcome of asking the hint engine to apply a hint. Modelled explicitly so
/// the UI can respond correctly to every case instead of guessing.
enum HintOutcome {
  applied,
  notEnoughCoins,
  nothingToReveal,
}
