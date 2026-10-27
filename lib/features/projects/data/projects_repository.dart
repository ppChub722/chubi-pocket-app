import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../../notifications/domain/notification.dart' show InboxSummary;
import '../domain/project.dart';
import '../../../ui/ui.dart';

class QuickCreateResult {
  const QuickCreateResult({
    required this.project,
    required this.linkedCount,
    this.transactionId,
    this.accountBalances = const {},
    this.patch,
  });

  final Project project;

  final int linkedCount;

  final String? transactionId;

  final Map<String, double> accountBalances;

  final EventPatch? patch;
}

class EventTagWrite {
  const EventTagWrite({required this.patch, required this.tag});

  final EventPatch patch;
  final BoardTag tag;
}

class EventTagImportResult {
  const EventTagImportResult({required this.created, required this.tags});

  final List<EmbeddedTag> created;

  final List<BoardTag> tags;
}

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

  /// [people] = the bill's `payer` + `members` (B2, beside new_transaction).
  Future<QuickCreateResult> quickCreate({
    required String name,
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
    Map<String, dynamic>? people,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/quick',
      data: <String, dynamic>{
        'name': name,
        'new_transaction': ?newTransaction,
        ...?people,
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

  /// [people] = the bill's `payer` + `members` (B2, beside new_transaction).
  Future<QuickCreateResult> addBills(
    String projectId, {
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
    Map<String, dynamic>? people,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/bills',
      data: <String, dynamic>{
        'new_transaction': ?newTransaction,
        ...?people,
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

  Future<void> removeBill(String projectId, String transactionId) =>
      _call(() async {
        await _client.dio.delete<dynamic>(
          '/projects/$projectId/bills/$transactionId',
        );
      });

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

  Future<InboxSummary> acceptInvite(String notificationId) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/link-requests/$notificationId/accept',
    );
    return InboxSummary.fromJson(
      (res.data?['inbox_summary'] as Map?)?.cast<String, dynamic>(),
    );
  });

  Future<InboxSummary> rejectInvite(String notificationId) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/link-requests/$notificationId/reject',
    );
    return InboxSummary.fromJson(
      (res.data?['inbox_summary'] as Map?)?.cast<String, dynamic>(),
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

  Future<List<ProjectMember>> listMembers(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/members',
    );
    final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
    return [
      for (final m in data) ProjectMember.fromJson(m, projectId: projectId),
    ];
  });

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

  /// "ลงบัญชีของฉัน" in ONE call and ONE DB transaction (0.4.1-1 E8): the
  /// new bill or payback ([bill], an EventBillInput json), the payback rows
  /// of the people marked "คืนแล้ว" and my book ([myBooks], EventBillBooks).
  /// [projectId] = an existing event, else [newEvent] (`{name, icon_code}`).
  Future<EventBillBookResult> bookEventBill({
    String? projectId,
    Map<String, dynamic>? newEvent,
    required Map<String, dynamic> bill,
    required Map<String, dynamic> myBooks,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/event-bills',
      data: <String, dynamic>{
        'project_id': ?projectId,
        'new_event': ?newEvent,
        'bill': bill,
        'my_books': myBooks,
      },
    );
    return EventBillBookResult.fromJson(res.data!);
  });

  /// [bookEventBill] on an existing bill ([ptId], its parent row): [bill]
  /// null = my book only ("ลงบัญชี" on a bill someone else recorded).
  Future<EventBillBookResult> rebookEventBill(
    String ptId, {
    Map<String, dynamic>? bill,
    required Map<String, dynamic> myBooks,
    bool applyToMyTx = false,
  }) => _call(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/event-bills/$ptId',
      data: <String, dynamic>{
        'bill': ?bill,
        'my_books': myBooks,
        if (applyToMyTx) 'apply_to_my_tx': true,
      },
    );
    return EventBillBookResult.fromJson(res.data!);
  });

  /// The bill sheet's before → after lines: the same body with
  /// `?preview=true` ([ptId] = an edit); nothing is saved.
  Future<EventBillBookPreview> previewEventBill({
    String? ptId,
    String? projectId,
    Map<String, dynamic>? bill,
    required Map<String, dynamic> myBooks,
  }) => _call(() async {
    final body = <String, dynamic>{
      if (ptId == null) 'project_id': ?projectId,
      'bill': ?bill,
      'my_books': myBooks,
    };
    const query = {'preview': 'true'};
    final res = ptId == null
        ? await _client.dio.post<Map<String, dynamic>>(
            '/event-bills',
            queryParameters: query,
            data: body,
          )
        : await _client.dio.put<Map<String, dynamic>>(
            '/event-bills/$ptId',
            queryParameters: query,
            data: body,
          );
    return EventBillBookPreview.fromJson(res.data!);
  });

  /// The people a bill names, as members (non-members are added); ids come
  /// back in [people]'s order. Each person is a BillPerson json.
  Future<({List<String> memberIds, EventPatch patch})> resolvePeople(
    String projectId,
    List<Map<String, dynamic>> people,
  ) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/people',
      data: <String, dynamic>{'people': people},
    );
    return (
      memberIds: [
        for (final id in (res.data!['member_ids'] as List)) id as String,
      ],
      patch: EventPatch.fromJson(res.data!),
    );
  });

  /// "ลงบัญชีของฉัน" on an existing row: [unlink] keeps my rows in my books
  /// without the link; [link] takes the remembered ones back. `relinked` =
  /// the kinds of [link] that found any (the rest are for the caller to make).
  Future<({List<String> relinked, EventPatch patch})> setMyBooks(
    String projectId,
    String ptId, {
    List<String> link = const [],
    List<String> unlink = const [],
  }) => _call(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/projects/$projectId/project-transactions/$ptId/my-books',
      data: <String, dynamic>{'link': link, 'unlink': unlink},
    );
    return (
      relinked: [
        for (final k in (res.data!['relinked'] as List? ?? const []))
          k as String,
      ],
      patch: EventPatch.fromJson(res.data!),
    );
  });

  Future<EventSettle> settle(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/settle',
    );
    return EventSettle.fromJson(res.data!);
  });

  /// [transactionMemberId]: paybacks only (who paid back).
  Future<EventPatch> updateTransaction(
    String projectId,
    String ptId, {
    String? transactionMemberId,
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
        'transaction_member_id': ?transactionMemberId,
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

  Future<EventPatch> toggleMark(String projectId, String ptId, bool marked) =>
      _patch(
        _client.dio.put<Map<String, dynamic>>(
          '/projects/$projectId/project-transactions/$ptId/mark',
          data: <String, dynamic>{'marked': marked},
        ),
      );

  Future<List<BoardTag>> eventTags(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/tags',
    );
    return [
      for (final t in ((res.data!['data'] as List?) ?? const []))
        BoardTag.fromJson(t as Map<String, dynamic>),
    ];
  });

  Future<List<String>> listTags(String projectId) async => [
    for (final t in await eventTags(projectId)) t.name,
  ];

  Future<BoardTag> createEventTag(
    String projectId,
    String name, {
    IconCode? iconCode,
  }) async =>
      (await writeEventTag(projectId, name: name, iconCode: iconCode)).tag;

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

  Future<EventPatch> deleteEventTag(String projectId, String tagId) => _patch(
    _client.dio.delete<Map<String, dynamic>>(
      '/projects/$projectId/tags/$tagId',
    ),
  );

  Future<EventPatch> archive(String id) =>
      _patch(_client.dio.post<Map<String, dynamic>>('/projects/$id/archive'));

  Future<EventPatch> restore(String id) =>
      _patch(_client.dio.post<Map<String, dynamic>>('/projects/$id/restore'));

  /// Copies event tags into MY personal set ([tagIds] empty = every one I don't
  /// have yet).
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
