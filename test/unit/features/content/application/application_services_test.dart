import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/tags/application/tag_application_service.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

import '../../../../support/database_test_support.dart';

void main() {
  group('ContentListController', () {
    late FakeContentRepository contents;
    late FakeContentDetailRepository details;
    late FakeTagRepository tags;
    late ContentListController controller;

    setUp(() {
      contents = FakeContentRepository([
        Content(
          id: 'content-1',
          name: 'Doraemon',
          tagId: 'tag-1',
          createdAt: DateTime.utc(2026, 9, 4),
          updatedAt: DateTime.utc(2026, 9, 5),
        ),
      ]);
      details = FakeContentDetailRepository({
        'content-1': ContentDetail(
          id: 'detail-1',
          contentId: 'content-1',
          link: 'https://example.com/chapter/1',
          note: 'Continue here',
          createdAt: DateTime.utc(2026, 9, 4),
          updatedAt: DateTime.utc(2026, 9, 5),
        ),
      });
      tags = FakeTagRepository([
        Tag(
          id: 'tag-1',
          name: 'Manga',
          createdAt: DateTime.utc(2026, 9, 4),
          updatedAt: DateTime.utc(2026, 9, 4),
        ),
      ]);
      controller = ContentListController(
        service: ContentApplicationService(
          contentRepository: contents,
          detailRepository: details,
          tagRepository: tags,
        ),
      );
    });

    test(
      'emits loading followed by data and joins latest detail and tag',
      () async {
        final statuses = <ContentListStatus>[];
        controller.addListener(() => statuses.add(controller.state.status));

        await controller.load();

        expect(statuses, [ContentListStatus.loading, ContentListStatus.data]);
        expect(controller.state.items, hasLength(1));
        expect(controller.state.items.single.content.name, 'Doraemon');
        expect(controller.state.items.single.tag!.name, 'Manga');
        expect(
          controller.state.items.single.latestDetail!.note,
          'Continue here',
        );
      },
    );

    test('emits empty when the repository has no content', () async {
      contents.values.clear();

      await controller.load();

      expect(controller.state.status, ContentListStatus.empty);
      expect(controller.state.items, isEmpty);
    });

    test('keeps the last committed items when a refresh fails', () async {
      await controller.load();
      details.error = StateError('database unavailable');

      await controller.load();

      expect(controller.state.status, ContentListStatus.error);
      expect(controller.state.items.single.content.id, 'content-1');
      expect(controller.state.error, isA<ApplicationFailure>());
      expect(controller.state.error!.isDatabase, isTrue);
    });

    test(
      'refreshes the ordered list only after a successful content save',
      () async {
        await controller.load();

        final result = await controller.createContent(name: '  New content  ');

        expect(result, isNotNull);
        expect(controller.state.status, ContentListStatus.data);
        expect(controller.state.items.map((item) => item.content.name), [
          'Doraemon',
          'New content',
        ]);
      },
    );

    test(
      'does not publish a newly created row when the repository fails',
      () async {
        await controller.load();
        contents.createError = StateError('write failed');

        final result = await controller.createContent(name: 'Never saved');

        expect(result, isNull);
        expect(controller.state.status, ContentListStatus.error);
        expect(controller.state.items.map((item) => item.content.name), [
          'Doraemon',
        ]);
      },
    );
  });

  test(
    'creating content returns a first-detail offer without creating a detail',
    () {
      final contents = FakeContentRepository();
      final service = ContentApplicationService(
        contentRepository: contents,
        detailRepository: FakeContentDetailRepository(),
        tagRepository: FakeTagRepository(),
      );

      final result = service.createContent(name: '  New content  ');

      expect(result.content.name, 'New content');
      expect(result.shouldOfferFirstDetail, isTrue);
      expect(result.content.id, 'created-content');
      expect(contents.createdNames, ['New content']);
    },
  );

  test('detail mutations return refreshed history and parent activity', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    final clock = MutableClock(DateTime.utc(2026, 9, 4));
    final contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1']),
    );
    final details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1', 'detail-2']),
    );
    final service = ContentApplicationService(
      contentRepository: contents,
      detailRepository: details,
      tagRepository: SqliteTagRepository(database, clock: clock),
    );
    final content = contents.create(name: 'Doraemon');

    clock.value = DateTime.utc(2026, 9, 5);
    final first = service.createDetail(
      contentId: content.id,
      link: 'https://example.com/1',
    );
    clock.value = DateTime.utc(2026, 9, 6);
    final second = service.createDetail(
      contentId: content.id,
      link: 'https://example.com/2',
    );

    expect(first.history.map((detail) => detail.id), ['detail-1']);
    expect(second.history.map((detail) => detail.id), ['detail-2', 'detail-1']);
    expect(second.content!.updatedAt, clock.value);

    clock.value = DateTime.utc(2026, 9, 7);
    final edited = service.editDetail(
      id: first.detail!.id,
      link: 'https://example.com/edited',
      note: 'Latest now',
    );
    expect(edited.history.first.id, first.detail!.id);
    expect(edited.content!.updatedAt, clock.value);
  });

  test('loads content detail history through the application boundary', () {
    final content = Content(
      id: 'content-1',
      name: 'Doraemon',
      tagId: 'tag-1',
      createdAt: DateTime.utc(2026, 9, 4),
      updatedAt: DateTime.utc(2026, 9, 4),
    );
    final first = ContentDetail(
      id: 'detail-1',
      contentId: content.id,
      link: 'https://example.com/1',
      createdAt: DateTime.utc(2026, 9, 4),
      updatedAt: DateTime.utc(2026, 9, 4),
    );
    final view = ContentApplicationService(
      contentRepository: FakeContentRepository([content]),
      detailRepository: FakeContentDetailRepository({content.id: first}),
      tagRepository: FakeTagRepository([
        Tag(
          id: 'tag-1',
          name: 'Manga',
          createdAt: DateTime.utc(2026, 9, 4),
          updatedAt: DateTime.utc(2026, 9, 4),
        ),
      ]),
    ).loadDetails(content.id);

    expect(view.content.id, content.id);
    expect(view.tag!.name, 'Manga');
    expect(view.latestDetail!.id, first.id);
  });

  test('content deletion is a no-op until explicitly confirmed', () {
    final contents = FakeContentRepository([
      Content(
        id: 'content-1',
        name: 'Doraemon',
        createdAt: DateTime.utc(2026, 9, 4),
        updatedAt: DateTime.utc(2026, 9, 4),
      ),
    ]);
    final service = ContentApplicationService(
      contentRepository: contents,
      detailRepository: FakeContentDetailRepository(),
      tagRepository: FakeTagRepository(),
    );

    final cancelled = service.deleteContent(id: 'content-1');

    expect(cancelled.cancelled, isTrue);
    expect(contents.deletedIds, isEmpty);

    final deleted = service.deleteContent(id: 'content-1', confirmed: true);
    expect(deleted.deleted, isTrue);
    expect(contents.deletedIds, ['content-1']);
  });

  test('detail deletion is a no-op until explicitly confirmed', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    final clock = MutableClock(DateTime.utc(2026, 9, 4));
    final contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1']),
    );
    final details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1']),
    );
    final content = contents.create(name: 'Doraemon');
    final detail = details.create(
      contentId: content.id,
      link: 'https://example.com/1',
    );
    final service = ContentApplicationService(
      contentRepository: contents,
      detailRepository: details,
      tagRepository: SqliteTagRepository(database),
    );

    final cancelled = service.deleteDetail(id: detail.id);
    expect(cancelled.cancelled, isTrue);
    expect(details.findById(detail.id), isNotNull);

    final deleted = service.deleteDetail(id: detail.id, confirmed: true);
    expect(deleted.deleted, isTrue);
    expect(details.findById(detail.id), isNull);
  });

  test('tag uniqueness errors become actionable conflict failures', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    final repository = SqliteTagRepository(
      database,
      clock: MutableClock(DateTime.utc(2026, 9, 4)),
      idGenerator: SequenceIdGenerator(['tag-1', 'tag-2']),
    );
    final service = TagApplicationService(repository);
    service.create('Manga');

    expect(
      () => service.create(' manga '),
      throwsA(
        isA<ApplicationFailure>()
            .having(
              (error) => error.kind,
              'kind',
              ApplicationFailureKind.conflict,
            )
            .having(
              (error) => error.message,
              'message',
              contains('already exists'),
            ),
      ),
    );
  });
}

