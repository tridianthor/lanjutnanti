import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';

class FakeRepository extends MemoryLocalePreferenceRepository {
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? pending;
  @override
  Future<LocalePreference> read() async {
    if (failRead) throw const FormatException('invalid setting');
    return super.read();
  }

  @override
  Future<void> write(LocalePreference value) async {
    await pending?.future;
    if (failWrite) throw StateError('write failed');
    await super.write(value);
  }
}

void main() {
  test('loads saved choice and recovers from failed reads', () async {
    final repo = FakeRepository()..preference = LocalePreference.indonesian;
    final controller = LocaleController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.preference, LocalePreference.indonesian);
    repo.failRead = true;
    await controller.load();
    expect(controller.preference, LocalePreference.system);
    expect(controller.failure, LocalePreferenceFailure.read);
    repo.failRead = false;
    await controller.load();
    expect(controller.preference, LocalePreference.indonesian);
    expect(controller.failure, isNull);
  });
  test('publishes only after save and preserves choice on failure', () async {
    final repo = FakeRepository()..pending = Completer<void>();
    final controller = LocaleController(repo);
    addTearDown(controller.dispose);
    final save = controller.select(LocalePreference.indonesian);
    expect(controller.busy, isTrue);
    expect(controller.preference, LocalePreference.system);
    expect(await controller.select(LocalePreference.english), isFalse);
    repo.pending!.complete();
    expect(await save, isTrue);
    expect(controller.preference, LocalePreference.indonesian);
    repo.failWrite = true;
    expect(await controller.select(LocalePreference.english), isFalse);
    expect(controller.preference, LocalePreference.indonesian);
    expect(repo.preference, LocalePreference.indonesian);
    expect(controller.failure, LocalePreferenceFailure.write);
    repo.failWrite = false;
    expect(await controller.select(LocalePreference.system), isTrue);
    expect(controller.failure, isNull);
    expect(controller.preference, LocalePreference.system);
  });
}
