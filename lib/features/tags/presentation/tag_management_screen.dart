import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';
import 'package:lanjut_nanti/l10n/application_failure_localization.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key, required this.tagService});

  final TagApplicationService tagService;

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  List<Tag> _tags = const [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    try {
      final tags = widget.tagService.list();
      setState(() => _tags = List.unmodifiable(tags));
    } catch (_) {
      // If reading fails, keep current tags
    }
  }

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
            title: Text(l.manageTags),
          actions: [
            IconButton(
              key: const ValueKey('create-tag-action'),
              icon: const Icon(Icons.add),
              tooltip: l.createTag,
              onPressed: _showCreateTagDialog,
            ),
          ],
        ),
        floatingActionButton: _tags.isEmpty
            ? null
            : FloatingActionButton(
                key: const ValueKey('create-tag-fab'),
                onPressed: _showCreateTagDialog,
                tooltip: l.createTag,
                child: const Icon(Icons.add),
              ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _tags.isEmpty
                    ? _buildEmptyState(context, l)
                    : _buildTagList(context, l),
              ),
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState(BuildContext context, AppLocalizations l) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l.emptyTags,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.emptyTagsHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _showCreateTagDialog,
              child: Text(l.createTag),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagList(BuildContext context, AppLocalizations l) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _tags.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return ListTile(
          key: ValueKey('tag-item-${tag.id}'),
          leading: const Icon(Icons.label_outline),
          title: Text(tag.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('rename-tag-${tag.id}'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.renameTag,
                onPressed: () => _showRenameDialog(tag),
              ),
              IconButton(
                key: ValueKey('delete-tag-${tag.id}'),
                icon: const Icon(Icons.delete_outline),
                tooltip: l.deleteTagAction,
                onPressed: () => _confirmDeleteTag(tag),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateTagDialog() async {
    final l = AppLocalizations.of(context)!;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _TagFormDialog(
        title: l.createTag,
        confirmLabel: l.create,
        onSubmit: (name) {
          widget.tagService.create(name);
        },
      ),
    );

    if (created == true && mounted) {
      _loadTags();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.tagCreated)));
    }
  }

  Future<void> _showRenameDialog(Tag tag) async {
    final l = AppLocalizations.of(context)!;
    final renamed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _TagFormDialog(
        title: l.renameTag,
        confirmLabel: l.rename,
        initialValue: tag.name,
        onSubmit: (name) {
          widget.tagService.rename(id: tag.id, name: name);
        },
      ),
    );

    if (renamed == true && mounted) {
      _loadTags();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.tagRenamed)));
    }
  }

  Future<void> _confirmDeleteTag(Tag tag) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteTagTitle),
        content: Text(l.deleteTagMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.deleteTagAction),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.tagService.delete(id: tag.id, confirmed: true);
      _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.tagDeleted)));
      }
    }
  }
}

class _TagFormDialog extends StatefulWidget {
  const _TagFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.onSubmit,
    this.initialValue = '',
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final void Function(String name) onSubmit;

  @override
  State<_TagFormDialog> createState() => _TagFormDialogState();
}

class _TagFormDialogState extends State<_TagFormDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l = AppLocalizations.of(context)!;
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorText = l.tagNameRequired);
      return;
    }

    try {
      widget.onSubmit(trimmed);
      Navigator.of(context).pop(true);
    } on ApplicationFailure catch (failure) {
      setState(() => _errorText = localizeFailure(l, failure));
    } catch (_) {
      setState(() => _errorText = l.failureUnknown(l.operationSaveTag));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l.tagName,
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
