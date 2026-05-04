import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/tag.dart';

/// Thin Dio wrapper for `/v1/tags`. Spec §3.8–§3.12, §4.11.
///
/// Tags are flat (no parent/child), hard-deleted (cascades the
/// `transaction_tags` junction), and server-sorted by `usage_count
/// DESC, name ASC` so the most-used tags surface first in pickers.
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
