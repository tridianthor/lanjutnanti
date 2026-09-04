import 'dart:io';

import 'package:path_provider/path_provider.dart';
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
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.clock,
    required this.idGenerator,
    this.database,
    this.contentController,
    this.tagService,
    this.backupExportController,
    this.backupRestoreController,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  factory AppDependencies.production() {
    return AppDependencies(
      clock: const SystemClock(),
      idGenerator: RandomIdGenerator(),
    );
  }

  static Future<AppDependencies> createProduction() async {
    final directory = await getApplicationSupportDirectory();
    final database = AppDatabase.open(
      '${directory.path}${Platform.pathSeparator}lanjut_nanti.sqlite',
    );
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
    final service = ContentApplicationService(
      contentRepository: contentRepository,
      detailRepository: detailRepository,
      tagRepository: tagRepository,
    );
    final backupExportController = BackupExportController(
      snapshotRepository: SqliteBackupSnapshotRepository(database),
      fileGateway: const FileSaverBackupFileGateway(),
      clock: clock,
    );
    final backupRestoreController = BackupRestoreController(
      restoreRepository: SqliteBackupRestoreRepository(database),
      fileGateway: const FilePickerBackupRestoreFileGateway(),
    );
    return AppDependencies(
      clock: clock,
      idGenerator: idGenerator,
      database: database,
      contentController: ContentListController(service: service),
      tagService: TagApplicationService(tagRepository),
      backupExportController: backupExportController,
      backupRestoreController: backupRestoreController,
    );
  }

  final Clock clock;
  final IdGenerator idGenerator;
  final AppDatabase? database;
  final ContentListController? contentController;
  final TagApplicationService? tagService;
  final BackupExportController? backupExportController;
  final BackupRestoreController? backupRestoreController;
  final LinkLauncher linkLauncher;
}
