import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../../features/categories/domain/category.dart';
import '../../features/categories/domain/category_type.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/categories/presentation/widgets/category_chip.dart';
import '../../features/categories/presentation/widgets/category_picker_sheet.dart';
import '../../features/contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../features/tags/domain/tag.dart';
import '../../features/tags/presentation/widgets/tag_chip.dart';
import '../../features/tags/presentation/widgets/tag_picker_sheet.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/transactions/presentation/widgets/account_picker_sheet.dart';
import '../../features/transactions/presentation/widgets/draft_form.dart';
import '../../features/transactions/presentation/widgets/event_pick.dart';
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
  final chip = PpForgeChip(
    icon: PpForgeIcons.add,
    label: 'Add person',
    tone: PpForgeChipTone.primary,
    selected: true,
    dashed: compact,
    size: compact ? ChipSize.chip : ChipSize.control,
    onTap: _noop,
  );
  final lines = [
    for (final p in const ['Lee  ฿200', 'Mai  ฿150'])
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : PpForgeSpacing.lg,
          vertical: PpForgeSpacing.xs,
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
  bool _selected = false;
  bool _selected2 = true;
  String _last = '—';

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _empty.dispose();
    super.dispose();
  }

  Widget _leading(IconData icon, Color color) =>
      IconTile(icon: icon, color: color, size: 36);

  void _note(String s) => setState(() => _last = s);

  Future<void> _openForm(bool chipLayout) async {
    final controller = DraftFormController();
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PpForgeSpacing.lg),
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
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final allCats = const [_catFood, _catSalary];
    final accounts = context.read<AccountsCubit>().state.accounts;
    final categories = context.read<CategoriesCubit>().state.categories;
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
          title: 'TxRow — the ONE transaction / pending row',
          note:
              'Two lines and an amount. Callers resolve names, icons and '
              'colours; the row is domain-agnostic.',
          child: Column(
            children: [
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ข้าวมันไก่',
                amount: -540,
                category: 'อาหาร',
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.income, palette.income),
                title: 'เงินเดือน',
                amount: 42000,
                walletLabel: 'กสิกร',
                walletIcon: const Icon(PpForgeIcons.wallet, size: 12),
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ค่ากาแฟ',
                amount: -95,
                source: const PpForgeChip(
                  label: 'Manual',
                  tone: PpForgeChipTone.info,
                  selected: true,
                  size: ChipSize.mini,
                ),
                category: 'อาหาร',
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ข้าวกลางวัน',
                amount: -180,
                category: 'อาหาร',
                tags: [
                  TextSpan(
                    text: '#lunch',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '#work',
                    style: TextStyle(
                      color: palette.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ค่าอาหารทริป',
                amount: -2400,
                category: 'อาหาร',
                hasSplits: true,
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.transfer, palette.primary),
                title: 'โอนเข้าออมทรัพย์',
                amount: 5000,
                tone: MoneyTone.plain,
                extra: '→ ออมทรัพย์',
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'Draft with a warning',
                amount: -300,
                warning: 'Pick a wallet before submitting',
                source: const PpForgeChip(
                  label: 'Text',
                  tone: PpForgeChipTone.primary,
                  selected: true,
                  size: ChipSize.mini,
                ),
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'Selectable (off)',
                amount: -120,
                category: 'อาหาร',
                select: SelectCheck(
                  value: _selected,
                  onTap: () => setState(() => _selected = !_selected),
                ),
                onTap: () => setState(() => _selected = !_selected),
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'Selectable (on)',
                amount: -120,
                category: 'อาหาร',
                select: SelectCheck(
                  value: _selected2,
                  onTap: () => setState(() => _selected2 = !_selected2),
                ),
                onTap: () => setState(() => _selected2 = !_selected2),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'TxRow — recurring / linked / status / archived markers',
          note:
              'recurring adds 🔁 + progress ("3/12"), linked adds 🔗 (the '
              'EventBillRow glyph); metaLeading leads line 2 with its own '
              'style (a DueText keeps its overdue tint), meta adds texts; '
              'statusChip is a mini chip on line 1 after the wallet; dimmed '
              'fades the row (archived). None changes the row height.',
          child: Column(
            children: [
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'Netflix',
                amount: -419,
                walletLabel: 'กสิกร',
                walletIcon: const Icon(PpForgeIcons.wallet, size: 12),
                metaLeading: DueText(
                  date: DateTime.now().add(const Duration(days: 3)),
                  withDate: false,
                ),
                meta: const ['ทุกวันที่ 3'],
                recurring: true,
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ผ่อนโทรศัพท์',
                amount: -1290,
                metaLeading: DueText(
                  date: DateTime.now().subtract(const Duration(days: 2)),
                  withDate: false,
                ),
                category: 'ช้อปปิ้ง',
                recurring: true,
                progress: '3/12',
                linked: true,
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.expense, palette.expense),
                title: 'ค่ายิม',
                amount: -900,
                category: 'สุขภาพ',
                meta: const ['ทุกเดือน'],
                recurring: true,
                statusChip: const PpForgeChip(
                  label: 'หยุดชั่วคราว',
                  tone: PpForgeChipTone.warning,
                  size: ChipSize.mini,
                ),
              ),
              const PpForgeDivider(),
              TxRow(
                leading: _leading(PpForgeIcons.income, palette.income),
                title: 'ค่าเช่าห้อง',
                amount: 6000,
                category: 'รายได้อื่น',
                recurring: true,
                progress: '12/12',
                statusChip: const PpForgeChip(
                  label: 'เก็บถาวร',
                  size: ChipSize.mini,
                ),
                dimmed: true,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'TxHeroCard — type switch, editing',
          note:
              'Inline layout (a transaction). Tap a chip or swipe the card to '
              'change type; the border and amount follow the type colour.',
          child: TxHeroCard(
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
              'ONE card for what you fill in first: type · date, description · '
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
                  icon: PpForgeIcons.wallet,
                  blank: 'เลือกกระเป๋า',
                  chips: ['กสิกร', 'เงินสด'],
                  selected: 0,
                ),
                toWalletRow: const _DemoChipRow(
                  icon: PpForgeIcons.wallet,
                  blank: 'เลือกกระเป๋าปลายทาง',
                  chips: ['ออมทรัพย์', 'เงินสด'],
                  selected: 0,
                ),
                categoryRow: const _DemoChipRow(
                  icon: PpForgeIcons.category,
                  blank: 'เลือกหมวด',
                  chips: ['อาหาร', 'เดินทาง', 'ของใช้'],
                  selected: 0,
                ),
              ),
              const SizedBox(height: PpForgeSpacing.sm),
              const _DemoChipRow(
                icon: PpForgeIcons.tag,
                chips: ['#งาน', '#กิน'],
                selected: -1,
              ),
              const SizedBox(height: PpForgeSpacing.md),
              EntryCard(
                type: TransactionType.expense,
                amount: TextEditingController(),
                title: TextEditingController(),
                dateLabel: 'Today',
                onTypeChanged: (_) {},
                missing: const {EntryField.wallet, EntryField.category},
                walletRow: const _DemoChipRow(
                  icon: PpForgeIcons.wallet,
                  blank: 'เลือกกระเป๋า',
                  chips: ['กสิกร', 'เงินสด'],
                  selected: -1,
                ),
                categoryRow: const _DemoChipRow(
                  icon: PpForgeIcons.category,
                  blank: 'เลือกหมวด',
                  chips: ['อาหาร', 'เดินทาง'],
                  selected: -1,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'EntryCard(debt: true) — quick create in debt mode',
          note:
              'The same card (owner 2026-10-12): Paid / Received replace the '
              'type (paid = the expense colour: I paid them; received = the '
              'income colour), the PERSON chip row replaces the category, the '
              'wallet row adds "ไม่ผูก" (no wallet = ledger only), and the '
              'line under the amount shows the result. Tags sit under the card '
              'only while a wallet is picked.',
          child: EntryCard(
            debt: true,
            type: _debtDir,
            amount: _amount,
            title: _title,
            dateLabel: 'Today',
            onTypeChanged: (t) => setState(() => _debtDir = t),
            onPickDate: () {},
            amountNote: Text(
              _debtDir == TransactionType.expense
                  ? 'After saving: Mom owes you ฿1,450'
                  : 'After saving: Mom owes you ฿-1,050',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            walletRow: const _DemoChipRow(
              icon: PpForgeIcons.wallet,
              blank: 'เลือกกระเป๋า',
              chips: ['ไม่ผูก', 'กสิกร', 'เงินสด'],
              selected: 0,
            ),
            categoryRow: const _DemoChipRow(
              icon: PpForgeIcons.contact,
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
              SizedBox(height: PpForgeSpacing.md),
              EntryCardSkeleton(editing: false),
            ],
          ),
        ),
        HubDemo(
          title: 'TxHeroCard — expense / income / transfer',
          child: Column(
            children: [
              for (final t in TransactionType.values) ...[
                TxHeroCard(
                  type: t,
                  amount: _amount,
                  title: _title,
                  dateLabel: 'Today',
                  inline: true,
                  onTypeChanged: (_) {},
                  onPickDate: () {},
                  compact: true,
                ),
                const SizedBox(height: PpForgeSpacing.md),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'TxHeroCard — view mode, amount note, empty title, stacked',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TxHeroCard(
                type: TransactionType.expense,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                inline: true,
                editing: false,
                onEdit: () => _note('hero: edit tapped'),
              ),
              const SizedBox(height: PpForgeSpacing.md),
              TxHeroCard(
                type: TransactionType.income,
                amount: _amount,
                title: _empty,
                dateLabel: 'Yesterday',
                inline: true,
                editing: false,
              ),
              const SizedBox(height: PpForgeSpacing.md),
              TxHeroCard(
                type: TransactionType.expense,
                amount: _amount,
                title: _title,
                dateLabel: 'Today',
                inline: true,
                onTypeChanged: (_) {},
                amountNote: Text(
                  'Your share ฿625 · others owe ฿625',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: PpForgeSpacing.md),
              TxHeroCard(
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
          title: 'txTypeChip · categoryAppChip · tagAppChip',
          note: 'Chip builders — one tap target each, control height.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HubRow(
                cells: [
                  HubCell(
                    caption: 'txTypeChip (null = all)',
                    child: Wrap(
                      spacing: PpForgeSpacing.xs,
                      children: [
                        txTypeChip(context, type: null, selected: true),
                        for (final t in TransactionType.values)
                          txTypeChip(context, type: t, selected: false),
                      ],
                    ),
                  ),
                  HubCell(
                    caption: 'txTypeChip selected / locked',
                    child: Wrap(
                      spacing: PpForgeSpacing.xs,
                      children: [
                        txTypeChip(
                          context,
                          type: TransactionType.expense,
                          selected: true,
                        ),
                        txTypeChip(
                          context,
                          type: TransactionType.income,
                          selected: true,
                          locked: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              HubRow(
                cells: [
                  HubCell(
                    caption: 'categoryAppChip',
                    child: Wrap(
                      spacing: PpForgeSpacing.xs,
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
                      spacing: PpForgeSpacing.xs,
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
                const SizedBox(height: PpForgeSpacing.xs),
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
                      name: 'Trip · 12 Oct',
                      onTap: _noop,
                      onClear: _noop,
                    ),
                  ),
                  (
                    'locked event',
                    false,
                    const SplitEventSlot(name: 'Trip · 12 Oct', locked: true),
                  ),
                ]) ...[
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  SplitEventSection(
                    first: true,
                    variant: variant,
                    collapsible: variant == SplitEventVariant.compact,
                    event: slot,
                    splits: _splitSample(variant, people),
                    helper: people
                        ? 'This split will live in the event.'
                        : null,
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
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
            spacing: PpForgeSpacing.md,
            runSpacing: PpForgeSpacing.md,
            children: [
              PpForgeButton(
                label: 'Open DraftForm',
                variant: PpForgeButtonVariant.outlined,
                onPressed: () => _openForm(false),
              ),
              PpForgeButton(
                label: 'Open DraftForm (chipLayout)',
                variant: PpForgeButtonVariant.outlined,
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
          title: 'Pickers and quick create',
          note: 'Live data: these open against the real app cubits.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: PpForgeSpacing.md,
                runSpacing: PpForgeSpacing.md,
                children: [
                  PpForgeButton(
                    label: 'showAccountPickerSheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showAccountPickerSheet(
                        context: context,
                        accounts: accounts,
                        allowNone: true,
                      );
                      _note('account: ${r.runtimeType}');
                    },
                  ),
                  PpForgeButton(
                    label: 'showCategoryPickerSheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showCategoryPickerSheet(
                        context: context,
                        categories: categories,
                        type: CategoryType.expense,
                      );
                      _note('category: ${r.runtimeType}');
                    },
                  ),
                  PpForgeButton(
                    label: 'showTagPickerSheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showTagPickerSheet(
                        context,
                        selected: const {},
                      );
                      _note('tags: ${r?.length}');
                    },
                  ),
                  PpForgeButton(
                    label: 'showContactPickerSheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showContactPickerSheet(context);
                      _note('contact: ${r.runtimeType}');
                    },
                  ),
                  PpForgeButton(
                    label: 'showEventTargetSheet',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showEventTargetSheet(
                        context,
                        suggestedName: 'ทริป',
                      );
                      _note('event: ${r.runtimeType}');
                    },
                  ),
                  PpForgeButton(
                    label: 'showQuickCreateSheet',
                    onPressed: () async {
                      final r = await showQuickCreateSheet(context);
                      _note('quick create saved: $r');
                    },
                  ),
                ],
              ),
              const SizedBox(height: PpForgeSpacing.sm),
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
        ? PpForgeChip(label: chips[selected], selected: true, onTap: () {})
        : PpForgeChip(
            label: blank!,
            icon: PpForgeIcons.add,
            dashed: true,
            onTap: () {},
          );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PpForgeIcon(
            icon,
            size: PpForgeIconSize.md,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: PpForgeSpacing.xs),
          if (first != null) ...[
            first,
            const SizedBox(width: PpForgeSpacing.xs),
          ],
          for (final (i, c) in chips.indexed)
            if (blank == null || i != selected) ...[
              PpForgeChip(
                label: c,
                selected: blank == null && i == selected,
                onTap: () {},
              ),
              const SizedBox(width: PpForgeSpacing.xs),
            ],
        ],
      ),
    );
  }
}
