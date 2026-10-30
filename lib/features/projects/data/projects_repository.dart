import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/transaction.dart';
import '../../notifications/domain/notification.dart' show InboxSummary;
import '../domain/event_bill.dart';
import '../domain/claim.dart';
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

/// The part of `EventBillApplyResult.my_copy` a notification / tx detail
/// needs (BE: POST /event-bills/{pt_id}/apply and /disconnect).
class MyBillCopyRef {
  const MyBillCopyRef({this.transactionId, this.connected = false});

  factory MyBillCopyRef.fromJson(Map<String, dynamic> json) {
    final copy = json['my_copy'];
    if (copy is! Map<String, dynamic>) return const MyBillCopyRef();
    final tx = copy['transaction'];
    return MyBillCopyRef(
      transactionId: tx is Map<String, dynamic> ? tx['id'] as String? : null,
      connected: copy['connected'] == true,
    );
  }

  /// My copy transaction; null = none (no part in the bill / disconnected).
  final String? transactionId;
  final bool connected;
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

  /// V15: a removed member's empty spots go to [to] (a BillPerson: `me`,
  /// `member_id`, `contact_id` or `person_name`); [billIds] empty = every
  /// bill of theirs. Totals never change.
  Future<EventPatch> assignRemovedMember(
    String projectId,
    String memberId, {
    required Map<String, dynamic> to,
    List<String> billIds = const [],
  }) => _patch(
    _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/members/$memberId/assign',
      data: {'to': to, if (billIds.isNotEmpty) 'bill_ids': billIds},
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

  /// "ลงบัญชีของฉัน" in ONE call and ONE DB transaction (0.4.1-1 E8): the
  /// new bill or payback ([bill], an EventBillInput json), the payback rows
  /// of the people marked "คืนแล้ว" and my book ([myBooks], EventBillBooks).
  /// [projectId] = an existing event, else [newEvent] (`{name, icon_code}`),
  /// else [split] = a split bill (0.4.1-2: no event, its people its members).
  Future<EventBillBookResult> bookEventBill({
    String? projectId,
    Map<String, dynamic>? newEvent,
    bool split = false,
    required Map<String, dynamic> bill,
    required Map<String, dynamic> myBooks,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/event-bills',
      data: <String, dynamic>{
        'project_id': ?projectId,
        'new_event': ?newEvent,
        if (split) 'split': true,
        'bill': bill,
        'my_books': myBooks,
      },
    );
    return EventBillBookResult.fromJson(res.data!);
  });

  /// [bookEventBill] on an existing bill ([ptId], its parent row): [bill]
  /// null = my book only ("ลงบัญชี" on a bill someone else recorded). My
  /// copy always follows the bill I save (0.4.1-2). [expectedUpdatedAt] =
  /// EventBillView.updatedAt (409 BILL_CHANGED when it moved on); [move] =
  /// EventBillMove (`{project_id}` / `{new_event}` / `{split: true}`).
  Future<EventBillBookResult> rebookEventBill(
    String ptId, {
    Map<String, dynamic>? bill,
    required Map<String, dynamic> myBooks,
    String? expectedUpdatedAt,
    Map<String, dynamic>? move,
  }) => _call(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/event-bills/$ptId',
      data: <String, dynamic>{
        'bill': ?bill,
        'my_books': myBooks,
        'expected_updated_at': ?expectedUpdatedAt,
        'move': ?move,
      },
    );
    return EventBillBookResult.fromJson(res.data!);
  });

  /// 0.4.1-2 SA2: one shared bill, page-ready for the bill form, from
  /// anywhere (a child row's id answers its bill).
  Future<EventBillView> getEventBill(String ptId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/event-bills/$ptId',
    );
    return EventBillView.fromJson(res.data!);
  });

  /// The bill form's ลบ: a split bill is gone for everyone (the others keep
  /// plain copies); an event bill by each member's switch. [keepMyTx] = my
  /// copy tx and debts stay as plain records.
  Future<EventBillDeleteResult> deleteEventBill(
    String ptId, {
    bool keepMyTx = false,
  }) => _call(() async {
    final res = await _client.dio.delete<Map<String, dynamic>>(
      '/event-bills/$ptId',
      queryParameters: {if (keepMyTx) 'keep_my_tx': 'true'},
    );
    return EventBillDeleteResult.fromJson(res.data!);
  });

  /// The bill sheet's before → after lines: the same body with
  /// `?preview=true` ([ptId] = an edit); nothing is saved.
  Future<EventBillBookPreview> previewEventBill({
    String? ptId,
    String? projectId,
    bool split = false,
    Map<String, dynamic>? bill,
    required Map<String, dynamic> myBooks,
  }) => _call(() async {
    final body = <String, dynamic>{
      if (ptId == null) 'project_id': ?projectId,
      if (ptId == null && split) 'split': true,
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

  Future<EventSettle> settle(String projectId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/settle',
    );
    return EventSettle.fromJson(res.data!);
  });

  /// V12 "ลงในสมุดฉัน" on a completed event: my fewest-transfers lines,
  /// once ([lines]: member_id + account_id / category_id each); answers
  /// the settle (booked), the rest rides `effects`.
  Future<EventSettle> bookEventSettle(
    String projectId, {
    required List<Map<String, dynamic>> lines,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/settle/book',
      data: {'lines': lines},
    );
    final settle = res.data!['settle'];
    return EventSettle.fromJson(
      settle is Map<String, dynamic> ? settle : const {},
    );
  });

  /// My real pairs per bill, for a claim. One person by [memberId], or by
  /// my [contactId] / a typed [personName] (the server finds the member);
  /// none = everyone.
  Future<List<ClaimableBill>> claimable(
    String projectId, {
    String? memberId,
    String? contactId,
    String? personName,
  }) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/projects/$projectId/claimable',
      queryParameters: {
        'member_id': ?memberId,
        'contact_id': ?contactId,
        'person_name': ?personName,
      },
    );
    return ClaimableBill.listOf(res.data!);
  });

  /// "ลงสมุดของฉัน": the picked bills with one person become ONE debt (a
  /// lump; debt-type bills a row each) + my "จ่ายโดย X" copies, in one DB
  /// transaction. [linkTransactionId] = my existing tx as the copy of the one
  /// bill (the tx form's join).
  Future<ClaimResult> claimBills(
    String projectId, {
    required String memberId,
    required List<String> billIds,
    String? linkTransactionId,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/projects/$projectId/claim',
      data: {
        'member_id': memberId,
        'bill_ids': billIds,
        'link_transaction_id': ?linkTransactionId,
      },
    );
    return ClaimResult.fromJson(res.data!);
  });

  /// "อัปเดตตาม" / "เพิ่มในสมุด": my copy takes the bill as it is now (made
  /// when I have none). The rest of what changed rides `effects`.
  Future<MyBillCopyRef> applyEventBill(String ptId) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/event-bills/$ptId/apply',
    );
    return MyBillCopyRef.fromJson(res.data!);
  });

  /// ตัดการเชื่อม: my copy tx + debts become plain; the bill is unchanged.
  Future<MyBillCopyRef> disconnectEventBill(String ptId) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/event-bills/$ptId/disconnect',
    );
    return MyBillCopyRef.fromJson(res.data!);
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
