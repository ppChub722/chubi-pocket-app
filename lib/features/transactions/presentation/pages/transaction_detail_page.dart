import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../transaction_edit.dart';
import '../tx_rules.dart';
import '../widgets/draft_form.dart';
import '../widgets/event_pick.dart';
import '../widgets/tx_summary_title.dart';

/// `/transactions/:id` (§9) — the quick-create form's own layout, in the
/// page (owner design 2026-10-10): hero (type · amount · ค่าอะไร · date),
/// category + wallet cards, tags. Then the detail-only rows: balance
/// after, split, recorded by, source project.
///
/// ✏️ on the hero, or a long-press on a field, edits in place
/// ([EditModeMixin]): ยกเลิก · ↶ · บันทึก, the nav hidden, back asks before
/// dropping changes, 🗑 as the last row. Saves through
/// [saveTransactionEdit]. System rows (opening balance / adjustment) and
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
  /// the one made for that transfer.
  late Transaction _edited;

  /// A transfer's other row fetched because it wasn't cached.
  Transaction? _fetchedTwin;
  String? _initialAccountId;
  String? _initialToAccountId;

  /// Pushing a draft into the controller — not a user edit.
  bool _restoring = false;

  /// The form was filled with the row's split people (or it has none).
  /// False = a list row with only split_count: the form's split list is
  /// empty, not "no splits" — editing them then would wipe the real ones.
  bool _splitsPrefilled = true;

  /// Edit mode: the hero's amount has scrolled under the top bar → the
  /// bar's title says amount · category instead (as the quick create).
  final _scroll = ScrollController();
  final _heroKey = GlobalKey();
  final _listKey = GlobalKey();
  bool _collapsed = false;

  /// Edit mode: the event picked on the card, applied on บันทึก after the
  /// row's own fields (null = no change).
  EventTarget? _eventChange;

  /// An event change alone is worth saving (and asking before discarding).
  @override
  bool get isDirty => super.isDirty || _eventChange != null;

  @override
  void cancelEdit() {
    _eventChange = null;
    super.cancelEdit();
  }

  Future<void> _pickEvent() async {
    final l = AppLocalizations.of(context)!;
    final current = widget.tx.projectId;
    final description = _c.description.text.trim();
    final date = DateFormatter.medium(
      _c.date,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final picked = await showEventTargetSheet(
      context,
      suggestedName:
          '${description.isEmpty ? l.quickEventDefaultName : description}'
          ' · $date',
      currentProjectId: current,
      selectedProjectId: switch (_eventChange) {
        ExistingEventTarget(:final project) => project.id,
        _ => null,
      },
    );
    if (picked == null || !mounted) return;
    setState(
      () => _eventChange = switch (picked) {
        // Back to how it is = no change.
        RemoveFromEvent() when current == null => null,
        ExistingEventTarget(:final project) when project.id == current => null,
        _ => picked,
      },
    );
  }

  /// ✕ on the card: out of the event it's in, or drop a pick not saved.
  void _clearEvent() => setState(
    () => _eventChange = widget.tx.projectId == null
        ? null
        : const RemoveFromEvent(),
  );

  /// The card's name while editing: the pick, else the event it's in.
  String? _eventName(AppLocalizations l, Transaction tx) =>
      switch (_eventChange) {
        null =>
          tx.projectId == null
              ? null
              : tx.project?.name ?? l.txDetailSourceProject,
        final change => eventTargetName(l, change),
      };

  /// The top bar's height over the body (status bar included) — the list
  /// runs beneath it. Read from the body's context each build.
  double _barInset = 0;

  @override
  void initState() {
    super.initState();
    _prefill();
    initDraft(_c.toDraft());
    _c.addListener(_onFormChanged);
    _scroll.addListener(_onScroll);
    _fetchTwinIfMissing();
    _fetchSplitsIfMissing();
  }

  /// List rows carry only `split_count`; the people (the split list) come
  /// with GET /:id. On open, and again before editing if that failed.
  /// refreshOne is a plain read — it doesn't re-fetch the list, which would
  /// put a row without splits back. Never retried from didUpdateWidget
  /// (refresh → didUpdateWidget → fetch would loop).
  Future<void> _fetchSplitsIfMissing() async {
    final tx = widget.tx;
    if (tx.splitCount == 0 || tx.splits.isNotEmpty) return;
    try {
      await context.read<TransactionsCubit>().refreshOne(tx.id);
    } on ApiException {
      // The row still opens the debts list.
    }
  }

  /// ✏️ / long-press: get the split people first when they're missing, so
  /// the form edits the real list. Still missing (offline) → edit mode
  /// opens with splits read-only ([_splitsPrefilled]).
  Future<void> _enterEdit({FocusNode? focus}) async {
    if (!_splitsPrefilled) {
      await _fetchSplitsIfMissing();
      if (!mounted || isEditing) return;
      _reload();
    }
    enterEdit(focus: focus);
  }

  void _scrollToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onScroll() {
    final c = isEditing && _amountHidden();
    if (c != _collapsed) setState(() => _collapsed = c);
  }

  /// The hero's amount line is above the list's visible top (under the
  /// top bar, which the body runs beneath).
  bool _amountHidden() {
    final hero = _heroKey.currentContext?.findRenderObject();
    final list = _listKey.currentContext?.findRenderObject();
    if (hero is! RenderBox || list is! RenderBox) return false;
    if (!hero.attached || !list.attached) return false;
    final top = list.localToGlobal(Offset.zero).dy + _barInset;
    final amountBottom = hero
        .localToGlobal(Offset(0, hero.size.height - AppSpacing.md))
        .dy;
    return amountBottom < top;
  }

  /// Opened from a wallet's tab, a deep link or a filtered list, the
  /// transfer's other row may not be cached — without it the form shows no
  /// destination wallet and saving fails.
  Future<void> _fetchTwinIfMissing() async {
    final tx = widget.tx;
    if (tx.transferGroupId == null || transferSibling(context, tx) != null) {
      return;
    }
    final twin = await fetchTransferSibling(context, tx);
    if (!mounted || twin == null) return;
    _fetchedTwin = twin;
    if (!isEditing) _reload();
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
    _scroll.dispose();
    super.dispose();
  }

  void _prefill() {
    final tx = widget.tx;
    final twin = tx.transferGroupId == null
        ? null
        : transferSibling(context, tx) ?? _fetchedTwin;
    final edited = tx.isTransferIn && twin != null ? twin : tx;
    final other = identical(edited, tx) ? twin : tx;
    _edited = edited;
    _restoring = true;
    _c.tagIds.clear();
    _c.knownTags.clear();
    _c.prefillTransaction(
      edited,
      accounts: context.read<AccountsCubit>().state.accounts,
      categories: context.read<CategoriesCubit>().state.categories,
      toAccount: other?.accountId == null
          ? null
          : context.read<AccountsCubit>().byId(other!.accountId!),
    );
    _restoring = false;
    _splitsPrefilled = edited.splitCount == 0 || edited.splits.isNotEmpty;
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
          : jsonEncode(next.splits) != jsonEncode(w.splits)
          ? 'splits'
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
    if (!await confirmIncompleteSplits(context, _c)) return;
    if (!mounted) return;
    setSaving(true);
    final projects = context.read<ProjectsRepository>();
    final projectsCubit = context.read<ProjectsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    try {
      final warn = await saveTransactionEdit(
        context,
        t: _edited,
        c: _c,
        initialAccountId: _initialAccountId,
        initialToAccountId: _initialToAccountId,
      );
      if (!mounted) return;
      // The event goes after the row's own fields. Failing, the fields
      // stay saved and edit mode stays open on the event pick.
      final change = _eventChange;
      if (change != null) {
        try {
          await applyEventChange(
            projects,
            txId: _edited.id,
            currentProjectId: _edited.projectId,
            change: change,
          );
        } on ApiException catch (e) {
          if (!mounted) return;
          commitSaved(working);
          _reload();
          enterEdit();
          showAppSnackBar(
            context,
            l.txEventFailedAfterSave(eventErrorMessage(l, e)),
            tone: Tone.danger,
          );
          return;
        }
        _eventChange = null;
        unawaited(projectsCubit.load());
        // Joining / leaving moves the row's splits too (BE) — re-read it.
        try {
          await txCubit.refreshOne(_edited.id, afterWrite: true);
        } on ApiException {
          // The event changed; the next refresh shows the rest.
        }
        if (!mounted) return;
      }
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
      showAppSnackBar(
        context,
        splitErrorMessage(l, e) ?? walletErrorMessage(l, e),
        tone: Tone.danger,
      );
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
    // A debt repayment (system Debt Paid / Received): not editable, but
    // deletable — its amount comes off the debt's repaid (BE v2).
    final isRepayment =
        isSystemRow &&
        !tx.isLocked &&
        (cat?.iconCode?.icon == 'system_debt_paid' ||
            cat?.iconCode?.icon == 'system_debt_received');
    // The row's author edits its splits in place (expense / income only);
    // anyone else sees them read-only, with the way to the debts.
    // Only once the form holds the real people — see [_splitsPrefilled].
    // Who may is one rule ([txCanEditSplits]: the BE's flag, else ours).
    final canEditSplits =
        canEdit && txCanEditSplits(_edited, category: cat) && _splitsPrefilled;
    final editing = isEditing;

    final locale = Localizations.localeOf(context).toLanguageTag();
    String stamp(DateTime d) =>
        '${DateFormatter.medium(d, locale: locale)} '
        '${DateFormatter.time(d, locale: locale)}';
    final splitCount = math.max(tx.splitCount, tx.splits.length);
    final hasSplits = splitCount > 0;
    final created = tx.createdAt;
    final updated = tx.updatedAt;
    // Only an edit after the row was made counts as "แก้ไขล่าสุด".
    final edited =
        created != null &&
        updated != null &&
        updated.difference(created).inSeconds.abs() >= 60;
    void openProject() => openPage(context, '/projects/${tx.projectId}');
    // The one rule for the event card ([txCanJoinEvent]).
    final canJoinEvent = canEdit && txCanJoinEvent(_edited, category: cat);

    // After the note (owner 2026-10-10). View: who it's split with, each
    // with where they stand, then the event card. Edit: what a saved row
    // can't change, read-only; the event card as a picker.
    // The sections after the form's own (owner 2026-10-10, rules #16 / #17
    // — the wallet / category detail kit): หารกับ, then อีเวนต์.
    final splitTitle = tx.type == TransactionType.income
        ? l.txSplitShareShort
        : l.txSplitWith;
    final eventName = tx.projectId == null
        ? null
        : tx.project?.name ?? l.txDetailSourceProject;
    final trailingRows = editing
        ? <Widget>[
            // Can't edit these people here (another member's row, or the
            // people didn't load): say so; nothing in splits pushes a page.
            if (hasSplits && !canEditSplits)
              SectionCard(
                title: splitTitle,
                children: [
                  DetailRow(
                    leading: const Icon(AppIcons.lock),
                    label: splitCount > 0
                        ? l.txDetailSplitEditElsewhere(splitCount)
                        : l.txSplitEditOnDebts,
                  ),
                ],
              ),
            // Joins / moves / leaves on บันทึก (with the rest of the edit).
            if (canJoinEvent)
              SectionCard(
                children: [
                  EventRow(
                    name: _eventName(l, tx),
                    onTap: _pickEvent,
                    onClear: _eventName(l, tx) == null ? null : _clearEvent,
                  ),
                ],
              )
            else if (eventName != null)
              SectionCard(children: [EventRow(name: eventName, locked: true)]),
          ]
        : <Widget>[
            if (tx.splits.isNotEmpty)
              SectionCard(
                title: splitTitle,
                children: [
                  for (final s in tx.splits)
                    _SplitRow(split: s, onOpen: () => _openSplits(s)),
                ],
              )
            else if (hasSplits)
              // Another member's row on a shared wallet: the BE keeps the
              // people to their author — say where to look, never a bare
              // count; tapping goes nowhere (owner 2026-10-10).
              SectionCard(
                title: splitTitle,
                children: [DetailRow(label: l.txSplitSeeDebts)],
              ),
            // Tapping opens the event — the one link here, like a split
            // person → their debts (owner 2026-10-10).
            if (eventName != null)
              SectionCard(
                children: [EventRow(name: eventName, onTap: openProject)],
              ),
          ];

    // The very bottom: small muted record info, one item per line (owner
    // 2026-10-10).
    final metaLines = <String>[
      if (tx.createdBy != null)
        l.txDetailMetaRecordedBy(tx.createdBy!.displayName),
      if (tx.accountBalanceAfter != null)
        '${l.txDetailBalanceAfter} '
            '${moneyString(context, tx.accountBalanceAfter!)}',
      if (created != null) '${l.txDetailCreatedAt} ${stamp(created)}',
      if (edited) '${l.txDetailUpdatedAt} ${stamp(updated)}',
    ];

    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: editing
              ? l.transactionFormTitleEdit
              : _titleForType(l, tx.type),
          // Scrolled past the hero while editing: the type-coloured
          // "฿1,250  อาหาร", as in the quick create (the bar cross-fades
          // it in and out; tap → back to the top).
          titleSlot: editing && _collapsed
              ? TxSummaryTitle(
                  type: _c.type,
                  amount: _c.amountValue,
                  category: _c.isTransfer ? null : _c.category,
                  onTap: _scrollToTop,
                )
              : null,
          showBack: true,
          editing: editing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        // Builder: the body's context sees the bar height in padding.top.
        body: Builder(
          builder: (context) {
            _barInset = MediaQuery.paddingOf(context).top;
            return PullToRefresh(
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
                key: _listKey,
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).top + AppSpacing.md,
                  AppSpacing.lg,
                  96 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  if (isSystemRow) ...[
                    _LockNote(
                      text: isRepayment
                          ? l.txDetailRepaymentBanner
                          : l.transactionDetailSystemRowBanner,
                    ),
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
                    heroKey: _heroKey,
                    autofocus: false,
                    // The type can't change after saving; splits can, by the
                    // author (PUT /transactions/:id/splits).
                    typeLocked: true,
                    allowSplits: canEditSplits,
                    editing: editing,
                    categoryLockedHint: _edited.canEditCategory
                        ? null
                        : l.transactionFormCategoryAuthorOnlyHint,
                    onEdit: canEdit ? _enterEdit : null,
                    onEnterEdit: canEdit ? (f) => _enterEdit(focus: f) : null,
                    trailingRows: trailingRows,
                    sectioned: true,
                    // Moving into an event: the splits go with it (titled so).
                    eventPending:
                        _eventChange is NewEventTarget ||
                        _eventChange is ExistingEventTarget,
                  ),
                  if ((editing && canEdit) || isRepayment)
                    DangerRow(
                      icon: AppIcons.delete,
                      label: l.transactionDeleteThis,
                      onTap: isSaving
                          ? null
                          : () => _confirmDelete(
                              context,
                              l,
                              repayment: isRepayment,
                            ),
                    ),
                  if (metaLines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: Text(
                        metaLines.join('\n'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  /// A split person → their debts page (by contact, else by name). No
  /// person given: the only one, or — several, or not loaded — the debts
  /// list.
  void _openSplits([TxSplit? person]) {
    final splits = widget.tx.splits;
    if (person == null && splits.length != 1) {
      openPage(context, '/personal-debts');
      return;
    }
    final s = person ?? splits.single;
    final query = Uri(
      queryParameters: {'contact': ?s.contactId, 'name': s.personName},
    ).query;
    openPage(context, '/personal-debts/person?$query');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l, {
    bool repayment = false,
  }) async {
    final tx = widget.tx;
    final isTransfer = tx.type == TransactionType.transfer;
    final ok = await showConfirmDialog(
      context,
      title: isTransfer
          ? l.transactionDetailDeleteConfirmTitleTransfer
          : l.transactionDetailDeleteConfirmTitle,
      message: repayment
          ? l.txDetailDeleteRepaymentBody(moneyString(context, tx.amount))
          : isTransfer
          ? l.transactionDetailDeleteConfirmBodyTransfer
          : l.transactionDetailDeleteConfirmBody,
      confirmLabel: l.transactionDetailDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final debtsCubit = context.read<PersonalDebtsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    try {
      await txCubit.remove(tx.id);
      // A transfer moves two balances — a full reload keeps it simple.
      await accountsCubit.load();
      // A repayment gone lowers its debt's repaid amount.
      if (repayment) unawaited(debtsCubit.load());
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

/// One person of the "หารกับ" section (owner 2026-10-10):
///
///   (avatar) ลี                        ฿120
///                                 รอคืน ฿20
///
/// Only the avatar + name are tappable — they open that person's debts;
/// the amount and where it stands are just text.
class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.split, required this.onOpen});
  final TxSplit split;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final s = split;
    String money(double v) => moneyString(context, v);
    // Where it stands, from my side of it.
    final status = switch (s.status) {
      // Repaid more than the (edited) amount: say which way the difference
      // goes back (owner 2026-10-10).
      _ when s.isOverpaid =>
        s.owedToMe
            ? l.txSplitStatusOverpaidToThem(money(-s.outstanding))
            : l.txSplitStatusOverpaidByMe(money(-s.outstanding)),
      'settled' => s.owedToMe ? l.txSplitStatusPaid : l.txSplitStatusRepaid,
      'cancelled' => l.txSplitStatusCancelled,
      _ when s.settledAmount > 0.005 =>
        s.owedToMe
            ? l.txSplitStatusPartPaid(money(s.settledAmount), money(s.amount))
            : l.txSplitStatusPartRepaid(
                money(s.settledAmount),
                money(s.amount),
              ),
      _ =>
        s.owedToMe
            ? l.txSplitStatusAwaiting(money(s.outstanding))
            : l.txSplitStatusToPay(money(s.outstanding)),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(displayName: s.personName, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          s.personName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(money(s.amount), style: textTheme.bodyLarge),
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(
                  color: s.isOverpaid
                      ? palette.warning
                      : s.status == 'settled'
                      ? palette.income
                      : scheme.onSurfaceVariant,
                  fontWeight: s.status == 'settled' ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
