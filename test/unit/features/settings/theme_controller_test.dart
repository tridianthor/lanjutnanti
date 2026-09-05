import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/settings/application/theme_controller.dart';
import 'package:lanjut_nanti/features/settings/data/theme_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/theme_preference.dart';

class FakeThemeRepository extends MemoryThemePreferenceRepository {
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? pending;

  @override
  Future<ThemePreference> read() async {
    if (failRead) throw const FormatException('invalid setting');
    return super.read();
  }

  @override
  Future<void> write(ThemePreference value) async {
    await pending?.future;
    if (failWrite) throw StateError('write failed');
    await super.write(value);
  }
}

void main() {
  test('loads saved choice and recovers from failed reads', () async {
    final repo = FakeThemeRepository()..preference = ThemePreference.dark;
    final controller = ThemeController(repo);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.preference, ThemePreference.dark);

    repo.failRead = true;
    await controller.load();
    expect(controller.preference, ThemePreference.system);
    expect(controller.failure, ThemePreferenceFailure.read);

    repo.failRead = false;
    await controller.load();
    expect(controller.preference, ThemePreference.dark);
    expect(controller.failure, isNull);
  });

  test('publishes only after save and preserves choice on failure', () async {
    final repo = FakeThemeRepository()..pending = Completer<void>();
    final controller = ThemeController(repo);
    addTearDown(controller.dispose);

    final save = controller.select(ThemePreference.dark);
    expect(controller.busy, isTrue);
    expect(controller.preference, ThemePreference.system);
    expect(await controller.select(ThemePreference.light), isFalse);

    repo.pending!.complete();
    expect(await save, isTrue);
    expect(controller.preference, ThemePreference.dark);

    repo.failWrite = true;
    expect(await controller.select(ThemePreference.light), isFalse);
    expect(controller.preference, ThemePreference.dark);
    expect(repo.preference, ThemePreference.dark);
    expect(controller.failure, ThemePreferenceFailure.write);

    repo.failWrite = false;
    expect(await controller.select(ThemePreference.system), isTrue);
    expect(controller.failure, isNull);
    expect(controller.preference, ThemePreference.system);
  });
}

