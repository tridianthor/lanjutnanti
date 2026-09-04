import 'dart:convert';

import 'package:lanjut_nanti/core/time/timestamp_parser.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

/// A single problem found while decoding a backup.
class BackupValidationIssue {
  const BackupValidationIssue({required this.path, required this.message});

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// The validated, immutable input to a restore transaction.
class BackupRestorePreview {
  BackupRestorePreview({
    required this.snapshot,
    required this.exportedAt,
    Map<String, DateTime>? contentActivityFloors,
  }) : contentActivityFloors = Map.unmodifiable(
         contentActivityFloors ??
             {
               for (final content in snapshot.contents)
                 content.id: content.updatedAt,
             },
       );

  final BackupSnapshot snapshot;
  final DateTime exportedAt;

  List<Tag> get tags => snapshot.tags;
  List<Content> get contents => snapshot.contents;
  List<ContentDetail> get contentDetails => snapshot.contentDetails;

  /// The content's activity before detail activity is applied. The portable
  /// format has no separate floor field, so this is the imported content
  /// timestamp and is retained when a later detail is eventually deleted.
  final Map<String, DateTime> contentActivityFloors;

  int get tagCount => snapshot.tags.length;
  int get contentCount => snapshot.contents.length;
  int get detailCount => snapshot.contentDetails.length;

  DateTime contentActivityFloor(String contentId) {
    final floor = contentActivityFloors[contentId];
    if (floor == null) {
      throw StateError('No activity floor exists for content $contentId');
    }
    return floor;
  }
}

/// The result of the pure decode and validation phase.
class BackupRestoreValidationResult {
  BackupRestoreValidationResult({
    this.preview,
    Iterable<BackupValidationIssue> issues = const [],
    this.tagCount = 0,
    this.contentCount = 0,
    this.detailCount = 0,
  }) : issues = List.unmodifiable(issues);

  final BackupRestorePreview? preview;
  final List<BackupValidationIssue> issues;
  final int tagCount;
  final int contentCount;
  final int detailCount;

  bool get isValid => preview != null && issues.isEmpty;
  bool get hasErrors => issues.isNotEmpty;

  String get summary {
    if (isValid) {
      return '$tagCount tags, $contentCount content items, and '
          '$detailCount details are ready to restore.';
    }
    if (issues.isEmpty) return 'The backup could not be restored.';
    final first = issues.first;
    final remaining = issues.length - 1;
    final suffix = remaining == 0 ? '' : ' (+$remaining more)';
    return '${first.path}: ${first.message}$suffix';
  }
}

/// Decodes and validates schema-version-1 backups without touching SQLite.
class BackupRestoreValidator {
  const BackupRestoreValidator();

  BackupRestoreValidationResult validate(String source) => validateJson(source);

  BackupRestoreValidationResult decodeAndValidate(String source) =>
      validateJson(source);

  BackupRestoreValidationResult validateBytes(List<int> bytes) {
    try {
      return validateJson(utf8.decode(bytes));
    } on FormatException {
      return BackupRestoreValidationResult(
        issues: const [
          BackupValidationIssue(
            path: 'file',
            message: 'The file is not valid UTF-8 JSON.',
          ),
        ],
      );
    }
  }

  BackupRestoreValidationResult validateJson(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return BackupRestoreValidationResult(
        issues: const [
          BackupValidationIssue(
            path: 'file',
            message: 'The file is not valid JSON.',
          ),
        ],
      );
    }

    if (decoded is! Map) {
      return BackupRestoreValidationResult(
        issues: const [
          BackupValidationIssue(
            path: r'$',
            message: 'The backup top level must be a JSON object.',
          ),
        ],
      );
    }

    final document = Map<Object?, Object?>.from(decoded);
    final issues = <BackupValidationIssue>[];
    final schemaVersion = document['schema_version'];
    if (schemaVersion is! int || schemaVersion != 1) {
      issues.add(
        const BackupValidationIssue(
          path: 'schema_version',
          message: 'Only schema version 1 is supported.',
        ),
      );
    }

    DateTime? exportedAt;
    final exportedAtValue = document['exported_at'];
    if (exportedAtValue is! String) {
      issues.add(
        const BackupValidationIssue(
          path: 'exported_at',
          message: 'A timestamp string is required.',
        ),
      );
    } else {
      exportedAt = _parseTimestamp(exportedAtValue, 'exported_at', issues);
    }

    final tagsValue = _collection(document, 'tags', issues);
    final contentsValue = _collection(document, 'contents', issues);
    final detailsValue = _collection(document, 'content_details', issues);
    final tags = <Tag>[];
    final contents = <Content>[];
    final details = <ContentDetail>[];
    final ids = <String, String>{};

