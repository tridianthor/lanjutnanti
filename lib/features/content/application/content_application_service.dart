import 'package:lanjut_nanti/core/errors/application_failure.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

export 'package:lanjut_nanti/core/errors/application_failure.dart';

/// A row-shaped projection used by the home screen.
class ContentListItem {
  const ContentListItem({
    required this.content,
    required this.latestDetail,
    this.tag,
  });

  final Content content;
  final Tag? tag;
  final ContentDetail? latestDetail;

  String? get latestPreview {
    final detail = latestDetail;
    if (detail == null) return null;
    final note = detail.note;
    return note == null || note.trim().isEmpty ? detail.link : note;
  }

  DateTime get latestActivity => latestDetail?.updatedAt ?? content.updatedAt;
}

class CreateContentResult {
  const CreateContentResult(this.content);

  final Content content;

  /// Content without a detail is valid, so the UI can offer this next step.
  bool get shouldOfferFirstDetail => true;
  bool get offerFirstDetail => shouldOfferFirstDetail;
}

class ContentDetailView {
  const ContentDetailView({
    required this.content,
    required this.history,
    this.tag,
  });

  final Content content;
  final Tag? tag;
  final List<ContentDetail> history;

  ContentDetail? get latestDetail => history.isEmpty ? null : history.first;
}

class ContentDetailMutationResult {
  const ContentDetailMutationResult({
    this.detail,
    this.content,
    this.history = const [],
    this.deleted = false,
    this.cancelled = false,
  });

  const ContentDetailMutationResult.cancelled()
    : detail = null,
      content = null,
      history = const [],
      deleted = false,
      cancelled = true;

  final ContentDetail? detail;
  final Content? content;
  final List<ContentDetail> history;
  final bool deleted;
  final bool cancelled;

  bool get changed => detail != null || deleted;
  ContentDetail? get latestDetail => history.isEmpty ? null : history.first;
}

class ContentDeletionResult {
  const ContentDeletionResult({
    required this.id,
    this.deleted = false,
    this.cancelled = false,
  });

  const ContentDeletionResult.cancelled(this.id)
    : deleted = false,
      cancelled = true;

  final String id;
  final bool deleted;
  final bool cancelled;
}

/// Coordinates content and detail repositories for application-facing code.
class ContentApplicationService {
  const ContentApplicationService({
    required this.contentRepository,
    required this.detailRepository,
    required this.tagRepository,
  });

  final ContentRepository contentRepository;
  final ContentDetailRepository detailRepository;
  final TagRepository tagRepository;

  List<ContentListItem> listRecent({String query = '', String? tagId}) {
    return _guard('load content', () {
      // Read all supporting records before exposing any row. If one read fails,
      // callers receive an error rather than a list assembled from partial data.
      final tags = <String, Tag>{
        for (final tag in tagRepository.list()) tag.id: tag,
      };
      final contents = _selectContents(query: query, tagId: tagId, tags: tags);
      if (contents.isEmpty) return const <ContentListItem>[];
      final latestDetails = _latestDetails(
        contents.map((content) => content.id),
      );
      final items = <ContentListItem>[];
      for (final content in contents) {
        items.add(
          ContentListItem(
            content: content,
            tag: content.tagId == null ? null : tags[content.tagId],
            latestDetail: latestDetails[content.id],
          ),
        );
      }
      return List.unmodifiable(items);
    });
  }

  List<ContentListItem> loadRecent({String query = '', String? tagId}) =>
      listRecent(query: query, tagId: tagId);

  List<ContentListItem> search(String query, {String? tagId}) {
    return listRecent(query: query, tagId: tagId);
  }

  ContentDetailView loadDetails(String contentId) {
    return _guard('load content details', () {
      final content = contentRepository.findById(contentId);
      if (content == null) {
        throw ApplicationFailure(
          kind: ApplicationFailureKind.notFound,
          message: 'The requested content could not be found.',
        );
      }
      final tag =
          content.tagId == null ? null : tagRepository.findById(content.tagId!);
      return ContentDetailView(
        content: content,
        tag: tag,
        history: detailRepository.listForContent(contentId),
      );
    });
  }

  ContentDetailView getContentDetails(String contentId) =>
      loadDetails(contentId);

  CreateContentResult createContent({required String name, String? tagId}) {
    return _guard('save content', () {
      final content = contentRepository.create(name: name, tagId: tagId);
      return CreateContentResult(content);
    });
  }

