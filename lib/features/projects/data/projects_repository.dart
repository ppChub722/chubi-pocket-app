import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/transaction.dart';
import '../../notifications/domain/notification.dart' show InboxSummary;
import '../domain/paper.dart';
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
    } catch (e, st) {
      throw ApiException.from(e, st);
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

  Future<ProjectDetail> detail(String id, {int perPage = 50}) =>
      _call(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '/projects/$id/detail',
          queryParameters: <String, dynamic>{'per_page': perPage.toString()},
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

  /// Deletes the event only (owner 2026-10-28): its bills stay as standalone
  /// split bills, every copy still connected; nobody's book loses a record.
  /// Answers how many bills became split bills; my re-pointed rows ride
  /// `effects`.
  Future<int> delete(String id) => _call(() async {
    final res = await _client.dio.delete<dynamic>('/projects/$id');
    final body = res.data;
    return body is Map<String, dynamic>
        ? (body['split_bill_count'] as num?)?.toInt() ?? 0
        : 0;
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
    String? contactId,
    MemberRole role = MemberRole.contributor,
    bool adHoc = false,
  }) => _patch(
    _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/members',
      data: <String, dynamic>{
        'email': ?email,
        'display_name': ?displayName,
        'contact_id': ?contactId,
        'role': role.wire,
        if (adHoc) 'ad_hoc': true,
      },
    ),
  );

  /// Invite (or invite again) a member who is my contact using the app; adding
  /// a contact never invites by itself (owner 2026-11-03).
  Future<EventPatch> inviteMember(String projectId, String memberId) => _patch(
    _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/members/$memberId/invite',
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

  /// F3: this member is my [contactId] (for me only); null = drop my binding.
  Future<EventPatch> setMyContact(
    String projectId,
    String memberId,
    String? contactId,
  ) => _patch(
    contactId == null
        ? _client.dio.delete<Map<String, dynamic>>(
            '/projects/$projectId/members/$memberId/my-contact',
          )
        : _client.dio.put<Map<String, dynamic>>(
            '/projects/$projectId/members/$memberId/my-contact',
            data: {'contact_id': contactId},
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
    // The paper model's board: the event's bills (papers; no payer filter).
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/bills',
      queryParameters: <String, dynamic>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'type': ?type,
        if (mine) 'mine': 'true',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'tag_id': ?tagId,
        'sort': ?sort,
      },
    );
    return [
      for (final r in (res.data!['data'] as List).cast<Map<String, dynamic>>())
        ...ProjectTransaction.flatten(r),
    ];
  });

  /// A new paper (paper model, 2026-11-02): a split bill, a bill of the
  /// event [projectId], or the first bill of a new event named [newEvent]
  /// (made in the same call). [paper] = PaperInput, [myBooks] = my claim
  /// (ClaimInput; null = my auto claim).
  Future<PaperWriteResult> createPaper({
    String? projectId,
    String? newEvent,
    required Map<String, dynamic> paper,
    Map<String, dynamic>? myBooks,
    bool skipMyBooks = false,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      projectId == null ? '/split-bills' : '/projects/$projectId/bills',
      data: <String, dynamic>{
        'paper': paper,
        if (skipMyBooks) 'skip_my_books': true else 'my_books': ?myBooks,
        if (projectId == null && newEvent != null)
          'new_event': {'name': newEvent},
      },
    );
    return PaperWriteResult.fromJson(res.data!);
  });

  String _paperPath(String paperId, String? projectId) => projectId == null
      ? '/split-bills/$paperId'
      : '/projects/$projectId/bills/$paperId';

  /// One paper as I see it (the bill form's edit).
  Future<PaperView> getPaper(String paperId, {String? projectId}) =>
      _call(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          _paperPath(paperId, projectId),
        );
        return PaperView.fromJson(res.data!);
      });

  /// Save an edit of the paper ([version] = the one read: 409 BILL_CHANGED
  /// when someone saved meanwhile). Only its own fields; my books follow
  /// by my switch.
  Future<PaperWriteResult> updatePaper(
    String paperId, {
    String? projectId,
    required Map<String, dynamic> paper,
    required int version,
  }) => _call(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      _paperPath(paperId, projectId),
      data: {'paper': paper, 'version': version},
    );
    return PaperWriteResult.fromJson(res.data!);
  });

  /// "ลงสมุดของฉัน": the pieces of my books the paper gives me and I lack.
  Future<PaperWriteResult> claimPaper(
    String paperId, {
    String? projectId,
    required Map<String, dynamic> claim,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '${_paperPath(paperId, projectId)}/claim',
      data: claim,
    );
    return PaperWriteResult.fromJson(res.data!);
  });

  /// Leave the paper; my books of it are kept as plain records or deleted.
  Future<void> leavePaper(
    String paperId, {
    String? projectId,
    required bool keepBooks,
  }) => _call(() async {
    await _client.dio.post<Map<String, dynamic>>(
      '${_paperPath(paperId, projectId)}/leave',
      data: {'books': keepBooks ? 'keep' : 'delete'},
    );
  });

  /// "คืนแล้ว" on one person of a paper: a shared mark only.
  Future<void> markPaperPaidBack(
    String paperId,
    String personId, {
    String? projectId,
    bool paidBack = true,
  }) => _call(() async {
    await _client.dio.patch<Map<String, dynamic>>(
      projectId == null
          ? '/split-bills/$paperId/people/$personId'
          : '/projects/$projectId/bills/$paperId/people/$personId',
      data: {'paid_back': paidBack},
    );
  });

  /// Move the paper into the event [toProjectId], or out of its event
  /// ([fromProjectId]) when null.
  Future<PaperWriteResult> movePaper(
    String paperId, {
    String? fromProjectId,
    String? toProjectId,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      fromProjectId == null
          ? '/split-bills/$paperId/move-to-event'
          : '/projects/$fromProjectId/bills/$paperId/move',
      data: {'project_id': toProjectId},
    );
    return PaperWriteResult.fromJson(res.data!);
  });

  /// "อัปเดตตาม": my tx of a paper takes the paper as it is now.
  Future<PaperWriteResult> syncMyTransaction(String txId) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/transactions/$txId/paper-sync',
    );
    return PaperWriteResult.fromJson(res.data!);
  });

  /// "อัปเดตตาม": my debt of a paper takes the paper as it is now.
  Future<void> syncMyDebt(String debtId) => _call(() async {
    await _client.dio.post<Map<String, dynamic>>(
      '/personal-debts/$debtId/paper-sync',
    );
  });

  /// A split bill's invite: join it ([join]) or decline.
  Future<void> answerSplitBill(String paperId, {required bool join}) =>
      _call(() async {
        await _client.dio.post<Map<String, dynamic>>(
          '/split-bills/$paperId/${join ? 'join' : 'decline'}',
        );
      });

  /// ตัดการเชื่อม: my tx becomes plain; the paper is unchanged.
  Future<void> unlinkMyTransaction(String txId) => _call(() async {
    await _client.dio.post<Map<String, dynamic>>(
      '/transactions/$txId/unlink-paper',
    );
  });

  Future<EventSettle> settle(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/settle',
    );
    return EventSettle.fromJson(res.data!);
  });

  /// "ลงหนี้" with one member (the paper model's lump): one debt per
  /// direction of every bill pair with them not booked yet. Answers the
  /// settle; the debts ride `effects`.
  Future<EventSettle> bookSettlePair(String projectId, String memberId) =>
      _call(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/projects/$projectId/settle/book',
          data: {'mode': 'pairs', 'with': memberId},
        );
        final settle = res.data!['settle'];
        return EventSettle.fromJson(
          settle is Map<String, dynamic> ? settle : const {},
        );
      });

  /// V12 "ลงในสมุดฉัน" on a completed event: my fewest-transfers lines,
  /// once; [accountId] = the wallet of the money that moves. Answers the
  /// settle (booked), the rest rides `effects`.
  Future<EventSettle> bookEventSettle(String projectId, {String? accountId}) =>
      _call(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/projects/$projectId/settle/book',
          data: {'mode': 'simplified', 'account_id': ?accountId},
        );
        final settle = res.data!['settle'];
        return EventSettle.fromJson(
          settle is Map<String, dynamic> ? settle : const {},
        );
      });

  Future<List<BoardTag>> eventTags(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/tags',
    );
    return [
      for (final t in ((res.data!['data'] as List?) ?? const []))
        BoardTag.fromJson(t as Map<String, dynamic>),
    ];
  });

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

  /// ปิดอีเวนต์ (owner only, for good): locked, every book unsynced.
  Future<EventPatch> complete(String id) =>
      _patch(_client.dio.post<Map<String, dynamic>>('/projects/$id/complete'));

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
