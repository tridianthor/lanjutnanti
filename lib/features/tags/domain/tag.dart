import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';

class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tag.create({
    required String name,
    required Clock clock,
    required IdGenerator idGenerator,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final now = clock.now().toUtc();
    return Tag(
      id: idGenerator.next(),
      name: normalizedName,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get comparisonKey => name.toLowerCase();
}