    if (tagsValue != null) {
      for (var index = 0; index < tagsValue.length; index++) {
        final path = 'tags[$index]';
        final map = _entityMap(tagsValue[index], path, issues);
        if (map == null) continue;
        final id = _requiredId(map, '$path.id', issues);
        if (id != null) _recordId(id, path, ids, issues);
        final name = _requiredString(map, 'name', path, issues);
        final createdAt = _requiredTimestamp(map, 'created_at', path, issues);
        final updatedAt = _requiredTimestamp(map, 'updated_at', path, issues);
        if (id == null ||
            name == null ||
            createdAt == null ||
            updatedAt == null) {
          continue;
        }
        try {
          tags.add(
            Tag(
              id: id,
              name: Tag.normalizeName(name),
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );
        } on ArgumentError {
          issues.add(
            BackupValidationIssue(
              path: '$path.name',
              message: 'The tag name must not be empty.',
            ),
          );
        }
      }
    }

    final tagIds = tags.map((tag) => tag.id).toSet();
    final contentIds = <String>{};
    final contentActivityFloors = <String, DateTime>{};
    if (contentsValue != null) {
      for (var index = 0; index < contentsValue.length; index++) {
        final path = 'contents[$index]';
        final map = _entityMap(contentsValue[index], path, issues);
        if (map == null) continue;
        final id = _requiredId(map, '$path.id', issues);
        if (id != null) {
          _recordId(id, path, ids, issues);
          contentIds.add(id);
        }
        final name = _requiredString(map, 'name', path, issues);
        final tagId = _nullableRequiredString(map, 'tag_id', path, issues);
        final createdAt = _requiredTimestamp(map, 'created_at', path, issues);
        final updatedAt = _requiredTimestamp(map, 'updated_at', path, issues);
        final ownership = map['user_id'];
        if (map.containsKey('user_id') &&
            ownership != null &&
            ownership is! String) {
          issues.add(
            BackupValidationIssue(
              path: '$path.user_id',
              message: 'Ownership data must be a string or null.',
            ),
          );
        }
        if (tagId != null && !tagIds.contains(tagId)) {
          issues.add(
            BackupValidationIssue(
              path: '$path.tag_id',
              message: 'The referenced tag does not exist in this backup.',
            ),
          );
        }
        if (id == null ||
            name == null ||
            createdAt == null ||
            updatedAt == null) {
          continue;
        }
        try {
          final normalizedName = Content.normalizeName(name);
          contents.add(
            Content(
              id: id,
              name: normalizedName,
              tagId: tagId,
              userId: null,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );
          contentActivityFloors[id] = updatedAt;
        } on ArgumentError {
          issues.add(
            BackupValidationIssue(
              path: '$path.name',
              message: 'The content name must not be empty.',
            ),
          );
        }
      }
    }

    if (detailsValue != null) {
      for (var index = 0; index < detailsValue.length; index++) {
        final path = 'content_details[$index]';
        final map = _entityMap(detailsValue[index], path, issues);
        if (map == null) continue;
        final id = _requiredId(map, '$path.id', issues);
        if (id != null) _recordId(id, path, ids, issues);
        final contentId = _requiredString(map, 'content_id', path, issues);
        final link = _requiredString(map, 'link', path, issues);
        final note = _nullableRequiredString(map, 'note', path, issues);
        final createdAt = _requiredTimestamp(map, 'created_at', path, issues);
        final updatedAt = _requiredTimestamp(map, 'updated_at', path, issues);
        if (contentId != null && !contentIds.contains(contentId)) {
          issues.add(
            BackupValidationIssue(
              path: '$path.content_id',
              message: 'The referenced content does not exist in this backup.',
            ),
          );
        }
        String? normalizedLink;
        if (link != null) {
          try {
            normalizedLink = ContentDetail.normalizeLink(link);
          } on ArgumentError {
            issues.add(
              BackupValidationIssue(
                path: '$path.link',
                message: 'The link must be a non-empty absolute URI.',
              ),
            );
          }
        }
        if (id == null ||
            contentId == null ||
            normalizedLink == null ||
            createdAt == null ||
            updatedAt == null) {
          continue;
        }
        details.add(
          ContentDetail(
            id: id,
            contentId: contentId,
            link: normalizedLink,
            note: note == null ? null : ContentDetail.normalizeNote(note),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
      }
    }

    _rejectDuplicateTagNames(tags, issues);

    if (issues.isNotEmpty || exportedAt == null) {
      return BackupRestoreValidationResult(
        issues: issues,
        tagCount: tagsValue?.length ?? 0,
        contentCount: contentsValue?.length ?? 0,
        detailCount: detailsValue?.length ?? 0,
      );
    }

    final normalizedContents = [
      for (final content in contents)
        _normalizeContentActivity(content, details),
    ];
    final snapshot = BackupSnapshot(
      tags: tags,
      contents: normalizedContents,
      contentDetails: details,
    );
    return BackupRestoreValidationResult(
      preview: BackupRestorePreview(
        snapshot: snapshot,
        exportedAt: exportedAt,
        contentActivityFloors: {
          for (final content in normalizedContents)
            content.id: contentActivityFloors[content.id]!,
        },
      ),
      tagCount: tags.length,
      contentCount: contents.length,
      detailCount: details.length,
    );
  }
}

List<Object?>? _collection(
  Map<Object?, Object?> document,
  String key,
  List<BackupValidationIssue> issues,
) {
  final value = document[key];
  if (value is! List) {
    issues.add(
      BackupValidationIssue(path: key, message: 'A JSON array is required.'),
    );
    return null;
  }
  return value;
}

Map<Object?, Object?>? _entityMap(
  Object? value,
  String path,
  List<BackupValidationIssue> issues,
) {
  if (value is! Map) {
    issues.add(
      BackupValidationIssue(path: path, message: 'A JSON object is required.'),
    );
    return null;
  }
  return Map<Object?, Object?>.from(value);
}

String? _requiredId(
  Map<Object?, Object?> map,
  String path,
  List<BackupValidationIssue> issues,
) {
  final value = map[path.split('.').last];
  if (value is! String ||
      !RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value)) {
    issues.add(
      BackupValidationIssue(path: path, message: 'A valid UUID is required.'),
    );
    return null;
  }
  return value;
}

String? _requiredString(
  Map<Object?, Object?> map,
  String key,
  String path,
  List<BackupValidationIssue> issues,
) {
  final value = map[key];
  if (value is! String) {
    issues.add(
      BackupValidationIssue(
        path: '$path.$key',
        message: 'A string value is required.',
      ),
    );
    return null;
  }
  return value;
}

String? _nullableRequiredString(
  Map<Object?, Object?> map,
  String key,
  String path,
  List<BackupValidationIssue> issues,
) {
  if (!map.containsKey(key)) {
    issues.add(
      BackupValidationIssue(
        path: '$path.$key',
        message: 'The field is required and may be null.',
      ),
    );
    return null;
  }
  final value = map[key];
  if (value != null && value is! String) {
    issues.add(
      BackupValidationIssue(
        path: '$path.$key',
        message: 'The value must be a string or null.',
      ),
    );
    return null;
  }
  return value as String?;
}

DateTime? _requiredTimestamp(
  Map<Object?, Object?> map,
  String key,
  String path,
  List<BackupValidationIssue> issues,
) {
  if (!map.containsKey(key)) {
    issues.add(
      BackupValidationIssue(
        path: '$path.$key',
        message: 'A timestamp string is required.',
      ),
    );
    return null;
  }
  final value = map[key];
  if (value is! String) {
    issues.add(
      BackupValidationIssue(
        path: '$path.$key',
        message: 'A timestamp string is required.',
      ),
    );
    return null;
  }
  return _parseTimestamp(value, '$path.$key', issues);
}

DateTime? _parseTimestamp(
  String value,
  String path,
  List<BackupValidationIssue> issues,
) {
  try {
    return parseUtcTimestamp(value);
  } on FormatException {
    issues.add(
      BackupValidationIssue(
        path: path,
        message: 'The timestamp must be a valid ISO 8601 timestamp.',
      ),
    );
    return null;
  }
}

void _recordId(
  String id,
  String path,
  Map<String, String> ids,
  List<BackupValidationIssue> issues,
) {
  final firstPath = ids[id];
  if (firstPath != null) {
    issues.add(
      BackupValidationIssue(
        path: '$path.id',
        message: 'This ID duplicates $firstPath and must be unique.',
      ),
    );
    return;
  }
  ids[id] = path;
}

void _rejectDuplicateTagNames(
  List<Tag> tags,
  List<BackupValidationIssue> issues,
) {
  final names = <String, String>{};
  for (final tag in tags) {
    final key = tag.name.toLowerCase();
    final firstId = names[key];
    if (firstId != null) {
      issues.add(
        BackupValidationIssue(
          path: 'tags',
          message:
              'Tag names must be unique regardless of letter case '
              '(duplicate of $firstId).',
        ),
      );
    } else {
      names[key] = tag.id;
    }
  }
}

Content _normalizeContentActivity(
  Content content,
  List<ContentDetail> details,
) {
  var activity = content.updatedAt;
  for (final detail in details) {
    if (detail.contentId == content.id && detail.updatedAt.isAfter(activity)) {
      activity = detail.updatedAt;
    }
  }
  if (activity == content.updatedAt) return content;
  return Content(
    id: content.id,
    name: content.name,
    tagId: content.tagId,
    userId: null,
    createdAt: content.createdAt,
    updatedAt: activity,
  );
}

typedef BackupImportValidator = BackupRestoreValidator;
typedef BackupImportPreview = BackupRestorePreview;
typedef BackupImportValidationResult = BackupRestoreValidationResult;
