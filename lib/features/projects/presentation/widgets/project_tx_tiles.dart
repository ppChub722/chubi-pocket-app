import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/personal_debt.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../pages/project_transaction_form_page.dart';
import 'project_common.dart';

String projectTxDateLabel(BuildContext context, String ymd) {
  final l = AppLocalizations.of(context)!;
  final d = DateFormatter.parseDay(ymd);
  if (d == null) return ymd;
  return DateFormatter.friendly(d,
      today: l.commonToday,
      yesterday: l.commonYesterday,
      locale: Localizations.localeOf(context).languageCode);
}

/// Category bubble for a project row (snapshot name + icon on the row).
class ProjectTxIcon extends StatelessWidget {
  const ProjectTxIcon({required this.tx, this.size = 36, super.key});

  final ProjectTransaction tx;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final isExpense = tx.type == 'expense';
    final color = tx.categoryIconCode?.accentColorFor(palette) ??
        (isExpense ? palette.expense : palette.income);
    return IconBubble(
      icon: IconRegistry.get(tx.categoryIconCode?.icon,
          fallback: isExpense ? AppIcons.expense : AppIcons.income),
      color: color,
      size: size,
    );
  }
}

/// One board row + its split children. Tap the icon to tick ("I've settled
/// this") — when it's yours to settle, the "record in my book" sheet comes
/// first. Tap the row for the action sheet (unmark / record / edit /
/// delete). Ticked rows fade.
class ProjectTxTreeTile extends StatelessWidget {
  const ProjectTxTreeTile({
    required this.tree,
    required this.view,
    required this.onChanged,
    super.key,
  });

