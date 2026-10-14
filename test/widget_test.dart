import 'package:flutter_test/flutter_test.dart';

import 'package:free_games/main.dart';

void main() {
  testWidgets('Home screen shows the title and games', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    expect(find.text('FREE GAMES'), findsOneWidget);
    expect(find.text('Memory Match'), findsOneWidget);
    expect(find.text('Bubble Pop'), findsOneWidget);
    expect(find.text('Reaction Time'), findsOneWidget);
  });

  testWidgets('Tapping Memory Match opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Memory Match'));
    await tester.pumpAndSettle();

    expect(find.text('Moves'), findsOneWidget);
    expect(find.text('Shuffle / Restart'), findsOneWidget);
  });

  testWidgets('Tapping Reaction Time opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Reaction Time'));
    await tester.pumpAndSettle();

    expect(find.text('Tap anywhere to start'), findsOneWidget);
  });
}
