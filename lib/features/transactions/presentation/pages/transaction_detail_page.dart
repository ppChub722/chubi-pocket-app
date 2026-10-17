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
import '../../../projects/presentation/cubit/projects_cubit.dart';
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
  /// The open's one GET /transactions/:id is in flight.
  bool _fetching = true;

  /// Why it failed. A 404 is "not found"; anything else is an error view
  /// with a retry (a cached row still shows either way).
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    // A debt entry's wallet side opens in debt mode, which makes its own
    // one call (GET /personal-debts/{id}) — no plain read first.
    final cached = context.read<TransactionsCubit>().byId(widget.transactionId);
    if (cached?.isDebtEntry ?? false) {
      _fetching = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  /// The one call on open: the full row (split people included). A row
  /// already in the cache shows at once and is refreshed underneath. A plain
  /// read — it never re-fetches the list.
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
        // The wallet side of a debt entry: the same page in debt mode
        // (owner 2026-10-12).
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

/// The draft is the form's fields as a [PendingDraft] (Equatable), so the
/// mixin's dirty check and undo work on the shared [DraftFormController].
class _LoadedState extends State<_Loaded>
    with EditModeMixin<_Loaded, PendingDraft> {
  final _c = DraftFormController();

  /// The row the form edits: the page's row, or for an incoming transfer
  /// its outgoing twin — so the wallets read [จาก] → [ไป] and the save is
  /// the one made for that transfer.
  late Transaction _edited;

  String? _initialAccountId;
  String? _initialToAccountId;

  /// Pushing a draft into the controller — not a user edit.
  bool _restoring = false;

  /// The form was filled with the row's split people (or it has none).
  /// False = a list row with only split_count: the form's split list is
  /// empty, not "no splits" — editing them then would wipe the real ones.
  bool _splitsPrefilled = true;

  /// The page's scroll, and the hero the compact bar watches (it shows
  /// once the hero has scrolled under the top bar — view and edit; the
  /// title itself never changes, owner 2026-10-11).
  final _scroll = ScrollController();

  /// The รายการประจำ row: links right away (one call), never on บันทึก.
  final _link = RecurringLinkHandle();
  final _heroKey = GlobalKey();

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

  /// List rows carry only `split_count`; the people (the split list) come
  /// with GET /:id — which the page made on open. Only when that failed (a
  /// cached list row opened offline) is it tried again, before editing.
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

  // ── Recurring link ────────────────────────────────────────────────

  void _onLinkChanged() {
    if (mounted) setState(() {});
  }

  void _say(String message, {Tone tone = Tone.danger}) {
    if (mounted) showAppSnackBar(context, message, tone: tone);
  }

  /// Picks a recurring and links this row to it at once: one call, the
  /// answer's row goes into the cache (no refetch).
  Future<void> _linkRecurring() async {
    final tx = _edited;
    final picked = await _link.choose(
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
    if (picked == null || !mounted) return;
    final cubit = context.read<TransactionsCubit>();
    final accounts = context.read<AccountsCubit>();
    final linked = await _link.linkNow(
      context,
      tx.id,
      onLinked: (fresh, balances) {
        cubit.patchRow(fresh, afterWrite: true);
        accounts.patchBalances(balances);
      },
      error: _say,
    );
    // A failed link leaves nothing chosen.
    if (linked == null) _link.clear();
  }

  /// The ✕ of the saved link: one unlink call, then the cached row loses its
  /// recurring (no refetch).
  Future<void> _unlinkRecurring(String itemId) async {
    final cubit = context.read<TransactionsCubit>();
    final cached = widget.tx;
    await _link.unlinkNow(
      context,
      itemId,
      onUnlinked: () => cubit.patchRow(
        cached.copyWith(clearRecurringItem: true),
        afterWrite: true,
      ),
      error: _say,
    );
  }

  /// The row the form edits and the transfer's other wallet, both from the
  /// row itself (`transfer_peer` carries the twin's id and wallet): an
  /// incoming transfer is edited as its outgoing twin, so the wallets read
  /// [จาก] → [ไป] and the save is the one made for that transfer.
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

  /// Wallets / categories the form may select: the form options or the
  /// app's caches (the pickers' own pools) plus what the row embeds, so the
  /// row's own wallet and category are always found.
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

  // ── EditModeMixin ─────────────────────────────────────────────────

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

  /// The split editor is open (as last built) — then saving needs the
  /// split to add up.
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
    // Linked to an event bill / a recurring item (owner 2026-10-13): no
    // sync — ask whether the other side gets the change too.
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
    final projectsCubit = context.read<ProjectsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    try {
      final outcome = await saveTransactionEdit(
        context,
        t: _edited,
        c: _c,
        initialAccountId: _initialAccountId,
        initialToAccountId: _initialToAccountId,
        alsoUpdateLink: alsoUpdateLink,
      );
      // A date after today: it's an upcoming item now — not in the book, so
      // this page has nothing to show (owner 2026-10-13).
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
      showSaveFailure(
        context,
        e,
        retry: _save,
        message: splitErrorMessage(l, e) ?? walletErrorMessage(l, e),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tx = widget.tx;
    // Opening balance / adjustment rows are bookkeeping — read-only.
    // Transfers carry a system category too but have their own cascade.
    // (The row's embedded category says it: is_system / system_kind.)
    final isSystemRow =
        tx.type != TransactionType.transfer && (tx.category?.isSystem ?? false);
    final canEdit = !isSystemRow && !tx.isLocked;
    // A debt repayment (system Debt Paid / Received): not editable, but
    // deletable — its amount comes off the debt's repaid (BE v2).
    final isRepayment =
        isSystemRow && !tx.isLocked && (tx.category?.isDebtRepayment ?? false);
    // The row's author edits its splits in place (expense / income only);
    // anyone else sees them read-only, with the way to the debts.
    // Only once the form holds the real people — see [_splitsPrefilled].
    // Who may is one rule ([txCanEditSplits]: the BE's flag, else ours).
    final canEditSplits =
        canEdit && txCanEditSplits(_edited) && _splitsPrefilled;
    _splitsEditable = canEditSplits;
    final editing = isEditing;

    final splitCount = math.max(tx.splitCount, tx.splits.length);
    final hasSplits = splitCount > 0;
    final created = tx.createdAt;
    final updated = tx.updatedAt;
    // The bill this row is on (event_bill) opens on the event's board;
    // an older row without it opens the event.
    final bill = tx.eventBill;
    void openProject() => openPage(
      context,
      bill != null
          ? '/projects/${bill.event.id}?bill=${bill.billId}'
          : '/projects/${tx.projectId}',
    );
    // The one rule for the event card ([txCanJoinEvent]).
    final canJoinEvent = canEdit && txCanJoinEvent(_edited);

    // After the note (owner 2026-10-10). View: who it's split with, each
    // with where they stand, then the event card. Edit: what a saved row
    // can't change, read-only; the event card as a picker.
    // The sections after the form's own (owner 2026-10-10, rules #16 / #17
    // — the wallet / category detail kit): หารกับ, then อีเวนต์.
    final eventName =
        bill?.event.name ??
        (tx.projectId == null
            ? null
            : tx.project?.name ?? l.txDetailSourceProject);
    // View: a long-press on the แบ่งรายการ section enters edit mode, like the
    // note (owner 2026-10-11). Taps (a person → their debts) still go through.
    Widget splitsLongPressable(Widget section) => canEdit
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _enterEdit,
            child: section,
          )
        : section;
    // The "แบ่งยอด" row label, as the อีเวนต์ row's.
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
    // The one "แบ่งรายการ" section's two rows (never collapsible here):
    // [splitsReadOnly] where the people can't be edited (view mode, or not
    // mine to edit) and [eventSlot].
    final Widget? splitsReadOnly;
    final SplitEventSlot? eventSlot;
    if (editing) {
      // Can't edit these people here (another member's row, or the people
      // didn't load): say so; nothing in splits pushes a page.
      splitsReadOnly = hasSplits && !canEditSplits
          ? DetailRow(
              leading: const AppIcon(AppIcons.lock),
              label: l.txSplitPeopleLabel,
              helper: splitCount > 0
                  ? l.txDetailSplitEditElsewhere(splitCount)
                  : l.txSplitEditOnDebts,
            )
          : null;
      // Joins / moves / leaves on บันทึก (with the rest of the edit).
      eventSlot = canJoinEvent
          ? SplitEventSlot(
              name: _eventName(l, tx),
              onTap: _pickEvent,
              onClear: _eventName(l, tx) == null ? null : _clearEvent,
            )
          : eventName != null
          ? SplitEventSlot(name: eventName, locked: true)
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
          // Another member's row on a shared wallet: the BE keeps the
          // people to their author — say where to look, never a bare
          // count; tapping goes nowhere (owner 2026-10-10).
          ? splitsLongPressable(
              splitsBlock([DetailRow(label: l.txSplitSeeDebts)]),
            )
          : null;
      // Tapping opens the event — the one link here, like a split person →
      // their debts (owner 2026-10-10).
      eventSlot = eventName != null
          ? SplitEventSlot(name: eventName, onTap: openProject)
          : null;
    }

    // The รายการประจำ row of the "ผูกกับ" section (0.4.0): a linked row shows
    // its recurring (tap opens it; ✕ unlinks, one call); a row I can edit
    // shows the add chip, which links at once.
    final recurringItem = tx.recurringItem;
    final SplitRecurringSlot? recurringSlot = recurringItem == null && !canEdit
        ? null
        : _link.slot(
            context,
            type: _edited.type,
            linkedName: recurringItem?.label(l.quickUpcomingHintTitle),
            onOpenLinked: () => openPage(
              context,
              recurringItem?.recurringId == null
                  ? '/recurring?tab=upcoming'
                  : '/recurring/${recurringItem!.recurringId}',
            ),
            onTap: canEdit ? _linkRecurring : null,
            onUnlink: canEdit && recurringItem != null
                ? () => _unlinkRecurring(recurringItem.itemId)
                : null,
            error: _say,
            done: (m) => _say(m, tone: Tone.success),
          );

    // The very bottom: small muted record info, one item per line (owner
    // 2026-10-10).
    final metaLines = [
      if (tx.createdBy != null)
        l.txDetailMetaRecordedBy(tx.createdBy!.displayName),
      ...detailMetaLines(context, createdAt: created, updatedAt: updated),
    ];

    // A save / delete in flight dims the page and blocks input.
    return editScope(
      SavingOverlay(
        saving: isSaving,
        child: Scaffold(
          appBar: AppTopBar(
            // Never changes (owner 2026-10-11): edit mode shows in the fields
            // and the action bar, not the title.
            title: _titleForType(l, tx.type),
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          extendBodyBehindAppBar: true,
          // Builder: the body's context sees the bar height in padding.top.
          body: Builder(
            builder: (context) {
              // The hero in one row, pinned under the top bar once it has
              // scrolled away (kit CompactHeroScope).
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
                        // The wallet · category cards sit inside the hero.
                        cardsInHero: true,
                        allowSplits: canEditSplits,
                        // Editing to a date after today moves it to the
                        // upcoming items (owner 2026-10-13): say so.
                        upcomingHint: editing,
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
                        splitsReadOnly: splitsReadOnly,
                        eventSlot: eventSlot,
                        recurringSlot: recurringSlot,
                        // Moving into an event: the splits go with it
                        // (titled so).
                        eventPending:
                            _eventChange is NewEventTarget ||
                            _eventChange is ExistingEventTarget,
                      ),
                    ],
                  ),
                  sections: const [],
                  // Delete: edit mode, or a repayment's only action in view.
                  manage: (editing && canEdit) || isRepayment
                      ? ManageSection(
                          deleteLabel: l.transactionDeleteThis,
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

  /// The compact hero, from the form as it is now (view: the saved row;
  /// edit: what's being typed). Tap → back to the hero.
  CompactHeroBar _compactBar(BuildContext context) {
    final category = _c.isTransfer ? null : _c.category;
    return txCompactHeroBar(
      context,
      type: _c.type,
      description: _c.description.text,
      amount: _c.amountValue,
      // A sub-category carries its own icon (the API embeds it).
      categoryName: category == null
          ? _c.foreignCategoryName
          : categoryDisplayName(AppLocalizations.of(context)!, category),
      categoryIcon:
          category?.iconCode ??
          (category == null ? null : widget.tx.category?.iconCode),
      onTap: _scrollToTop,
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
    // Linked to an event bill / a recurring item (owner 2026-10-13): one
    // prompt asks whether the linked item goes too — it is the confirm.
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
      // The answer carries the wallets' new balances (both of a transfer).
      accountsCubit.patchBalances(result.accountBalances);
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      // Opened alone in its tab (from another tab) there's nothing to pop
      // — back to where the user came from.
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

/// One person of the "หารกับ" section (owner 2026-10-10):
///
///   (mark) ลี                          ฿120
///                                 รอคืน ฿20
///
/// A kit [DetailRow]: the row opens that person's debts; the amount and
/// where it stands are its trailing text.
DetailRow _splitRow(BuildContext context, TxSplit s, VoidCallback onOpen) {
  final l = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final palette = Theme.of(context).extension<AppColors>()!;
  // The person's look comes embedded in the split — no contacts cache.
  final person = s.person;
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
          : l.txSplitStatusPartRepaid(money(s.settledAmount), money(s.amount)),
    _ =>
      s.owedToMe
          ? l.txSplitStatusAwaiting(money(s.outstanding))
          : l.txSplitStatusToPay(money(s.outstanding)),
  };
  return DetailRow(
    label: s.personName,
    onTap: onOpen,
    // The kit's three looks, as on the edit chip — and the 🔗 slot kept so
    // the names line up (QA run-3 H).
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
