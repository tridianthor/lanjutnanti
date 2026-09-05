import 'package:lanjut_nanti/core/errors/application_failure.dart';
import 'package:lanjut_nanti/l10n/application_failure_localization.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';

class DetailFormScreen extends StatefulWidget {
  const DetailFormScreen({
    super.key,
    required this.contentId,
    required this.controller,
    this.initialDetail,
    this.linkLauncher = const UrlLauncherLinkLauncher(),
  });

  final String contentId;
  final ContentListController controller;
  final ContentDetail? initialDetail;
  final LinkLauncher linkLauncher;

  bool get isEditing => initialDetail != null;

  @override
  State<DetailFormScreen> createState() => _DetailFormScreenState();
}

class _DetailFormScreenState extends State<DetailFormScreen> {
  late final TextEditingController _linkController;
  late final TextEditingController _noteController;
  bool _linkError = false;
  ApplicationFailure? _formError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(
      text: widget.initialDetail?.link ?? '',
    );
    _noteController = TextEditingController(
      text: widget.initialDetail?.note ?? '',
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? AppLocalizations.of(context)!.editDetail
              : AppLocalizations.of(context)!.addDetail,
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
              ? AppLocalizations.of(context)!.editDetailHint
              : AppLocalizations.of(context)!.createDetailHint,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _linkController,
          autofocus: true,
          enabled: !_busy,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.link,
            hintText: 'https://…',
            border: const OutlineInputBorder(),
            errorText:
                _linkError
                    ? AppLocalizations.of(context)!.validLinkRequired
                    : null,
          ),
          onChanged: (_) {
            if (_linkError) setState(() => _linkError = false);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          enabled: !_busy,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.optionalNote,
            hintText: AppLocalizations.of(context)!.noteHint,
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onSubmitted: (_) => _save(),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(
            localizeFailure(AppLocalizations.of(context)!, _formError!),
            key: const Key('detail-form-error'),
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
                : AppLocalizations.of(context)!.saveDetail,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final rawLink = _linkController.text;
    try {
      ContentDetail.normalizeLink(rawLink);
    } on ArgumentError {
      setState(() {
        _linkError = true;
        _formError = null;
      });
      return;
    }

    setState(() {
      _linkError = false;
      _formError = null;
      _busy = true;
    });

    final result =
        widget.initialDetail == null
            ? await widget.controller.createDetail(
              contentId: widget.contentId,
              link: rawLink,
              note: _noteController.text,
            )
            : await widget.controller.editDetail(
              id: widget.initialDetail!.id,
              link: rawLink,
              note: _noteController.text,
            );
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _busy = false;
        _formError =
            widget.controller.state.error ??
            ApplicationFailure(
              kind: ApplicationFailureKind.unknown,
              message:
                  'Could not save this detail. Your entered values are still here.',
            );
      });
      return;
    }
    Navigator.of(context).pop(result);
  }
}
