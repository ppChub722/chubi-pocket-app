import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/project.dart';
import '../../../ui/ui.dart';

/// `POST /v1/projects/quick` / `POST /v1/projects/:id/bills` result: the
/// event, the new bill's personal transaction and the wallets it moved.
class QuickCreateResult {
  const QuickCreateResult({
    required this.project,
    required this.linkedCount,
    this.transactionId,
    this.accountBalances = const {},
    this.patch,
  });

  final Project project;

  /// Bills the call added.
  final int linkedCount;

  /// The new bill's personal transaction (null when only existing ones
  /// were pulled in).
  final String? transactionId;

  /// {account id: balance after the write} (API `account_balances`).
  final Map<String, double> accountBalances;

  /// The event page's patch (bills added to an existing event).
  final EventPatch? patch;
}

/// An event-tag write's answer (API `EventTagWriteResult`).
class EventTagWrite {
  const EventTagWrite({required this.patch, required this.tag});

  final EventPatch patch;
  final BoardTag tag;
}

/// `POST /projects/:id/tags/import` result.
class EventTagImportResult {
  const EventTagImportResult({required this.created, required this.tags});

  /// My new personal tags.
  final List<EmbeddedTag> created;

  /// The event's tags, `mine` updated.
  final List<BoardTag> tags;
}

/// Thin Dio wrapper around `/v1/projects` (API tag "Events"). Every write
/// returns an [EventPatch] the page applies — no re-fetch.
class ProjectsRepository {
  ProjectsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<EventPatch> _patch(Future<Response<Map<String, dynamic>>> request) =>
      _call(() async => EventPatch.fromJson((await request).data!));

  // --- Events ---

