import 'package:flutter/material.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/content_detail_screen.dart';
import 'package:lanjut_nanti/features/content/presentation/content_form_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.controller,
    this.tagService,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  final ContentListController? controller;
  final TagApplicationService? tagService;
  final LinkLauncher linkLauncher;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContentListController _controller;
  late final TagApplicationService? _tagService;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadContent();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
      _ownedDatabase?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContent() async {
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lanjut Nanti'),
        actions: [
          IconButton(
            onPressed: _openCreateContent,
            icon: const Icon(Icons.add),
            tooltip: 'Add Content',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => _buildState(context, _controller.state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateContent,
        icon: const Icon(Icons.add),
        label: const Text('Add Content'),
      ),
    );
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
      if (mounted && !opened) _showMessage('Could not open this link.');
    } catch (_) {
      if (mounted) _showMessage('Could not open this link.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
