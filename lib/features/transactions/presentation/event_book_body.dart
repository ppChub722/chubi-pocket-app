import '../domain/transaction_type.dart';
import 'widgets/draft_form.dart';

/// The quick-create อีเวนต์ tab as ONE book-bill call (0.4.1-1 E8,
/// `POST /event-bills`): [bill] is the EventBillInput (payer, everyone's
/// share, "คืนแล้ว"), [myBooks] the EventBillBooks (my tx: the whole bill when
/// I paid, my share with no wallet when someone else did; "จดหนี้ด้วย" =
/// debt). The server books the paybacks, debts and repayments (E2–E5).
({Map<String, dynamic> bill, Map<String, dynamic> myBooks}) eventBookBodies(
  DraftFormController c, {
  List<String> tagIds = const [],
}) {
  final amount = c.amountValue;
  final members = c.eventMembers;
  final payer = c.link.eventPayer;
  final description = c.description.text.trim();
  final note = c.note.text.trim();
  final date = c.date;
  String two(int n) => n.toString().padLeft(2, '0');
  return (
    bill: {
      'kind': c.type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'date': '${date.year}-${two(date.month)}-${two(date.day)}',
      if (description.isNotEmpty) 'description': description,
      if (note.isNotEmpty) 'note': note,
      'payer': payer?.toJson() ?? const {'me': true},
      'members': [
        {
          'me': true,
          'share': c.link.eventMine(amount, members),
          // "คืน X แล้ว" on my row (SA6): my share from my wallet, no debt.
          if (payer != null && c.link.mePaidBack) 'paid_back': true,
        },
        for (final p in members)
          {
            ...p.toJson(),
            'share': c.link.eventShareOf(p, amount, members),
            if (p != payer && c.isPaidBack(p)) 'paid_back': true,
          },
      ],
    },
    myBooks: {
      'on': true,
      'tx': true,
      'debt': c.link.eventBookDebts ?? false,
      // Someone else paid: my share has no wallet ("จ่ายโดย X") until I
      // paid them back.
      'account_id': payer == null || c.link.mePaidBack ? c.account?.id : null,
      'category_id': c.category?.id,
      if (tagIds.isNotEmpty) 'tag_ids': tagIds,
    },
  );
}

/// `new_event` of the same call for an event made on the spot.
Map<String, dynamic> newEventBody(String name) => {'name': name};
