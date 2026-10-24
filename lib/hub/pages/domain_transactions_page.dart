import 'package:flutter/material.dart';

import '../../features/categories/domain/category.dart';
import '../../features/categories/domain/category_type.dart';
import '../../features/categories/presentation/widgets/category_chip.dart';
import '../../features/tags/domain/tag.dart';
import '../../features/tags/presentation/widgets/tag_chip.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/transactions/presentation/widgets/draft_form.dart';
import '../../features/transactions/presentation/widgets/period_summary_card.dart';
import '../../features/transactions/presentation/widgets/quick_create_sheet.dart';
import '../../features/transactions/presentation/widgets/transaction_tile.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/domain/transactions` — the transaction row, hero card, chip
/// builders and the pieces that need live app data.
Widget buildTransactionsPage(BuildContext context) => const _TransactionsPage();

void _noop() {}

/// A static "Split" row for the [SplitEventSection] demo: the add chip, and
/// with [people] two plain person lines under it.
Widget _splitSample(SplitEventVariant variant, bool people) {
  final compact = variant == SplitEventVariant.compact;
  final chip = AppChip(
    icon: AppIcons.add,
    label: 'Add person',
    tone: AppChipTone.primary,
    selected: true,
    dashed: compact,
    size: compact ? ChipSize.chip : ChipSize.control,
    onTap: _noop,
  );
  final lines = [
    for (final p in const ['Lee  ฿200', 'Mai  ฿150'])
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Text(p),
      ),
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (compact)
        DraftFieldRow(label: 'Split', dense: true, child: chip)
      else
        DetailRow(label: 'Split', trailing: chip),
      if (people) ...lines,
    ],
  );
}

const _tagFood = Tag(
  id: 't1',
  name: 'lunch',
  iconCode: IconCode(iconColors: ['#E67E22']),
);
const _tagWork = Tag(
  id: 't2',
  name: 'work',
  iconCode: IconCode(iconColors: ['#3F8EFC']),
);
const _tagTrip = Tag(id: 't3', name: 'trip');

const _catFood = Category(
  id: 'c1',
  name: 'อาหาร',
  type: CategoryType.expense,
  iconCode: IconCode(iconColors: ['#E67E22']),
);
const _catSalary = Category(
  id: 'c2',
  name: 'เงินเดือน',
  type: CategoryType.income,
  iconCode: IconCode(iconColors: ['#2ECC71']),
);

class _TransactionsPage extends StatefulWidget {
  const _TransactionsPage();

  @override
  State<_TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<_TransactionsPage> {
  final _amount = TextEditingController(text: '1,250');
  final _title = TextEditingController(text: 'ข้าวมันไก่');
  final _empty = TextEditingController();
  TransactionType _type = TransactionType.expense;
  TransactionType _debtDir = TransactionType.expense;
  bool _repay = false;
  int _linkMode = 1;
  String _last = '—';

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _empty.dispose();
    super.dispose();
  }

  void _note(String s) => setState(() => _last = s);

