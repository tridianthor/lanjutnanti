import 'package:lanjut_nanti/core/errors/application_failure.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

export 'package:lanjut_nanti/core/errors/application_failure.dart';

class TagDeletionResult {
  const TagDeletionResult({
    required this.id,
    this.deleted = false,
    this.cancelled = false,
  });

  const TagDeletionResult.cancelled(this.id)
    : deleted = false,
      cancelled = true;

  final String id;
  final bool deleted;
  final bool cancelled;
}

/// Converts persistence failures into errors that tag-management UI can act on.
class TagApplicationService {
  const TagApplicationService(this.repository);

  const TagApplicationService.fromRepository({
    required TagRepository repository,
  }) : this(repository);

  final TagRepository repository;

  List<Tag> list() {
    return _guard('load tags', repository.list);
  }

  List<Tag> getAll() => list();

  Tag create(String name) {
    return _guard('save tag', () => repository.create(name));
  }

  Tag createTag(String name) => create(name);

  Tag rename({required String id, required String name}) {
    return _guard('rename tag', () {
      return repository.rename(id: id, name: name);
    });
  }

  Tag renameTag({required String id, required String name}) {
    return rename(id: id, name: name);
  }

  TagDeletionResult delete({required String id, bool confirmed = false}) {
    if (!confirmed) return TagDeletionResult.cancelled(id);

    return _guard('delete tag', () {
      if (repository.findById(id) == null) {
        return TagDeletionResult(id: id);
      }
      repository.delete(id);
      return TagDeletionResult(id: id, deleted: true);
    });
  }

  TagDeletionResult deleteTag({required String id, bool confirmed = false}) {
    return delete(id: id, confirmed: confirmed);
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

typedef TagService = TagApplicationService;
