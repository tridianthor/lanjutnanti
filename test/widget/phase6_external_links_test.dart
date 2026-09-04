import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/content_detail_screen.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late SqliteContentRepository contents;
  late SqliteContentDetailRepository details;
  late ContentListController controller;

  setUp(() {
    database = AppDatabase.openInMemory();
    final clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1']),
    );
    details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1', 'detail-2']),
    );
    controller = ContentListController(
      service: ContentApplicationService(
        contentRepository: contents,
        detailRepository: details,
        tagRepository: SqliteTagRepository(
          database,
          clock: clock,
          idGenerator: SequenceIdGenerator([]),
        ),
      ),
    );
  });

  tearDown(() => database.dispose());

  testWidgets(
    'home latest Open button delegates the exact URI and is keyboard activatable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      final content = contents.create(name: 'Doraemon');
      const link = 'https://example.com/latest?chapter=6';
      details.create(contentId: content.id, link: link);
      final launcher = _SequenceLinkLauncher([true]);

      await tester.pumpWidget(
        _app(
          HomeScreen(controller: controller, linkLauncher: launcher),
        ),
      );
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      final openButton = find.byKey(
        const ValueKey('open-latest-content-content-1'),
      );
      expect(find.bySemanticsLabel('Open latest link'), findsOneWidget);
      final openButtonSemantics = find
          .descendant(of: openButton, matching: find.byType(Semantics))
          .first;
      final openButtonFocus = Focus.of(tester.element(openButtonSemantics));

      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (openButtonFocus.hasFocus) break;
      }
      expect(openButtonFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(launcher.opened, [link]);
    },
  );

  testWidgets('historical Open button delegates its own exact URI', (
    tester,
  ) async {
    final content = contents.create(name: 'Doraemon');
    const olderLink = 'https://example.com/older';
    const latestLink = 'https://example.com/latest';
    details.create(contentId: content.id, link: olderLink);
    details.create(contentId: content.id, link: latestLink);
    final launcher = _SequenceLinkLauncher([true]);

    await tester.pumpWidget(
      _app(
        ContentDetailScreen(
          contentId: content.id,
          controller: controller,
          linkLauncher: launcher,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final olderCard = find.byKey(const ValueKey('detail-detail-1'));
    await tester.tap(
      find.descendant(of: olderCard, matching: find.text('Open link')),
    );
    await tester.pump();

    expect(launcher.opened, [olderLink]);
    expect(find.bySemanticsLabel('Open link'), findsNWidgets(2));
  });

  testWidgets(
    'failed launch keeps saved data and offers a retry action',
    (tester) async {
      final content = contents.create(name: 'Doraemon');
      const link = 'https://example.com/unavailable';
      final detail = details.create(contentId: content.id, link: link);
      final launcher = _SequenceLinkLauncher([false, true]);

      await tester.pumpWidget(
        _app(
          ContentDetailScreen(
            contentId: content.id,
            controller: controller,
            linkLauncher: launcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open link'));
      await tester.pump();

      expect(find.text('Could not open this link.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(contents.findById(content.id), isNotNull);
      expect(details.findById(detail.id), isNotNull);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(launcher.opened, [link, link]);
      expect(contents.findById(content.id), isNotNull);
      expect(details.findById(detail.id), isNotNull);
    },
  );

  testWidgets('failed latest launch offers the same retry action on home', (
    tester,
  ) async {
    final content = contents.create(name: 'Doraemon');
    const link = 'https://example.com/home-error';
    final detail = details.create(contentId: content.id, link: link);
    final launcher = _SequenceLinkLauncher([false]);

    await tester.pumpWidget(
      _app(HomeScreen(controller: controller, linkLauncher: launcher)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('open-latest-content-content-1')),
    );
    await tester.pump();

    expect(find.text('Could not open this link.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(contents.findById(content.id), isNotNull);
    expect(details.findById(detail.id), isNotNull);
  });

  testWidgets('launcher exceptions show the same non-destructive retry error', (
    tester,
  ) async {
    final content = contents.create(name: 'Doraemon');
    const link = 'https://example.com/error';
    final detail = details.create(contentId: content.id, link: link);
    final launcher = _ThrowingLinkLauncher();

    await tester.pumpWidget(
      _app(
        ContentDetailScreen(
          contentId: content.id,
          controller: controller,
          linkLauncher: launcher,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open link'));
    await tester.pump();

    expect(find.text('Could not open this link.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(contents.findById(content.id), isNotNull);
    expect(details.findById(detail.id), isNotNull);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: home,
  );
}

class _SequenceLinkLauncher implements LinkLauncher {
  _SequenceLinkLauncher(this._results);

  final List<bool> _results;
  final List<String> opened = [];

  @override
  Future<bool> open(String link) async {
    opened.add(link);
    return _results.removeAt(0);
  }
}

class _ThrowingLinkLauncher implements LinkLauncher {
  @override
  Future<bool> open(String link) async {
    throw StateError('No handler is available');
  }
}