class FakeContentRepository implements ContentRepository {
  FakeContentRepository([Iterable<Content> initial = const []])
    : values = initial.toList();

  final List<Content> values;
  final List<String> createdNames = [];
  final List<String> deletedIds = [];
  Object? createError;

  @override
  List<Content> getAll() => listRecent();

  @override
  List<Content> listRecent() => List<Content>.of(values);

  @override
  Content? findById(String id) =>
      values.where((content) => content.id == id).firstOrNull;

  @override
  Content? getById(String id) => findById(id);

  @override
  Content create({required String name, String? tagId}) {
    if (createError != null) throw createError!;
    final content = Content(
      id: 'created-content',
      name: name.trim(),
      tagId: tagId,
      createdAt: DateTime.utc(2026, 9, 4),
      updatedAt: DateTime.utc(2026, 9, 4),
    );
    createdNames.add(content.name);
    values.add(content);
    return content;
  }

  @override
  Content insert(Content content) => content;

  @override
  Content update(Content content) => content;

  @override
  Content edit({required String id, required String name, String? tagId}) {
    throw UnimplementedError();
  }

  @override
  Content assignTag({required String id, required String? tagId}) {
    throw UnimplementedError();
  }

  @override
  void delete(String id) => deletedIds.add(id);
}

class FakeContentDetailRepository implements ContentDetailRepository {
  FakeContentDetailRepository([Map<String, ContentDetail>? initial])
    : values = {...?initial};

