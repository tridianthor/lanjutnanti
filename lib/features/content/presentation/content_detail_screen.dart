import 'package:lanjut_nanti/l10n/application_failure_localization.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/content/presentation/content_form_screen.dart';
import 'package:lanjut_nanti/features/content/presentation/detail_form_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';

class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({
    super.key,
    required this.contentId,
    required this.controller,
    this.tagService,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  final String contentId;
  final ContentListController controller;
  final TagApplicationService? tagService;
  final LinkLauncher linkLauncher;

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentDetailView? _view;
  ApplicationFailure? _errorMessage;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    if (_view == null) setState(() => _loading = true);
    try {
      final view = widget.controller.service.loadDetails(widget.contentId);
      if (!mounted) return;
      setState(() {
        _view = view;
        _errorMessage = null;
        _loading = false;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = mapApplicationFailure(
          error,
          operation: 'load content details',
        );
        _loading = false;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          view?.content.name ?? AppLocalizations.of(context)!.contentDetails,
        ),
        actions: [
          if (view != null)
            IconButton(
              onPressed: _busy ? null : _editContent,
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppLocalizations.of(context)!.editContentAction,
            ),
          if (view != null)
            IconButton(
              onPressed: _busy ? null : _deleteContent,
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.of(context)!.deleteContent,
            ),
        ],
      ),
      body: _buildBody(context, view),
      floatingActionButton:
          view == null
              ? null
              : FloatingActionButton.extended(
                onPressed: _busy ? null : _addDetail,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addDetail),
              ),
    );
  }

  Widget _buildBody(BuildContext context, ContentDetailView? view) {
    if (_loading && view == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (view == null) {
      return _DetailErrorState(
        message:
            _errorMessage == null
                ? AppLocalizations.of(context)!.loadContentFailed
                : localizeFailure(
                  AppLocalizations.of(context)!,
                  _errorMessage!,
                ),
        onRetry: _loadDetails,
      );
    }

    return LayoutBuilder(
      builder:
          (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 600 ? 16 : 24,
                  20,
                  constraints.maxWidth < 600 ? 16 : 24,
                  96,
                ),
                children: [
                  if (_errorMessage != null)
                    _DetailErrorBanner(
                      message: localizeFailure(
                        AppLocalizations.of(context)!,
                        _errorMessage!,
                      ),
                      onRetry: _loadDetails,
                    ),
                  if (_busy) const LinearProgressIndicator(),
                  _ContentHeader(view: view),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.history,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.detailCount(view.history.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (view.history.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(AppLocalizations.of(context)!.emptyHistory),
                      ),
                    )
                  else
                    ...view.history.map(_buildDetailCard),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailCard(ContentDetail detail) {
    final isLatest = _view?.latestDetail?.id == detail.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        key: ValueKey('detail-${detail.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isLatest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppLocalizations.of(context)!.latest),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: _busy ? null : () => _editDetail(detail),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: AppLocalizations.of(context)!.editDetailAction,
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => _deleteDetail(detail),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: AppLocalizations.of(context)!.deleteDetail,
                  ),
                ],
              ),
              SelectableText(
                detail.link,
                key: ValueKey('link-${detail.id}'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              if (detail.note != null) ...[
                const SizedBox(height: 10),
                Text(detail.note!),
              ],
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(
                  context,
                )!.updatedAt(_formatTimestamp(context, detail.updatedAt)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _openLink(detail.link),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context)!.openLink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final local = timestamp.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(local);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date, $time';
  }

  Future<void> _addDetail() async {
    final view = _view;
    if (view == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (context) => DetailFormScreen(
              contentId: view.content.id,
              controller: widget.controller,
              linkLauncher: widget.linkLauncher,
            ),
      ),
    );
    if (mounted) await _loadDetails();
  }

  Future<void> _editDetail(ContentDetail detail) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (context) => DetailFormScreen(
              contentId: detail.contentId,
              initialDetail: detail,
              controller: widget.controller,
              linkLauncher: widget.linkLauncher,
            ),
      ),
    );
    if (mounted) await _loadDetails();
  }

  Future<void> _editContent() async {
    final view = _view;
    if (view == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (context) => ContentFormScreen(
              controller: widget.controller,
              tagService: widget.tagService,
              initialContent: view.content,
              linkLauncher: widget.linkLauncher,
            ),
      ),
    );
    if (mounted) await _loadDetails();
  }

  Future<void> _deleteDetail(ContentDetail detail) async {
    final confirmed = await _confirm(
      title: (l) => l.deleteDetailTitle,
      message: (l) => l.deleteDetailMessage,
      confirmLabel: (l) => l.deleteDetail,
    );
    if (!mounted || !confirmed) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final result = await widget.controller.deleteDetail(
      id: detail.id,
      confirmed: true,
    );
    if (!mounted) return;
    if (result?.deleted == true) {
      await _loadDetails();
    } else {
      setState(() {
        _busy = false;
        _errorMessage =
            widget.controller.state.error ??
            ApplicationFailure(
              kind: ApplicationFailureKind.unknown,
              message:
                  'Could not delete this detail. Your saved data was not changed.',
            );
      });
    }
  }

  Future<void> _deleteContent() async {
    final view = _view;
    if (view == null) return;
    final confirmed = await _confirm(
      title: (l) => l.deleteContentTitle,
      message: (l) => l.deleteContentMessage,
      confirmLabel: (l) => l.deleteContent,
    );
    if (!mounted || !confirmed) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final result = await widget.controller.deleteContent(
      id: view.content.id,
      confirmed: true,
    );
    if (!mounted) return;
    if (result?.deleted == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _errorMessage =
            widget.controller.state.error ??
            ApplicationFailure(
              kind: ApplicationFailureKind.unknown,
              message:
                  'Could not delete this content. Your saved data was not changed.',
            );
      });
    }
  }

  Future<bool> _confirm({
    required String Function(AppLocalizations) title,
    required String Function(AppLocalizations) message,
    required String Function(AppLocalizations) confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop(false);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: AlertDialog(
                  title: Text(title(AppLocalizations.of(context)!)),
                  content: Text(message(AppLocalizations.of(context)!)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel(AppLocalizations.of(context)!)),
                    ),
                  ],
                ),
              ),
        ) ??
        false;
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
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.linkUnavailable),
            content: Text(AppLocalizations.of(context)!.openLinkFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openLink(link);
                },
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.view});

  final ContentDetailView view;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              view.content.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (view.tag != null) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.label_outline),
                label: Text(view.tag!.name),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorBanner extends StatelessWidget {
  const _DetailErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(AppLocalizations.of(context)!.dataUnchanged),
        subtitle: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context)!.retry),
        ),
      ),
    );
  }
}
