import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app.dart';
import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/application/theme_controller.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/data/theme_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/theme_preference.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase database;
  late ThemeController themeController;
  late LocaleController localeController;
  late ContentListController contentController;
  late TagApplicationService tagService;

  setUp(() {
    database = AppDatabase.openInMemory();
    final clock = const SystemClock();
    final idGenerator = RandomIdGenerator();
    final contentRepository = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: idGenerator,
    );
    final detailRepository = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: idGenerator,
    );
    final tagRepository = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: idGenerator,
    );
    contentController = ContentListController(
      service: ContentApplicationService(
        contentRepository: contentRepository,
        detailRepository: detailRepository,
        tagRepository: tagRepository,
      ),
    );
    tagService = TagApplicationService(tagRepository);
    localeController = LocaleController(MemoryLocalePreferenceRepository());
    themeController = ThemeController(SqliteThemePreferenceRepository(database));
  });

  tearDown(() {
    themeController.dispose();
    localeController.dispose();
    contentController.dispose();
    database.dispose();
  });

  AppDependencies createDependencies() {
    return AppDependencies(
      clock: const SystemClock(),
      idGenerator: RandomIdGenerator(),
      database: database,
      localeController: localeController,
      themeController: themeController,
      contentController: contentController,
      tagService: tagService,
    );
  }

  testWidgets(
    'system theme mode dynamically follows platform brightness',
    (tester) async {
      await themeController.load();

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        LanjutNantiApp(dependencies: createDependencies()),
      );
      await tester.pumpAndSettle();

      var scaffoldElement = tester.element(find.byType(Scaffold));
      expect(Theme.of(scaffoldElement).brightness, Brightness.light);

      // Change platform brightness to dark
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      scaffoldElement = tester.element(find.byType(Scaffold));
      expect(Theme.of(scaffoldElement).brightness, Brightness.dark);
    },
  );

  testWidgets(
    'selecting Dark mode in settings applies dark brightness and persists in database',
    (tester) async {
      await themeController.load();

      // Start with system in light mode
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        LanjutNantiApp(dependencies: createDependencies()),
      );
      await tester.pumpAndSettle();

      // Open Settings
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();

      // Select Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(themeController.preference, ThemePreference.dark);

      // Verify widget tree is now dark
      final scaffoldElement = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(scaffoldElement).brightness, Brightness.dark);

      // Verify persisted in SQLite database
      final rows = database.raw.select(
        "SELECT value FROM app_settings WHERE key = 'app_theme_mode'",
      );
      expect(rows.single['value'], 'dark');

      // Reopening a new controller loads dark mode
      final newController = ThemeController(
        SqliteThemePreferenceRepository(database),
      );
      addTearDown(newController.dispose);
      await newController.load();
      expect(newController.preference, ThemePreference.dark);
    },
  );

  testWidgets(
    'selecting Light mode forces light brightness even when platform is dark',
    (tester) async {
      await themeController.load();

      // Platform is dark
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        LanjutNantiApp(dependencies: createDependencies()),
      );
      await tester.pumpAndSettle();

      // Open Settings
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();

      // Select Light mode
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(themeController.preference, ThemePreference.light);

      // Verify widget tree is light despite platform being dark
      final scaffoldElement = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(scaffoldElement).brightness, Brightness.light);

      // Verify persisted in database
      final rows = database.raw.select(
        "SELECT value FROM app_settings WHERE key = 'app_theme_mode'",
      );
      expect(rows.single['value'], 'light');
    },
  );

  testWidgets(
    'selecting System default removes override and follows platform',
    (tester) async {
      // Pre-set dark mode
      await themeController.select(ThemePreference.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        LanjutNantiApp(dependencies: createDependencies()),
      );
      await tester.pumpAndSettle();

      // Open Settings
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();

      // Select System default
      await tester.tap(
        find.widgetWithText(RadioListTile<ThemePreference>, 'System default'),
      );
      await tester.pumpAndSettle();

      expect(themeController.preference, ThemePreference.system);

      // Verify widget tree reverted to following platform (light)
      final scaffoldElement = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(scaffoldElement).brightness, Brightness.light);

      // Verify database row removed
      final rows = database.raw.select(
        "SELECT value FROM app_settings WHERE key = 'app_theme_mode'",
      );
      expect(rows, isEmpty);
    },
  );
}
