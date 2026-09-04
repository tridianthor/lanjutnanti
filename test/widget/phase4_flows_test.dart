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
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late SqliteContentRepository contents;
  late SqliteContentDetailRepository details;
  late SqliteTagRepository tags;
  late ContentListController controller;
  late RecordingLinkLauncher launcher;

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1', 'content-2']),
    );
    details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1', 'detail-2']),
    );
    tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-1', 'tag-2']),
    );
    controller = ContentListController(
      service: ContentApplicationService(
        contentRepository: contents,
        detailRepository: details,
        tagRepository: tags,
      ),
    );
    launcher = RecordingLinkLauncher();
  });

  tearDown(() {
    database.dispose();
  });

  testWidgets('home rows show latest projections and only enable real links', (
    tester,
  ) async {
    final emptyContent = contents.create(name: 'Empty entry');
    clock.value = DateTime.utc(2026, 9, 5, 5);
    final tag = tags.create('Manga');
    final savedContent = contents.create(name: 'Doraemon', tagId: tag.id);
    details.create(
      contentId: savedContent.id,
      link: 'https://example.com/chapter-6',
      note: 'Continue at chapter 6',
    );

    await tester.pumpWidget(
      _app(
        HomeScreen(
          controller: controller,
          tagService: TagApplicationService(tags),
          linkLauncher: launcher,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doraemon'), findsOneWidget);
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Continue at chapter 6'), findsOneWidget);
    expect(find.textContaining('Latest ·'), findsNWidgets(2));
    expect(find.text('Empty entry'), findsOneWidget);

    final savedOpenButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('open-latest-content-2')),
    );
    final emptyOpenButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('open-latest-content-1')),
    );
    expect(savedOpenButton.onPressed, isNotNull);
    expect(emptyOpenButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('open-latest-content-2')));
    await tester.pumpAndSettle();
    expect(launcher.opened, ['https://example.com/chapter-6']);

    // The controller-provided ordering puts the recently active saved item
    // before the content that has never had a detail.
    expect(
      tester.getTopLeft(find.text('Doraemon')).dy,
      lessThan(tester.getTopLeft(find.text('Empty entry')).dy),
    );

    expect(emptyContent.id, 'content-1');
  });

  testWidgets(
    'content creation supports tags and offers the first detail flow',
    (tester) async {
      await tester.pumpWidget(
        _app(
          HomeScreen(
            controller: controller,
            tagService: TagApplicationService(tags),
            linkLauncher: launcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Content').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Content'));
      await tester.pump();
      expect(find.text('Enter a content name.'), findsOneWidget);

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '  Doraemon  ');
      await tester.tap(find.text('Create tag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, ' Manga ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Manga'), findsOneWidget);
      await tester.tap(find.text('Save Content'));
      await tester.pumpAndSettle();

      expect(find.text('Doraemon'), findsNWidgets(2));
      expect(
        find.text('No details saved yet. Add your first continuation link.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FloatingActionButton, 'Add Detail'),
        findsOneWidget,
      );
      expect(contents.findById('content-1')!.tagId, 'tag-1');
    },
  );

  testWidgets('detail form validates inline and preserves input on failure', (
    tester,
  ) async {
    final content = contents.create(name: 'Doraemon');
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

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Detail'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'chapter/6');
    await tester.enterText(fields.last, 'Keep this note');
    await tester.tap(find.text('Save Detail'));
    await tester.pump();

    expect(find.text('Enter a valid absolute link.'), findsOneWidget);
    expect(
      tester.widget<TextField>(fields.first).controller!.text,
      'chapter/6',
    );
    expect(
      tester.widget<TextField>(fields.last).controller!.text,
      'Keep this note',
    );

    await tester.enterText(fields.first, '  https://example.com/chapter-6  ');
    await tester.tap(find.text('Save Detail'));
    await tester.pumpAndSettle();

    expect(find.text('https://example.com/chapter-6'), findsOneWidget);
    expect(find.text('Keep this note'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
  });

  testWidgets('editing an older detail visibly promotes it to latest', (
    tester,
  ) async {
    final content = contents.create(name: 'Doraemon');
    final first = details.create(
      contentId: content.id,
      link: 'https://example.com/first',
    );
    clock.value = DateTime.utc(2026, 9, 5);
    details.create(contentId: content.id, link: 'https://example.com/second');
    clock.value = DateTime.utc(2026, 9, 6);

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

    final firstCard = find.byKey(ValueKey('detail-${first.id}'));
    await tester.tap(
      find.descendant(of: firstCard, matching: find.byTooltip('Edit detail')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'https://example.com/edited',
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final secondCard = find.byKey(const ValueKey('detail-detail-2'));
    expect(
      find.descendant(of: firstCard, matching: find.text('Latest')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: secondCard, matching: find.text('Latest')),
      findsNothing,
    );
    expect(find.text('https://example.com/edited'), findsOneWidget);
  });

  testWidgets(
    'canceling detail and content deletion leaves records unchanged',
    (tester) async {
      final content = contents.create(name: 'Doraemon');
      final detail = details.create(
        contentId: content.id,
        link: 'https://example.com/chapter-6',
      );
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

      await tester.tap(find.byTooltip('Delete detail'));
      await tester.pumpAndSettle();
      expect(find.text('Delete detail?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete detail?'), findsNothing);
      expect(details.findById(detail.id), isNotNull);

      await tester.tap(find.byTooltip('Delete content'));
      await tester.pumpAndSettle();
      expect(find.text('Delete content?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(contents.findById(content.id), isNotNull);
      expect(details.findById(detail.id), isNotNull);
    },
  );

  testWidgets('forms remain usable at phone and desktop-like widths', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _app(
          HomeScreen(
            controller: controller,
            tagService: TagApplicationService(tags),
            linkLauncher: launcher,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada konten'), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
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

class RecordingLinkLauncher implements LinkLauncher {
  final List<String> opened = [];

  @override
  Future<bool> open(String link) async {
    opened.add(link);
    return true;
  }
}