  Content editContent({
    required String id,
    required String name,
    String? tagId,
  }) {
    return _guard('save content', () {
      return contentRepository.edit(id: id, name: name, tagId: tagId);
    });
  }

  ContentDetailMutationResult createDetail({
    required String contentId,
    required String link,
    String? note,
  }) {
    return _guard('save detail', () {
      final detail = detailRepository.create(
        contentId: contentId,
        link: link,
        note: note,
      );
      return _detailResult(detail);
    });
  }

  ContentDetailMutationResult editDetail({
    required String id,
    required String link,
    String? note,
  }) {
    return _guard('save detail', () {
      final detail = detailRepository.edit(id: id, link: link, note: note);
      return _detailResult(detail);
    });
  }

  ContentDetailMutationResult deleteDetail({
    required String id,
    bool confirmed = false,
  }) {
    if (!confirmed) return const ContentDetailMutationResult.cancelled();

    return _guard('delete detail', () {
      final existing = detailRepository.findById(id);
      if (existing == null) {
        return const ContentDetailMutationResult();
      }
      detailRepository.delete(id);
      final content = _requireContent(existing.contentId);
      return ContentDetailMutationResult(
        detail: existing,
        content: content,
        history: detailRepository.listForContent(existing.contentId),
        deleted: true,
      );
    });
  }

  ContentDeletionResult deleteContent({
    required String id,
    bool confirmed = false,
  }) {
    if (!confirmed) return ContentDeletionResult.cancelled(id);

    return _guard('delete content', () {
      if (contentRepository.findById(id) == null) {
        return ContentDeletionResult(id: id);
      }
      contentRepository.delete(id);
      return ContentDeletionResult(id: id, deleted: true);
    });
  }

  Content _requireContent(String id) {
    final content = contentRepository.findById(id);
    if (content == null) {
      throw ApplicationFailure(
        kind: ApplicationFailureKind.database,
        message: 'The detail was saved, but its content could not be reloaded.',
      );
    }
    return content;
  }

  ContentDetailMutationResult _detailResult(ContentDetail detail) {
    return ContentDetailMutationResult(
      detail: detail,
      content: _requireContent(detail.contentId),
      history: detailRepository.listForContent(detail.contentId),
    );
  }

  List<Content> _selectContents({
    required String query,
    required String? tagId,
    required Map<String, Tag> tags,
  }) {
    if (query.trim().isEmpty && tagId == null) {
      return contentRepository.listRecent();
    }

    final searchable = contentRepository;
    if (searchable is ContentSearchRepository) {
      return (searchable as ContentSearchRepository).search(
        query: query,
        tagId: tagId,
      );
    }

    // Application fakes and alternate stores can remain small by implementing
    // only ContentRepository. Their fallback keeps the same semantics, while
    // SQLite uses the set-based SQL search above.
    final normalizedQuery = query.trim().toLowerCase();
    return contentRepository.listRecent().where((content) {
      if (tagId != null && content.tagId != tagId) return false;
      if (normalizedQuery.isEmpty) return true;
      final tagName = content.tagId == null ? null : tags[content.tagId]?.name;
      if (content.name.toLowerCase().contains(normalizedQuery) ||
          tagName?.toLowerCase().contains(normalizedQuery) == true) {
        return true;
      }
      return detailRepository
          .listForContent(content.id)
          .any(
            (detail) =>
                detail.note?.toLowerCase().contains(normalizedQuery) == true,
          );
    }).toList();
  }

  Map<String, ContentDetail> _latestDetails(Iterable<String> contentIds) {
    final bulkReader = detailRepository;
    if (bulkReader is LatestContentDetailReader) {
      return (bulkReader as LatestContentDetailReader).latestForContents(
        contentIds,
      );
    }

    final latest = <String, ContentDetail>{};
    for (final contentId in contentIds) {
      final detail = detailRepository.latestForContent(contentId);
      if (detail != null) latest[contentId] = detail;
    }
    return latest;
  }
}

R _guard<R>(String operation, R Function() action) {
  try {
    return action();
  } on ApplicationFailure {
    rethrow;
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      mapApplicationFailure(error, operation: operation),
      stackTrace,
    );
  }
}

typedef ContentService = ContentApplicationService;
typedef ContentDetailResult = ContentDetailMutationResult;
