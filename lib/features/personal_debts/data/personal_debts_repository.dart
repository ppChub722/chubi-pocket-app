import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/debt_ledger.dart';
import '../domain/debt_plans.dart';

class PersonalDebtsRepository {
  PersonalDebtsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

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
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

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
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// A DEBT (ให้ยืม / ยืม). The transaction side: none (ledger-only), a new
  /// one ([createTransaction] / [accountId]) or one of mine connected in the
  /// same call ([linkTransactionId]: its amount and date are used, so
  /// [amount] may be null).
  Future<DebtEntryWriteResult> createEntry(
    String key, {
    required DebtEntryDirection direction,
    double? amount,
    DateTime? date,
    String? accountId,
    bool? createTransaction,
    String? linkTransactionId,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
    String? billId,
    String? eventId,
    DateTime? dueDate,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/entries',
        data: <String, dynamic>{
          'direction': direction.wire,
          'amount': ?amount,
          if (date != null) 'date': debtDateWire(date),
          'account_id': ?accountId,
          'create_transaction': ?createTransaction,
          'link_transaction_id': ?linkTransactionId,
          'description': ?description,
          'note': ?note,
          if ((accountId != null || createTransaction == true) &&
              tagIds != null)
            'tag_ids': tagIds,
          if (markPaidIds != null && markPaidIds.isNotEmpty)
            'mark_paid_ids': markPaidIds,
          'person_name': ?personName,
          // The event resolve sheet's "as debt" (0.4.0-3 B3): the bill it
          // settles a share of; the debt keeps it as its source.
          'bill_id': ?billId,
          // An event's จัดการ line (no bill): settle shows it as recorded.
          'event_id': ?eventId,
          if (dueDate != null) 'due_date': debtDateWire(dueDate),
        },
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// `POST /personal-debts/people/{key}/repayments` (createDebtRepayment): a
  /// repayment is a person-book row tied to the PERSON (0.4.1-1 D3), its
  /// transaction optional as on a debt: none = ledger-only ("paid outside
  /// the app"), [createTransaction] (wallet optional) = a new one (expense
  /// "Debt Paid" / income "Debt Received"), [linkTransactionId] = one of mine
  /// connected ([amount] may then be null). [markAllPaid] = ปิดหนี้.
  Future<DebtEntryWriteResult> createRepayment(
    String key, {
    required DebtRepaymentKind kind,
    double? amount,
    String? accountId,
    bool? createTransaction,
    String? linkTransactionId,
    DateTime? date,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    bool markAllPaid = false,
    String? personName,
    String? billId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/repayments',
        data: <String, dynamic>{
          'kind': kind.wire,
          'amount': ?amount,
          'account_id': ?accountId,
          'create_transaction': ?createTransaction,
          'link_transaction_id': ?linkTransactionId,
          if (date != null) 'date': debtDateWire(date),
          'description': ?description,
          'note': ?note,
          if (tagIds != null && tagIds.isNotEmpty) 'tag_ids': tagIds,
          if (markPaidIds != null && markPaidIds.isNotEmpty)
            'mark_paid_ids': markPaidIds,
          if (markAllPaid) 'mark_all_paid': true,
          'person_name': ?personName,
          'bill_id': ?billId,
        },
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// The quick-create debt result box (0.4.0-3): the same POST with
  /// `?preview=true`; nothing is saved. Record = [direction] (+ a wallet when
  /// [createTransaction]); settle = [kind].
  Future<DebtPreview> preview(
    String key, {
    DebtEntryDirection? direction,
    DebtRepaymentKind? kind,
    required double amount,
    String? accountId,
    bool? createTransaction,
    String? personName,
  }) async {
    assert((direction == null) != (kind == null), 'record or settle');
    try {
      final person = Uri.encodeComponent(key);
      final res = await _client.dio.post<Map<String, dynamic>>(
        kind == null
            ? '/personal-debts/people/$person/entries'
            : '/personal-debts/people/$person/repayments',
        queryParameters: const {'preview': 'true'},
        data: <String, dynamic>{
          'direction': ?direction?.wire,
          'kind': ?kind?.wire,
          'amount': amount,
          'account_id': ?accountId,
          'create_transaction': ?createTransaction,
          'person_name': ?personName,
        },
      );
      return DebtPreview.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<DebtEntryDetail> getEntry(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

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
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// The "จ่ายแล้ว" label only (it never changes a number).
  Future<DebtEntryWriteResult> setPaid(String id, bool paid) =>
      updateEntry(id, DebtEntryUpdate(paid: paid));

  /// ผูกกับรายการที่มีอยู่ (0.4.1-1 D2): one of my transactions becomes the
  /// entry's, connected + synced (the entry takes its amount and date; it
  /// takes the kind's category). Only an entry with no transaction (409
  /// ENTRY_HAS_TRANSACTION).
  Future<DebtEntryWriteResult> linkTx(String id, String transactionId) =>
      _write('/personal-debts/$id/link', {'transaction_id': transactionId});

  /// Disconnects a CONNECTED transaction (its old category comes back); the
  /// entry stays ledger-only. A transaction made from the entry: 409
  /// TX_NOT_DISCONNECTABLE.
  Future<DebtEntryWriteResult> unlinkTx(String id) =>
      _write('/personal-debts/$id/unlink', null);

  /// D9: my copy of a linked debt stops following the other user's (my
  /// side only); they get debt_disconnected. 409 DEBT_NOT_LINKED.
  Future<DebtEntryWriteResult> disconnect(String id) =>
      _write('/personal-debts/$id/disconnect', null);

  Future<DebtEntryWriteResult> _write(String path, Object? body) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        path,
        data: body,
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<DebtEntryDeleteResult> deleteEntry(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDeleteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  // ---- debt plans + cards (0.4.3) ----

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  /// My cards / PayLater wallets as debts (bill, unbilled, plans).
  Future<List<CardSummary>> cardSummaries() => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/card-summaries');
    return [
      for (final c in (res.data?['data'] as List?) ?? const [])
        ?CardSummary.tryParse(c),
    ];
  });

  Future<CardSummary> cardSummary(String accountId) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/card-summaries/$accountId',
    );
    return CardSummary.tryParse(res.data)!;
  });

  /// My plans (open first); [accountId] = only the plans on that card.
  Future<List<DebtPlan>> plans({String? accountId}) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/debt-plans',
      queryParameters: {'account_id': ?accountId},
    );
    return [
      for (final p in (res.data?['data'] as List?) ?? const [])
        ?DebtPlan.tryParse(p),
    ];
  });