  /// One page of my events. [status]: active (default) / completed /
  /// cancelled / archived / all; [q] searches the name; [tagIds] = MY
  /// personal tags (any of them).
  Future<ProjectPage> list({
    String? status,
    String? q,
    List<String> tagIds = const [],
    ProjectSort? sort,
    int page = 1,
    int perPage = 20,
  }) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects',
      queryParameters: <String, dynamic>{
        'status': ?status,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (tagIds.isNotEmpty) 'tag_id': tagIds,
        'sort': ?sort?.wire,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
    final pag = res.data!['pagination'] as Map<String, dynamic>?;
    final summary = res.data!['summary'];
    return ProjectPage(
      projects: data.map(Project.fromJson).toList(),
      page: (pag?['page'] as num?)?.toInt() ?? page,
      totalPages: (pag?['total_pages'] as num?)?.toInt() ?? page,
      summary: summary is Map<String, dynamic>
          ? ProjectListSummary.fromJson(summary)
          : null,
    );
  });

  Future<Project> get(String id) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/projects/$id');
    return Project.fromJson(res.data!);
  });

  /// The event page in one call: event, summary, members, tags and the
  /// board's first page.
  ///
  /// [deletePreview] adds what a delete removes (`include=delete_preview`,
  /// the delete confirm's numbers).
  Future<ProjectDetail> detail(
    String id, {
    int perPage = 50,
    bool deletePreview = false,
  }) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$id/detail',
      queryParameters: <String, dynamic>{
        'per_page': perPage.toString(),
        if (deletePreview) 'include': 'delete_preview',
      },
    );
    return ProjectDetail.fromJson(res.data!);
  });

  /// One call (plan, dates and my tags included) → the new event's detail.
  /// [startDate] / [endDate] are `YYYY-MM-DD`.
  Future<ProjectDetail> create({
    required String name,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    double? plannedAmount,
    List<String> tagIds = const [],
    IconCode? iconCode,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects',
      data: <String, dynamic>{
        'name': name,
        'description': ?description,
        'note': ?note,
        'start_date': ?startDate,
        'end_date': ?endDate,
        'planned_amount': ?plannedAmount,
        if (tagIds.isNotEmpty) 'tag_ids': tagIds,
        if (iconCode != null) 'icon_code': iconCode.toJson(),
      },
    );
    return ProjectDetail.fromJson(res.data!);
  });

  /// Partial update. [description] / [note]: null = unchanged, `''` =
  /// clear. [plannedAmount] / [startDate] / [endDate]: a value sets it,
  /// [clearPlannedAmount] / [clearStartDate] / [clearEndDate] send an
  /// explicit null (clear). [tagIds] = MY personal tags (any member).
  Future<EventPatch> update(
    String id, {
    String? name,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    ProjectStatus? status,
    IconCode? iconCode,
    double? plannedAmount,
    bool clearPlannedAmount = false,
    List<String>? tagIds,
  }) => _patch(
    _client.dio.put<Map<String, dynamic>>(
      '/projects/$id',
      data: <String, dynamic>{
        'name': ?name,
        'description': ?description,
        'note': ?note,
        if (startDate != null)
          'start_date': startDate
        else if (clearStartDate)
          'start_date': null,
        if (endDate != null)
          'end_date': endDate
        else if (clearEndDate)
          'end_date': null,
        'status': ?status?.wire,
        if (iconCode != null) 'icon_code': iconCode.toJson(),
        if (plannedAmount != null)
          'planned_amount': plannedAmount
        else if (clearPlannedAmount)
          'planned_amount': null,
        'tag_ids': ?tagIds,
      },
    ),
  );

  /// `POST /v1/projects/quick` — atomic: create the event + auto-add
  /// members + board bills from the new transaction ([newTransaction], the
  /// exact `POST /v1/transactions` body) and / or saved rows
  /// ([transactionIds]; [move] takes them out of another event).
  ///
  /// Errors: `400 VALIDATION_ERROR` (a transfer), `404 TX_NOT_FOUND`,
  /// `409 TX_ALREADY_IN_PROJECT`, `422 TX_NOT_BILLABLE`.
  Future<QuickCreateResult> quickCreate({
    required String name,
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/quick',
      data: <String, dynamic>{
        'name': name,
        'new_transaction': ?newTransaction,
        if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
        if (move) 'move': true,
      },
    );
    final detail = ProjectDetail.fromJson(
      res.data!['detail'] as Map<String, dynamic>,
    );
    return QuickCreateResult(
      project: detail.project,
      linkedCount: detail.transactions.where((t) => t.isParent).length,
      transactionId: res.data!['new_transaction_id'] as String?,
      accountBalances: WalletBalance.mapOf(res.data!['account_balances']),
    );
  });

  /// `POST /v1/projects/:id/bills` — a new bill and / or saved rows pulled
  /// into an existing event (`AddBillsResult`: the patch + the new rows).
  Future<QuickCreateResult> addBills(
    String projectId, {
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/bills',
      data: <String, dynamic>{
        'new_transaction': ?newTransaction,
        if (transactionIds.isNotEmpty) 'transaction_ids': transactionIds,
        if (move) 'move': true,
      },
    );
    final patch = EventPatch.fromJson(res.data!);
    return QuickCreateResult(
      project: patch.project,
      linkedCount: EventPatch.rowsOf(res.data!).where((t) => t.isParent).length,
      transactionId: res.data!['new_transaction_id'] as String?,
      accountBalances: patch.accountBalances,
      patch: patch,
    );
  });

  /// `DELETE /v1/projects/:id/bills/:transaction_id` — takes a saved row
  /// back out of the event (it stays in the book).
  Future<void> removeBill(String projectId, String transactionId) =>
      _call(() async {
        await _client.dio.delete<dynamic>(
          '/projects/$projectId/bills/$transactionId',
        );
      });

  /// Deletes the event and its bills; [deleteLinkedTxs] also deletes MY
  /// personal transactions linked to them (else they stay, unlinked).
  /// Returns the wallets those deletions moved ({account id: balance}).
  Future<Map<String, double>> delete(
    String id, {
    bool deleteLinkedTxs = false,
  }) => _call(() async {
    final res = await _client.dio.delete<dynamic>(
      '/projects/$id',
      queryParameters: <String, dynamic>{
        if (deleteLinkedTxs) 'delete_linked_txs': 'true',
      },
    );
    final body = res.data;
    return body is Map<String, dynamic>
        ? WalletBalance.mapOf(body['account_balances'])
        : const <String, double>{};
  });

  /// `POST /projects/link-requests/:notification_id/accept` — the answer to
  /// an event invite (the inbox's ตอบรับ). The notification becomes actioned.
  Future<void> acceptInvite(String notificationId) => _call(() async {
    await _client.dio.post<dynamic>(
      '/projects/link-requests/$notificationId/accept',
    );
  });

  /// `POST /projects/link-requests/:notification_id/reject` — ปฏิเสธ.
  Future<void> rejectInvite(String notificationId) => _call(() async {
    await _client.dio.post<dynamic>(
      '/projects/link-requests/$notificationId/reject',
    );
  });

  Future<void> leave(String id) => _call(() async {
    await _client.dio.post<dynamic>('/projects/$id/leave');
  });

  Future<EventPatch> transferOwnership(String id, String newOwnerUserId) =>
      _patch(
        _client.dio.post<Map<String, dynamic>>(
          '/projects/$id/transfer-ownership',
          data: <String, dynamic>{'new_owner_user_id': newOwnerUserId},
        ),
      );

  // --- Members ---

  Future<List<ProjectMember>> listMembers(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/members',
    );
    final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
    return [
      for (final m in data) ProjectMember.fromJson(m, projectId: projectId),
    ];
  });

  /// By email (+ [displayName]) or a typed person ([displayName] +
  /// [adHoc]); bad input → 400.
  Future<EventPatch> addMember(
    String projectId, {
    String? email,
    String? displayName,
    MemberRole role = MemberRole.contributor,
    bool adHoc = false,
  }) => _patch(
    _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/members',
      data: <String, dynamic>{
        'email': ?email,
        'display_name': ?displayName,
        'role': role.wire,
        if (adHoc) 'ad_hoc': true,
      },
    ),
  );

  Future<EventPatch> updateMemberRole(
    String projectId,
    String memberId,
    MemberRole role,
  ) => _patch(
    _client.dio.put<Map<String, dynamic>>(
      '/projects/$projectId/members/$memberId',
      data: <String, dynamic>{'role': role.wire},
    ),
  );

  Future<EventPatch> removeMember(String projectId, String memberId) => _patch(
    _client.dio.delete<Map<String, dynamic>>(
      '/projects/$projectId/members/$memberId',
    ),
  );

  // --- Board ---

  /// A board page (bills with their splits, flat). Filters: [type]
  /// (expense / income), [mine], [q], [tagId]; [sort]: date_desc (default) /
  /// date_asc / amount_desc / amount_asc.
  Future<List<ProjectTransaction>> listTransactions(
    String projectId, {
    int page = 1,
    int perPage = 20,
    String? type,
    bool mine = false,
    String? q,
    String? tagId,
    String? sort,
    String? payerMemberId,
  }) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/transactions',
      queryParameters: <String, dynamic>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'type': ?type,
        if (mine) 'mine': 'true',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'tag_id': ?tagId,
        'payer_member_id': ?payerMemberId,
        'sort': ?sort,
      },
    );
    return [
      for (final r in (res.data!['data'] as List).cast<Map<String, dynamic>>())
        ...ProjectTransaction.flatten(r),
    ];
  });

  /// A board bill (no wallet). [tagIds] = this event's tags. [tags] /
  /// [currency] are ignored (the API takes tag ids; single currency) — kept
  /// until quick create moves to [tagIds].
  Future<EventPatch> createTransaction(
    String projectId, {
    required String transactionMemberId,
    required String type,
    required double amount,
    required String date,
    String? currency,
    String? description,
    String? note,
    List<String> tags = const [],
    List<String> tagIds = const [],
    List<ProjectSplitInput> splits = const [],
  }) => _patch(
    _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/project-transactions',
      data: <String, dynamic>{
        'transaction_member_id': transactionMemberId,
        'type': type,
        'amount': amount,
        'date': date,
        'description': ?description,
        'note': ?note,
        if (tagIds.isNotEmpty) 'tag_ids': tagIds,
        if (splits.isNotEmpty) 'splits': splits.map((s) => s.toJson()).toList(),
      },
    ),
  );

  /// `splits` semantics: pass `null` to leave existing children untouched;
  /// pass a list (possibly empty) to full-replace children. [tagIds]: null =
  /// unchanged. [tags] (names) is ignored, see [createTransaction].
  /// [alsoUpdateLink]: my OWN linked bill — also change my transaction
  /// (amount / date; the app asks at save). Ignored for anyone else (the
  /// owner gets "อัปเดตตาม").
  Future<EventPatch> updateTransaction(
    String projectId,
    String ptId, {
    double? amount,
    String? date,
    String? description,
    String? note,
    List<String>? tags,
    List<String>? tagIds,
    List<ProjectSplitInput>? splits,
    bool alsoUpdateLink = false,
  }) => _patch(
    _client.dio.put<Map<String, dynamic>>(
      '/projects/$projectId/project-transactions/$ptId',
      data: <String, dynamic>{
        'amount': ?amount,
        'date': ?date,
        'description': ?description,
        'note': ?note,
        'tag_ids': ?tagIds,
        if (splits != null) 'splits': splits.map((s) => s.toJson()).toList(),
        if (alsoUpdateLink) 'also_update_link': true,
      },
    ),
  );

  Future<EventPatch> deleteTransaction(String projectId, String ptId) => _patch(
    _client.dio.delete<Map<String, dynamic>>(
      '/projects/$projectId/project-transactions/$ptId',
    ),
  );

  /// `POST /v1/projects/:id/project-transactions/:pt_id/copy` — copy my
  /// share of a bill into my own book. Returns the personal transaction id.
  Future<String> copyToPersonal(String projectId, String ptId) =>
      _call(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/projects/$projectId/project-transactions/$ptId/copy',
        );
        final tx = res.data!['transaction'];
        return tx is Map<String, dynamic>
            ? tx['id'] as String
            : res.data!['transaction_id'] as String;
      });

  /// Tick / untick a bill (or split) as resolved for me. Idempotent;
  /// independent of the personal-book resolve.
  Future<EventPatch> toggleMark(String projectId, String ptId, bool marked) =>
      _patch(
        _client.dio.put<Map<String, dynamic>>(
          '/projects/$projectId/project-transactions/$ptId/mark',
          data: <String, dynamic>{'marked': marked},
        ),
      );

  // --- Event tags ---

  /// The event's tags (shared by the members), with ids.
  Future<List<BoardTag>> eventTags(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/tags',
    );
    return [
      for (final t in ((res.data!['data'] as List?) ?? const []))
        BoardTag.fromJson(t as Map<String, dynamic>),
    ];
  });

  /// The event tags' names (quick create's suggestions).
  Future<List<String>> listTags(String projectId) async => [
    for (final t in await eventTags(projectId)) t.name,
  ];

  /// A new event tag → the tag (+ the patch).
  Future<BoardTag> createEventTag(
    String projectId,
    String name, {
    IconCode? iconCode,
  }) async =>
      (await writeEventTag(projectId, name: name, iconCode: iconCode)).tag;

  /// `POST /projects/:id/tags` (create) or `PUT /projects/:id/tags/:tag_id`
  /// (rename / restyle, [tagId] given): the patch (tags updated) + the tag.
  Future<EventTagWrite> writeEventTag(
    String projectId, {
    String? tagId,
    required String name,
    IconCode? iconCode,
  }) => _call(() async {
    final body = <String, dynamic>{
      'name': name,
      if (iconCode != null) 'icon_code': iconCode.toJson(),
    };
    final res = tagId == null
        ? await _client.dio.post<Map<String, dynamic>>(
            '/projects/$projectId/tags',
            data: body,
          )
        : await _client.dio.put<Map<String, dynamic>>(
            '/projects/$projectId/tags/$tagId',
            data: body,
          );
    return EventTagWrite(
      patch: EventPatch.fromJson(res.data!),
      tag: BoardTag.fromJson(res.data!['tag'] as Map<String, dynamic>),
    );
  });

  /// Hard delete; the tag comes off every bill. Answers the patch.
  Future<EventPatch> deleteEventTag(String projectId, String tagId) => _patch(
    _client.dio.delete<Map<String, dynamic>>(
      '/projects/$projectId/tags/$tagId',
    ),
  );

  /// `POST /projects/:id/archive` (owner): hidden, not counted, read-only.
  Future<EventPatch> archive(String id) =>
      _patch(_client.dio.post<Map<String, dynamic>>('/projects/$id/archive'));

  /// `POST /projects/:id/restore` (owner): back to active.
  Future<EventPatch> restore(String id) =>
      _patch(_client.dio.post<Map<String, dynamic>>('/projects/$id/restore'));

  /// Copies event tags into MY personal set ([tagIds] empty = every one I
  /// don't have yet).
  Future<EventTagImportResult> importTags(
    String projectId, {
    List<String> tagIds = const [],
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/tags/import',
      data: <String, dynamic>{if (tagIds.isNotEmpty) 'tag_ids': tagIds},
    );
    return EventTagImportResult(
      created: [
        for (final t in ((res.data!['created'] as List?) ?? const []))
          EmbeddedTag.fromJson(t as Map<String, dynamic>),
      ],
      tags: [
        for (final t in ((res.data!['tags'] as List?) ?? const []))
          BoardTag.fromJson(t as Map<String, dynamic>),
      ],
    );
  });
}