  final ProjectTxTree tree;
  final ProjectView view;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final parent = tree.parent;
    final payer = view.member(parent.transactionMemberId);
    final myId = view.me?.id;
    final marked = myId != null && parent.isMarkedBy(myId);
    final scheme = Theme.of(context).colorScheme;
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: marked ? 0.5 : 1,
          child: MoneyListTile(
            leading: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: view.rowsLocked
                  ? null
                  : () => marked
                      ? _actions(context, parent, isParent: true)
                      : _tick(context, parent, isParent: true),
              child: CornerBadge(
                badge: marked
                    ? const Icon(AppIcons.check, size: 12)
                    : const SizedBox.shrink(),
                child: ProjectTxIcon(tx: parent),
              ),
            ),
            title: parent.description ?? parent.categoryName ?? '—',
            subtitle: Row(
              children: [
                ProjectMemberAvatar(member: payer, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    [
                      payer.displayName,
                      projectTxDateLabel(context, parent.date),
                      if (parent.categoryName?.isNotEmpty ?? false)
                        parent.categoryName!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ),
              ],
            ),
            amount: parent.type == 'expense' ? -parent.amount : parent.amount,
            onTap: () => _actions(context, parent, isParent: true),
          ),
        ),
        for (final c in tree.children)
          _ChildRow(
            child: c,
            debtor: view.member(c.transactionMemberId),
            creditor: payer,
            marked: myId != null && c.isMarkedBy(myId),
            locked: view.rowsLocked,
            onTap: () => myId != null && c.isMarkedBy(myId)
                ? _actions(context, c, isParent: false)
                : _tick(context, c, isParent: false),
            symbol: Currencies.symbolOf(c.currency),
            owesLabel: l.projectTxOwes(payer.displayName),
          ),
      ],
    );
  }

  /// Mine to settle: payer of a parent row, or debtor / creditor of a split.
  bool _canResolve(ProjectTransaction tx, {required bool isParent}) {
    final my = view.me?.id;
    if (my == null) return false;
    if (isParent) return tx.transactionMemberId == my;
    return tx.transactionMemberId == my ||
        tree.parent.transactionMemberId == my;
  }

  Future<void> _tick(BuildContext context, ProjectTransaction tx,
      {required bool isParent}) async {
    if (view.rowsLocked) {
      await _actions(context, tx, isParent: isParent);
      return;
    }
    if (_canResolve(tx, isParent: isParent)) {
      final done = await _resolve(context, tx, isParent: isParent);
      if (!done || !context.mounted) return;
    }
    await _mark(context, tx, true);
  }

  Future<bool> _resolve(BuildContext context, ProjectTransaction tx,
      {required bool isParent}) async {
    final my = view.me!.id;
    final counterparty = isParent
        ? null
        : tx.transactionMemberId == my
            ? view.member(tree.parent.transactionMemberId)
            : view.member(tx.transactionMemberId);
    final ok = await showAppSheet<bool>(
      context,
      title: AppLocalizations.of(context)!.projectTxResolve,
      builder: (_) => _ResolveSheet(
        tx: tx,
        isParent: isParent,
        childrenTotal: isParent ? tree.childrenTotal : 0,
        myMemberId: my,
        counterparty: counterparty,
      ),
    );
    if (ok == true && context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.projectResolveDone,
          tone: Tone.success);
    }
    return ok == true;
  }

  Future<void> _mark(BuildContext context, ProjectTransaction tx, bool on) async {
    try {
      await context
          .read<ProjectsRepository>()
          .toggleMark(view.project.id, tx.id, on);
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _actions(BuildContext context, ProjectTransaction tx,
      {required bool isParent}) async {
    final l = AppLocalizations.of(context)!;
    final my = view.me?.id;
    final marked = my != null && tx.isMarkedBy(my);
    final editable = isParent && !view.rowsLocked;
    final canResolve = !view.rowsLocked && _canResolve(tx, isParent: isParent);
    final action = await showAppSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: ProjectTxIcon(tx: tx),
            title: Text(tx.description ?? tx.categoryName ?? '—'),
            subtitle: Text([
              view.member(tx.transactionMemberId).displayName,
              projectTxDateLabel(context, tx.date),
              if (tx.note?.isNotEmpty ?? false) tx.note!,
            ].join(' · ')),
            trailing: MoneyText(
              tx.type == 'expense' ? -tx.amount : tx.amount,
              symbol: Currencies.symbolOf(tx.currency),
              tone: MoneyTone.signed,
            ),
          ),
          const Divider(height: 1),
          if (marked && !view.rowsLocked)
            ListTile(
              leading: const Icon(AppIcons.undo),
              title: Text(l.projectTxUnmark),
              onTap: () => Navigator.pop(sheet, 'unmark'),
            ),
          if (canResolve)
            ListTile(
              leading: const Icon(AppIcons.settle),
              title: Text(l.projectTxResolve),
              subtitle: Text(l.projectTxResolveHint),
              onTap: () => Navigator.pop(sheet, 'resolve'),
            ),
          if (editable)
            ListTile(
              leading: const Icon(AppIcons.edit),
              title: Text(l.projectTxEdit),
              onTap: () => Navigator.pop(sheet, 'edit'),
            ),
          if (editable)
            ListTile(
              leading: Icon(AppIcons.delete,
                  color: Theme.of(context).colorScheme.error),
              title: Text(l.projectTxDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.pop(sheet, 'delete'),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'unmark':
        await _mark(context, tx, false);
      case 'resolve':
        await _resolve(context, tx, isParent: isParent);
      case 'edit':
        final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => ProjectTransactionFormPage(
            projectId: view.project.id,
            editing: tree,
          ),
        ));
        if (saved == true) await onChanged();
      case 'delete':
        await _delete(context, tx);
    }
  }

  Future<void> _delete(BuildContext context, ProjectTransaction tx) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.projectTxDeleteTitle,
      message: l.projectTxDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await context
          .read<ProjectsRepository>()
          .deleteTransaction(view.project.id, tx.id);
      if (context.mounted) {
        showAppSnackBar(context, l.projectTxDeleted, tone: Tone.success);
      }
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.debtor,
    required this.creditor,
    required this.marked,
    required this.locked,
    required this.onTap,
    required this.symbol,
    required this.owesLabel,
  });

  final ProjectTransaction child;
  final ProjectMember debtor;
  final ProjectMember creditor;
  final bool marked;
  final bool locked;
  final VoidCallback onTap;
  final String symbol;
  final String owesLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: marked ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl + AppSpacing.lg, 2, AppSpacing.lg, 2),
          child: Row(
            children: [
              SelectCheck(value: marked, onTap: locked ? null : onTap, size: 18),
              const SizedBox(width: AppSpacing.xs),
              ProjectMemberAvatar(member: debtor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: debtor.displayName),
                    TextSpan(
                      text: ' $owesLabel',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              MoneyText(child.amount,
                  symbol: symbol,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// "ลงบัญชีส่วนตัว" — copy a board row into my own book.
// ────────────────────────────────────────────────────────────────────

enum _Mode { asTransaction, asDebt }

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({
    required this.tx,
    required this.isParent,
    required this.childrenTotal,
    required this.myMemberId,
    required this.counterparty,
  });

  final ProjectTransaction tx;
  final bool isParent;
  final double childrenTotal;
  final String myMemberId;

  /// Split rows only: the other side (payer if I'm the debtor, the debtor
  /// if I paid).
  final ProjectMember? counterparty;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  _Mode _mode = _Mode.asTransaction;
  Account? _account;
  Category? _category;
  bool _shareOnly = false;
  bool _saving = false;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    final accounts = context.read<AccountsCubit>();
    if (accounts.state.accounts.isEmpty) accounts.load();
    context.read<CategoriesCubit>().loadIfNeeded();
  }

  double get _amount {
    if (widget.isParent && _shareOnly) {
      final share = widget.tx.amount - widget.childrenTotal;
      return share < 0 ? 0 : share;
    }
    return widget.tx.amount;
  }

  bool get _iAmDebtor => widget.tx.transactionMemberId == widget.myMemberId;

  /// Parent: same direction as the row. Split: debtor pays (expense),
  /// payer gets paid back (income).
  TransactionType get _txType {
    if (widget.isParent) {
      return widget.tx.type == 'expense'
          ? TransactionType.expense
          : TransactionType.income;
    }
    return _iAmDebtor ? TransactionType.expense : TransactionType.income;
  }

  Future<void> _pickAccount() async {
    final l = AppLocalizations.of(context)!;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: context.read<AccountsCubit>().state.accounts,
      selected: _account,
      title: l.debtSettleAccount,
    );
    if (r is AccountPickerSelected) {
      setState(() {
        _account = r.account;
        _accountError = null;
      });
    }
  }

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: _txType == TransactionType.expense
          ? CategoryType.expense
          : CategoryType.income,
      selected: _category,
      allowNone: true,
      noneLabel: l.projectResolveCategoryNone,
      title: l.projectResolveCategory,
    );
    if (r is CategoryPickerSelected) setState(() => _category = r.category);
    if (r is CategoryPickerCleared) setState(() => _category = null);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_mode == _Mode.asTransaction && _account == null) {
      setState(() => _accountError = l.debtSettleAccountRequired);
      return;
    }
    final txCubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    setState(() => _saving = true);
    try {
      if (_mode == _Mode.asTransaction) {
        await context.read<TransactionsRepository>().create(
              type: _txType,
              accountId: _account!.id,
              amount: _amount,
              date: widget.tx.date,
              note: widget.tx.note ?? widget.tx.description,
              categoryId: _category?.id,
              sourceProjectTransactionId: widget.tx.id,
            );
        await Future.wait([txCubit.load(), accounts.load()]);
      } else {
        await context.read<PersonalDebtsRepository>().create(
              direction:
                  _iAmDebtor ? DebtDirection.iOwe : DebtDirection.owedToMe,
              counterpartyPersonName: widget.counterparty?.displayName ?? '?',
              amount: _amount,
              currency: widget.tx.currency,
              note: widget.tx.description ?? widget.tx.note,
            );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = Currencies.symbolOf(widget.tx.currency);
    final name = widget.counterparty?.displayName ?? '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isParent) ...[
            AppTabBar<_Mode>(
              selected: _mode,
              onChanged: (m) => setState(() => _mode = m),
              tabs: [
                AppTab(value: _Mode.asTransaction, label: l.projectResolveAsTx),
                AppTab(value: _Mode.asDebt, label: l.projectResolveAsDebt),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          DetailRow(
            label: l.projectResolveAmount,
            trailing: MoneyText(_amount, symbol: symbol),
          ),
          if (widget.isParent && widget.childrenTotal > 0)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _shareOnly,
              onChanged: (v) => setState(() => _shareOnly = v),
              title: Text(l.projectResolveShareOnly),
              subtitle: Text(l.projectResolveShareHint(
                moneyString(context, widget.tx.amount, symbol: symbol),
                moneyString(context, widget.tx.amount - widget.childrenTotal,
                    symbol: symbol),
              )),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (_mode == _Mode.asTransaction) ...[
            PickerTile(
              label: l.debtSettleAccount,
              value: _account?.name,
              placeholder: l.debtSettleAccountRequired,
              leading: const Icon(AppIcons.bank),
              errorText: _accountError,
              onTap: _pickAccount,
            ),
            const SizedBox(height: AppSpacing.sm),
            PickerTile(
              label: l.projectResolveCategory,
              value: _category?.name,
              placeholder: l.projectResolveCategoryNone,
              leading: const Icon(AppIcons.category),
              onTap: _pickCategory,
            ),
          ] else
            DetailRow(
              leading: const Icon(AppIcons.debt),
              label: _iAmDebtor ? l.debtYouOwe(name) : l.debtTheyOweYou(name),
              helper: l.projectResolveDebtHint,
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.projectResolveConfirm,
            icon: AppIcons.settle,
            expand: true,
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
