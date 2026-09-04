import 'package:url_launcher/url_launcher.dart';

/// Application-owned boundary for handing a saved link to the operating
/// system. UI tests can provide a deterministic fake instead of invoking a
/// platform plugin.
abstract interface class LinkLauncher {
  Future<bool> open(String link);
}

class UrlLauncherLinkLauncher implements LinkLauncher {
  const UrlLauncherLinkLauncher();

  @override
  Future<bool> open(String link) {
    return launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }
}

class UnavailableLinkLauncher implements LinkLauncher {
  const UnavailableLinkLauncher();

  @override
  Future<bool> open(String link) async => false;
}
