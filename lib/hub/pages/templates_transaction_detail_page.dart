import 'package:flutter/material.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/categories/domain/category.dart';
import '../../features/categories/domain/category_type.dart';
import '../../features/transactions/domain/refs.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/transactions/presentation/widgets/draft_form.dart';
import '../../features/transactions/presentation/widgets/tx_compact_hero.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/templates/transaction-detail` — the transaction detail page's
/// anatomy, on sample data. The page is exempt from the generic detail-page
/// standard; this shows its own layout in view / edit / transfer / split /
/// system states. The form runs on the app's real cubits (tags, categories,
/// wallets for the pickers); the row itself is sample data.
Widget buildTransactionDetailPage(BuildContext context) => const _TxPage();

const _kbank = Account(
  id: 'demo-a1',
  name: 'KBank',
  type: AccountType.bank,
  balance: 18250,
  currency: 'THB',
);
const _cash = Account(
  id: 'demo-a2',
  name: 'Cash',
  type: AccountType.cash,
  balance: 1200,
  currency: 'THB',
);
const _food = Category(
  id: 'demo-c1',
  name: 'อาหาร',
  type: CategoryType.expense,
);
const _opening = Category(
  id: 'demo-c2',
  name: 'Opening balance',
  type: CategoryType.income,
  isSystem: true,
);

const _tags = [
  EmbeddedTag(id: 'demo-t1', name: 'งาน'),
  EmbeddedTag(id: 'demo-t2', name: 'กิน'),
];

const _people = [
  TxSplit(
    debtId: 'demo-d1',
    person: EmbeddedPerson(name: 'ลี'),
    amount: 120,
    settledAmount: 100,
  ),
  TxSplit(
    debtId: 'demo-d2',
    person: EmbeddedPerson(name: 'เอ'),
    amount: 120,
  ),
];

const _viewTx = Transaction(
  id: 'demo-tx1',
  accountId: 'demo-a1',
  type: TransactionType.expense,
  amount: 360,
  date: '2026-10-11',
  categoryId: 'demo-c1',
  description: 'ข้าวมันไก่',
  note: 'หารกับเพื่อนที่ทำงาน',
  tags: _tags,
  splitCount: 2,
  splits: _people,
);

const _transferTx = Transaction(
  id: 'demo-tx2',
  accountId: 'demo-a1',
  type: TransactionType.transfer,
  amount: 5000,
  date: '2026-10-10',
  description: 'เติมเงินสด',
);

const _eventTx = Transaction(
  id: 'demo-tx3',
  accountId: 'demo-a1',
  type: TransactionType.expense,
  amount: 1240,
  date: '2026-10-09',
  categoryId: 'demo-c1',
  description: 'หมูกระทะ',
  projectId: 'demo-p1',
  project: EventRef(id: 'demo-p1', name: 'ทริปเชียงใหม่'),
  tags: _tags,
  splitCount: 2,
  splits: _people,
);

const _systemTx = Transaction(
  id: 'demo-tx4',
  accountId: 'demo-a1',
  type: TransactionType.income,
  amount: 18250,
  date: '2026-09-01',
  categoryId: 'demo-c2',
);

class _TxPage extends StatefulWidget {
  const _TxPage();

  @override
  State<_TxPage> createState() => _TxPageState();
}

