import 'package:lanjut_nanti/features/content/domain/content_detail.dart';

List<ContentDetail> orderDetailsLatestFirst(Iterable<ContentDetail> details) {
  return details.toList()..sort((first, second) {
    final updatedComparison = second.updatedAt.compareTo(first.updatedAt);
    if (updatedComparison != 0) return updatedComparison;

    final createdComparison = second.createdAt.compareTo(first.createdAt);
    if (createdComparison != 0) return createdComparison;

    return second.id.compareTo(first.id);
  });
}

ContentDetail? latestDetail(Iterable<ContentDetail> details) {
  final ordered = orderDetailsLatestFirst(details);
  return ordered.isEmpty ? null : ordered.first;
}
