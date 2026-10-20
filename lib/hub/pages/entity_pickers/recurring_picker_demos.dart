import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/recurring/data/recurring_link_repository.dart';
import '../../../features/recurring/domain/recurrence_rule.dart';
import '../../../features/recurring/domain/recurring_item.dart';
import '../../../features/recurring/presentation/cubit/recurring_directory_cubit.dart';
import '../../../features/recurring/presentation/widgets/recurring_picker.dart';
import '../../../features/transactions/domain/transaction_type.dart';
import '../../../features/transactions/presentation/widgets/recurring_link.dart';
import '../../../features/transactions/presentation/widgets/transaction_picker.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [RecurringPicker] as the transaction pages open it, on the real recurring
/// cache.
class RecurringPickerDemos extends StatelessWidget {
  const RecurringPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static String _say(LinkCandidate? c) => c == null
      ? 'closed'
      : '${c.setting.name} (${c.occurrence.slot ?? c.occurrence.itemId}'
            '${c.replace ? ', replace' : ''})';

  /// Step 2 rows for any rule: 2 overdue, 1 recorded on another tx, 2 coming.
  static Future<({List<RecurringItem> items, String? suggestedSlot})>
  _fakeOccurrences(String ruleId, DateTime? txDate) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    Map<String, dynamic> row(
      int days,
      String status, {
      double? amount = 419,
      Map<String, dynamic>? tx,
    }) {
      final d = ymd(now.add(Duration(days: days)));
      return {
        'rule_id': ruleId,
        'slot': d,
        'date': d,
        'days_until': days,
        'type': 'expense',
        'status': status,
        'amount': ?amount,
        'transaction': ?tx,
        'tags': const <dynamic>[],
      };
    }

    final rows = [
      row(-40, 'due'),
      row(-10, 'due', amount: null),
      row(-70, 'done', tx: {'id': 'tx-other', 'description': 'Netflix ก.ย.'}),
      row(20, 'upcoming'),
      row(50, 'upcoming'),
    ];
    return (
      items: [for (final r in rows) RecurringItem.fromJson(r)],
      suggestedSlot: rows.first['slot'] as String,
    );
  }

  Widget _new(String label, Future<String> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => onResult(await run()),
  );

  Widget _demo(String title, String note, List<Widget> buttons) => HubDemo(
    title: title,
    note: note,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<RecurringDirectoryCubit>();
    final expense = directory.candidates(TransactionType.expense);
    final hint = expense.firstOrNull?.setting;
    final linked = expense.lastOrNull?.setting.id;
    final createExpense = recurringCreateRoute(
      type: TransactionType.expense,
      amount: hint?.amount,
      categoryId: hint?.category?.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'RecurringPicker.one — quick create',
          'Expense; the first recurring\'s category and amount put it under '
              'น่าจะใช่. The pinned create row closes the sheet and opens '
              '/recurring/new (leaves the hub).',
          [
            _new(
              'New',
              () async => _say(
                await RecurringPicker.one(
                  context,
                  type: TransactionType.expense,
                  categoryId: hint?.category?.id,
                  amount: hint?.amount,
                  createRoute: createExpense,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'RecurringPicker.one — transaction detail',
          'Expense, already linked to the last one: it is highlighted and '
              'scrolled to.',
          [
            _new(
              'New',
              () async => _say(
                await RecurringPicker.one(
                  context,
                  type: TransactionType.expense,
                  selectedRuleId: linked,
                  createRoute: createExpense,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'RecurringPicker.one — 2 steps (occurrence)',
          'Fake occurrences for whichever rule you pick (the real ones need '
              'C3): งวดใกล้เคียง on top, then ค้าง / งวดถัดไป / งวดที่ผ่านมา. '
              'The recorded one is on another tx: picking it asks สลับ? '
              '(no = back to the list). "เลือกรายการประจำอื่น" goes back to '
              'step 1.',
          [
            _new(
              'New',
              () async => _say(
                await RecurringPicker.one(
                  context,
                  type: TransactionType.expense,
                  txDate: DateTime.now(),
                  loadOccurrences: _fakeOccurrences,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'RecurringPicker.one — income',
          'Without a createRoute: no create row.',
          [
            _new(
              'New, no create',
              () async => _say(
                await RecurringPicker.one(
                  context,
                  type: TransactionType.income,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'TransactionPicker.one — ผูกกับรายการที่มีอยู่',
          'The occurrence side of linking: your expense tx within 45 days of '
              'today, nearest first; the first recurring\'s category / amount '
              'go under น่าจะใช่. A tx already linked shows its recurring.',
          [
            _new('Pick', () async {
              final tx = await TransactionPicker.one(
                context,
                type: TransactionType.expense,
                near: DateTime.now(),
                categoryId: hint?.category?.id,
                amount: hint?.amount,
              );
              return tx == null ? 'closed' : '${tx.description} (${tx.id})';
            }),
          ],
        ),
        if (directory.state.rules.isEmpty)
          const HubDemo(
            title: 'No recurring',
            child: AppText(
              'The recurring cache is empty: sign in first (the pickers load '
              'it when opened).',
            ),
          ),
      ],
    );
  }
}
