import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app.dart';

import '../support/database_test_support.dart';
import '../support/phase9_app_support.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;
  late MutableClock clock;
  late Phase9AppInstance app;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'lanjut_nanti_phase9_crud_',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}app.sqlite';
    clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    app = _openApp(databasePath: databasePath, clock: clock);
  });

  tearDown(() {
    app.dispose();
    temporaryDirectory.deleteSync(recursive: true);
  });

  testWidgets(
    'creates tagged content, edits history, and preserves latest after reopen',
    (tester) async {
      await tester.pumpWidget(LanjutNantiApp(dependencies: app.dependencies));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada konten'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Add Content'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '  Doraemon  ');
      await tester.tap(find.text('Create tag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, ' Manga ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Content'));
      await tester.pumpAndSettle();

      expect(find.text('Doraemon'), findsNWidgets(2));
      expect(
        find.text('No details saved yet. Add your first continuation link.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Detail'));
      await tester.pumpAndSettle();
      await _saveDetail(
        tester,
        link: 'https://example.com/doraemon/chapter-6',
        note: 'Continue at chapter 6',
      );

      clock.value = DateTime.utc(2026, 9, 5, 5);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Detail'));
      await tester.pumpAndSettle();
      await _saveDetail(
        tester,
        link: 'https://example.com/doraemon/chapter-7',
        note: 'Continue at chapter 7',
      );

      clock.value = DateTime.utc(2026, 9, 6, 5);
      final firstDetailCard = find.byKey(const ValueKey('detail-detail-1'));
      await tester.ensureVisible(firstDetailCard);
      await tester.pumpAndSettle();
      final firstDetailEditButton =
          find
              .descendant(
                of: firstDetailCard,
                matching: find.byType(IconButton),
              )
              .first;
      await tester.tap(firstDetailEditButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'https://example.com/doraemon/chapter-6-corrected',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'Corrected older checkpoint',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: firstDetailCard, matching: find.text('Latest')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('detail-detail-2')),
          matching: find.text('Latest'),
        ),
        findsNothing,
      );
      expect(find.text('Corrected older checkpoint'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      app.dispose();
      app = _openApp(databasePath: databasePath, clock: clock);

      await tester.pumpWidget(LanjutNantiApp(dependencies: app.dependencies));
      await tester.pumpAndSettle();
      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Corrected older checkpoint'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('content-search-field')),
        'chapter 7',
      );
      await tester.pumpAndSettle();
      expect(find.text('Doraemon'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('content-card-content-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('content-card-content-1')));
      await tester.pumpAndSettle();
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('2 details'), findsOneWidget);
      expect(
        find.text('https://example.com/doraemon/chapter-6-corrected'),
        findsOneWidget,
      );
      expect(
        find.text('https://example.com/doraemon/chapter-7'),
        findsOneWidget,
      );
      expect(find.text('Corrected older checkpoint'), findsOneWidget);
      expect(find.text('Latest'), findsOneWidget);
    },
  );
}

Phase9AppInstance _openApp({
  required String databasePath,
  required MutableClock clock,
}) {
  return Phase9AppInstance.open(
    databasePath: databasePath,
    clock: clock,
    idGenerator: SequenceIdGenerator([
      'tag-1',
      'content-1',
      'detail-1',
      'detail-2',
    ]),
  );
}

Future<void> _saveDetail(
  WidgetTester tester, {
  required String link,
  required String note,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, link);
  await tester.enterText(fields.last, note);
  await tester.tap(find.text('Save Detail'));
  await tester.pumpAndSettle();
}
