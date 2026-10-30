import 'package:chubi_pocket/features/pending/data/pending_repository.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/pending_selection.dart';
import 'package:flutter_test/flutter_test.dart';

const _wallet = {
  'id': 'a1',
  'name': 'KBank',
  'icon_code': null,
  'logo_url': null,
  'type': 'bank',
  'group': 'asset',
  'currency': 'THB',
  'archived': false,
};

/// Prod-shaped draft (`needs_input` / `can_confirm` as BE 0.4.0 sends them).
Map<String, dynamic> draftJson(
  String id, {
  double? amount = 120,
  String source = 'manual',
  List<String>? needsInput,
  bool? canConfirm,
  String? description,
  Map<String, dynamic>? error,
}) => {
  'id': id,
  'source': source,
  'kind': 'create',
  'draft': {
    'type': 'expense',
    'amount': amount,
    'account_id': 'a1',
    'date': '2026-10-17',
    'description': description,
  },
  'resolved': {
    'account': _wallet,
    'transfer_to_account': null,
    'category': null,
    'tags': <dynamic>[],
    'project': null,
    'splits': <dynamic>[],
    'missing': <dynamic>[],
  },
  'target_debt_id': null,
  'target_transaction_id': null,
  'source_ref': null,
  'last_error': error,
  'needs_input': ?needsInput,
  'can_confirm': ?canConfirm,
  'created_at': '2026-10-17T08:00:00Z',
  'updated_at': '2026-10-17T08:00:00Z',
};

Map<String, dynamic> summaryJson({
  int count = 3,
  int manual = 2,
  int ready = 2,
  int needs = 1,
}) => {
  'count': count,
  'expense_total': 500.5,
  'income_total': 0,
  'needs_input_count': needs,
  'ready_count': ready,
  'by_source': {
    'recurring': count - manual,
    'manual': manual,
    'other_people': 0,
    'slip': 0,
    'other': 0,
  },
};

class _Repo extends Fake implements PendingRepository {
  _Repo(this.rows, {this.summary});
  List<PendingTransaction> rows;
  Map<String, dynamic>? summary;
  int listCalls = 0;
  final submitCalls = <List<String>>[];
  int submitReadyCalls = 0;
  final submitOneCalls = <String>[];
  Map<String, dynamic>? nextAnswer;
  final created = <PendingDraft>[];
  final updated = <String>[];

  /// `POST /pending-transactions` answers {data, summary}.
  @override
  Future<PendingList> create(List<PendingDraft> drafts) async {
    created.addAll(drafts);
    final fresh = [
      for (var i = 0; i < drafts.length; i++)
        PendingTransaction.fromJson(draftJson('n${created.length}-$i')),
    ];
    rows = [...fresh, ...rows];
    return PendingList(
      items: fresh,
      summary: PendingSummary.fromJson(
        summaryJson(
          count: rows.length,
          manual: rows.length,
          ready: 1,
          needs: 4,
        ),
      ),
    );
  }

  /// `PUT /pending-transactions/:id` answers the draft plus `summary`.
  @override
  Future<PendingUpdated> update(String id, PendingDraft draft) async {
    updated.add(id);
    return PendingUpdated(
      draft: PendingTransaction.fromJson(
        draftJson(id, description: 'edited', needsInput: []),
      ),
      summary: PendingSummary.fromJson(
        summaryJson(
          count: rows.length,
          manual: rows.length,
          ready: 2,
          needs: 0,
        ),
      ),
    );
  }

  @override
  Future<PendingList> list() async {
    listCalls++;
    return PendingList(
      items: rows,
      summary: summary == null ? null : PendingSummary.fromJson(summary!),
    );
  }

  /// What the BE answers after taking [ids] out: the summary over the rest.
  Map<String, dynamic> _summaryAfter(List<String> ids) {
    final left = rows.where((p) => !ids.contains(p.id)).length;
    return summaryJson(count: left, manual: left, ready: left, needs: 0);
  }

  PendingSubmitResult _answer(List<String> ids) => PendingSubmitResult.fromJson(
    nextAnswer ??
        {
          'summary': _summaryAfter(ids),
          'submitted': [
            for (final id in ids) {'id': id},
          ],
          'failed': <dynamic>[],
          'account_balances': <String, dynamic>{},
          'badges': {'pending_drafts': 0},
        },
  );

  @override
  Future<PendingSubmitResult> submit(List<String> ids) async {
    submitCalls.add(ids);
    return _answer(ids);
  }

  @override
  Future<PendingSubmitResult> submitReady() async {
    submitReadyCalls++;
    return _answer([
      for (final p in rows)
        if (p.needsInput?.isEmpty ?? true) p.id,
    ]);
  }

  @override
  Future<PendingSubmitResult> submitOne(String id) async {
    submitOneCalls.add(id);
    return _answer([id]);
  }
}

