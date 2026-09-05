import 'package:flutter/foundation.dart';
import '../data/theme_preference_repository.dart';
import '../domain/theme_preference.dart';

enum ThemePreferenceFailure { read, write }

class ThemeController extends ChangeNotifier {
  ThemeController(this.repository);

  final ThemePreferenceRepository repository;
  ThemePreference preference = ThemePreference.system;
  ThemePreferenceFailure? failure;
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
      preference = ThemePreference.system;
      failure = ThemePreferenceFailure.read;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> select(ThemePreference value) async {
    if (busy) return false;
    busy = true;
    _notify();
    try {
      await repository.write(value);
      preference = value;
      failure = null;
      return true;
    } catch (_) {
      failure = ThemePreferenceFailure.write;
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }
}