  final Map<String, ContentDetail> values;
  Object? error;

  @override
  List<ContentDetail> getForContent(String contentId) =>
      listForContent(contentId);

  @override
  List<ContentDetail> listForContent(String contentId) {
    if (error != null) throw error!;
    return values.values
        .where((detail) => detail.contentId == contentId)
        .toList();
  }

  @override
  ContentDetail? findById(String id) => values[id];

  @override
  ContentDetail? getById(String id) => findById(id);

  @override
  ContentDetail? latestForContent(String contentId) {
    if (error != null) throw error!;
    final matching = listForContent(contentId);
    return matching.isEmpty ? null : matching.first;
  }

  @override
  ContentDetail create({
    required String contentId,
    required String link,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  ContentDetail insert(ContentDetail detail) => detail;

  @override
  ContentDetail update(ContentDetail detail) => detail;

  @override
  ContentDetail edit({required String id, required String link, String? note}) {
    throw UnimplementedError();
  }

  @override
  void delete(String id) {}
}

class FakeTagRepository implements TagRepository {
  FakeTagRepository([Iterable<Tag> initial = const []])
    : values = initial.toList();

  final List<Tag> values;

  @override
  List<Tag> getAll() => List<Tag>.of(values);

  @override
  List<Tag> list() => getAll();

  @override
  Tag? findById(String id) => values.where((tag) => tag.id == id).firstOrNull;

  @override
  Tag? getById(String id) => findById(id);

  @override
  Tag create(String name) => throw UnimplementedError();

  @override
  Tag insert(Tag tag) => tag;

  @override
  Tag update(Tag tag) => tag;

  @override
  Tag rename({required String id, required String name}) =>
      throw UnimplementedError();

  @override
  void delete(String id) {}
}
