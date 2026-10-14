import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:free_games/main.dart';

void main() {
  testWidgets('Home screen shows all games', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FreeGamesApp());

    expect(find.text('ARCADE'), findsOneWidget);
    for (final name in const ['Stack', 'Flip', 'Dodge']) {
      expect(find.text(name), findsOneWidget, reason: 'missing card: $name');
    }
  });

  testWidgets('Tapping Stack opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Stack'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Best'), findsOneWidget);
  });

  testWidgets('Tapping Dodge opens the game', (tester) async {
    await tester.pumpWidget(const FreeGamesApp());

    await tester.tap(find.text('Dodge'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Best'), findsOneWidget);
  });
}
