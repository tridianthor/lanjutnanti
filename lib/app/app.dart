import 'package:flutter/material.dart';
import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/links/link_launcher.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';

class LanjutNantiApp extends StatelessWidget {
  const LanjutNantiApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lanjut Nanti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(
        controller: dependencies?.contentController,
        tagService: dependencies?.tagService,
        backupExportController: dependencies?.backupExportController,
        backupRestoreController: dependencies?.backupRestoreController,
        linkLauncher:
            dependencies?.linkLauncher ?? const UrlLauncherLinkLauncher(),
      ),
    );
  }
}
