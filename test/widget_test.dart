import 'package:flutter_test/flutter_test.dart';

import 'package:free_games/main.dart';

void main() {
  testWidgets('Home screen shows the title and games', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    expect(find.text('FREE GAMES'), findsOneWidget);
    expect(find.text('Tic-Tac-Toe'), findsOneWidget);
    expect(find.text('Ludo'), findsOneWidget);
  });

  testWidgets('Tapping Tic-Tac-Toe opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Tic-Tac-Toe'));
    await tester.pumpAndSettle();

    expect(find.text('Your turn (X)'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
  });
}
