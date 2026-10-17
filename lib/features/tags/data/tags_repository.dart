import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/tag.dart';

class TagsRepository {
  TagsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<Tag>> list() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/tags');
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Tag.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Tag> create(Tag draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/tags',
        data: draft.toCreateJson(),
      );
      return Tag.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<({List<Tag> created, List<Tag> data})> batch({
    List<Tag> create = const [],
    List<Tag> update = const [],
    List<String> delete = const [],
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/tags',
        data: <String, dynamic>{
          'create': [for (final t in create) t.toCreateJson()],
          'update': [
            for (final t in update) {'id': t.id, ...t.toUpdateJson()},
          ],
          'delete': delete,
        },
      );
      List<Tag> tags(String key) => [
        for (final j in (res.data![key] as List).cast<Map<String, dynamic>>())
          Tag.fromJson(j),
      ];
      return (created: tags('created'), data: tags('data'));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Tag> update(Tag tag) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/tags/${tag.id}',
        data: tag.toUpdateJson(),
      );
      return Tag.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<Map<String, dynamic>>('/tags/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