  Future<void> _openForm(bool chipLayout) async {
    final controller = DraftFormController();
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: DraftForm(
            controller: controller,
            chipLayout: chipLayout,
            autofocus: false,
          ),
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCats = const [_catFood, _catSalary];
    final sample = Transaction(
      id: 'demo',
      accountId: 'a',
      type: TransactionType.expense,
      amount: 540,
      date: '2026-10-12',
      description: 'ข้าวมันไก่',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'LinkSectionFrame — the whole ผูกกับ block',
          note:
              'The recurring row (optional), the LinkModeBar, then the picked '
              'tab\'s card, with the kit gap between. The feature (LinkSection) '
              'only wires state into it. "+ เลือกคนจ่าย" = SplitPickChip.',
          child: LinkSectionFrame(
            bar: LinkModeBar<int>(
              selected: 2,
              onChanged: (_) {},
              tabs: const [
                AppTab(value: 0, label: 'ส่วนตัว', icon: AppIcons.wallet),
                AppTab(value: 1, label: 'แบ่ง', icon: AppIcons.split),
                AppTab(value: 2, label: 'จ่ายแทน', icon: AppIcons.contact),
                AppTab(value: 3, label: 'อีเวนต์', icon: AppIcons.project),
              ],
            ),
            card: ShareCard(
              title: 'ใครจ่ายแทน',
              rows: [
                ShareRow(
                  avatar: const SizedBox.square(dimension: SplitRow.avatarSize),
                  name: SplitPickChip(label: 'เลือกคนจ่าย', onTap: () {}),
                  amount: ShareAmountField(value: 120, onChanged: null),
                ),
              ],
            ),
          ),
        ),
        HubDemo(
          title: 'LinkModeBar + ShareCard — quick create "ผูกกับ"',
          note:
              '"ผูกกับ" and its pill tabs on one row (4 tabs: only the selected '
              'one shows its icon, and only when it fits). Each tab but '
              'ส่วนตัว shows ONE ShareCard: a header with its chips, '
              'ShareRows (SplitRow + an optional tag), the status line. All '
              'three views edit one data set (owner 2026-10-21).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinkModeBar<int>(
                selected: _linkMode,
                onChanged: (v) => setState(() => _linkMode = v),
                tabs: const [
                  AppTab(value: 0, label: 'ส่วนตัว', icon: AppIcons.wallet),
                  AppTab(value: 1, label: 'แบ่ง', icon: AppIcons.split),
                  AppTab(value: 2, label: 'จ่ายแทน', icon: AppIcons.contact),
                  AppTab(value: 3, label: 'อีเวนต์', icon: AppIcons.project),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_linkMode == 1)
                ShareCard(
                  title: 'แบ่งให้ใคร',
                  actions: [
                    AppChip(label: 'หารเท่ากัน', onTap: () {}),
                    AppChip(label: 'เพิ่มคน', icon: AppIcons.add, onTap: () {}),
                  ],
                  rows: [
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.muted('ส่วนของฉัน'),
                      amount: ShareAmountField(
                        value: 41,
                        auto: true,
                        onChanged: (_) {},
                      ),
                      trailing: AutoToggleChip(value: true, onChanged: (_) {}),
                    ),
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.picked('บอส ทดสอบ'),
                      amount: ShareAmountField(value: 82, onChanged: (_) {}),
                      trailing: SplitRowAction(
                        icon: AppIcons.close,
                        tooltip: 'Remove',
                        onTap: () {},
                      ),
                    ),
                  ],
                  status: const ShareStatus('✓ แบ่งครบแล้ว', ok: true),
                )
              else if (_linkMode == 2)
                ShareCard(
                  title: 'ใครจ่าย และจ่ายเท่าไหร่',
                  actions: [AppChip(label: 'หารเท่ากัน', onTap: () {})],
                  rows: [
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.muted('ฉันจ่ายเอง'),
                      amount: ShareAmountField(value: 0, onChanged: (_) {}),
                      trailing: AutoToggleChip(value: false, onChanged: (_) {}),
                    ),
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.picked('ลี ทดสอบ'),
                      amount: ShareAmountField(value: 100, onChanged: (_) {}),
                      trailing: SplitRowAction(
                        icon: AppIcons.close,
                        tooltip: 'Remove',
                        onTap: () {},
                      ),
                    ),
                  ],
                  status: const ShareStatus('ยังขาด ฿23', ok: false),
                )
              else if (_linkMode == 3)
                ShareCard(
                  // No title: the EventPickChip takes the header.
                  headerLeading: EventPickChip(
                    name: 'ทริปเขาใหญ่',
                    onTap: () => _note('pick event'),
                    onClear: () => _note('event removed'),
                  ),
                  rows: [
                    const ShareSubhead(title: 'ใครจ่าย'),
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: SplitRowName.picked('ลี ทดสอบ', onTap: () {}),
                      amount: const ShareAmountField(
                        value: 123,
                        onChanged: null,
                      ),
                    ),
                    ShareSubhead(
                      title: 'ใครอยู่ในบิล',
                      actions: [
                        AppChip(label: 'หารเท่ากัน', onTap: () {}),
                        AppChip(
                          label: 'เพิ่มคน',
                          icon: AppIcons.add,
                          onTap: () {},
                        ),
                      ],
                    ),
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.muted('ฉัน'),
                      amount: ShareAmountField(
                        value: 41,
                        auto: true,
                        onChanged: (_) {},
                      ),
                      trailing: AutoToggleChip(value: true, onChanged: (_) {}),
                    ),
                    ShareRow(
                      avatar: const SizedBox.square(
                        dimension: SplitRow.avatarSize,
                      ),
                      name: const SplitRowName.picked('มาตาก'),
                      amount: ShareAmountField(value: 41, onChanged: (_) {}),
                      trailing: SplitRowAction(
                        icon: AppIcons.close,
                        tooltip: 'Remove',
                        onTap: () {},
                      ),
                      tag: const AppChip(
                        label: 'ใหม่ · เพิ่มเข้าอีเวนต์',
                        size: ChipSize.mini,
                        tone: AppChipTone.info,
                        selected: true,
                      ),
                    ),
                  ],
                  status: const ShareStatus('เกินยอด ฿5', ok: false),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'TransactionHeroCard — type switch, editing',
          note:
              'Inline layout (a transaction). Tap a chip or swipe the card to '
              'change type; the border and amount follow the type colour.',
          child: TransactionHeroCard(
            type: _type,
            amount: _amount,
            title: _title,
            dateLabel: 'Today',
            inline: true,
            onTypeChanged: (t) => setState(() => _type = t),
            onPickDate: () {},
          ),
        ),
        HubDemo(
          title: 'EntryCard — quick create / pending drafts',
          note:
              'ONE card for what you fill in first: type | date, description | '
              'amount, the wallet chip row and the category chip row (a '
              'transfer: from / to wallet rows, no category). The tags row sits '
              'outside, right below. The first chip of a row is the pick chip: dashed '
              'until something is picked, then the picked item (highlighted, tap = '
              'the full picker) — never repeated among the quick options. '
              'Values and callbacks only: the rows are '
              'slots (built from resolved display data, so a draft can feed '
              'it). "Missing" rows get a danger outline.',
          child: Column(
            children: [
              EntryCard(
                type: _type,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                onTypeChanged: (t) => setState(() => _type = t),
                onPickDate: () {},
                walletRow: const _DemoChipRow(
                  icon: AppIcons.wallet,
                  blank: 'เลือกกระเป๋า',
                  chips: ['กสิกร', 'เงินสด'],
                  selected: 0,
                ),
                toWalletRow: const _DemoChipRow(
                  icon: AppIcons.wallet,
                  blank: 'เลือกกระเป๋าปลายทาง',
                  chips: ['ออมทรัพย์', 'เงินสด'],
                  selected: 0,
                ),
                categoryRow: const _DemoChipRow(
                  icon: AppIcons.category,
                  blank: 'เลือกหมวด',
                  chips: ['อาหาร', 'เดินทาง', 'ของใช้'],
                  selected: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _DemoChipRow(
                icon: AppIcons.tag,
                chips: ['#งาน', '#กิน'],
                selected: -1,
              ),
              const SizedBox(height: AppSpacing.md),
              EntryCard(
                type: TransactionType.expense,
                amount: TextEditingController(),
                title: TextEditingController(),
                dateLabel: 'Today',
                onTypeChanged: (_) {},
                missing: const {EntryField.wallet, EntryField.category},
                walletRow: const _DemoChipRow(
                  icon: AppIcons.wallet,
                  blank: 'เลือกกระเป๋า',
                  chips: ['กสิกร', 'เงินสด'],
                  selected: -1,
                ),
                categoryRow: const _DemoChipRow(
                  icon: AppIcons.category,
                  blank: 'เลือกหมวด',
                  chips: ['อาหาร', 'เดินทาง'],
                  selected: -1,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'EntryCard(debt / repay) — quick create in debt mode',
          note:
              'Debt mode has two sides (owner 2026-10-21), picked by a '
              'SegmentedChoice [จดหนี้ | จ่ายคืน] above the card. debt: true = '
              'recording a debt: the type chips say รอรับ / รอจ่าย in '
              'the DEBT-STATE colours (txWordsColor ← debtStateColor: รอรับ '
              'green, รอจ่าย red; the card tint follows). repay: true = a '
              'repayment (a real '
              'transaction): จ่ายคืน / รับคืน, a wallet always, "หลังบันทึก '
              'เหลือ ฿x" / "เคลียร์ครบ" under the amount. Toggle below.',
          child: EntryCard(
            debt: true,
            repay: _repay,
            type: _debtDir,
            amount: _amount,
            title: _title,
            dateLabel: 'Today',
            onTypeChanged: (t) => setState(() => _debtDir = t),
            onPickDate: () {},
            amountNote: GestureDetector(
              onTap: () => setState(() => _repay = !_repay),
              child: Text(
                _repay
                    ? 'After saving: ฿230 left  (tap: debt words)'
                    : _debtDir == TransactionType.expense
                    ? 'After saving: Mom owes you ฿1,450  (tap: repay words)'
                    : 'After saving: Mom owes you ฿-1,050  (tap: repay words)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            walletRow: const _DemoChipRow(
              icon: AppIcons.wallet,
              blank: 'เลือกกระเป๋า',
              chips: ['ไม่ผูก', 'กสิกร', 'เงินสด'],
              selected: 0,
            ),
            categoryRow: const _DemoChipRow(
              icon: AppIcons.contact,
              blank: 'เลือกคน',
              chips: ['แม่', 'บีม', 'โอ๊ต'],
              selected: 0,
            ),
          ),
        ),
        const HubDemo(
          title: 'EntryCardSkeleton — a draft’s first load',
          note:
              'แก้ร่าง opens at once and shows this until the form options '
              'land, then the draft fills the real EntryCard. Built from the '
              'same tokens (top row = control height, the hero field rows, '
              'chip rows itemGap apart), so nothing jumps; a pixel test keeps '
              'it equal to the real card at text scale 1.0 and 1.3. A new '
              'transaction shows the real card at once (typing starts right '
              'away); only its chip rows shimmer.',
          child: Column(
            children: [
              EntryCardSkeleton(),
              SizedBox(height: AppSpacing.md),
              EntryCardSkeleton(editing: false),
            ],
          ),
        ),
        HubDemo(
          title: 'TransactionHeroCard — expense / income / transfer',
          child: Column(
            children: [
              for (final t in TransactionType.values) ...[
                TransactionHeroCard(
                  type: t,
                  amount: _amount,
                  title: _title,
                  dateLabel: 'Today',
                  inline: true,
                  onTypeChanged: (_) {},
                  onPickDate: () {},
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'TransactionHeroCard(extraTypeChip) — one more type',
          note:
              'An event bill sheet adds "จ่ายคืน" after the built-in chips; '
              'extraTypeSelected shows every built-in chip unpicked and the '
              'caller paints the card (accentColor).',
          child: TransactionHeroCard(
            type: TransactionType.expense,
            amount: _amount,
            title: _title,
            dateLabel: 'Today',
            inline: true,
            allowTransfer: false,
            onTypeChanged: (_) {},
            onPickDate: () {},
            compact: true,
            showTitle: false,
            extraTypeSelected: true,
            accentColor: ModuleColors.of(context).planning,
            extraTypeChip: AppChip(
              label: 'จ่ายคืน',
              icon: AppIcons.transfer,
              color: ModuleColors.of(context).planning,
              selected: true,
            ),
          ),
        ),
        HubDemo(
          title:
              'TransactionHeroCard — view mode, amount note, empty title, stacked',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionHeroCard(
                type: TransactionType.expense,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                inline: true,
                editing: false,
                onEdit: () => _note('hero: edit tapped'),
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionHeroCard(
                type: TransactionType.income,
                amount: _amount,
                title: _empty,
                dateLabel: 'Yesterday',
                inline: true,
                editing: false,
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionHeroCard(
                type: TransactionType.expense,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                inline: true,
                onTypeChanged: (_) {},
                amountNote: Text(
                  'Your share ฿625 | others owe ฿625',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionHeroCard(
                type: TransactionType.expense,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                allowTransfer: false,
                amountLabel: 'Per instalment',
                amountError: 'Could not save',
                onTypeChanged: (_) {},
                onPickDate: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'txTypeChip | categoryAppChip | tagAppChip',
          note: 'Chip builders — one tap target each, control height.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HubRow(
                cells: [
                  HubCell(
                    caption: 'txTypeChip (null = all)',
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        txTypeChip(context, type: null, selected: true),
                        for (final t in TransactionType.values)
                          txTypeChip(context, type: t, selected: false),
                      ],
                    ),
                  ),
                  HubCell(
                    caption:
                        'txTypeChip: the chosen one is solid (it does nothing '
                        'on tap); the others are dashed with no icon',
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        txTypeChip(
                          context,
                          type: TransactionType.expense,
                          selected: true,
                        ),
                        txTypeChip(
                          context,
                          type: TransactionType.income,
                          selected: false,
                          dashed: true,
                        ),
                        txTypeChip(
                          context,
                          type: TransactionType.transfer,
                          selected: false,
                          dashed: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              HubRow(
                cells: [
                  HubCell(
                    caption:
                        'FlowCards: [from] → [to] (quick create transfer / '
                        'debt / saving) — two-line cards, no row icon, no '
                        'suggested chips; the arrow swaps',
                    child: FlowCards(
                      from: PickCard(
                        label: 'From',
                        value: 'KBank',
                        leading: const PickCardEmptyIcon(
                          AppIcons.wallet,
                          size: 32,
                        ),
                        dense: true,
                        editable: true,
                        onTap: () {},
                      ),
                      to: PickCard(
                        label: 'To',
                        placeholder: 'Pick a wallet',
                        leading: const PickCardEmptyIcon(
                          AppIcons.wallet,
                          size: 32,
                        ),
                        dense: true,
                        onTap: () {},
                      ),
                      swapTooltip: 'Swap',
                      onSwap: () {},
                    ),
                  ),
                ],
              ),
              HubRow(
                cells: [
                  HubCell(
                    caption: 'categoryAppChip',
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        categoryAppChip(
                          context,
                          _catFood,
                          all: allCats,
                          onTap: () {},
                        ),
                        categoryAppChip(
                          context,
                          _catSalary,
                          all: allCats,
                          selected: true,
                          onTap: () {},
                        ),
                        categoryAppChip(
                          context,
                          _catFood,
                          all: allCats,
                          size: ChipSize.mini,
                        ),
                      ],
                    ),
                  ),
                  HubCell(
                    caption: 'tagAppChip',
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        tagAppChip(context, _tagFood, onTap: () {}),
                        tagAppChip(
                          context,
                          _tagWork,
                          selected: false,
                          onTap: () {},
                        ),
                        tagAppChip(context, _tagTrip, size: ChipSize.mini),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title:
              'SplitEventSection — compact (quick create / pending) and full (detail)',
          note:
              'One organism, two variants. compact: one-line green header, rows '
              'like the Note row (72 px muted label column, chips beside it). '
              'full: the detail page section. Static samples; the event is an '
              'entity chip (empty = add chip, locked = chip + lock).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final variant in SplitEventVariant.values) ...[
                Text(
                  variant.name,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final (label, people, slot) in [
                  ('empty', false, const SplitEventSlot(onTap: _noop)),
                  (
                    'with people',
                    true,
                    const SplitEventSlot(onTap: _noop, onClear: _noop),
                  ),
                  (
                    'with event',
                    false,
                    const SplitEventSlot(
                      name: 'Trip | 12 Oct',
                      onTap: _noop,
                      onClear: _noop,
                    ),
                  ),
                  (
                    'locked event',
                    false,
                    const SplitEventSlot(name: 'Trip | 12 Oct', locked: true),
                  ),
                ]) ...[
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  SplitEventSection(
                    first: true,
                    variant: variant,
                    collapsible: variant == SplitEventVariant.compact,
                    event: slot,
                    recurring: label == 'with event'
                        ? const SplitRecurringSlot(
                            name: 'Car loan',
                            periodLabel: 'Period 16 Oct',
                            onTap: _noop,
                          )
                        : const SplitRecurringSlot(onTap: _noop),
                    splits: _splitSample(variant, people),
                    helper: people
                        ? 'This split will live in the event.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'TxTagStrip',
          note: 'A transaction’s tags in view mode, under the hero.',
          child: const TxTagStrip(tags: [_tagFood, _tagWork, _tagTrip]),
        ),
        HubDemo(
          title: 'TransactionTile',
          note: 'Live: reads the wallets / categories cubits for icons.',
          child: TransactionTile(transaction: sample, onTap: () {}),
        ),
        HubDemo(
          title: 'DraftForm — normal and chipLayout',
          note:
              'Live data: opens the real form (a local DraftFormController) '
              'in a dialog. chipLayout is the pending drafts layout.',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                label: 'Open DraftForm',
                variant: AppButtonVariant.outlined,
                onPressed: () => _openForm(false),
              ),
              AppButton(
                label: 'Open DraftForm (chipLayout)',
                variant: AppButtonVariant.outlined,
                onPressed: () => _openForm(true),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PeriodSummaryCard',
          note: 'Live data: fetches the real summary from the server.',
          child: const PeriodSummaryCard(),
        ),
        HubDemo(
          title: 'Quick create',
          note:
              'Live data: opens against the real app cubits. The pickers are '
              'on the entity pickers page.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
                    label: 'showQuickCreateSheet',
                    onPressed: () async {
                      final r = await showQuickCreateSheet(context);
                      _note('quick create saved: $r');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Last result: $_last',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A static stand-in for the wallet / category / tag chip rows (the real ones
/// read cubits). With a [blank] pick label the FIRST slot is the pick chip:
/// dashed while nothing is picked ([selected] -1), else the picked item
/// (highlighted, tap = the full picker); the other chips never repeat it.
class _DemoChipRow extends StatelessWidget {
  const _DemoChipRow({
    required this.icon,
    required this.chips,
    required this.selected,
    this.blank,
  });

  final IconData icon;
  final String? blank;
  final List<String> chips;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final first = blank == null
        ? null
        : selected >= 0
        ? AppChip(label: chips[selected], selected: true, onTap: () {})
        : AppChip(
            label: blank!,
            icon: AppIcons.add,
            dashed: true,
            onTap: () {},
          );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppIcon(
            icon,
            size: AppIconSize.md,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          if (first != null) ...[first, const SizedBox(width: AppSpacing.xs)],
          for (final (i, c) in chips.indexed)
            if (blank == null || i != selected) ...[
              AppChip(
                label: c,
                selected: blank == null && i == selected,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
        ],
      ),
    );
  }
}