  Future<DebtPlan> plan(String id) => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/debt-plans/$id');
    return DebtPlan.tryParse(res.data)!;
  });

  /// POST /debt-plans (the BE DebtPlanInput as a map).
  Future<DebtPlan> createPlan(Map<String, dynamic> body) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/debt-plans',
      data: body,
    );
    return DebtPlan.tryParse(res.data)!;
  });

  /// จ่ายงวดนี้: the principal back + its interest (ดอกเบี้ย) from [accountId].
  Future<DebtPlan> payInstallment(String id, {int? seq, String? accountId}) =>
      _call(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/debt-plans/$id/pay',
          data: {'seq': ?seq, 'account_id': ?accountId},
        );
        return DebtPlan.tryParse(res.data)!;
      });

  /// แก้งวดนี้: its due date and / or money (amount + interest; principal =
  /// amount − interest).
  Future<DebtPlan> editInstallment(
    String id,
    int seq, {
    DateTime? dueDate,
    double? amount,
    double? interest,
    bool recalcRest = false,
  }) => _call(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/debt-plans/$id/installments/$seq',
      data: {
        if (dueDate != null) 'due_date': _ymd(dueDate),
        'amount': ?amount,
        'interest': ?interest,
        // the user said yes to "คำนวณงวดที่เหลือใหม่ไหม"
        if (recalcRest) 'recalc_rest': true,
      },
    );
    return DebtPlan.tryParse(res.data)!;
  });

  /// ข้าม: the installment moves to the end of the plan.
  Future<DebtPlan> skipInstallment(String id, int seq) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/debt-plans/$id/installments/$seq/skip',
    );
    return DebtPlan.tryParse(res.data)!;
  });

  /// What I owe people now (the recurring hero's ติดคน).
  Future<double> iOwePeople() => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/personal-debts/people',
      queryParameters: {'section': 'person', 'per_page': 1},
    );
    final t = res.data?['totals'];
    return t is Map ? ((t['i_owe'] as num?)?.toDouble() ?? 0) : 0;
  });

  Future<DebtPlan> closePlan(String id) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/debt-plans/$id/close',
    );
    return DebtPlan.tryParse(res.data)!;
  });

  Future<void> deletePlan(String id) =>
      _call(() => _client.dio.delete<void>('/debt-plans/$id'));

  /// ตั้ง reminder of a plan (0.4.3): a debt item paying it, monthly on
  /// [day] from [fromAccountId] for the [left] installments still open (each
  /// round = the plan's next installment, principal + ดอกเบี้ย). Answers the
  /// item id.
  Future<String> createPlanReminder({
    required String planId,
    required String name,
    required String fromAccountId,
    required DateTime first,
    required int left,
  }) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/recurring',
      data: {
        'name': name,
        'tracking_type': 'installment',
        'rules': [
          {
            'type': 'debt',
            'debt_plan_id': planId,
            'source': {'account_id': fromAccountId},
            'schedule': {
              'freq': 'monthly',
              'interval': 1,
              'month_days': [first.day],
              'start_date': _ymd(first),
              'end': {'kind': 'count', 'count': left},
            },
          },
        ],
      },
    );
    return res.data!['id'] as String;
  });

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// จ่ายบิลบัตร: a recurring whose rule pays the card's bill: monthly on
  /// [day] (the statement day) from [fromAccountId], a transfer into the card
  /// whose amount is asked (prefilled with the bill). Answers the recurring id.
  Future<String> createCardBillReminder({
    required String accountId,
    required String name,
    required String fromAccountId,
    required int day,
  }) => _call(() async {
    final now = DateTime.now();
    final start =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/recurring',
      data: {
        'name': name,
        'tracking_type': 'credit_card',
        'rules': [
          {
            'type': 'transfer',
            'to_account_id': accountId,
            'amount_mode': 'ask',
            'source': {'account_id': fromAccountId},
            'schedule': {
              'freq': 'monthly',
              'interval': 1,
              'month_days': [day],
              'start_date': start,
            },
          },
        ],
      },
    );
    return res.data!['id'] as String;
  });
}

