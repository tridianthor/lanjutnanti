import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
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

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1', 'content-2', 'content-3']),
    );
    details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator([
        'detail-1',
        'detail-2',
        'detail-3',
        'detail-4',
      ]),
    );
    tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-1']),
    );
  });

  tearDown(() => database.dispose());

  testWidgets(
    'search updates live, matches names tags and all notes, and deduplicates rows',
    (tester) async {
      final manga = tags.create('Manga');
      final doraemon = contents.create(name: 'Doraemon', tagId: manga.id);
      details.create(
        contentId: doraemon.id,
        link: 'https://example.com/doraemon',
        note: 'Continue at chapter 7',
      );
      details.create(
        contentId: doraemon.id,
        link: 'https://example.com/other',
        note: 'Chapter 6 was already read',
      );
      final cooking = contents.create(name: 'Cooking show');
      details.create(
        contentId: cooking.id,
        link: 'https://example.com/manga-link-only',
      );

      await tester.pumpWidget(
        _app(
          HomeScreen(
            controller: ContentListController(
              service: ContentApplicationService(
                contentRepository: contents,
                detailRepository: details,
                tagRepository: tags,
              ),
            ),
            tagService: TagApplicationService(tags),
            linkLauncher: _NoOpLinkLauncher(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('content-search-field')),
        findsOneWidget,
      );
      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Cooking show'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('content-search-field')),
        '  CHAPTER  ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Cooking show'), findsNothing);
      expect(
        find.byKey(const ValueKey('content-card-content-1')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('content-search-field')),
        'MANGA',
      );
      await tester.pumpAndSettle();
      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Cooking show'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('content-search-field')),
        'manga-link-only',
      );
      await tester.pumpAndSettle();
      expect(find.text('No content matches your search.'), findsOneWidget);
      expect(find.text('Cooking show'), findsNothing);
      expect(
        find.byKey(const ValueKey('clear-content-search')),
        findsOneWidget,
      );
      expect(find.text('Clear search'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clear-search-empty-state')));
      await tester.pumpAndSettle();
      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Cooking show'), findsOneWidget);
    },
  );

  testWidgets('tag filter narrows results and can be cleared', (tester) async {
    final manga = tags.create('Manga');
    contents.create(name: 'Doraemon', tagId: manga.id);
    contents.create(name: 'Cooking show');

    await tester.pumpWidget(
      _app(
        HomeScreen(
          controller: ContentListController(
            service: ContentApplicationService(
              contentRepository: contents,
              detailRepository: details,
              tagRepository: tags,
            ),
          ),
          tagService: TagApplicationService(tags),
          linkLauncher: _NoOpLinkLauncher(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('content-tag-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manga').last);
    await tester.pumpAndSettle();

    expect(find.text('Doraemon'), findsOneWidget);
    expect(find.text('Cooking show'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('content-tag-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All tags').last);
    await tester.pumpAndSettle();
    expect(find.text('Doraemon'), findsOneWidget);
    expect(find.text('Cooking show'), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: home,
  );
}

class _NoOpLinkLauncher implements LinkLauncher {
  @override
  Future<bool> open(String link) async => true;
}
