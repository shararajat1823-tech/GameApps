import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:free_games/main.dart';

void main() {
  testWidgets('Home screen shows all games', (tester) async {
    // Use a tall window so every tile in the scrolling grid is built.
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FreeGamesApp());

    expect(find.text('FREE GAMES'), findsOneWidget);
    for (final name in const [
      'Memory Match',
      '2048',
      'Sliding Puzzle',
      'Simon',
      'Reaction Time',
      'Bubble Pop',
    ]) {
      expect(find.text(name), findsOneWidget, reason: 'missing tile: $name');
    }
  });

  testWidgets('Tapping Memory Match opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Memory Match'));
    await tester.pumpAndSettle();

    expect(find.text('Moves'), findsOneWidget);
    expect(find.text('Shuffle / Restart'), findsOneWidget);
  });

  testWidgets('Tapping 2048 opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('2048'));
    await tester.pumpAndSettle();

    expect(find.text('New Game'), findsOneWidget);
  });
}
