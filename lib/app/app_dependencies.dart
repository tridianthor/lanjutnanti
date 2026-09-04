import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';

class AppDependencies {
  const AppDependencies({required this.clock, required this.idGenerator});

  factory AppDependencies.production() {
    return AppDependencies(
      clock: const SystemClock(),
      idGenerator: RandomIdGenerator(),
    );
  }

  final Clock clock;
  final IdGenerator idGenerator;
}
