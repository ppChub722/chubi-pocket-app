import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/project.dart';

class ProjectsRepository {
  ProjectsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  // --- Project CRUD ---

  Future<List<Project>> list({String? status, String? type}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects',
        queryParameters: <String, dynamic>{
          'status': ?status,
          'type': ?type,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Project.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> get(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/projects/$id');
      return Project.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> create({
    required String name,
    String? type,
    String? description,
    String? startDate,
    String? endDate,
    String? iconId,
    String? colorId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects',
        data: <String, dynamic>{
          'name': name,
          'type': ?type,
          'description': ?description,
          'start_date': ?startDate,
          'end_date': ?endDate,
          'icon_id': ?iconId,
          'color_id': ?colorId,
        },
      );
      return Project.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Project> update(String id, {
    String? name,
    String? type,
    String? description,
    String? startDate,
    String? endDate,
    ProjectStatus? status,
    String? iconId,
    String? colorId,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/projects/$id',
        data: <String, dynamic>{
          'name': ?name,
          'type': ?type,
          'description': ?description,
          'start_date': ?startDate,
          'end_date': ?endDate,
          'status': ?status?.wire,
          'icon_id': ?iconId,
          'color_id': ?colorId,
        },
      );
      return Project.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<dynamic>('/projects/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> leave(String id) async {
    try {
      await _client.dio.post<dynamic>('/projects/$id/leave');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> transferOwnership(String id, String newOwnerUserId) async {
    try {
      await _client.dio.post<dynamic>(
        '/projects/$id/transfer-ownership',
        data: <String, dynamic>{'new_owner_user_id': newOwnerUserId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // --- Members ---

  Future<List<ProjectMember>> listMembers(String projectId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects/$projectId/members',
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(ProjectMember.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Two variants (post-migration 27 — the from-contact variant is gone):
  ///   by-email:  pass `email` + `displayName`
  ///   ad-hoc:    pass `displayName` + `adHoc=true`
  ///
  /// "Add my contact X": resolve the contact's `linkedUserId` locally first,
  /// then call this with the contact's email (if any), or fall back to ad-hoc.
  Future<ProjectMember> addMember(String projectId, {
    String? email,
    String? displayName,
    MemberRole role = MemberRole.contributor,
    bool adHoc = false,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects/$projectId/members',
        data: <String, dynamic>{
          'email': ?email,
          'display_name': ?displayName,
          'role': role.wire,
          if (adHoc) 'ad_hoc': true,
        },
      );
      return ProjectMember.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProjectMember> updateMemberRole(
      String projectId, String memberId, MemberRole role) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/projects/$projectId/members/$memberId',
        data: <String, dynamic>{'role': role.wire},
      );
      return ProjectMember.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeMember(String projectId, String memberId) async {
    try {
      await _client.dio.delete<dynamic>(
        '/projects/$projectId/members/$memberId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> requestLink(String projectId, String memberId) async {
    try {
      await _client.dio.post<dynamic>(
        '/projects/$projectId/members/$memberId/request-link',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // --- Project transactions ---

  Future<List<ProjectTransaction>> listTransactions(String projectId,
      {int page = 1, int perPage = 20}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects/$projectId/transactions',
        queryParameters: <String, dynamic>{
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(ProjectTransaction.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProjectTransaction> createTransaction(
    String projectId, {
    required String transactionMemberId,
    required String type,
    required double amount,
    required String currency,
    required String date,
    String? description,
    String? note,
    String? categoryName,
    String? categoryIconId,
    String? categoryColorId,
    List<ProjectSplitInput> splits = const [],
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects/$projectId/project-transactions',
        data: <String, dynamic>{
          'transaction_member_id': transactionMemberId,
          'type': type,
          'amount': amount,
          'currency': currency,
          'date': date,
          'description': ?description,
          'note': ?note,
          'category_name': ?categoryName,
          'category_icon_id': ?categoryIconId,
          'category_color_id': ?categoryColorId,
          if (splits.isNotEmpty)
            'splits': splits.map((s) => s.toJson()).toList(),
        },
      );
      return ProjectTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `splits` semantics: pass `null` to leave existing children untouched;
  /// pass a list (possibly empty) to full-replace children.
  Future<ProjectTransaction> updateTransaction(
    String projectId,
    String ptId, {
    double? amount,
    String? date,
    String? description,
    String? note,
    String? categoryName,
    String? categoryIconId,
    String? categoryColorId,
    List<ProjectSplitInput>? splits,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/projects/$projectId/project-transactions/$ptId',
        data: <String, dynamic>{
          'amount': ?amount,
          'date': ?date,
          'description': ?description,
          'note': ?note,
          'category_name': ?categoryName,
          'category_icon_id': ?categoryIconId,
          'category_color_id': ?categoryColorId,
          if (splits != null) 'splits': splits.map((s) => s.toJson()).toList(),
        },
      );
      return ProjectTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteTransaction(String projectId, String ptId) async {
    try {
      await _client.dio.delete<dynamic>(
        '/projects/$projectId/project-transactions/$ptId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Toggle the caller's per-row "marked resolved" flag. Idempotent.
  /// Independent of personal-book resolve — does NOT create personal
  /// entries.
  Future<ProjectTransaction> toggleMark(
      String projectId, String ptId, bool marked) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/projects/$projectId/project-transactions/$ptId/mark',
        data: <String, dynamic>{'marked': marked},
      );
      return ProjectTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProjectSummary> summary(String projectId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects/$projectId/summary',
      );
      return ProjectSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
