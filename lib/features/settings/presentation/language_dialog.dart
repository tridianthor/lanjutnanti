import 'package:flutter/material.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';
import '../application/locale_controller.dart';
import '../domain/locale_preference.dart';

class LanguageAction extends StatelessWidget {
  const LanguageAction({super.key, required this.controller});
  final LocaleController controller;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context)!.language,
    icon: const Icon(Icons.language),
    onPressed:
        () => showDialog<void>(
          context: context,
          builder: (context) => LanguageDialog(controller: controller),
        ),
  );
}

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key, required this.controller});
  final LocaleController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      final l = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(l.language),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.failure == LocalePreferenceFailure.write)
              Text(
                l.languagePreferenceSaveFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            for (final preference in LocalePreference.values)
              RadioListTile<LocalePreference>(
                title: Text(switch (preference) {
                  LocalePreference.system => l.systemDefault,
                  LocalePreference.english => 'English',
                  LocalePreference.indonesian => 'Bahasa Indonesia',
                }),
                value: preference,
                groupValue: controller.preference,
                onChanged:
                    controller.busy
                        ? null
                        : (value) async {
                          final saved = await controller.select(value!);
                          if (context.mounted && saved) {
                            Navigator.of(context).pop();
                          }
                        },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
        ],
      );
    },
  );
}

class LanguagePreferenceNotice extends StatelessWidget {
  const LanguagePreferenceNotice({super.key, required this.controller});
  final LocaleController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      if (controller.failure != LocalePreferenceFailure.read) {
        return const SizedBox.shrink();
      }
      final l = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.languagePreferenceReadFailed),
            TextButton(
              onPressed: controller.busy ? null : controller.load,
              child: Text(l.retry),
            ),
          ],
        ),
      );
    },
  );
}
