import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

/// Composes the same application-owned boundaries as production, but against
/// a test-selected file path and deterministic dependencies.
class Phase9AppInstance {
  Phase9AppInstance._({
    required this.database,
    required this.contentRepository,
    required this.detailRepository,
    required this.tagRepository,
    required this.contentController,
    required this.tagService,
    required this.localeController,
    required this.dependencies,
    this.exportController,
    this.restoreController,
  });

  factory Phase9AppInstance.open({
    required String databasePath,
    required Clock clock,
    required IdGenerator idGenerator,
    LinkLauncher linkLauncher = const UnavailableLinkLauncher(),
    BackupFileGateway? exportGateway,
    BackupRestoreFileGateway? restoreGateway,
  }) {
    final database = AppDatabase.open(databasePath);
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
    final contentService = ContentApplicationService(
      contentRepository: contentRepository,
      detailRepository: detailRepository,
      tagRepository: tagRepository,
    );
    final contentController = ContentListController(service: contentService);
    final tagService = TagApplicationService(tagRepository);
    final exportController =
        exportGateway == null
            ? null
            : BackupExportController(
              snapshotRepository: SqliteBackupSnapshotRepository(database),
              fileGateway: exportGateway,
              clock: clock,
            );
    final restoreController =
        restoreGateway == null
            ? null
            : BackupRestoreController(
              restoreRepository: SqliteBackupRestoreRepository(database),
              fileGateway: restoreGateway,
            );
    final localeController = LocaleController(
      SqliteLocalePreferenceRepository(database),
    );
    final dependencies = AppDependencies(
      clock: clock,
      idGenerator: idGenerator,
      database: database,
      localeController: localeController,
      contentController: contentController,
      tagService: tagService,
      backupExportController: exportController,
      backupRestoreController: restoreController,
      linkLauncher: linkLauncher,
    );
    return Phase9AppInstance._(
      database: database,
      contentRepository: contentRepository,
      detailRepository: detailRepository,
      tagRepository: tagRepository,
      contentController: contentController,
      tagService: tagService,
      localeController: localeController,
      exportController: exportController,
      restoreController: restoreController,
      dependencies: dependencies,
    );
  }

  final AppDatabase database;
  final SqliteContentRepository contentRepository;
  final SqliteContentDetailRepository detailRepository;
  final SqliteTagRepository tagRepository;
  final ContentListController contentController;
  final TagApplicationService tagService;
  final LocaleController localeController;
  final BackupExportController? exportController;
  final BackupRestoreController? restoreController;
  final AppDependencies dependencies;

  void dispose() {
    localeController.dispose();
    contentController.dispose();
    exportController?.dispose();
    restoreController?.dispose();
    database.dispose();
  }
}
