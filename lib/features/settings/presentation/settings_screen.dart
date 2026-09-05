import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/presentation/tag_management_screen.dart';
import 'package:lanjut_nanti/l10n/application_failure_localization.dart';
import 'package:lanjut_nanti/l10n/backup_message_localization.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.localeController,
    this.tagService,
    this.backupExportController,
    this.backupRestoreController,
  });

  final LocaleController? localeController;
  final TagApplicationService? tagService;
  final BackupExportController? backupExportController;
  final BackupRestoreController? backupRestoreController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l.settings),
          ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (localeController != null)
                    _LanguageSection(controller: localeController!),
                  if (tagService != null) ...[
                    const SizedBox(height: 16),
                    _TagsSection(tagService: tagService!),
                  ],
                  if (backupExportController != null ||
                      backupRestoreController != null) ...[
                    const SizedBox(height: 16),
                    _BackupSection(
                      exportController: backupExportController,
                      restoreController: backupRestoreController,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  ),
);
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tagService});

  final TagApplicationService tagService;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.label_outline),
        title: Text(l.manageTags),
        subtitle: Text(l.manageTagsDescription),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => TagManagementScreen(tagService: tagService),
            ),
          );
        },
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 8),
                    Text(
                      l.language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (controller.failure == LocalePreferenceFailure.read) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l.languagePreferenceReadFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: controller.busy ? null : controller.load,
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                ],
                if (controller.failure == LocalePreferenceFailure.write) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.languagePreferenceSaveFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                for (final pref in LocalePreference.values)
                  RadioListTile<LocalePreference>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (pref) {
                      LocalePreference.system => l.systemDefault,
                      LocalePreference.english => 'English',
                      LocalePreference.indonesian => 'Bahasa Indonesia',
                    }),
                    value: pref,
                    groupValue: controller.preference,
                    onChanged: controller.busy
                        ? null
                        : (value) {
                            if (value != null) {
                              controller.select(value);
                            }
                          },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackupSection extends StatelessWidget {
  const _BackupSection({
    this.exportController,
    this.restoreController,
  });

  final BackupExportController? exportController;
  final BackupRestoreController? restoreController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined),
                const SizedBox(width: 8),
                Text(
                  l.backupAndRestore,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (exportController != null) ...[
              const SizedBox(height: 16),
              _ExportSubsection(controller: exportController!),
            ],
            if (exportController != null && restoreController != null)
              const Divider(height: 32),
            if (restoreController != null)
              _RestoreSubsection(controller: restoreController!),
          ],
        ),
      ),
    );
  }
}

class _ExportSubsection extends StatelessWidget {
  const _ExportSubsection({required this.controller});

  final BackupExportController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isBusy = controller.state.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.exportBackup,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l.exportDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('export-backup-action'),
              onPressed: isBusy ? null : () => _confirmExport(context),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_upload_outlined),
              label: Text(l.export),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmExport(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.exportBackupTitle),
        content: Text(l.exportPrivacy),
        actions: [
          TextButton(
            key: const ValueKey('cancel-export-backup'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-export-backup'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.export),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await controller.export();
    if (!context.mounted || result.status == BackupExportStatus.duplicate) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              final message = switch (result.status) {
                BackupExportStatus.success => loc.exportSuccess,
                BackupExportStatus.cancelled => loc.exportCancelled,
                _ => result.failure == null
                    ? loc.exportFailed
                    : localizeFailure(loc, result.failure!),
              };
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(message),
                  if (result.status == BackupExportStatus.error)
                    TextButton(
                      onPressed: () => _confirmExport(context),
                      child: Text(loc.retry),
                    ),
                ],
              );
            },
          ),
        ),
      );
  }
}

class _RestoreSubsection extends StatelessWidget {
  const _RestoreSubsection({required this.controller});

  final BackupRestoreController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isBusy = controller.state.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.importBackup,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l.importDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('import-backup-action'),
              onPressed: isBusy ? null : () => _selectRestore(context),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
              label: Text(l.importBackup),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectRestore(BuildContext context) async {
    final result = await controller.selectAndValidate();
    if (!context.mounted || result.status == BackupRestoreStatus.duplicate) {
      return;
    }

    if (result.status == BackupRestoreStatus.validationError) {
      await _showRestoreValidation(context, result);
      return;
    }
    if (result.status == BackupRestoreStatus.error) {
      if (result.message != null) _showRestoreMessage(context, result);
      return;
    }
    if (result.status != BackupRestoreStatus.preview ||
        result.preview == null) {
      if (result.message != null) {
        _showRestoreMessage(context, result);
      }
      return;
    }

    final preview = result.preview!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.replaceLocalData),
        content: Text(
          AppLocalizations.of(context)!.restorePreview(
            preview.tagCount,
            preview.contentCount,
            preview.detailCount,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-restore-backup'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-restore-backup'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context)!.replace),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final restored = await controller.restore(confirmed: true);
    if (!context.mounted || restored.status == BackupRestoreStatus.duplicate) {
      return;
    }
    if (restored.message != null) _showRestoreMessage(context, restored);
  }

  Future<void> _showRestoreValidation(
    BuildContext context,
    BackupRestoreResult result,
  ) async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.backupValidationFailed),
        content: SingleChildScrollView(
          child: Text(
            localizeBackupIssues(
              AppLocalizations.of(context)!,
              result.issues,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  void _showRestoreMessage(BuildContext context, BackupRestoreResult result) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(localizeRestoreResult(l, result)),
        ),
      );
  }
}
