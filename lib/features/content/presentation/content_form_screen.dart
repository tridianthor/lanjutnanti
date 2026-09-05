import 'package:lanjut_nanti/l10n/application_failure_localization.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/presentation/content_detail_screen.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

class ContentFormScreen extends StatefulWidget {
  const ContentFormScreen({
    super.key,
    required this.controller,
    this.tagService,
    this.initialContent,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  final ContentListController controller;
  final TagApplicationService? tagService;
  final Content? initialContent;
  final LinkLauncher linkLauncher;

  bool get isEditing => initialContent != null;

  @override
  State<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends State<ContentFormScreen> {
  late final TextEditingController _nameController;
  late String? _tagId;
  List<Tag> _tags = const [];
  bool _nameError = false;
  ApplicationFailure? _formError;
  ApplicationFailure? _tagError;
  bool _loadingTags = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final content = widget.initialContent;
    _nameController = TextEditingController(text: content?.name ?? '');
    _tagId = content?.tagId;
    _loadTags();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadTags() {
    final service = widget.tagService;
    if (service == null) return;
    try {
      _tags = service.list();
      if (_tagId != null && !_tags.any((tag) => tag.id == _tagId)) {
        _tagId = null;
      }
    } catch (error) {
      _tagError = mapApplicationFailure(error, operation: 'load tags');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? AppLocalizations.of(context)!.editContent
              : AppLocalizations.of(context)!.addContent,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 600 ? 20 : 32,
                      24,
                      constraints.maxWidth < 600 ? 20 : 32,
                      32,
                    ),
                    child: _buildForm(context),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isEditing
              ? AppLocalizations.of(context)!.updateContentHint
              : AppLocalizations.of(context)!.createContentHint,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          autofocus: !widget.isEditing,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.contentName,
            hintText: AppLocalizations.of(context)!.contentNameHint,
            border: const OutlineInputBorder(),
            errorText:
                _nameError
                    ? AppLocalizations.of(context)!.contentNameRequired
                    : null,
          ),
          onChanged: (_) {
            if (_nameError) setState(() => _nameError = false);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tagId ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.optionalTag,
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(AppLocalizations.of(context)!.noTag),
            ),
            ..._tags.map(
              (tag) => DropdownMenuItem<String>(
                value: tag.id,
                child: Text(tag.name),
              ),
            ),
          ],
          onChanged:
              _busy
                  ? null
                  : (value) => setState(
                    () => _tagId = value?.isEmpty == true ? null : value,
                  ),
        ),
        if (_tagError != null) ...[
          const SizedBox(height: 8),
          Text(
            localizeFailure(AppLocalizations.of(context)!, _tagError!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (widget.tagService != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy || _loadingTags ? null : _createTag,
              icon: const Icon(Icons.new_label_outlined),
              label: Text(AppLocalizations.of(context)!.createTag),
            ),
          ),
        ],
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(
            localizeFailure(AppLocalizations.of(context)!, _formError!),
            key: const Key('content-form-error'),
            style: TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon:
              _busy
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_outlined),
          label: Text(
            widget.isEditing
                ? AppLocalizations.of(context)!.saveChanges
                : AppLocalizations.of(context)!.saveContent,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = true;
        _formError = null;
      });
      return;
    }

    setState(() {
      _nameError = false;
      _formError = null;
      _busy = true;
    });

    if (widget.initialContent == null) {
      final result = await widget.controller.createContent(
        name: name,
        tagId: _tagId,
      );
      if (!mounted) return;
      if (result == null) {
        _showFailure();
        return;
      }
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder:
              (context) => ContentDetailScreen(
                contentId: result.content.id,
                controller: widget.controller,
                tagService: widget.tagService,
                linkLauncher: widget.linkLauncher,
              ),
        ),
      );
      return;
    }

    final result = await widget.controller.editContent(
      id: widget.initialContent!.id,
      name: name,
      tagId: _tagId,
    );
    if (!mounted) return;
    if (result == null) {
      _showFailure();
      return;
    }
    Navigator.of(context).pop(result);
  }

  Future<void> _createTag() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateTagDialog(),
    );
    if (!mounted || name == null) return;

    setState(() {
      _loadingTags = true;
      _tagError = null;
    });
    try {
      final tag = widget.tagService!.create(name);
      setState(() {
        _tags = [..._tags, tag]..sort((a, b) {
          final comparison = a.comparisonKey.compareTo(b.comparisonKey);
          return comparison == 0 ? a.id.compareTo(b.id) : comparison;
        });
        _tagId = tag.id;
        _loadingTags = false;
      });
    } catch (error) {
      setState(() {
        _loadingTags = false;
        _tagError = mapApplicationFailure(error, operation: 'save tag');
      });
    }
  }

  void _showFailure() {
    setState(() {
      _busy = false;
      _formError =
          widget.controller.state.error ??
          ApplicationFailure(
            kind: ApplicationFailureKind.unknown,
            message:
                'Could not save your changes. Your entered values are still here.',
          );
    });
  }
}

class _CreateTagDialog extends StatefulWidget {
  const _CreateTagDialog();

  @override
  State<_CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<_CreateTagDialog> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: Text(AppLocalizations.of(context)!.createTag),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.tagName,
            border: const OutlineInputBorder(),
            errorText:
                _error ? AppLocalizations.of(context)!.tagNameRequired : null,
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: _submit,
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }
}
