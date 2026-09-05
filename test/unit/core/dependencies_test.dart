import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/settings/application/theme_controller.dart';
import 'package:lanjut_nanti/features/settings/data/theme_preference_repository.dart';

void main() {
  test('system clock always returns a UTC instant', () {
    final now = const SystemClock().now();

    expect(now.isUtc, isTrue);
  });

  test('ID generator supports a deterministic random source', () {
    final generator = RandomIdGenerator(nextInt: (_) => 0);

    expect(generator.next(), '00000000-0000-4000-8000-000000000000');
  });

  test('application dependencies expose injected clock and ID generator', () {
    final clock = _FixedClock(DateTime.utc(2026, 9, 4));
    final idGenerator = _FixedIdGenerator('content-1');
    final dependencies = AppDependencies(
      clock: clock,
      idGenerator: idGenerator,
    );

    expect(dependencies.clock.now(), DateTime.utc(2026, 9, 4));
    expect(dependencies.idGenerator.next(), 'content-1');
  });

  test('application dependencies expose injected themeController', () {
    final clock = _FixedClock(DateTime.utc(2026, 9, 4));
    final idGenerator = _FixedIdGenerator('content-1');
    final themeController = ThemeController(MemoryThemePreferenceRepository());
    addTearDown(themeController.dispose);
    final dependencies = AppDependencies(
      clock: clock,
      idGenerator: idGenerator,
      themeController: themeController,
    );

    expect(dependencies.themeController, same(themeController));
  });
}

class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}
