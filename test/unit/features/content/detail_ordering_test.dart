import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/content/domain/detail_ordering.dart';

void main() {
  test('orders details by updatedAt descending', () {
    final older = _detail(
      id: 'older',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 2, 1),
    );
    final newer = _detail(
      id: 'newer',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2026, 3, 1),
    );

    expect(orderDetailsLatestFirst([older, newer]), [newer, older]);
  });

  test('uses createdAt descending when updated timestamps tie', () {
    final updatedAt = DateTime.utc(2026, 3, 1);
    final olderCreation = _detail(
      id: 'a',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: updatedAt,
    );
    final newerCreation = _detail(
      id: 'b',
      createdAt: DateTime.utc(2026, 2, 1),
      updatedAt: updatedAt,
    );

    expect(orderDetailsLatestFirst([olderCreation, newerCreation]), [
      newerCreation,
      olderCreation,
    ]);
  });

  test('uses ID descending when both timestamps tie exactly', () {
    final timestamp = DateTime.utc(2026, 3, 1);
    final lowerId = _detail(
      id: 'detail-a',
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final higherId = _detail(
      id: 'detail-b',
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    expect(orderDetailsLatestFirst([lowerId, higherId]), [higherId, lowerId]);
    expect(latestDetail([lowerId, higherId]), higherId);
  });

  test('returns null when no latest detail exists', () {
    expect(latestDetail(const []), isNull);
  });
}

ContentDetail _detail({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return ContentDetail(
    id: id,
    contentId: 'content-1',
    link: 'https://example.com/$id',
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
