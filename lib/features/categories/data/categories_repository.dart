import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/category.dart';

/// Thin Dio wrapper for the `/v1/categories` family of endpoints.
///
/// Mirrors spec §3.1–§3.7 + §3.13. Pure data layer — translates
/// [DioException] into [ApiException] and parses JSON into [Category].
/// State + caching + optimistic updates live in [CategoriesCubit].
class CategoriesRepository {
  CategoriesRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/categories`. By default fetches only the user's active
  /// non-system rows (the categories management page hides system rows).
  /// Pass `includeSystem: true` for transaction screens that need to
  /// resolve the Transfer / Adjustment / Opening rows.
  Future<List<Category>> list({
    String? type,
    String status = 'active',
    bool includeSystem = false,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/categories',
        queryParameters: <String, dynamic>{
          'type': ?type,
          'status': status,
          'include_system': includeSystem.toString(),
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/categories`. Server assigns id + sort_order.
  Future<Category> create(Category draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/categories',
        data: draft.toCreateJson(),
      );
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/categories/:id`. Sends the full editable surface; server
  /// distinguishes "clear" (explicit null) from "leave alone" (field
  /// missing) per [Category.toUpdateJson]'s presence convention.
  Future<Category> update(Category category) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/categories/${category.id}',
        data: category.toUpdateJson(),
      );
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/categories/:id`. Returns the resolved status —
  /// `"deleted"` when there were no transactions (hard delete) or
  /// `"archived"` when soft-deleted with attached transactions
  /// (spec §3.5).
  Future<String> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/categories/$id',
      );
      return (res.data!['status'] as String?) ?? 'deleted';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/categories/:id/restore` — reactivates an archived row.
  Future<Category> restore(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/categories/$id/restore',
      );
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/categories/:id/permanent` — only valid from archived
  /// state with zero transactions (spec §3.7).
  Future<void> permanentDelete(String id) async {
    try {
      await _client.dio.delete<Map<String, dynamic>>(
        '/categories/$id/permanent',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /v1/categories/reorder` — atomic batch (parent_id,
  /// sort_order) rewrite. Returns the user's full updated active list
  /// per spec §3.13 so the cubit can drop its staged state straight in.
  ///
  /// [entries] should be the complete post-reorder list of `(id,
  /// parent_id, sort_order)` for whichever `(type)` the user touched —
  /// the server treats the payload as authoritative for that type.
  Future<List<Category>> reorder(List<Category> entries) async {
    try {
      final body = <String, dynamic>{
        'categories': [
          for (final c in entries)
            <String, dynamic>{
              'id': c.id,
              'parent_id': c.parentId,
              'sort_order': c.sortOrder,
            },
        ],
      };
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/categories/reorder',
        data: body,
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
