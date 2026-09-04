import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';

class ContentDetail {
  const ContentDetail({
    required this.id,
    required this.contentId,
    required this.link,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory ContentDetail.create({
    required String contentId,
    required String link,
    required Clock clock,
    required IdGenerator idGenerator,
    String? note,
  }) {
    final now = clock.now().toUtc();
    return ContentDetail(
      id: idGenerator.next(),
      contentId: contentId,
      link: normalizeLink(link),
      note: normalizeNote(note),
      createdAt: now,
      updatedAt: now,
    );
  }

  static String normalizeLink(String link) {
    final normalized = link.trim();
    final uri = Uri.tryParse(normalized);
    if (normalized.isEmpty || uri == null || !uri.isAbsolute) {
      throw ArgumentError.value(link, 'link', 'must be an absolute URI');
    }
    return normalized;
  }

  static String? normalizeNote(String? note) {
    return note == null || note.trim().isEmpty ? null : note;
  }

  final String id;
  final String contentId;
  final String link;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentDetailMutation edit({
    required String link,
    required String? note,
    required Clock clock,
  }) {
    final now = clock.now().toUtc();
    return ContentDetailMutation(
      detail: ContentDetail(
        id: id,
        contentId: contentId,
        link: normalizeLink(link),
        note: normalizeNote(note),
        createdAt: createdAt,
        updatedAt: now,
      ),
      parentUpdatedAt: now,
    );
  }
}

class ContentDetailMutation {
  const ContentDetailMutation({
    required this.detail,
    required this.parentUpdatedAt,
  });

  final ContentDetail detail;
  final DateTime parentUpdatedAt;
}
