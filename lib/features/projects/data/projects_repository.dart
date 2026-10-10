import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icon_maker/icon_code.dart';
import '../domain/project.dart';

/// `POST /v1/projects/quick` response envelope (API §10 "Quick create"):
/// the created project (same shape as `POST /v1/projects`) plus
/// `linked_count` — the number of board rows created from the included
/// bills (new + ticked).
class QuickCreateResult {
  const QuickCreateResult({
    required this.project,
    required this.linkedCount,
    this.transactionId,
  });

  final Project project;
  final int linkedCount;

  /// The new bill the call created (null from an older server) — used to
  /// attach tags after the fact.
  final String? transactionId;
}

/// Thin Dio wrapper around `/v1/projects` (API §10).
class ProjectsRepository {
  ProjectsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  // --- Project CRUD ---

  Future<List<Project>> list({String? status, String? type}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects',
        queryParameters: <String, dynamic>{'status': ?status, 'type': ?type},
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
    String? note,
    String? startDate,
    String? endDate,
    IconCode? iconCode,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects',
        data: <String, dynamic>{
          'name': name,
          'type': ?type,
          'description': ?description,
          'note': ?note,
          'start_date': ?startDate,
          'end_date': ?endDate,
          if (iconCode != null) 'icon_code': iconCode.toJson(),
        },
      );
      return Project.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `planned_amount` (API §10, spec §10/4.23) uses presence semantics:
  /// pass [plannedAmount] to set the plan, set [clearPlannedAmount] to
  /// send an explicit `null` (turns the plan display off), leave both
  /// unset to keep the column unchanged. [description] / [note]: null =
  /// unchanged, `''` = clear (migration 51).
  Future<Project> update(
    String id, {
    String? name,
    String? type,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    ProjectStatus? status,
    IconCode? iconCode,
    double? plannedAmount,
    bool clearPlannedAmount = false,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/projects/$id',
        data: <String, dynamic>{
          'name': ?name,
          'type': ?type,
          'description': ?description,
          'note': ?note,
          'start_date': ?startDate,
          'end_date': ?endDate,
          'status': ?status?.wire,
          if (iconCode != null) 'icon_code': iconCode.toJson(),
          if (plannedAmount != null)
            'planned_amount': plannedAmount
          else if (clearPlannedAmount)
            'planned_amount': null,
        },
      );
      return Project.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/projects/quick` (API §10 "Quick create", spec §10/4.24) —
  /// atomic: create project + auto-add members + board rows for every
  /// included bill, born auto-claimed. Settled debt state is never
  /// modified.
  ///
  /// Request shape:
  /// - `name` — required (FE composes the members+date default, editable)
  /// - `new_transaction` — optional; the exact `POST /v1/transactions`
  ///   body (splits[] allowed), processed through the normal personal
  ///   transaction create path
  /// - `transaction_ids` — saved rows to pull in; each must belong to the
  ///   caller and have `project_id IS NULL` (unless [move]), else the whole
  ///   call fails (atomic)
  /// - `move` — true: rows already in another event move here (atomic)
  ///
  /// Errors: `400 VALIDATION_ERROR` (a transfer), `404 TX_NOT_FOUND`,
  /// `409 TX_ALREADY_IN_PROJECT`, `422 TX_NOT_BILLABLE` (repayment /
  /// opening balance / adjustment).
  Future<QuickCreateResult> quickCreate({
    required String name,
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects/quick',
        data: <String, dynamic>{
          'name': name,
          'new_transaction': ?newTransaction,
          if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
          if (move) 'move': true,
        },
      );
      return QuickCreateResult(
        project: Project.fromJson(res.data!),
        linkedCount: (res.data!['linked_count'] as num?)?.toInt() ?? 0,
        transactionId: res.data!['transaction_id'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/projects/:id/bills` — a new bill and / or saved rows
  /// ([transactionIds]) pulled into an existing project; [move] takes rows
  /// out of the event they're in. Same response and errors as
  /// [quickCreate], plus the project's own (NOT_MEMBER, FORBIDDEN_ROLE,
  /// PROJECT_LOCKED, PROJECT_NOT_ACTIVE).
  Future<QuickCreateResult> addBills(
    String projectId, {
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects/$projectId/bills',
        data: <String, dynamic>{
          'new_transaction': ?newTransaction,
          if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
          if (move) 'move': true,
        },
      );
      return QuickCreateResult(
        project: Project.fromJson(res.data!),
        linkedCount: (res.data!['linked_count'] as num?)?.toInt() ?? 0,
        transactionId: res.data!['transaction_id'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/projects/:id/bills/:transaction_id` → 204 — takes a saved
  /// row back out of the event (it stays in the book). Errors: 404
  /// TX_NOT_FOUND / TX_NOT_IN_PROJECT, the project's own.
  Future<void> removeBill(String projectId, String transactionId) async {
    try {
      await _client.dio.delete<dynamic>(
        '/projects/$projectId/bills/$transactionId',
      );
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
  Future<ProjectMember> addMember(
    String projectId, {
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
    String projectId,
    String memberId,
    MemberRole role,
  ) async {
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

  Future<List<ProjectTransaction>> listTransactions(
    String projectId, {
    int page = 1,
    int perPage = 20,
  }) async {
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
    List<String> tags = const [],
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
          if (tags.isNotEmpty) 'tags': tags,
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
    List<String>? tags,
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
          'tags': ?tags,
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
  /// `POST /v1/projects/:id/project-transactions/:pt_id/copy` — copy a
  /// project row into my own book (floating, no wallet; contract §5).
  /// Idempotent; returns the personal transaction id.
  Future<String> copyToPersonal(String projectId, String ptId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/projects/$projectId/project-transactions/$ptId/copy',
      );
      return res.data!['transaction_id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProjectTransaction> toggleMark(
    String projectId,
    String ptId,
    bool marked,
  ) async {
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

  /// `GET /projects/:id/tags` — names in use on the project's rows, most
  /// used first.
  Future<List<String>> listTags(String projectId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/projects/$projectId/tags',
      );
      return ((res.data!['data'] as List?) ?? const [])
          .map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList();
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
