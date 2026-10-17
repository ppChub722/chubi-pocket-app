import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/debt_ledger.dart';

/// The person ledger API (0.3.1-10, openapi tag "Debts"): people, a
/// person, their entries, and the entry writes. Every write returns the final
/// state (entry + person balance + wallet balances): patch, never re-fetch.
class PersonalDebtsRepository {
  PersonalDebtsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  /// `GET /personal-debts/people`: ONE list (ติดคุณ and คุณติด together),
  /// paged; by default only people with something open ([all] shows the
  /// settled ones too); [side] = the summary-box filter.
  Future<DebtPeoplePage> listPeople({
    int page = 1,
    int perPage = 30,
    String? q,
    bool all = false,
    NetSide? side,
    DebtPeopleSort sort = DebtPeopleSort.oldest,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people',
        queryParameters: <String, dynamic>{
          'page': page.toString(),
          'per_page': perPage.toString(),
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (all) 'all': 'true',
          if (side != null && side != NetSide.even) 'side': side.wire,
          'sort': sort.wire,
        },
      );
      return DebtPeoplePage.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /personal-debts/people/{key}`: the person page in one call (person,
  /// net, counts, the summary message, the first page of [cycle]'s entries —
  /// the current cycle by default). Works for typed names too.
  Future<DebtPersonDetail> person(
    String key, {
    int perPage = 30,
    DebtCycle cycle = DebtCycle.current,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}',
        queryParameters: <String, dynamic>{
          'per_page': perPage.toString(),
          'cycle': cycle.wire,
        },
      );
      return DebtPersonDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /personal-debts/people/{key}/entries`: one page of a person's
  /// entries, searched / filtered / sorted on the server.
  Future<DebtEntriesPage> entries(
    String key, {
    DebtEntryQuery query = const DebtEntryQuery(),
    int page = 1,
    int perPage = 30,
    DebtCycle? cycle,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/entries',
        queryParameters: <String, dynamic>{
          ...query.toQuery(),
          'cycle': ?cycle?.wire,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      return DebtEntriesPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /personal-debts/people/{key}/entries`: the ONE write for a new
  /// entry (quick create in debt mode). A wallet → the BE also writes the
  /// wallet tx (paid = expense, received = income); none → ledger-only.
  /// [tagIds] only with [accountId]; [markPaidIds] labels the person's other
  /// entries paid in the same call; [personName] = the shown spelling of a
  /// typed (`n:`) name.
  Future<DebtEntryWriteResult> createEntry(
    String key, {
    required DebtEntryDirection direction,
    required double amount,
    DateTime? date,
    String? accountId,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/entries',
        data: <String, dynamic>{
          'direction': direction.wire,
          'amount': amount,
          if (date != null) 'date': debtDateWire(date),
          'account_id': ?accountId,
          'description': ?description,
          'note': ?note,
          if (accountId != null && tagIds != null) 'tag_ids': tagIds,
          if (markPaidIds != null && markPaidIds.isNotEmpty)
            'mark_paid_ids': markPaidIds,
          'person_name': ?personName,
        },
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /personal-debts/{id}`: the tx detail page in debt mode (entry,
  /// person balance, the full transaction or null). A deleted id → 404.
  Future<DebtEntryDetail> getEntry(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /personal-debts/{id}`: a partial edit (see [DebtEntryUpdate]). A
  /// split-sourced entry takes only description / note / paid (409
  /// ENTRY_MANAGED_BY_SOURCE otherwise).
  Future<DebtEntryWriteResult> updateEntry(
    String id,
    DebtEntryUpdate update,
  ) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/personal-debts/$id',
        data: update.toJson(),
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The "จ่ายแล้ว" label only (it never changes a number).
  Future<DebtEntryWriteResult> setPaid(String id, bool paid) =>
      updateEntry(id, DebtEntryUpdate(paid: paid));

  /// `DELETE /personal-debts/{id}`: the entry AND its wallet transaction.
  Future<DebtEntryDeleteResult> deleteEntry(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDeleteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /personal-debts/split-requests/{notification_id}/accept`: "add to
  /// my debts" on a split someone shared with me → my new entry.
  Future<DebtEntryWriteResult> acceptSplit(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/split-requests/$notificationId/accept',
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /personal-debts/split-changes/{notification_id}/apply`:
  /// "อัปเดตตาม" — my entry follows the splitter's change (or goes).
  Future<DebtSplitChangeResult> applySplit(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/split-changes/$notificationId/apply',
      );
      return DebtSplitChangeResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// A partial `PUT /personal-debts/{id}` body: null = unchanged. [clearAccount]
/// sends `account_id: null` (ledger-only: the wallet tx is deleted), distinct
/// from leaving it out. [description] / [note]: `''` clears.
class DebtEntryUpdate {
  const DebtEntryUpdate({
    this.direction,
    this.amount,
    this.date,
    this.accountId,
    this.clearAccount = false,
    this.description,
    this.note,
    this.paid,
    this.tagIds,
    this.key,
    this.personName,
  }) : assert(
         !clearAccount || accountId == null,
         'clearAccount and accountId together',
       );

  final DebtEntryDirection? direction;
  final double? amount;
  final DateTime? date;
  final String? accountId;
  final bool clearAccount;
  final String? description;
  final String? note;
  final bool? paid;
  final List<String>? tagIds;

  /// Move the entry to another person (`c:` / `n:` key).
  final String? key;
  final String? personName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'direction': ?direction?.wire,
    'amount': ?amount,
    if (date != null) 'date': debtDateWire(date!),
    if (clearAccount) 'account_id': null else 'account_id': ?accountId,
    'description': ?description,
    'note': ?note,
    'paid': ?paid,
    'tag_ids': ?tagIds,
    'key': ?key,
    'person_name': ?personName,
  };
}
