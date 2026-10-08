import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../domain/pending_transaction.dart';
import '../cubit/pending_cubit.dart';

/// `/pending/new` — jot several drafts at once (owner design 2026-10-08).
/// A row needs only an amount; category / wallet / date are optional chips
/// and the rest (transfer, splits, tags) is done later by opening the draft.
/// "เก็บเป็นร่าง" parks them in รอยืนยัน; "ยืนยันเลยทั้งหมด" also submits.
class PendingBatchAddPage extends StatefulWidget {
  const PendingBatchAddPage({super.key});

  @override
  State<PendingBatchAddPage> createState() => _PendingBatchAddPageState();
}

class _Row {
  _Row() : date = DateTime.now();
  final amount = TextEditingController();
  final note = TextEditingController();
  bool income = false;
  Category? category;
  Account? account;
  bool accountPicked = false;
  DateTime date;

  void dispose() {
    amount.dispose();
    note.dispose();
  }
}

class _PendingBatchAddPageState extends State<PendingBatchAddPage> {
  final List<_Row> _rows = [_Row()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<_Row> get _filled =>
      _rows.where((r) => (AmountField.parse(r.amount.text) ?? 0) > 0).toList();

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  PendingDraft _draftOf(_Row r) {
    final note = r.note.text.trim();
    return PendingDraft(
      type: r.income ? TransactionType.income : TransactionType.expense,
      amount: AmountField.parse(r.amount.text),
      accountId: r.account?.id,
      categoryId: r.category?.id,
      date: _ymd(r.date),
      note: note.isEmpty ? null : note,
    );
  }

  Future<void> _save({required bool submit}) async {
    final l = AppLocalizations.of(context)!;
    final rows = _filled;
    if (rows.isEmpty) {
      showAppSnackBar(context, l.quickAmountRequired, tone: Tone.warning);
      return;
    }
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final created = await pending.add([for (final r in rows) _draftOf(r)]);
      var msg = l.pendingSavedCount(created.length);
      if (submit) {
        final r = await pending.submit([for (final p in created) p.id]);
        if (r.submitted.isNotEmpty) {
          await Future.wait([accounts.load(), txCubit.load()]);
        }
        msg = l.pendingResult(r.submitted.length, r.failed.length);
      }
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final n = _filled.length;
    return Scaffold(
      appBar: AppTopBar(
        title: l.pendingAdd,
        showBack: true,
        showUniversal: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Text(l.pendingBatchHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              children: [
                for (var i = 0; i < _rows.length; i++) ...[
                  _RowCard(
                    key: ObjectKey(_rows[i]),
                    row: _rows[i],
                    autofocus: i == _rows.length - 1,
                    defaultAccount: accounts.firstOrNull,
                    onChanged: () => setState(() {}),
                    onRemove: _rows.length == 1
                        ? null
                        : () => setState(() => _rows.removeAt(i).dispose()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AddTile(
                  label: l.pendingAddRow,
                  variant: AddTileVariant.row,
                  onTap: () => setState(() => _rows.add(_Row())),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.pendingBatchMoreHint,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                AppSpacing.lg, AppSpacing.sm + MediaQuery.paddingOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: l.pendingSaveAsDrafts(n),
                  expand: true,
                  loading: _saving,
                  onPressed: n == 0 ? null : () => _save(submit: false),
                ),
                TextButton(
                  onPressed: _saving || n == 0 ? null : () => _save(submit: true),
                  child: Text(l.pendingSubmitAllNow(n)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.row,
    required this.autofocus,
    required this.defaultAccount,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _Row row;
  final bool autofocus;
  final Account? defaultAccount;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (!row.accountPicked) row.account = defaultAccount;

    Future<void> pickCategory() async {
      final r = await showCategoryPickerSheet(
        context: context,
        categories: context.read<CategoriesCubit>().state.categories,
        type: row.income ? CategoryType.income : CategoryType.expense,
        selected: row.category,
      );
      if (r == null) return;
      row.category = r is CategoryPickerSelected ? r.category : null;
      onChanged();
    }

    Future<void> pickAccount() async {
      final r = await showAccountPickerSheet(
        context: context,
        accounts: context.read<AccountsCubit>().state.accounts,
        selected: row.account,
        allowNone: true,
      );
      if (r == null) return;
      row.accountPicked = true;
      row.account = r is AccountPickerSelected ? r.account : null;
      onChanged();
    }

    Future<void> pickDate() async {
      final d = await showDatePicker(
        context: context,
        initialDate: row.date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (d == null) return;
      row.date = d;
      onChanged();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: const Text('−'), tooltip: l.transactionTypeExpense),
                  ButtonSegment(value: true, label: const Text('+'), tooltip: l.transactionTypeIncome),
                ],
                selected: {row.income},
                onSelectionChanged: (s) {
                  row.income = s.first;
                  row.category = null; // a category belongs to one type
                  onChanged();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: row.amount,
                  autofocus: autofocus,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsInputFormatter()],
                  onChanged: (_) => onChanged(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    isDense: true,
                    labelText: l.transactionFormAmountLabel,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: l.pendingRemoveRow,
                  icon: const Icon(AppIcons.close, size: 18),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: row.note,
            decoration: InputDecoration(
              hintText: l.quickNoteHint,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ActionChip(
                avatar: const Icon(AppIcons.category, size: 16),
                label: Text(row.category?.name ?? l.transactionFormCategoryLabel),
                onPressed: pickCategory,
              ),
              ActionChip(
                avatar: Icon(row.account == null ? AppIcons.noWallet : AppIcons.wallet,
                    size: 16),
                label: Text(row.account?.name ?? l.transactionFormAccountNone),
                onPressed: pickAccount,
              ),
              ActionChip(
                avatar: const Icon(AppIcons.date, size: 16),
                label: Text(DateFormatter.friendly(row.date,
                    today: l.commonToday,
                    yesterday: l.commonYesterday,
                    locale: Localizations.localeOf(context).languageCode)),
                onPressed: pickDate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
