import 'package:flutter/material.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/content_detail_screen.dart';
import 'package:lanjut_nanti/features/content/presentation/content_form_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.controller,
    this.tagService,
    this.backupExportController,
    this.backupRestoreController,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  final ContentListController? controller;
  final TagApplicationService? tagService;
  final BackupExportController? backupExportController;
  final BackupRestoreController? backupRestoreController;
  final LinkLauncher linkLauncher;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContentListController _controller;
  late final TagApplicationService? _tagService;
  late final TextEditingController _searchController;
  List<Tag> _tags = const [];
  AppDatabase? _ownedDatabase;

  @override
  void initState() {
    super.initState();
    final injectedController = widget.controller;
    final injectedTagService = widget.tagService;
    if (injectedController != null) {
      _controller = injectedController;
      _tagService = injectedTagService;
    } else {
      final database = AppDatabase.openInMemory();
      _ownedDatabase = database;
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
      _controller = ContentListController(
        service: ContentApplicationService(
          contentRepository: contentRepository,
          detailRepository: detailRepository,
          tagRepository: tagRepository,
        ),
      );
      _tagService = TagApplicationService(tagRepository);
    }
    _searchController = TextEditingController(text: _controller.state.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadContent();
        _loadTags();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
      _ownedDatabase?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContent() async {
    await _controller.load();
  }

  Future<void> _loadTags() async {
    final tagService = _tagService;
    if (tagService == null) return;
    try {
      final tags = tagService.list();
      if (mounted) setState(() => _tags = List.unmodifiable(tags));
    } catch (_) {
      // Tag filtering is optional; the content list remains usable if tags
      // cannot be read.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lanjut Nanti'),
        actions: [
          if (widget.backupExportController != null)
            _buildBackupAction(widget.backupExportController!),
          if (widget.backupRestoreController != null)
            _buildRestoreAction(widget.backupRestoreController!),
          IconButton(
            onPressed: _openCreateContent,
            icon: const Icon(Icons.add),
            tooltip: 'Add Content',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, child) => Column(
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: _search,
                  onClear: _clearSearch,
                ),
                if (_tags.isNotEmpty)
                  _TagFilter(
                    tags: _tags,
                    selectedTagId: _controller.state.tagId,
                    onChanged: _setTagFilter,
                  ),
                Expanded(child: _buildState(context, _controller.state)),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateContent,
        icon: const Icon(Icons.add),
        label: const Text('Add Content'),
      ),
    );
  }

  Widget _buildBackupAction(BackupExportController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (context, child) => IconButton(
            key: const ValueKey('export-backup-action'),
            onPressed: controller.state.isBusy ? null : _confirmExport,
            tooltip: 'Export backup',
            icon:
                controller.state.isBusy
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.file_upload_outlined),
          ),
    );
  }

  Future<void> _confirmExport() async {
    final controller = widget.backupExportController;
    if (controller == null || controller.state.isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export backup?'),
            content: const Text(
              'This backup may contain private links and notes. The destination '
              'you choose controls who can access the file.',
            ),
            actions: [
              TextButton(
                key: const ValueKey('cancel-export-backup'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('confirm-export-backup'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Export'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final result = await controller.export();
    if (!mounted || result.status == BackupExportStatus.duplicate) return;
    final message = result.message ?? 'Could not export backup.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action:
              result.status == BackupExportStatus.error
                  ? SnackBarAction(label: 'Retry', onPressed: _confirmExport)
                  : null,
        ),
      );
  }

  Widget _buildRestoreAction(BackupRestoreController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (context, child) => IconButton(
            key: const ValueKey('import-backup-action'),
            onPressed: controller.state.isBusy ? null : _selectRestore,
            tooltip: 'Import backup',
            icon:
                controller.state.isBusy
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.file_download_outlined),
          ),
    );
  }

  Future<void> _selectRestore() async {
    final controller = widget.backupRestoreController;
    if (controller == null || controller.state.isBusy) return;

    final result = await controller.selectAndValidate();
    if (!mounted || result.status == BackupRestoreStatus.duplicate) return;
    if (result.status == BackupRestoreStatus.validationError) {
      await _showRestoreValidation(result);
      return;
    }
    if (result.status == BackupRestoreStatus.error) {
      if (result.message != null) _showRestoreMessage(result.message!);
      return;
    }
    if (result.status != BackupRestoreStatus.preview ||
        result.preview == null) {
      if (result.message != null &&
          result.status != BackupRestoreStatus.cancelled) {
        _showRestoreMessage(result.message!);
      }
      return;
    }

    final preview = result.preview!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Replace local data?'),
            content: Text(
              'This valid backup contains ${preview.tagCount} '
              '${preview.tagCount == 1 ? 'tag' : 'tags'}, '
              '${preview.contentCount} '
              '${preview.contentCount == 1 ? 'content item' : 'content items'}, '
              'and ${preview.detailCount} '
              '${preview.detailCount == 1 ? 'detail' : 'details'}. '
              'Confirming will replace all current local data.',
            ),
            actions: [
              TextButton(
                key: const ValueKey('cancel-restore-backup'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('confirm-restore-backup'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Replace'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final restored = await controller.restore(confirmed: true);
    if (!mounted || restored.status == BackupRestoreStatus.duplicate) return;
    if (restored.status == BackupRestoreStatus.success) {
      await _loadContent();
      await _loadTags();
    }
    if (restored.message != null) _showRestoreMessage(restored.message!);
  }

  Future<void> _showRestoreValidation(BackupRestoreResult result) async {
    final details = result.issues
        .take(5)
        .map((issue) => issue.toString())
        .join('\n');
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Backup validation failed'),
            content: SingleChildScrollView(
              child: Text(
                '${result.issues.length} validation error(s). Your saved data '
                'was not changed.\n\n$details',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showRestoreMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildState(BuildContext context, ContentListState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: _buildContent(context, constraints.maxWidth, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    double availableWidth,
    ContentListState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty && state.hasSearch && !state.hasError) {
      return _NoSearchResultsState(onClear: _clearFilters);
    }

    if (state.items.isEmpty) {
      return _EmptyContentState(
        hasError: state.hasError,
        errorMessage: state.error?.message,
        onRetry: state.hasError ? _loadContent : null,
        onAdd: _openCreateContent,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          availableWidth < 600 ? 16 : 24,
          16,
          availableWidth < 600 ? 16 : 24,
          96,
        ),
        children: [
          if (state.hasError)
            _ErrorBanner(message: state.error!.message, onRetry: _loadContent),
          if (state.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          ...state.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ContentListTile(
                item: item,
                onTap: () => _openDetails(item.content.id),
                onOpenLatest:
                    item.latestDetail == null
                        ? null
                        : () => _openLink(item.latestDetail!.link),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _search(String query) => _controller.search(query);

  Future<void> _clearSearch() async {
    _searchController.clear();
    if (_controller.state.query.isEmpty) return;
    await _controller.search('');
  }

  Future<void> _clearFilters() async {
    await _clearSearch();
    if (mounted && _controller.state.tagId != null) {
      await _controller.setTagFilter(null);
    }
  }

  Future<void> _setTagFilter(String? tagId) => _controller.setTagFilter(tagId);

  Future<void> _openCreateContent() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (context) => ContentFormScreen(
              controller: _controller,
              tagService: _tagService,
              linkLauncher: widget.linkLauncher,
            ),
      ),
    );
    if (mounted) await _loadTags();
  }

  Future<void> _openDetails(String contentId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (context) => ContentDetailScreen(
              contentId: contentId,
              controller: _controller,
              tagService: _tagService,
              linkLauncher: widget.linkLauncher,
            ),
      ),
    );
    if (mounted) await _loadContent();
  }

  Future<void> _openLink(String link) async {
    try {
      final opened = await widget.linkLauncher.open(link);
      if (mounted && !opened) _showLinkError(link);
    } catch (_) {
      if (mounted) _showLinkError(link);
    }
  }

  void _showLinkError(String link) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Could not open this link.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _openLink(link);
            },
          ),
        ),
      );
  }
}

class _EmptyContentState extends StatelessWidget {
  const _EmptyContentState({
    required this.hasError,
    required this.errorMessage,
    required this.onRetry,
    required this.onAdd,
  });

  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.cloud_off_outlined : Icons.bookmark_border,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: hasError ? 'Database error' : 'No saved content',
            ),
            const SizedBox(height: 16),
            Text(
              hasError ? 'Could not load content' : 'Belum ada konten',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? errorMessage ?? 'Please try again.'
                  : 'Save something you want to continue later.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (hasError)
              OutlinedButton(onPressed: onRetry, child: const Text('Try again'))
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: 'No search results',
            ),
            const SizedBox(height: 16),
            Text(
              'No content matches your search.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              key: const ValueKey('clear-search-empty-state'),
              onPressed: onClear,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                4,
              ),
              child: TextField(
                key: const ValueKey('content-search-field'),
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search content',
                  hintText: 'Name, tag, or note',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      controller.text.isEmpty
                          ? null
                          : IconButton(
                            key: const ValueKey('clear-content-search'),
                            onPressed: onClear,
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                          ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagFilter extends StatelessWidget {
  const _TagFilter({
    required this.tags,
    required this.selectedTagId,
    required this.onChanged,
  });

  final List<Tag> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                4,
              ),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Filter by tag',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    key: const ValueKey('content-tag-filter'),
                    value: selectedTagId,
                    isExpanded: true,
                    hint: const Text('All tags'),
                    onChanged: onChanged,
                    items: [
                      const DropdownMenuItem<String?>(
                        key: ValueKey('tag-filter-option-all'),
                        value: null,
                        child: Text('All tags'),
                      ),
                      ...tags.map(
                        (tag) => DropdownMenuItem<String?>(
                          key: ValueKey('tag-filter-option-${tag.id}'),
                          value: tag.id,
                          child: Text(tag.name),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Saved data was not changed'),
        subtitle: Text(message),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}

class _ContentListTile extends StatelessWidget {
  const _ContentListTile({
    required this.item,
    required this.onTap,
    required this.onOpenLatest,
  });

  final ContentListItem item;
  final VoidCallback? onTap;
  final VoidCallback? onOpenLatest;

  @override
  Widget build(BuildContext context) {
    final localActivity = item.latestActivity.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final latest = localizations.formatMediumDate(localActivity);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localActivity),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Card(
      key: ValueKey('content-card-${item.content.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.content.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.tag != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.tag!.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      item.latestPreview ?? 'No detail saved yet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Latest · $latest, $time',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('open-latest-${item.content.id}'),
                onPressed: onOpenLatest,
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open latest link',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
