import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';

class MutableClock implements Clock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class SequenceIdGenerator implements IdGenerator {
  SequenceIdGenerator([Iterable<String> values = const []])
    : _values = values.toList();

  final List<String> _values;
  int _nextValue = 0;

  @override
  String next() {
    if (_nextValue >= _values.length) {
      throw StateError('No deterministic ID remains');
    }
    return _values[_nextValue++];
  }
}
