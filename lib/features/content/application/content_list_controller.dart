import 'package:flutter/foundation.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

enum ContentListStatus { initial, loading, data, empty, error }

class ContentListState {
  static const _notProvided = Object();

  const ContentListState({
    this.status = ContentListStatus.initial,
    this.items = const [],
    this.query = '',
    this.tagId,
    this.error,
  });

  final ContentListStatus status;
  final List<ContentListItem> items;
  final String query;
  final String? tagId;
  final ApplicationFailure? error;

  bool get isLoading => status == ContentListStatus.loading;
  bool get hasData => status == ContentListStatus.data;
  bool get isEmpty => status == ContentListStatus.empty;
  bool get hasError => status == ContentListStatus.error;
  bool get hasSearch => query.trim().isNotEmpty || tagId != null;

  ContentListState copyWith({
    ContentListStatus? status,
    List<ContentListItem>? items,
    String? query,
    Object? tagId = _notProvided,
    ApplicationFailure? error,
  }) {
    return ContentListState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      tagId: identical(tagId, _notProvided) ? this.tagId : tagId as String?,
      error: error,
    );
  }
}

/// Holds the observable list state and refreshes it only after a mutation has
/// completed successfully.
class ContentListController extends ChangeNotifier {
  ContentListController({
    ContentApplicationService? service,
    ContentRepository? contentRepository,
    ContentDetailRepository? detailRepository,
    TagRepository? tagRepository,
  }) : _service =
           service ??
           _serviceFromRepositories(
             contentRepository,
             detailRepository,
             tagRepository,
           );

  final ContentApplicationService _service;
  ContentListState _state = const ContentListState();
  String _query = '';
  String? _tagId;

  ContentListState get state => _state;

  /// Exposes read-only application operations to screens that are not the
  /// home list. Mutations should continue to go through this controller so
  /// the home list is refreshed only after a committed change.
  ContentApplicationService get service => _service;

  Future<void> load({String? query, String? tagId}) async {
    if (query != null) _query = query;
    if (tagId != null || query != null) _tagId = tagId;
    final previousItems = _state.items;
    _publish(
      ContentListState(
        status: ContentListStatus.loading,
        items: previousItems,
        query: _query,
        tagId: _tagId,
      ),
    );
    try {
      _publishLoaded(_loadItems());
    } catch (error, stackTrace) {
      _publish(
        ContentListState(
          status: ContentListStatus.error,
          items: previousItems,
          query: _query,
          tagId: _tagId,
          error: _asFailure(error, stackTrace, operation: 'load content'),
        ),
      );
    }
  }

  /// Refreshes the list immediately as the user types; no submit action is
  /// needed for local search.
  Future<void> search(String query) async {
    _query = query;
    await load();
  }

  Future<void> setQuery(String query) => search(query);

  Future<void> setSearchQuery(String query) => search(query);

  Future<void> setTagFilter(String? tagId) async {
    _tagId = tagId;
    await load();
  }

  Future<CreateContentResult?> createContent({
    required String name,
    String? tagId,
  }) {
    return _runMutation(() => _service.createContent(name: name, tagId: tagId));
  }

  Future<Content?> editContent({
    required String id,
    required String name,
    String? tagId,
  }) {
    return _runMutation(
      () => _service.editContent(id: id, name: name, tagId: tagId),
    );
  }

  Future<ContentDetailMutationResult?> createDetail({
    required String contentId,
    required String link,
    String? note,
  }) {
    return _runMutation(
      () => _service.createDetail(contentId: contentId, link: link, note: note),
    );
  }

  Future<ContentDetailMutationResult?> editDetail({
    required String id,
    required String link,
    String? note,
  }) {
    return _runMutation(
      () => _service.editDetail(id: id, link: link, note: note),
    );
  }

  Future<ContentDetailMutationResult?> deleteDetail({
    required String id,
    bool confirmed = false,
  }) {
    if (!confirmed) {
      return Future.value(_service.deleteDetail(id: id));
    }
    return _runMutation(() => _service.deleteDetail(id: id, confirmed: true));
  }

  Future<ContentDeletionResult?> deleteContent({
    required String id,
    bool confirmed = false,
  }) {
    if (!confirmed) {
      return Future.value(_service.deleteContent(id: id));
    }
    return _runMutation(() => _service.deleteContent(id: id, confirmed: true));
  }

  Future<T?> _runMutation<T>(T Function() operation) async {
    final previousItems = _state.items;
    _publish(
      ContentListState(
        status: ContentListStatus.loading,
        items: previousItems,
        query: _query,
        tagId: _tagId,
      ),
    );
    try {
      final result = operation();
      _publishLoaded(_loadItems());
      return result;
    } catch (error, stackTrace) {
      _publish(
        ContentListState(
          status: ContentListStatus.error,
          items: previousItems,
          query: _query,
          tagId: _tagId,
          error: _asFailure(error, stackTrace, operation: 'save changes'),
        ),
      );
      return null;
    }
  }

  void _publishLoaded(List<ContentListItem> items) {
    final stableItems = List<ContentListItem>.unmodifiable(items);
    _publish(
      ContentListState(
        status:
            stableItems.isEmpty
                ? ContentListStatus.empty
                : ContentListStatus.data,
        items: stableItems,
        query: _query,
        tagId: _tagId,
      ),
    );
  }

  List<ContentListItem> _loadItems() {
    return _query.trim().isEmpty && _tagId == null
        ? _service.listRecent()
        : _service.search(_query, tagId: _tagId);
  }

  void _publish(ContentListState next) {
    _state = next;
    notifyListeners();
  }
}

ContentApplicationService _serviceFromRepositories(
  ContentRepository? contentRepository,
  ContentDetailRepository? detailRepository,
  TagRepository? tagRepository,
) {
  if (contentRepository == null ||
      detailRepository == null ||
      tagRepository == null) {
    throw ArgumentError(
      'Provide a ContentApplicationService or all three repositories.',
    );
  }
  return ContentApplicationService(
    contentRepository: contentRepository,
    detailRepository: detailRepository,
    tagRepository: tagRepository,
  );
}

ApplicationFailure _asFailure(
  Object error,
  StackTrace stackTrace, {
  required String operation,
}) {
  final failure = mapApplicationFailure(error, operation: operation);
  return ApplicationFailure(
    kind: failure.kind,
    message: failure.message,
    cause: failure.cause,
    stackTrace: failure.stackTrace ?? stackTrace,
  );
}

typedef ContentController = ContentListController;
typedef ContentApplicationController = ContentListController;
