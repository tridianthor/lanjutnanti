import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/settings/presentation/settings_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/features/tags/presentation/tag_management_screen.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

void main() {
  late AppDatabase database;
  late SqliteTagRepository tagRepository;
  late TagApplicationService tagService;

  setUp(() {
    database = AppDatabase.openInMemory();
    tagRepository = SqliteTagRepository(database, clock: const SystemClock());
    tagService = TagApplicationService(tagRepository);
  });

  tearDown(() {
    database.dispose();
  });

  Widget buildApp({Widget? home, Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home ?? TagManagementScreen(tagService: tagService),
    );
  }

  group('CF-005: Settings to TagManagement navigation', () {
    testWidgets('SettingsScreen has Manage tags tile navigating to TagManagementScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(home: SettingsScreen(tagService: tagService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage tags'), findsOneWidget);
      expect(
        find.text('Create, rename, and delete tags for organizing content.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Manage tags'));
      await tester.pumpAndSettle();

      expect(find.byType(TagManagementScreen), findsOneWidget);
      expect(find.text('Manage tags'), findsOneWidget);
    });
  });

  group('CF-006: Tag listing and empty state', () {
    testWidgets('shows empty state when no tags exist', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No tags yet'), findsOneWidget);
      expect(
        find.text('Create tags to categorize and filter your saved content.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Create tag'), findsOneWidget);
    });

    testWidgets('displays tags in alphabetical order with action buttons', (
      tester,
    ) async {
      tagRepository.create('Zeta');
      tagRepository.create('Alpha');
      tagRepository.create('Beta');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));

      // Verify order: Alpha, Beta, Zeta
      expect(
        tester.getTopLeft(find.text('Alpha')).dy <
            tester.getTopLeft(find.text('Beta')).dy,
        isTrue,
      );
      expect(
        tester.getTopLeft(find.text('Beta')).dy <
            tester.getTopLeft(find.text('Zeta')).dy,
        isTrue,
      );

      expect(find.byTooltip('Rename tag'), findsNWidgets(3));
      expect(find.byTooltip('Delete tag'), findsNWidgets(3));
    });
  });

  group('CF-007: Tag creation flow', () {
    testWidgets('validates non-empty name and rejects duplicates with conflict error', (
      tester,
    ) async {
      tagRepository.create('Existing');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap create action in AppBar
      await tester.tap(find.byKey(const ValueKey('create-tag-action')));
      await tester.pumpAndSettle();

      // Submit empty
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a tag name.'), findsOneWidget);

      // Submit duplicate (case-insensitive check)
      await tester.enterText(find.byType(TextField), 'existing');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('A tag with that name already exists.'), findsOneWidget);

      // Submit valid new tag
      await tester.enterText(find.byType(TextField), 'Novel');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      // Dialog is dismissed, new tag is visible, SnackBar shows feedback
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Novel'), findsOneWidget);
      expect(find.text('Tag created.'), findsOneWidget);
    });
  });

  group('CF-008: Tag rename flow', () {
    testWidgets('pre-fills name, validates, rejects duplicate, and updates tag', (
      tester,
    ) async {
      final tag1 = tagRepository.create('Comics');
      tagRepository.create('Manga');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap rename on Comics
      await tester.tap(find.byKey(ValueKey('rename-tag-${tag1.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Rename tag'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Comics'),
        ),
        findsOneWidget,
      );

      // Clear text and submit empty
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a tag name.'), findsOneWidget);

      // Submit duplicate of Manga
      await tester.enterText(find.byType(TextField), 'manga');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();
      expect(find.text('A tag with that name already exists.'), findsOneWidget);

      // Submit valid rename
      await tester.enterText(find.byType(TextField), 'Graphic Novels');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Graphic Novels'), findsOneWidget);
      expect(find.text('Comics'), findsNothing);
      expect(find.text('Tag renamed.'), findsOneWidget);
    });
  });

  group('CF-009: Tag deletion flow', () {
    testWidgets('confirms deletion, unassigns tag without deleting content', (
      tester,
    ) async {
      final tag = tagRepository.create('Anime');
      final clock = const SystemClock();
      final contentRepo = SqliteContentRepository(database, clock: clock);
      contentRepo.create(name: 'Death Note', tagId: tag.id);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byKey(ValueKey('delete-tag-${tag.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Delete tag?'), findsOneWidget);
      expect(
        find.text('Content assigned to this tag will become untagged.'),
        findsOneWidget,
      );

      // Cancel first
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Anime'), findsOneWidget);
      expect(tagRepository.list(), hasLength(1));

      // Open and confirm deletion
      await tester.tap(find.byKey(ValueKey('delete-tag-${tag.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete tag'));
      await tester.pumpAndSettle();

      // Tag deleted feedback, empty state shown
      expect(find.text('Tag deleted.'), findsOneWidget);
      expect(find.text('Anime'), findsNothing);
      expect(tagRepository.list(), isEmpty);

      // Content still exists, with null tagId
      final contents = contentRepo.listRecent();
      expect(contents, hasLength(1));
      expect(contents.first.name, 'Death Note');
      expect(contents.first.tagId, isNull);
    });
  });

  group('CF-010: Synchronization to HomeScreen', () {
    testWidgets('returning to HomeScreen after tag changes refreshes tag filters', (
      tester,
    ) async {
      final clock = const SystemClock();
      final contentRepo = SqliteContentRepository(database, clock: clock);
      final detailRepo = SqliteContentDetailRepository(database, clock: clock);
      final contentController = ContentListController(
        service: ContentApplicationService(
          contentRepository: contentRepo,
          detailRepository: detailRepo,
          tagRepository: tagRepository,
        ),
      );
      addTearDown(contentController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            controller: contentController,
            tagService: tagService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no tags filter dropdown
      expect(find.byKey(const ValueKey('content-tag-filter')), findsNothing);

      // Open Settings
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();

      // Open TagManagement
      await tester.tap(find.text('Manage tags'));
      await tester.pumpAndSettle();

      // Create tag 'Series'
      await tester.tap(find.byKey(const ValueKey('create-tag-action')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Series');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      // Pop back from TagManagement to Settings
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Pop back from Settings to Home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // HomeScreen should now have the tag filter showing 'Series'
      expect(find.byKey(const ValueKey('content-tag-filter')), findsOneWidget);
    });
  });

  group('CF-014, CF-015, CF-016: TagManagement Responsiveness, keyboard and text scaling', () {
    testWidgets('renders cleanly on mobile 390x844 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      tagRepository.create('Testing tag');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(TagManagementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports Escape key dismissal on desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => TagManagementScreen(
                            tagService: tagService,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Tags'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Tags'));
      await tester.pumpAndSettle();
      expect(find.byType(TagManagementScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TagManagementScreen), findsNothing);
    });

    testWidgets('renders cleanly at 1.5x text scaling without overflow', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

      tagRepository.create('Text scale tag');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