class _TxPageState extends State<_TxPage> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    Widget rule(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.info, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title. ', style: text.titleSmall),
                  TextSpan(text: body, style: muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HubDemo(
          title: 'View mode — expense with people',
          note:
              'Hero (type chip + date, pencil, description, amount), then the '
              'category and wallet cards below it, the tag strip, the note '
              'row (label left), the split section with where each person '
              'stands. Tap the pencil or long-press a field to edit.',
          child: _Sample(
            tx: _viewTx,
            accounts: [_kbank, _cash],
            category: _food,
          ),
        ),
        const HubDemo(
          title: 'Edit mode — same row',
          note:
              'Pickers and chip rows open, the type stays locked, the split '
              'editor replaces the read-only list, delete is the last row. '
              'The top bar swaps to cancel / undo / save and the bottom nav '
              'hides (not shown here).',
          child: _Sample(
            tx: _viewTx,
            accounts: [_kbank, _cash],
            category: _food,
            startEditing: true,
          ),
        ),
        const HubDemo(
          title: 'Transfer',
          note:
              'From → to wallets in one row, no category, no splits; the arrow '
              'swaps the wallets in edit mode.',
          child: _Sample(
            tx: _transferTx,
            accounts: [_kbank, _cash],
            toAccount: _cash,
          ),
        ),
        const HubDemo(
          title: 'Row split with people, and an event row',
          note:
              'The split section lists each person (tap → their debts); the '
              'event row under it opens the event. In edit mode the event row '
              'becomes a picker.',
          child: _Sample(
            tx: _eventTx,
            accounts: [_kbank, _cash],
            category: _food,
            event: 'ทริปเชียงใหม่',
          ),
        ),
        const HubDemo(
          title: 'System row — locked',
          note:
              'Opening balance / adjustment rows are bookkeeping: a lock '
              'banner on top, no pencil, no long-press, no delete.',
          child: _Sample(
            tx: _systemTx,
            accounts: [_kbank, _cash],
            category: _opening,
            system: true,
          ),
        ),
        HubDemo(
          title: 'Page rules',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rule(
                'The title never changes',
                'The top bar always names the type (Expense / Income / '
                    'Transfer); edit mode shows in the fields and the action '
                    'bar, not the title.',
              ),
              rule(
                'Compact hero bar',
                'Once the hero scrolls under the top bar, one line is pinned '
                    'there (view and edit alike); tapping it scrolls back up.',
              ),
              Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: txCompactHeroBar(
                      context,
                      type: TransactionType.expense,
                      description: 'ข้าวมันไก่',
                      amount: 360,
                      categoryName: 'อาหาร',
                    ),
                  ),
                ),
              ),
              rule(
                'Long-press enters edit',
                'On the hero fields, the cards, the tags, the note or the '
                    'split section. Taps in view mode never leave the page '
                    'except a person (→ debts) or the event.',
              ),
              rule(
                'Delete only in edit mode',
                'The danger row is the last row of edit mode. Exception: a '
                    'debt repayment row is read-only but still deletable.',
              ),
              rule(
                'The note is always shown',
                'Empty, it reads as a long-press hint, so the way in is '
                    'never hidden.',
              ),
              rule(
                'Record info at the bottom',
                'Small muted lines: recorded by, balance after, created, '
                    'last edited.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One framed page body: the real [DraftForm] on a sample row.
class _Sample extends StatefulWidget {
  const _Sample({
    required this.tx,
    required this.accounts,
    this.category,
    this.toAccount,
    this.event,
    this.system = false,
    this.startEditing = false,
  });

  final Transaction tx;
  final List<Account> accounts;
  final Category? category;
  final Account? toAccount;
  final String? event;
  final bool system;
  final bool startEditing;

  @override
  State<_Sample> createState() => _SampleState();
}

class _SampleState extends State<_Sample> {
  final _c = DraftFormController();
  late bool _editing = widget.startEditing;

  @override
  void initState() {
    super.initState();
    _c.prefillTransaction(
      widget.tx,
      accounts: widget.accounts,
      categories: [?widget.category],
      toAccount: widget.toAccount,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tx = widget.tx;
    final canEdit = !widget.system;
    final people = tx.splits;
    final canSplit = canEdit && tx.type != TransactionType.transfer;
    final eventName = widget.event;
    final eventSlot = eventName == null
        ? null
        : _editing
        ? SplitEventSlot(name: eventName, onTap: () {}, onClear: () {})
        : SplitEventSlot(name: eventName, onTap: () {});
    final splitsReadOnly = !_editing && people.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  l.txSplitRowLabel,
                  style: detailLabelStyle(context),
                ),
              ),
              for (final s in people) _PersonRow(split: s),
            ],
          )
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.system) ...[
              AppCard(
                style: AppCardStyle.bordered,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      AppIcons.lock,
                      size: AppIconSize.md,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l.transactionDetailSystemRowBanner,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            DraftForm(
              controller: _c,
              autofocus: false,
              typeLocked: true,
              allowSplits: canSplit,
              editing: _editing,
              onEdit: canEdit ? () => setState(() => _editing = true) : null,
              onEnterEdit: canEdit
                  ? (_) => setState(() => _editing = true)
                  : null,
              splitsReadOnly: splitsReadOnly,
              eventSlot: eventSlot,
            ),
            if (_editing && canEdit)
              DangerRow(
                icon: AppIcons.delete,
                label: l.transactionDeleteThis,
                onTap: () {},
              ),
            if (_editing && !widget.startEditing)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'Back to view',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => setState(() => _editing = false),
                  ),
                ),
              ),
            if (!_editing)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  'Recorded by You\nCreated 11 Oct 2026 12:30',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One person of the split section: mark + name left, amount and where it
/// stands right (a static copy of the page's row).
class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.split});

  final TxSplit split;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = split;
    final status = s.settledAmount > 0
        ? 'part paid ฿${s.settledAmount.toStringAsFixed(0)} of '
              '฿${s.amount.toStringAsFixed(0)}'
        : 'awaiting ฿${s.amount.toStringAsFixed(0)}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          PersonMark(
            name: s.personName,
            level: PersonLevel.name,
            size: 32,
            reserveLinkSlot: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              s.personName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('฿${s.amount.toStringAsFixed(0)}', style: text.bodyLarge),
              Text(
                status,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
