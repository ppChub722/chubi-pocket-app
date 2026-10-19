import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../transaction_edit.dart';
import '../tx_rules.dart';
import '../save_failure.dart';
import '../widgets/draft_form.dart';
import 'debt_entry_detail_page.dart';
import '../widgets/event_pick.dart';
import '../widgets/recurring_link.dart';
import '../widgets/tx_compact_hero.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _fetching = true;

  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final cached = context.read<TransactionsCubit>().byId(widget.transactionId);
    if (cached?.isDebtEntry ?? false) {
      _fetching = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _fetching = true;
      _error = null;
    });
    ApiException? error;
    try {
      await context.read<TransactionsCubit>().refreshOne(widget.transactionId);
    } catch (e, st) {
      error = ApiException.from(e, st);
    }
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final tx = context.read<TransactionsCubit>().byId(widget.transactionId);
        final link = tx?.counterparty;
        if (link != null) return DebtEntryDetailPage(entryId: link.entryId);
        if (tx != null) return _Loaded(tx: tx);
        final missing = _error?.statusCode == 404;
        return Scaffold(
          appBar: AppTopBar(title: l.navTransactions, showBack: true),
          extendBodyBehindAppBar: true,
          body: AsyncStateView.fallback(
            loading: _fetching,
            error: missing ? null : _error,
            onRetry: _fetch,
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

class _LoadedState extends State<_Loaded>
    with EditModeMixin<_Loaded, PendingDraft> {
  final _c = DraftFormController();

  late Transaction _edited;

  String? _initialAccountId;
  String? _initialToAccountId;

  bool _restoring = false;

  bool _splitsPrefilled = true;

  final _scroll = ScrollController();

  /// The รายการประจำ row: links right away (one call), never on บันทึก.
  final _link = RecurringLinkHandle();
  final _heroKey = GlobalKey();

  EventTarget? _eventChange;

  bool _pendingUnlink = false;

  @override
  bool get canEdit {
    final tx = widget.tx;
    final isSystemRow =
        tx.type != TransactionType.transfer && (tx.category?.isSystem ?? false);
    return !isSystemRow && !tx.isLocked;
  }

  @override
  bool get isDirty =>
      super.isDirty ||
      _eventChange != null ||
      _pendingUnlink ||
      _link.candidateFor(_edited.type) != null;

  @override
  void cancelEdit() {
    _eventChange = null;
    _pendingUnlink = false;
    _link.clear();
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
          ' | $date',
      currentProjectId: current,
      selectedProjectId: switch (_eventChange) {
        ExistingEventTarget(:final project) => project.id,
        _ => null,
      },
    );
    if (picked == null || !mounted) return;
    setState(
      () => _eventChange = switch (picked) {
        RemoveFromEvent() when current == null => null,
        ExistingEventTarget(:final project) when project.id == current => null,
        _ => picked,
      },
    );
  }

  void _clearEvent() => setState(
    () => _eventChange = widget.tx.projectId == null
        ? null
        : const RemoveFromEvent(),
  );

  String? _eventName(AppLocalizations l, Transaction tx) =>
      switch (_eventChange) {
        null =>
          tx.eventBill?.event.name ??
              (tx.projectId == null
                  ? null
                  : tx.project?.name ?? l.txDetailSourceProject),
        final change => eventTargetName(l, change),
      };

  @override
  void initState() {
    super.initState();
    _link.addListener(_onLinkChanged);
    _prefill();
    initDraft(_c.toDraft());
    _c.addListener(_onFormChanged);
  }

  Future<void> _fetchSplitsIfMissing() async {
    final tx = widget.tx;
    if (tx.splitCount == 0 || tx.splits.isNotEmpty) return;
    try {
      await context.read<TransactionsCubit>().refreshOne(tx.id);
    } on ApiException {
      // Keep the cached row.
    }
  }

  Future<void> _enterEdit({FocusNode? focus, VoidCallback? then}) async {
    if (!_splitsPrefilled) {
      await _fetchSplitsIfMissing();
      if (!mounted || isEditing) return;
      _reload();
    }
    enterEdit(focus: focus, then: then);
  }

  void _longPressHint() => _say(
    AppLocalizations.of(context)!.commonLongPressToEdit,
    tone: Tone.info,
  );

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
    _link.dispose();
    super.dispose();
  }

  void _onLinkChanged() {
    if (mounted) setState(() {});
  }

  void _say(String message, {Tone tone = Tone.danger}) {
    if (mounted) showAppSnackBar(context, message, tone: tone);
  }

  Future<void> _linkRecurring() async {
    final tx = _edited;
    await _link.choose(
      context,
      type: tx.type,
      categoryId: tx.type == TransactionType.transfer ? null : tx.categoryId,
      amount: tx.amount > 0 ? tx.amount : null,
      createRoute: recurringCreateRoute(
        type: tx.type,
        amount: tx.amount,
        categoryId: tx.categoryId,
        accountId: tx.accountId,
        name: tx.description,
      ),
    );
  }

  void _dropRecurring() {
    if (_link.candidateFor(_edited.type) != null) {
      _link.clear();
    } else {
      setState(() => _pendingUnlink = true);
    }
  }

  Future<void> _applyRecurringChange(
    TransactionsCubit txCubit,
    AccountsCubit accounts,
  ) async {
    final item = widget.tx.recurringItem;
    final cached = widget.tx;
    if (_pendingUnlink && item != null) {
      await _link.unlinkNow(
        context,
        item.itemId,
        onUnlinked: () => txCubit.patchRow(
          cached.copyWith(clearRecurringItem: true),
          afterWrite: true,
        ),
        error: _say,
      );
    }
    _pendingUnlink = false;
    if (!mounted) return;
    if (_link.candidateFor(_edited.type) != null) {
      await _link.linkNow(
        context,
        _edited.id,
        onLinked: (fresh, balances) {
          txCubit.patchRow(fresh, afterWrite: true);
          accounts.patchBalances(balances);
        },
        error: _say,
      );
      _link.clearChoice();
    }
  }

  ({Transaction edited, AccountRef? other}) _transferView(Transaction tx) {
    final peer = tx.transferPeer;
    final mine = tx.account;
    if (tx.type != TransactionType.transfer || peer == null) {
      return (edited: tx, other: null);
    }
    if (tx.isTransferIn && mine != null) {
      return (
        edited: tx.copyWith(
          id: peer.id,
          accountId: peer.account.id,
          account: peer.account,
          transferPeer: TransferPeer(id: tx.id, isOut: false, account: mine),
        ),
        other: mine,
      );
    }
    return (edited: tx, other: peer.account);
  }

  List<Account> _accountPool(Iterable<AccountRef?> embedded) {
    final base =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final ids = {for (final a in base) a.id};
    return [
      ...base,
      for (final a in embedded)
        if (a != null && ids.add(a.id)) a.toAccount(),
    ];
  }

  List<Category> _categoryPool(EmbeddedCategory? embedded) {
    final base =
        maybeTxFormOptions(
          context,
          watch: false,
        )?.state.options?.categoryList ??
        context.read<CategoriesCubit>().state.categories;
    return [
      ...base,
      if (embedded != null && !base.any((c) => c.id == embedded.id))
        embedded.toCategory(),
    ];
  }

  void _prefill() {
    final tx = widget.tx;
    final view = _transferView(tx);
    final edited = view.edited;
    _edited = edited;
    _restoring = true;
    _c.tagIds.clear();
    _c.knownTags.clear();
    _c.prefillTransaction(
      edited,
      accounts: _accountPool([edited.account, view.other]),
      categories: _categoryPool(edited.category),
      toAccount: view.other?.toAccount(),
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

  @override
  void onDraftRestored() {
    _restoring = true;
    final view = _transferView(widget.tx);
    _c.restoreTransaction(
      working,
      accounts: _accountPool([view.edited.account, view.other]),
      categories: _categoryPool(view.edited.category),
    );
    _restoring = false;
  }

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

  bool _splitsEditable = false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    commitTextSession();
    final problem = transactionEditProblem(
      l,
      _c,
      splitsEditable: _splitsEditable,
    );
    if (problem != null) {
      HapticFeedback.lightImpact();
      showAppSnackBar(context, problem, tone: Tone.danger);
      return;
    }
    if (!await confirmIncompleteSplits(context, _c)) return;
    if (!mounted) return;
    bool? alsoUpdateLink;
    if (widget.tx.hasPromptedLink) {
      final choice = await showLinkedPrompt(
        context,
        title: l.linkedSaveTitle,
        cancelLabel: l.linkedCancel,
        thisSideLabel: l.linkedSaveThisOnly,
        bothSidesLabel: l.linkedSaveBoth,
      );
      if (choice == null || !mounted) return;
      alsoUpdateLink = choice == LinkedChoice.bothSides;
    }
    setSaving(true);
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    final projects = context.read<ProjectsRepository>();
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    try {
      final outcome = await saveTransactionEdit(
        context,
        t: _edited,
        c: _c,
        initialAccountId: _initialAccountId,
        initialToAccountId: _initialToAccountId,
        alsoUpdateLink: alsoUpdateLink,
      );
      if (outcome.movedToUpcoming) {
        commitSaved(working);
        showAppSnackBarOn(messenger, l.txMovedToUpcoming, tone: Tone.success);
        if (router == null) {
          navigator.maybePop();
        } else if (router.canPop()) {
          router.pop();
        } else {
          back?.call();
        }
        return;
      }
      final warn = outcome.warning;
      if (!mounted) return;
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
        try {
          await txCubit.refreshOne(_edited.id, afterWrite: true);
        } on ApiException {
          // Keep the cached row.
        }
        if (!mounted) return;
      }
      await _applyRecurringChange(txCubit, accountsCubit);
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
      showSaveFailure(
        context,
        e,
        retry: _save,
        message: splitErrorMessage(l, e) ?? walletErrorMessage(l, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tx = widget.tx;
    final isSystemRow =
        tx.type != TransactionType.transfer && (tx.category?.isSystem ?? false);
    final isRepayment =
        isSystemRow && !tx.isLocked && (tx.category?.isDebtRepayment ?? false);
    final canEditSplits =
        canEdit && txCanEditSplits(_edited) && _splitsPrefilled;
    _splitsEditable = canEditSplits;
    final editing = isEditing;

    final splitCount = math.max(tx.splitCount, tx.splits.length);
    final hasSplits = splitCount > 0;
    final created = tx.createdAt;
    final updated = tx.updatedAt;
    // The bill this row is on (event_bill) opens on the event's board; an older
    // row without it opens the event.
    final bill = tx.eventBill;
    void openProject() => openPage(
      context,
      bill != null
          ? '/projects/${bill.event.id}?bill=${bill.billId}'
          : '/projects/${tx.projectId}',
    );
    final canJoinEvent = canEdit && txCanJoinEvent(_edited);

    final eventName =
        bill?.event.name ??
        (tx.projectId == null
            ? null
            : tx.project?.name ?? l.txDetailSourceProject);
    Widget splitsLongPressable(Widget section) => canEdit
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _enterEdit,
            child: section,
          )
        : section;
    Widget splitsBlock(List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(l.txSplitPeopleLabel, style: detailLabelStyle(context)),
        ),
        ...rows,
      ],
    );
    final Widget? splitsReadOnly;
    final SplitEventSlot? eventSlot;
    final SplitRecurringSlot? recurringSlot;
    // The recurring link: the saved one (unless its removal is held), else a
    // held pick.
    final recurringItem = tx.recurringItem;
    final savedLink = _pendingUnlink || recurringItem == null
        ? null
        : recurringItem;
    final recurringName = savedLink?.label(l.quickUpcomingHintTitle);
    void openRecurring() => openPage(
      context,
      savedLink?.recurringId == null
          ? '/recurring?tab=upcoming'
          : '/recurring/${savedLink!.recurringId}',
    );
    if (editing) {
      splitsReadOnly = null;
      eventSlot = canJoinEvent
          ? SplitEventSlot(
              name: _eventName(l, tx),
              onTap: _pickEvent,
              onClear: _eventName(l, tx) == null ? null : _clearEvent,
            )
          : null;
      recurringSlot = canEdit
          ? _link.slot(
              context,
              type: _edited.type,
              linkedName: recurringName,
              onOpenLinked: null,
              onTap: _linkRecurring,
              onClear: _dropRecurring,
              onUnlink: _dropRecurring,
              error: _say,
              done: (m) => _say(m, tone: Tone.success),
            )
          : null;
    } else {
      splitsReadOnly = tx.splits.isNotEmpty
          ? splitsLongPressable(
              splitsBlock([
                for (final s in tx.splits)
                  _splitRow(context, s, () => _openSplits(s)),
              ]),
            )
          : hasSplits
          ? splitsLongPressable(
              splitsBlock([DetailRow(label: l.txSplitSeeDebts)]),
            )
          : canEditSplits
          ? splitsLongPressable(
              DetailRow(
                label: l.txSplitPeopleLabel,
                trailing: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppChip(
                    icon: AppIcons.add,
                    label: l.txSplitAddPerson,
                    tone: AppChipTone.primary,
                    selected: true,
                    dashed: true,
                    onTap: _longPressHint,
                  ),
                ),
              ),
            )
          : null;
      eventSlot = eventName != null
          ? SplitEventSlot(name: eventName, onTap: openProject, editing: false)
          : canJoinEvent
          ? SplitEventSlot(
              onTap: _longPressHint,
              editing: false,
              onLongPress: () => _enterEdit(then: _pickEvent),
            )
          : null;
      recurringSlot = recurringItem == null && !canEdit
          ? null
          : _link.slot(
              context,
              type: _edited.type,
              linkedName: recurringName,
              onOpenLinked: openRecurring,
              onTap: _longPressHint,
              editing: false,
              onLongPress: canEdit
                  ? () => _enterEdit(then: _linkRecurring)
                  : null,
              error: _say,
              done: (m) => _say(m, tone: Tone.success),
            );
    }

    final metaLines = [
      if (tx.createdBy != null)
        l.txDetailMetaRecordedBy(tx.createdBy!.displayName),
      ...detailMetaLines(context, createdAt: created, updatedAt: updated),
    ];

    return editScope(
      SavingOverlay(
        saving: isSaving,
        child: Scaffold(
          appBar: AppTopBar(
            title: _titleForType(l, tx.type),
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          extendBodyBehindAppBar: true,
          body: Builder(
            builder: (context) {
              return CompactHeroScope(
                heroKey: _heroKey,
                bar: _compactBar(context),
                child: DetailPageBody(
                  onRefresh: () async {
                    try {
                      await context.read<TransactionsCubit>().refreshOne(tx.id);
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(context, e.message, tone: Tone.danger);
                      }
                    }
                  },
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  topInset: MediaQuery.paddingOf(context).top + AppSpacing.md,
                  bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
                  // The form renders hero -> note -> tags -> the headed
                  // "แบ่งรายการ" section itself, so it is the whole hero.
                  hero: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSystemRow) ...[
                        AppMessage(
                          message: isRepayment
                              ? l.txDetailRepaymentBanner
                              : l.transactionDetailSystemRowBanner,
                          tone: Tone.info,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else if (tx.isLocked) ...[
                        AppMessage(
                          message: l.transactionFormLockedBanner,
                          tone: Tone.warning,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      DraftForm(
                        controller: _c,
                        heroKey: _heroKey,
                        autofocus: false,
                        // The type can't change after saving; splits can, by
                        // the author (PUT /transactions/:id/splits).
                        typeLocked: true,
                        cardsInHero: true,
                        allowSplits: canEditSplits,
                        upcomingHint:
                            editing && tx.type != TransactionType.transfer,
                        onUpcomingHintTap: () =>
                            openPage(context, '/recurring?tab=upcoming'),
                        editing: editing,
                        categoryLockedHint: _edited.canEditCategory
                            ? null
                            : l.transactionFormCategoryAuthorOnlyHint,
                        onEdit: canEdit ? _enterEdit : null,
                        onEnterEdit: canEdit
                            ? (f) => _enterEdit(focus: f)
                            : null,
                        onViewTap: _longPressHint,
                        splitsReadOnly: splitsReadOnly,
                        eventSlot: eventSlot,
                        recurringSlot: recurringSlot,
                        eventPending:
                            _eventChange is NewEventTarget ||
                            _eventChange is ExistingEventTarget,
                      ),
                    ],
                  ),
                  sections: const [],
                  manage: (editing && canEdit) || isRepayment
                      ? ManageSection(
                          deleteLabel: l.transactionDeleteThis,
                          deleteConsequence: l.transactionDeleteConsequence,
                          onDelete: isSaving
                              ? null
                              : () => _confirmDelete(
                                  context,
                                  l,
                                  repayment: isRepayment,
                                ),
                        )
                      : null,
                  metaLines: metaLines,
                ),
              );
            },
          ),
          bottomNavigationBar: editing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }

  AppCompactHeroCard _compactBar(BuildContext context) {
    final category = _c.isTransfer ? null : _c.category;
    return txCompactHeroBar(
      context,
      type: _c.type,
      description: _c.description.text,
      amount: _c.amountValue,
      categoryName: category == null
          ? _c.foreignCategoryName
          : categoryDisplayName(AppLocalizations.of(context)!, category),
      categoryIcon:
          category?.iconCode ??
          (category == null ? null : widget.tx.category?.iconCode),
      onTap: _scrollToTop,
    );
  }

  void _openSplits([TxSplit? person]) {
    final splits = widget.tx.splits;
    if (person == null && splits.length != 1) {
      openPage(context, '/personal-debts');
      return;
    }
    final s = person ?? splits.single;
    final key = s.contactId != null
        ? 'c:${s.contactId}'
        : 'n:${s.personName.trim().toLowerCase()}';
    openPage(context, '/personal-debts/people/${Uri.encodeComponent(key)}');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l, {
    bool repayment = false,
  }) async {
    final tx = widget.tx;
    if (tx.hasPromptedLink && !repayment) {
      final choice = await showLinkedPrompt(
        context,
        title: l.linkedDeleteTitle,
        cancelLabel: l.linkedCancel,
        thisSideLabel: l.linkedDeleteThisOnly,
        bothSidesLabel: l.linkedDeleteBoth,
        destructive: true,
      );
      if (choice == null || !context.mounted) return;
      await _deleteNow(
        context,
        l,
        alsoDeleteLink: choice == LinkedChoice.bothSides,
      );
      return;
    }
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
    await _deleteNow(context, l, repayment: repayment);
  }

  Future<void> _deleteNow(
    BuildContext context,
    AppLocalizations l, {
    bool repayment = false,
    bool? alsoDeleteLink,
  }) async {
    final tx = widget.tx;
    final router = GoRouter.of(context);
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    setSaving(true);
    try {
      final result = await txCubit.remove(
        tx.id,
        alsoDeleteLink: alsoDeleteLink,
      );
      accountsCubit.patchBalances(result.accountBalances);
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      if (router.canPop()) {
        router.pop();
      } else {
        back?.call();
      }
    } on ApiException catch (e) {
      if (!mounted || !context.mounted) return;
      setSaving(false);
      showSaveFailure(
        context,
        e,
        retry: () => _deleteNow(
          context,
          l,
          repayment: repayment,
          alsoDeleteLink: alsoDeleteLink,
        ),
      );
    }
  }
}

String _titleForType(AppLocalizations l, TransactionType t) => switch (t) {
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};

DetailRow _splitRow(BuildContext context, TxSplit s, VoidCallback onOpen) {
  final l = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final palette = Theme.of(context).extension<AppColors>()!;
  final person = s.person;
  String money(double v) => moneyString(context, v);
  final status = switch (s.status) {
    _ when s.isOverpaid =>
      s.owedToMe
          ? l.txSplitStatusOverpaidToThem(money(-s.outstanding))
          : l.txSplitStatusOverpaidByMe(money(-s.outstanding)),
    'settled' => s.owedToMe ? l.txSplitStatusPaid : l.txSplitStatusRepaid,
    'cancelled' => l.txSplitStatusCancelled,
    _ when s.settledAmount > 0.005 =>
      s.owedToMe
          ? l.txSplitStatusPartPaid(money(s.settledAmount), money(s.amount))
          : l.txSplitStatusPartRepaid(money(s.settledAmount), money(s.amount)),
    _ =>
      s.owedToMe
          ? l.txSplitStatusAwaiting(money(s.outstanding))
          : l.txSplitStatusToPay(money(s.outstanding)),
  };
  return DetailRow(
    label: s.personName,
    onTap: onOpen,
    leading: PersonMark(
      name: s.personName,
      level: s.contactId == null
          ? PersonLevel.name
          : person.linked
          ? PersonLevel.linked
          : PersonLevel.contact,
      iconCode: person.iconCode,
      size: 32,
      reserveLinkSlot: true,
    ),
    trailing: Column(
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
  );
}
