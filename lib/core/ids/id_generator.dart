import 'dart:math';

abstract interface class IdGenerator {
  String next();
}

class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator({int Function(int max)? nextInt})
    : _nextInt = nextInt ?? Random.secure().nextInt;

  final int Function(int max) _nextInt;

  @override
  String next() {
    final bytes = List<int>.generate(16, (_) => _nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