class DebtEntryUpdate {
  const DebtEntryUpdate({
    this.direction,
    this.amount,
    this.date,
    this.accountId,
    this.clearAccount = false,
    this.createTransaction,
    this.description,
    this.note,
    this.paid,
    this.tagIds,
    this.key,
    this.personName,
    this.dueDate,
    this.clearDueDate = false,
  }) : assert(
         !clearAccount || accountId == null,
         'clearAccount and accountId together',
       ),
       assert(
         !clearDueDate || dueDate == null,
         'clearDueDate and dueDate together',
       );

  final DateTime? dueDate;
  final bool clearDueDate;

  final DebtEntryDirection? direction;
  final double? amount;
  final DateTime? date;
  final String? accountId;
  final bool clearAccount;

  final bool? createTransaction;
  final String? description;
  final String? note;
  final bool? paid;
  final List<String>? tagIds;

  final String? key;
  final String? personName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'direction': ?direction?.wire,
    'amount': ?amount,
    if (date != null) 'date': debtDateWire(date!),
    if (clearAccount) 'account_id': null else 'account_id': ?accountId,
    'create_transaction': ?createTransaction,
    'description': ?description,
    'note': ?note,
    'paid': ?paid,
    'tag_ids': ?tagIds,
    'key': ?key,
    'person_name': ?personName,
    if (clearDueDate)
      'due_date': null
    else if (dueDate != null)
      'due_date': debtDateWire(dueDate!),
  };
}
