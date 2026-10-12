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
import '../../features/transactions/presentation/widgets/tx_hero_card.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';

/// `/dev/domain/transactions` — the transaction row, hero card, chip
/// builders and the pieces that need live app data.
Widget buildTransactionsPage(BuildContext context) => const _TransactionsPage();

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
    final palette = Theme.of(context).extension<AppColors>()!;
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
                leading: _leading(AppIcons.expense, palette.expense),
                title: 'ข้าวมันไก่',
                amount: -540,
                category: 'อาหาร',
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.income, palette.income),
                title: 'เงินเดือน',
                amount: 42000,
                walletLabel: 'กสิกร',
                walletIcon: const Icon(AppIcons.wallet, size: 12),
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
                title: 'ค่ากาแฟ',
                amount: -95,
                source: const AppChip(
                  label: 'Manual',
                  tone: AppChipTone.info,
                  selected: true,
                  size: ChipSize.mini,
                ),
                category: 'อาหาร',
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
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
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
                title: 'ค่าอาหารทริป',
                amount: -2400,
                category: 'อาหาร',
                hasSplits: true,
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.transfer, palette.primary),
                title: 'โอนเข้าออมทรัพย์',
                amount: 5000,
                tone: MoneyTone.plain,
                extra: '→ ออมทรัพย์',
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
                title: 'Draft with a warning',
                amount: -300,
                warning: 'Pick a wallet before submitting',
                source: const AppChip(
                  label: 'Text',
                  tone: AppChipTone.primary,
                  selected: true,
                  size: ChipSize.mini,
                ),
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
                title: 'Selectable (off)',
                amount: -120,
                category: 'อาหาร',
                select: SelectCheck(
                  value: _selected,
                  onTap: () => setState(() => _selected = !_selected),
                ),
                onTap: () => setState(() => _selected = !_selected),
              ),
              const AppDivider(),
              TxRow(
                leading: _leading(AppIcons.expense, palette.expense),
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
                const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              TxHeroCard(
                type: TransactionType.income,
                amount: _amount,
                title: _empty,
                dateLabel: 'Yesterday',
                inline: true,
                editing: false,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
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
                      spacing: AppSpacing.xs,
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
          title: 'Pickers and quick create',
          note: 'Live data: these open against the real app cubits.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
                    label: 'showAccountPickerSheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showAccountPickerSheet(
                        context: context,
                        accounts: accounts,
                        allowNone: true,
                      );
                      _note('account: ${r.runtimeType}');
                    },
                  ),
                  AppButton(
                    label: 'showCategoryPickerSheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showCategoryPickerSheet(
                        context: context,
                        categories: categories,
                        type: CategoryType.expense,
                      );
                      _note('category: ${r.runtimeType}');
                    },
                  ),
                  AppButton(
                    label: 'showTagPickerSheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showTagPickerSheet(
                        context,
                        selected: const {},
                      );
                      _note('tags: ${r?.length}');
                    },
                  ),
                  AppButton(
                    label: 'showContactPickerSheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showContactPickerSheet(context);
                      _note('contact: ${r.runtimeType}');
                    },
                  ),
                  AppButton(
                    label: 'showEventTargetSheet',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final r = await showEventTargetSheet(
                        context,
                        suggestedName: 'ทริป',
                      );
                      _note('event: ${r.runtimeType}');
                    },
                  ),
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
