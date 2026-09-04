import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';

class Content {
  const Content({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.tagId,
    this.userId,
  });

  factory Content.create({
    required String name,
    required Clock clock,
    required IdGenerator idGenerator,
    String? tagId,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }

    final now = clock.now().toUtc();
    return Content(
      id: idGenerator.next(),
      name: normalizedName,
      tagId: tagId,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String name;
  final String? tagId;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
