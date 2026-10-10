import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../transaction_edit.dart';
import '../widgets/draft_form.dart';

/// `/transactions/:id` (§9) — the quick-create form's own layout, in the
/// page (owner design 2026-10-10): hero (type · amount · ค่าอะไร · date),
/// category + wallet cards, tags. Then the detail-only rows: balance
/// after, split, recorded by, source project.
///
/// ✏️ on the hero, or a long-press on a field, edits in place
/// ([EditModeMixin]): ยกเลิก · ↶ · บันทึก, the nav hidden, back = cancel,
/// 🗑 as the last row. Saves the same way as the sheet's edit mode
/// ([saveTransactionEdit]). System rows (opening balance / adjustment) and
/// an ex-member's locked rows stay read-only, with a banner.
class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  /// Fetching just this row — it isn't in the global cache.
  bool _fetchingOne = false;

  @override
  void initState() {
    super.initState();
    // Deep links: make sure the cache is there.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cubit = context.read<TransactionsCubit>();
      await cubit.loadIfNeeded();
      // Opened from a list on its own cubit (a wallet's รายการ tab) or
      // beyond the loaded pages → fetch the row itself.
      if (!mounted || cubit.byId(widget.transactionId) != null) return;
      setState(() => _fetchingOne = true);
      try {
        await cubit.refreshOne(widget.transactionId);
      } on ApiException {
        // Falls through to the not-found view.
      }
      if (mounted) setState(() => _fetchingOne = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final tx = context.read<TransactionsCubit>().byId(widget.transactionId);
        if (tx != null) return _Loaded(tx: tx);
        return Scaffold(
          appBar: AppTopBar(title: l.navTransactions, showBack: true),
          extendBodyBehindAppBar: true,
          body: AsyncStateView.fallback(
            loading:
                _fetchingOne ||
                state.status == TransactionsStatus.loading ||
                state.status == TransactionsStatus.initial,
            error: state.error,
            // Not loaded (it failed) → loadIfNeeded refetches.
            onRetry: context.read<TransactionsCubit>().loadIfNeeded,
            skeleton: const LoadingView(),
            notFound: EmptyView(
              icon: AppIcons.empty,
              title: l.transactionDetailNotFound,
              message: l.transactionDetailNotFoundMessage,
            ),
          ),
        );
      },
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({required this.tx});
  final Transaction tx;

  @override
  State<_Loaded> createState() => _LoadedState();
}

