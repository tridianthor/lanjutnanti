import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';
import 'package:lanjut_nanti/features/settings/presentation/settings_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

void main() {
  late AppDatabase database;
  late ContentListController contentController;
  late TagApplicationService tagService;
  late LocaleController localeController;
  late BackupExportController exportController;
  late BackupRestoreController restoreController;

  setUp(() {
    database = AppDatabase.openInMemory();
    final clock = const SystemClock();
    final contentRepository = SqliteContentRepository(database, clock: clock);
    final detailRepository = SqliteContentDetailRepository(
      database,
      clock: clock,
    );
    final tagRepository = SqliteTagRepository(database, clock: clock);
    contentController = ContentListController(
      service: ContentApplicationService(
        contentRepository: contentRepository,
        detailRepository: detailRepository,
        tagRepository: tagRepository,
      ),
    );
    tagService = TagApplicationService(tagRepository);
    localeController = LocaleController(MemoryLocalePreferenceRepository());
    exportController = BackupExportController(
      snapshotRepository: SqliteBackupSnapshotRepository(database),
      fileGateway: _DummyExportGateway(),
      clock: clock,
    );
    restoreController = BackupRestoreController(
      restoreRepository: SqliteBackupRestoreRepository(database),
      fileGateway: _DummyRestoreGateway(),
    );
  });

  tearDown(() {
    contentController.dispose();
    localeController.dispose();
    exportController.dispose();
    restoreController.dispose();
    database.dispose();
  });

  Widget buildTestApp({
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        controller: contentController,
        localeController: localeController,
        tagService: tagService,
        backupExportController: exportController,
        backupRestoreController: restoreController,
      ),
    );
  }

  group('CF-001 & CF-002: Home AppBar settings action and navigation', () {
    testWidgets(
      'HomeScreen renders settings action and removes old backup/language actions',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // CF-001: Settings button is present in AppBar
        expect(find.byKey(const ValueKey('settings-action')), findsOneWidget);
        expect(find.byKey(const ValueKey('add-content-action')), findsOneWidget);

        // Old action buttons are removed from HomeScreen
        expect(find.byKey(const ValueKey('export-backup-action')), findsNothing);
        expect(find.byKey(const ValueKey('import-backup-action')), findsNothing);
        expect(find.byTooltip('Language'), findsNothing);
      },
    );

    testWidgets(
      'Tapping settings button opens SettingsScreen and back returns to Home',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Tap Settings button
        await tester.tap(find.byKey(const ValueKey('settings-action')));
        await tester.pumpAndSettle();

        // CF-002: SettingsScreen is displayed with localized title 'Settings'
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Back button is present and tapping it returns to HomeScreen
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });

  group('CF-003 & CF-004: Language settings in SettingsScreen', () {
    testWidgets(
      'displays active language and updates preference on selection',
      (tester) async {
        final repo = _FakeLocaleRepo()..preference = LocalePreference.english;
        final controller = LocaleController(repo);
        await controller.load();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              locale: controller.preference.languageCode == null
                  ? null
                  : Locale(controller.preference.languageCode!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SettingsScreen(localeController: controller),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Language section header and options are displayed
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Bahasa Indonesia'), findsOneWidget);
        expect(find.text('System default'), findsOneWidget);

        // Selecting Bahasa Indonesia updates controller and UI
        await tester.tap(find.text('Bahasa Indonesia'));
        await tester.pumpAndSettle();

        expect(controller.preference, LocalePreference.indonesian);
        expect(repo.preference, LocalePreference.indonesian);
        // Retranslated to Indonesian
        expect(find.text('Pengaturan'), findsOneWidget);
        expect(find.text('Bahasa'), findsOneWidget);
      },
    );

    testWidgets(
      'read failure displays retryable notice and retries successfully',
      (tester) async {
        final repo = _FakeLocaleRepo()..failRead = true;
        final controller = LocaleController(repo);
        await controller.load();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(localeController: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Could not read your language preference. Using System default.'),
          findsOneWidget,
        );

        // Tap Retry after fixing repo
        repo.failRead = false;
        await tester.tap(find.widgetWithText(TextButton, 'Retry'));
        await tester.pumpAndSettle();

        expect(
          find.text('Could not read your language preference. Using System default.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'write failure displays localized error and retains prior preference',
      (tester) async {
        final repo = _FakeLocaleRepo()..preference = LocalePreference.english;
        final controller = LocaleController(repo);
        await controller.load();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(localeController: controller),
          ),
        );
        await tester.pumpAndSettle();

        repo.failWrite = true;
        await tester.tap(find.text('Bahasa Indonesia'));
        await tester.pumpAndSettle();

        expect(
          find.text('Could not save your language preference. Try selecting it again.'),
          findsOneWidget,
        );
        expect(controller.preference, LocalePreference.english);
      },
    );
  });

  group('CF-011: Backup export in SettingsScreen', () {
    testWidgets('export shows privacy warning and cancels without exporting', (
      tester,
    ) async {
      final gateway = _RecordingExportGateway();
      final controller = BackupExportController(
        snapshotRepository: SqliteBackupSnapshotRepository(database),
        fileGateway: gateway,
        clock: const SystemClock(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(backupExportController: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Export backup'), findsOneWidget);
      expect(
        find.text('Save tags, content, and details to a portable JSON file.'),
        findsOneWidget,
      );

      // Tap export button
      await tester.tap(find.byKey(const ValueKey('export-backup-action')));
      await tester.pumpAndSettle();

      expect(find.text('Export backup?'), findsOneWidget);
      expect(
        find.text(
          'This backup may contain private links and notes. The destination you choose controls who can access the file.',
        ),
        findsOneWidget,
      );

      // Cancel export
      await tester.tap(find.byKey(const ValueKey('cancel-export-backup')));
      await tester.pumpAndSettle();

      expect(find.text('Export backup?'), findsNothing);
      expect(gateway.calls, 0);
    });

    testWidgets('confirming export calls gateway and reports success via SnackBar', (
      tester,
    ) async {
      final gateway = _RecordingExportGateway();
      final controller = BackupExportController(
        snapshotRepository: SqliteBackupSnapshotRepository(database),
        fileGateway: gateway,
        clock: const SystemClock(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(backupExportController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-backup-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm-export-backup')));
      await tester.pumpAndSettle();

      expect(gateway.calls, 1);
      expect(find.text('Backup exported successfully.'), findsOneWidget);
    });
  });

  group('CF-012 & CF-013: Backup restore and data synchronization', () {
    testWidgets('corrupted backup file shows validation dialog', (tester) async {
      final gateway = _RecordingRestoreGateway()..json = '{bad';
      final restoreRepo = _RecordingRestoreRepo();
      final controller = BackupRestoreController(
        restoreRepository: restoreRepo,
        fileGateway: gateway,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(backupRestoreController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('import-backup-action')));
      await tester.pumpAndSettle();

      expect(find.text('Backup validation failed'), findsOneWidget);
      expect(
        find.textContaining('Your saved data was not changed.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Backup validation failed'), findsNothing);
      expect(restoreRepo.calls, 0);
    });

    testWidgets('valid backup shows preview with counts and cancels without replacing', (
      tester,
    ) async {
      final gateway = _RecordingRestoreGateway()..json = _validRestoreJson;
      final restoreRepo = _RecordingRestoreRepo();
      final controller = BackupRestoreController(
        restoreRepository: restoreRepo,
        fileGateway: gateway,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(backupRestoreController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('import-backup-action')));
      await tester.pumpAndSettle();

      expect(find.text('Replace local data?'), findsOneWidget);
      expect(find.textContaining('1 tag'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cancel-restore-backup')));
      await tester.pumpAndSettle();

      expect(find.text('Replace local data?'), findsNothing);
      expect(restoreRepo.calls, 0);
    });

    testWidgets('confirming restore replaces data and reports restored counts', (
      tester,
    ) async {
      final gateway = _RecordingRestoreGateway()..json = _validRestoreJson;
      final restoreRepo = _RecordingRestoreRepo();
      final controller = BackupRestoreController(
        restoreRepository: restoreRepo,
        fileGateway: gateway,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(backupRestoreController: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('import-backup-action')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
      await tester.pumpAndSettle();

      expect(restoreRepo.calls, 1);
      expect(
        find.text('Restored 1 tag, 1 content item, and 1 detail.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'CF-013: returning to HomeScreen after restore displays restored data immediately',
      (tester) async {
        final gateway = _RecordingRestoreGateway()..json = _validRestoreJson;
        final restoreRepo = SqliteBackupRestoreRepository(database);
        final restoreCtrl = BackupRestoreController(
          restoreRepository: restoreRepo,
          fileGateway: gateway,
        );
        addTearDown(restoreCtrl.dispose);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(
              controller: contentController,
              tagService: tagService,
              backupRestoreController: restoreCtrl,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No content yet'), findsOneWidget);

        // Navigate to Settings
        await tester.tap(find.byKey(const ValueKey('settings-action')));
        await tester.pumpAndSettle();

        // Restore backup
        await tester.tap(find.byKey(const ValueKey('import-backup-action')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
        await tester.pumpAndSettle();

        // Return to Home
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Restored data is visible on Home
        expect(find.text('Doraemon'), findsOneWidget);
        expect(find.text('Manga'), findsOneWidget);
      },
    );
  });

  group('CF-014, CF-015, CF-016: Responsiveness, keyboard and text scaling', () {
    testWidgets('renders cleanly on mobile 390x844 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeController: localeController,
            tagService: tagService,
            backupExportController: exportController,
            backupRestoreController: restoreController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
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
                          builder: (context) => SettingsScreen(
                            localeController: localeController,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('renders cleanly at 1.5x text scaling without overflow', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeController: localeController,
            tagService: tagService,
            backupExportController: exportController,
            backupRestoreController: restoreController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeLocaleRepo implements LocalePreferenceRepository {
  LocalePreference preference = LocalePreference.system;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<LocalePreference> read() async {
    if (failRead) throw StateError('read failed');
    return preference;
  }

  @override
  Future<void> write(LocalePreference value) async {
    if (failWrite) throw StateError('write failed');
    preference = value;
  }
}

class _DummyExportGateway implements BackupFileGateway {
  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    return const BackupFileSaveResult.saved();
  }
}

class _DummyRestoreGateway implements BackupRestoreFileGateway {
  @override
  Future<BackupFileReadResult> pick() async {
    return const BackupFileReadResult.cancelled();
  }
}

class _RecordingExportGateway implements BackupFileGateway {
  int calls = 0;
  BackupFileSaveResult result = const BackupFileSaveResult.saved();
  Object? error;

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _RecordingRestoreGateway implements BackupRestoreFileGateway {
  int calls = 0;
  String json = _validRestoreJson;

  @override
  Future<BackupFileReadResult> pick() async {
    calls++;
    return BackupFileReadResult.selected(utf8.encode(json));
  }
}

class _RecordingRestoreRepo implements BackupRestoreRepository {
  int calls = 0;

  @override
  void replace(BackupRestorePreview preview) {
    calls++;
  }
}

const _validRestoreJson = '''
{
  "schema_version": 1,
  "exported_at": "2026-09-04T05:00:00.000Z",
  "tags": [{"id":"11111111-1111-4111-8111-111111111111","name":"Manga","created_at":"2026-09-01T05:00:00.000Z","updated_at":"2026-09-01T05:00:00.000Z"}],
  "contents": [{"id":"22222222-2222-4222-8222-222222222222","name":"Doraemon","tag_id":"11111111-1111-4111-8111-111111111111","created_at":"2026-09-01T05:01:00.000Z","updated_at":"2026-09-01T05:02:00.000Z"}],
  "content_details": [{"id":"33333333-3333-4333-8333-333333333333","content_id":"22222222-2222-4222-8222-222222222222","link":"https://example.com/chapter-1","note":"Continue here","created_at":"2026-09-01T05:03:00.000Z","updated_at":"2026-09-01T05:04:00.000Z"}]
}
''';