void main() {
  test('parses needs_input / can_confirm and the summary (null-safe)', () {
    final p = PendingTransaction.fromJson(
      draftJson('p1', amount: null, needsInput: ['amount'], canConfirm: false),
    );
    expect(p.needsInput, ['amount']);
    expect(p.canConfirm, isFalse);
    expect(p.needs('amount'), isTrue);
    expect(p.needs('type'), isFalse);
    final old = PendingTransaction.fromJson(draftJson('p2'));
    expect(old.needsInput, isNull);
    expect(old.canConfirm, isTrue);
    expect(old.needs('amount'), isFalse);

    final s = PendingSummary.fromJson(summaryJson());
    expect(s.count, 3);
    expect(s.expenseTotal, 500.5);
    expect(s.readyCount, 2);
    expect(s.needsInputCount, 1);
    expect(s.manual, 2);
    expect(s.notManual, 1);
    expect(PendingSummary.fromJson(const {}).count, 0);
  });

  group('cubit', () {
    test('create and update take the summary from their answers', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(draftJson('p1')),
      ], summary: summaryJson(count: 1, manual: 1, ready: 0, needs: 1));
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.summary?.needsInputCount, 1);

      await cubit.add(const [PendingDraft(amount: 50)]);
      expect(cubit.state.items, hasLength(2));
      // The chips are the create answer's numbers, not a count of rows.
      expect(cubit.state.summary?.count, 2);
      expect(cubit.state.summary?.readyCount, 1);
      expect(cubit.state.summary?.needsInputCount, 4);

      await cubit.updateDraft('p1', const PendingDraft(amount: 60));
      expect(
        cubit.state.items.firstWhere((p) => p.id == 'p1').draft.description,
        'edited',
      );
      expect(cubit.state.summary?.readyCount, 2);
      expect(cubit.state.summary?.needsInputCount, 0);
      expect(repo.listCalls, 1);
      await cubit.close();
    });

    test('a write answer carries the summary; no second list call', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(draftJson('p1')),
        PendingTransaction.fromJson(draftJson('p2')),
      ], summary: summaryJson(count: 2, manual: 2, ready: 2, needs: 0));
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.summary?.readyCount, 2);
      await cubit.submitOne('p1');
      expect(cubit.state.items.map((e) => e.id), ['p2']);
      // The numbers are the answer's, not the old load's, not row counts.
      expect(cubit.state.summary?.count, 1);
      expect(cubit.state.summary?.readyCount, 1);
      expect(repo.submitOneCalls, ['p1']);
      expect(repo.listCalls, 1);
      await cubit.close();
    });

    test('submitReady is ONE call; submitted leave the list', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(draftJson('p1', needsInput: [])),
        PendingTransaction.fromJson(
          draftJson(
            'p2',
            amount: null,
            needsInput: ['amount'],
            canConfirm: false,
          ),
        ),
      ]);
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      final r = await cubit.submitReady();
      expect(repo.submitReadyCalls, 1);
      expect(repo.submitCalls, isEmpty);
      expect(r.submitted, ['p1']);
      expect(cubit.state.items.map((e) => e.id), ['p2']);
      await cubit.close();
    });

    test('a failed[] answer keeps the draft (server copy)', () async {
      final repo = _Repo([
        PendingTransaction.fromJson(
          draftJson(
            'p1',
            amount: null,
            needsInput: ['amount'],
            canConfirm: false,
          ),
        ),
      ]);
      repo.nextAnswer = {
        'submitted': <dynamic>[],
        'failed': [
          {
            'id': 'p1',
            'error': {'code': 'MISSING_AMOUNT', 'message': 'amount needed'},
            'pending': draftJson(
              'p1',
              amount: null,
              needsInput: ['amount'],
              canConfirm: false,
              error: {'code': 'MISSING_AMOUNT', 'message': 'amount needed'},
            ),
          },
        ],
        'account_balances': <String, dynamic>{},
        'badges': {'pending_drafts': 1},
      };
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      final r = await cubit.submitOne('p1');
      expect(r.failed.keys, ['p1']);
      expect(cubit.state.items.single.id, 'p1');
      expect(cubit.state.items.single.lastError?.code, 'MISSING_AMOUNT');
      await cubit.close();
    });
  });

  test(
    'only the confirmable part of a selection is sent, in one call',
    () async {
      final lunch = PendingTransaction.fromJson(
        draftJson('p1', description: 'Lunch'),
      );
      final noAmount = PendingTransaction.fromJson(
        draftJson(
          'p3',
          amount: null,
          needsInput: ['amount'],
          canConfirm: false,
          description: 'Rent reminder',
        ),
      );
      for (final c in [
        (
          name: 'amount-less alone: nothing goes, it is blocked',
          selected: ['p3'],
          ready: <String>[],
          blocked: ['p3'],
        ),
        (
          name: 'mixed: only the confirmable go',
          selected: ['p1', 'p3'],
          ready: ['p1'],
          blocked: ['p3'],
        ),
        (
          name: 'all confirmable',
          selected: ['p1'],
          ready: ['p1'],
          blocked: <String>[],
        ),
        (
          name: 'an id the list does not hold still goes',
          selected: ['p9'],
          ready: ['p9'],
          blocked: <String>[],
        ),
      ]) {
        final r = splitSelection(c.selected, [lunch, noAmount]);
        expect(r.ready, c.ready, reason: c.name);
        expect(r.blocked.map((p) => p.id), c.blocked, reason: c.name);
      }

      final repo = _Repo([
        lunch,
        noAmount,
      ], summary: summaryJson(count: 2, manual: 2, ready: 1, needs: 1));
      final cubit = PendingCubit(repository: repo);
      await cubit.load();
      await cubit.submit(splitSelection(['p1', 'p3'], cubit.state.items).ready);
      expect(repo.submitCalls, [
        ['p1'],
      ]);
      expect(cubit.state.items.map((e) => e.id), ['p3']);
      expect(repo.listCalls, 1);
      expect(cubit.state.summary?.count, 1);
      await cubit.close();
    },
  );
}
