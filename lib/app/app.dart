import 'package:flutter/material.dart';
import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/application/theme_controller.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/data/theme_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/theme_preference.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

class LanjutNantiApp extends StatefulWidget {
  const LanjutNantiApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<LanjutNantiApp> createState() => _LanjutNantiAppState();
}

class _LanjutNantiAppState extends State<LanjutNantiApp> {
  late final LocaleController _locale =
      widget.dependencies?.localeController ??
      LocaleController(MemoryLocalePreferenceRepository());
  late final ThemeController _theme =
      widget.dependencies?.themeController ??
      ThemeController(MemoryThemePreferenceRepository());

  @override
  void dispose() {
    if (widget.dependencies?.localeController == null) _locale.dispose();
    if (widget.dependencies?.themeController == null) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return ListenableBuilder(
      listenable: Listenable.merge([_locale, _theme]),
      builder:
          (context, child) => MaterialApp(
            locale:
                _locale.preference.languageCode == null
                    ? null
                    : Locale(_locale.preference.languageCode!),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Lanjut Nanti',
            themeMode: switch (_theme.preference) {
              ThemePreference.system => ThemeMode.system,
              ThemePreference.light => ThemeMode.light,
              ThemePreference.dark => ThemeMode.dark,
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: HomeScreen(
              localeController: _locale,
              themeController: _theme,
              controller: dependencies?.contentController,
              tagService: dependencies?.tagService,
              backupExportController: dependencies?.backupExportController,
              backupRestoreController: dependencies?.backupRestoreController,
              linkLauncher:
                  dependencies?.linkLauncher ?? const UrlLauncherLinkLauncher(),
            ),
          ),
    );
  }
}
