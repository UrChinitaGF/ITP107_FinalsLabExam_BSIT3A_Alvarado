import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:post_reader_favorites/boxes.dart';
import 'package:post_reader_favorites/main.dart';

void main() {
  setUpAll(() async {
    // Local Hive directory for tests (main() is not called here).
    Hive.init(Directory.systemTemp.createTempSync('favorites_test').path);
    await Hive.openBox<Map<dynamic, dynamic>>(Boxes.favoritesBoxName);
  });

  tearDownAll(() async {
    // The swipe test starts a Hive write from inside the fake-async zone of
    // testWidgets, so that future can never settle and closing the box may
    // block forever. Never let disk cleanup hang the suite.
    try {
      await Hive.deleteFromDisk().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort cleanup of the temp directory only.
    }
  });

  testWidgets('Posts screen shows its AppBar, list area, and FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Posts'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Favorites'), findsOneWidget);
  });

  testWidgets('Named route /details receives the post arguments',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed(
      '/details',
      arguments: <String, dynamic>{
        'id': 7,
        'userId': 1,
        'title': 'A post read through ModalRoute',
        'body': 'The body text of the post.',
      },
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Post Details'), findsOneWidget);
    expect(find.text('A post read through ModalRoute'), findsOneWidget);
    expect(find.text('The body text of the post.'), findsOneWidget);
    expect(find.text('Save to Favorites'), findsOneWidget);
  });

  testWidgets('Named route /favorites is reachable', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/favorites');
    await tester.pump();
    await tester.pump();

    expect(find.text('Favorites'), findsOneWidget);
  });

  test('Hive favorites support create, read, update, delete', () async {
    final Box<Map<dynamic, dynamic>> box = Boxes.favorites;

    // CREATE
    await Boxes.saveFavorite(<String, dynamic>{
      'id': 42,
      'title': 'Stored locally',
      'body': 'Persisted on the device.',
    });
    expect(box.containsKey(42), isTrue);
    // Saving the same id again must not create a duplicate.
    await Boxes.saveFavorite(<String, dynamic>{'id': 42, 'title': 'Stored locally'});
    expect(box.length, 1);

    // READ
    final Map<dynamic, dynamic>? saved = box.get(42);
    expect(saved, isNotNull);
    expect(saved!['title'], 'Stored locally');

    // UPDATE
    await Boxes.saveNote(42, 'Reviewed for the exam');
    expect(box.get(42)!['note'], 'Reviewed for the exam');

    // DELETE
    await Boxes.deleteFavorite(42);
    expect(box.containsKey(42), isFalse);
  });

  // Keep this test last: the swipe writes to Hive from inside the fake-async
  // zone, which leaves the box's write queue unable to settle.
  testWidgets('Swiping a favorite to the left removes it from the box',
      (WidgetTester tester) async {
    // Hive writes do real file I/O, which never completes inside the
    // fake-async zone of testWidgets unless we hand it to runAsync().
    await tester.runAsync(() => Boxes.saveFavorite(<String, dynamic>{
          'id': 99,
          'title': 'Swipe me',
          'body': 'Swipe this card to the left to delete it.',
        }));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/favorites');
    await tester.pump();
    await tester.pump();

    expect(find.byType(Dismissible), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));

    // Bounded pumps instead of pumpAndSettle(): the screen below keeps
    // scheduling frames, so pumpAndSettle() would never finish.
    // Covers the dismiss animation, the Hive delete, and the rebuild.
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The card is gone from the screen and from the Hive box.
    expect(find.byType(Dismissible), findsNothing);
    expect(Boxes.favorites.containsKey(99), isFalse);
  });
}