/// The draft is the form's fields as a [PendingDraft] (Equatable), so the
/// mixin's dirty check and undo work on the shared [DraftFormController].
class _LoadedState extends State<_Loaded>
    with EditModeMixin<_Loaded, PendingDraft> {
  final _c = DraftFormController();

  /// The row the form edits: the page's row, or for an incoming transfer
  /// its outgoing twin — so the wallets read [จาก] → [ไป] and the save is
  /// the one the sheet makes for that transfer.
  late Transaction _edited;
  String? _initialAccountId;
  String? _initialToAccountId;

  /// Pushing a draft into the controller — not a user edit.
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _prefill();
    initDraft(_c.toDraft());
    _c.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(_Loaded old) {
    super.didUpdateWidget(old);
    // Refreshed underneath (pull, another page) — rebase unless editing.
    if (old.tx != widget.tx && !isEditing) _reload();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _prefill() {
    final tx = widget.tx;
    var edited = tx;
    if (tx.isTransferIn) edited = transferSibling(context, tx) ?? tx;
    _edited = edited;
    _restoring = true;
    _c.tagIds.clear();
    _c.knownTags.clear();
    _c.prefillTransaction(
      edited,
      accounts: context.read<AccountsCubit>().state.accounts,
      categories: context.read<CategoriesCubit>().state.categories,
      toAccount: transferOtherAccount(context, edited),
    );
    _restoring = false;
    _initialAccountId = _c.account?.id;
    _initialToAccountId = _c.toAccount?.id;
  }

  void _reload() {
    _prefill();
    resetDraft(_c.toDraft());
  }

  // ── EditModeMixin ─────────────────────────────────────────────────

  @override
  void onDraftRestored() {
    _restoring = true;
    _c.restoreTransaction(
      working,
      accounts: context.read<AccountsCubit>().state.accounts,
      categories: context.read<CategoriesCubit>().state.categories,
    );
    _restoring = false;
  }

  /// Typing in the amount / description / note is one undo step per burst;
  /// a pick (date, category, wallet, tag) is a step of its own.
  void _onFormChanged() {
    if (_restoring) return;
    final next = _c.toDraft();
    final w = working;
    if (next == w) return;
    final textOnly =
        next.type == w.type &&
        next.date == w.date &&
        next.accountId == w.accountId &&
        next.categoryId == w.categoryId &&
        next.transferToAccountId == w.transferToAccountId &&
        listEquals(next.tagIds, w.tagIds);
    if (textOnly) {
      final field = next.note != w.note
          ? 'note'
          : next.description != w.description
          ? 'description'
          : 'amount';
      applyTextChange(field, next);
    } else {
      applyChange(next);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    commitTextSession();
    final problem = transactionEditProblem(l, _c);
    if (problem != null) {
      HapticFeedback.lightImpact();
      showAppSnackBar(context, problem, tone: Tone.danger);
      return;
    }
    setSaving(true);
    try {
      final warn = await saveTransactionEdit(
        context,
        t: _edited,
        c: _c,
        initialAccountId: _initialAccountId,
        initialToAccountId: _initialToAccountId,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(working);
      _reload();
      showAppSnackBar(
        context,
        warn ?? l.quickSaved,
        tone: warn == null ? Tone.success : Tone.warning,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, walletErrorMessage(l, e), tone: Tone.danger);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tx = widget.tx;
    final cat = tx.categoryId == null
        ? null
        : context.watch<CategoriesCubit>().byId(tx.categoryId!);
    // Opening balance / adjustment rows are bookkeeping — read-only.
    // Transfers carry a system category too but have their own cascade.
    final isSystemRow =
        tx.type != TransactionType.transfer && (cat?.isSystem ?? false);
    final canEdit = !isSystemRow && !tx.isLocked;
    final editing = isEditing;

    final info = <Widget>[
      if (tx.accountBalanceAfter != null)
        DetailRow(
          label: l.txDetailBalanceAfter,
          trailing: MoneyText(tx.accountBalanceAfter!),
        ),
      if (tx.hasSplits)
        DetailRow(
          leading: const Icon(AppIcons.split),
          label: l.txDetailSplits,
          trailing: Text(l.txDetailHasSplits),
        ),
      if (tx.createdBy != null)
        DetailRow(
          leading: UserAvatar(
            displayName: tx.createdBy!.displayName,
            iconCode: tx.createdBy!.iconCode,
            size: 24,
          ),
          label: l.txDetailRecordedBy,
          trailing: Text(tx.createdBy!.displayName),
        ),
      if (tx.projectId != null)
        DetailRow(
          leading: const Icon(AppIcons.project),
          label: l.txDetailSource,
          trailing: Text(l.txDetailSourceProject),
          showChevron: true,
          onTap: () => openPage(context, '/projects/${tx.projectId}'),
        ),
    ];

    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: editing
              ? l.transactionFormTitleEdit
              : _titleForType(l, tx.type),
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        // Builder: the body's context sees the bar height in padding.top.
        body: Builder(
          builder: (context) => PullToRefresh(
            enabled: !editing,
            onRefresh: () async {
              try {
                await context.read<TransactionsCubit>().refreshOne(tx.id);
              } on ApiException catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, e.message, tone: Tone.danger);
                }
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + AppSpacing.md,
                AppSpacing.lg,
                96 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (isSystemRow) ...[
                  _LockNote(text: l.transactionDetailSystemRowBanner),
                  const SizedBox(height: AppSpacing.md),
                ] else if (tx.isLocked) ...[
                  MessageBanner(
                    message: l.transactionFormLockedBanner,
                    tone: Tone.warning,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                DraftForm(
                  controller: _c,
                  autofocus: false,
                  // The update API can't change these.
                  typeLocked: true,
                  allowSplits: false,
                  editing: editing,
                  categoryLockedHint: _edited.canEditCategory
                      ? null
                      : l.transactionFormCategoryAuthorOnlyHint,
                  onEdit: canEdit ? enterEdit : null,
                  onEnterEdit: canEdit ? (f) => enterEdit(focus: f) : null,
                  onOpenCategory: (c) =>
                      openPage(context, '/categories/${c.id}'),
                  onOpenAccount: (a) => openPage(context, '/accounts/${a.id}'),
                ),
                if (info.isNotEmpty)
                  SectionCard(locked: editing, children: info),
                if (editing && canEdit)
                  DangerRow(
                    icon: AppIcons.delete,
                    label: l.transactionDeleteThis,
                    onTap: isSaving ? null : () => _confirmDelete(context, l),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l) async {
    final tx = widget.tx;
    final isTransfer = tx.type == TransactionType.transfer;
    final ok = await showConfirmDialog(
      context,
      title: isTransfer
          ? l.transactionDetailDeleteConfirmTitleTransfer
          : l.transactionDetailDeleteConfirmTitle,
      message: isTransfer
          ? l.transactionDetailDeleteConfirmBodyTransfer
          : l.transactionDetailDeleteConfirmBody,
      confirmLabel: l.transactionDetailDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    try {
      await txCubit.remove(tx.id);
      // A transfer moves two balances — a full reload keeps it simple.
      await accountsCubit.load();
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      // Opened alone in its tab (from another tab) there's nothing to pop
      // — back to where the user came from.
      if (router.canPop()) {
        router.pop();
      } else {
        back?.call();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, e.message, tone: Tone.danger);
      }
    }
  }
}

String _titleForType(AppLocalizations l, TransactionType t) => switch (t) {
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};

/// 🔒 + why a system row can't be edited.
class _LockNote extends StatelessWidget {
  const _LockNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.lock, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
