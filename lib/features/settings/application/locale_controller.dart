import 'package:flutter/foundation.dart';
import '../data/locale_preference_repository.dart';
import '../domain/locale_preference.dart';

enum LocalePreferenceFailure { read, write }

class LocaleController extends ChangeNotifier {
  LocaleController(this.repository);
  final LocalePreferenceRepository repository;
  LocalePreference preference = LocalePreference.system;
  LocalePreferenceFailure? failure;
  bool busy = false;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      preference = await repository.read();
      failure = null;
    } catch (_) {
      preference = LocalePreference.system;
      failure = LocalePreferenceFailure.read;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> select(LocalePreference value) async {
    if (busy) return false;
    busy = true;
    _notify();
    try {
      await repository.write(value);
      preference = value;
      failure = null;
      return true;
    } catch (_) {
      failure = LocalePreferenceFailure.write;
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }
}
