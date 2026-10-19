import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../tags/domain/tag.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/tx_form_options_cubit.dart';
import '../../../transactions/presentation/widgets/draft_form.dart';
import '../../../transactions/presentation/widgets/tx_compact_hero.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring_item.dart';
import '../recurring_item_actions.dart';

class RecurringItemPage extends StatefulWidget {
  const RecurringItemPage({required this.itemId, super.key});

  final String itemId;

  @override
  State<RecurringItemPage> createState() => _RecurringItemPageState();
}

class _RecurringItemPageState extends State<RecurringItemPage> {
  RecurringItem? _item;
  bool _fetching = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (_item == null) {
      setState(() {
        _fetching = true;
        _error = null;
      });
    }
    try {
      final item = await RecurringRepository.of(context).getItem(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _fetching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_item != null) {
        showAppSnackBar(context, e.message, tone: Tone.danger);
        return;
      }
      setState(() {
        _error = e;
        _fetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item != null) {
      return _Loaded(
        item: item,
        onChanged: (i) => setState(() => _item = i),
        onRefresh: _load,
      );
    }
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.quickUpcomingHintTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: AsyncStateView.fallback(
        loading: _fetching,
        error: _error?.statusCode == 404 ? null : _error,
        onRetry: _load,
        notFound: EmptyView(
          icon: AppIcons.empty,
          title: l.transactionDetailNotFound,
          message: l.transactionDetailNotFoundMessage,
        ),
      ),
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({
    required this.item,
    required this.onChanged,
    required this.onRefresh,
  });

  final RecurringItem item;
  final ValueChanged<RecurringItem> onChanged;
  final Future<void> Function() onRefresh;

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded>
    with EditModeMixin<_Loaded, PendingDraft> {
  final _c = DraftFormController();
  final _scroll = ScrollController();
  final _heroKey = GlobalKey();
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
    if (old.item != widget.item && !isEditing) _reload();
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Account> _accountPool() {
    final base =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final ids = {for (final a in base) a.id};
    return [
      ...base,
      for (final a in [widget.item.account, widget.item.toAccount])
        if (a != null && ids.add(a.id)) a.toAccount(),
    ];
  }

  List<Category> _categoryPool() {
    final base =
        maybeTxFormOptions(
          context,
          watch: false,
        )?.state.options?.categoryList ??
        context.read<CategoriesCubit>().state.categories;
    final embedded = widget.item.category;
    return [
      ...base,
      if (embedded != null && !base.any((c) => c.id == embedded.id))
        embedded.toCategory(),
    ];
  }

  void _prefill() {
    final i = widget.item;
    _restoring = true;
    _c.amount.clear();
    _c.tagIds.clear();
    _c.knownTags
      ..clear()
      ..addAll({
        for (final t in i.tags)
          t.id: Tag(id: t.id, name: t.name, iconCode: t.iconCode),
      });
    _c.prefill(
      i.toDraft(),
      accounts: _accountPool(),
      categories: _categoryPool(),
    );
    _restoring = false;
  }

  void _reload() {
    _prefill();
    resetDraft(_c.toDraft());
  }

  @override
  void onDraftRestored() {
    _restoring = true;
    _c.restoreTransaction(
      working,
      accounts: _accountPool(),
      categories: _categoryPool(),
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
          : 'amount';
      applyTextChange(field, next);
    } else {
      applyChange(next);
    }
  }

  void _longPressHint() => showAppSnackBar(
    context,
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

  /// A reminder may still have no amount; every other item needs one.
  String? _problem(AppLocalizations l) {
    final noAmountYet =
        widget.item.amount == null && _c.amount.text.trim().isEmpty;
    if (!noAmountYet && _c.amountValue <= 0) return l.quickAmountRequired;
    if (_c.isTransfer) {
      if (_c.account == null || _c.toAccount == null) {
        return l.txTransferNeedsTo;
      }
      if (_c.account!.id == _c.toAccount!.id) return l.txTransferSameWallet;
    }
    return null;
  }

  Future<bool> _write(
    Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ) async {
    final repo = RecurringRepository.of(context);
    final accounts = context.read<AccountsCubit>();
    try {
      final result = await run(repo);
      accounts.patchBalances(result.balances);
      HapticFeedback.mediumImpact();
      final fresh = result.items
          .where((i) => i.id == widget.item.id)
          .firstOrNull;
      if (fresh != null) {
        widget.onChanged(fresh);
      } else {
        await widget.onRefresh();
      }
      return true;
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
      return false;
    }
  }

  Future<void> _act(
    Future<ItemWriteResult> Function(RecurringRepository repo) run,
  ) async {
    setSaving(true);
    await _write(run);
    if (mounted) setSaving(false);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    commitTextSession();
    final problem = _problem(l);
    if (problem != null) {
      HapticFeedback.lightImpact();
      showAppSnackBar(context, problem, tone: Tone.danger);
      return;
    }
    final item = widget.item;
    var scope = EditScope.thisOne;
    if (item.recurring != null) {
      final picked = await askItemScope(context);
      if (picked == null || !mounted) return;
      scope = picked;
    }
    var alsoUpdateLink = false;
    if (item.linked) {
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
    final ok = await _write(
      (r) => r.updateItem(
        item.id,
        _c.toDraft(),
        scope: scope,
        alsoUpdateLink: alsoUpdateLink,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      setSaving(false);
      return;
    }
    commitSaved(working);
    showAppSnackBar(context, l.quickSaved, tone: Tone.success);
  }

  Future<void> _create() async {
    final target = await askCreateTarget(context);
    if (target == null || !mounted) return;
    await _act((r) => r.createFromItem(widget.item.id, target));
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final item = widget.item;
    final withTx = await askDeleteLinked(
      context,
      linkedTx: item.transaction != null,
    );
    if (withTx == null || !mounted) return;
    final repo = RecurringRepository.of(context);
    final accounts = context.read<AccountsCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final back = ShellBackScope.maybeOf(context);
    setSaving(true);
    try {
      final result = await repo.deleteItem(item.id, deleteLinkedTx: withTx);
      accounts.patchBalances(result.balances);
      showAppSnackBarOn(messenger, l.txDeleted, tone: Tone.success);
      if (router.canPop()) {
        router.pop();
      } else {
        back?.call();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  String _statusText(AppLocalizations l, RecurringItem i) => switch (i.state) {
    OccurrenceState.upcoming => l.recurringItemStatusUpcoming(
      DateFormatter.medium(
        i.date,
        locale: Localizations.localeOf(context).toLanguageTag(),
      ),
    ),
    OccurrenceState.notCreated => l.recurringItemStatusNotCreated,
    OccurrenceState.pending => l.recurringItemStatusPending,
    OccurrenceState.done => l.recurringItemStatusDone,
    OccurrenceState.archived => l.recurringItemStatusArchived,
  };

  List<Widget> _actionRows(AppLocalizations l, RecurringItem i) {
    DetailRow row(IconData icon, String label, VoidCallback onTap) =>
        DetailRow(icon: icon, label: label, onTap: onTap, showChevron: true);
    final archive = row(
      AppIcons.archive,
      l.recurringItemArchive,
      () => _act((r) => r.setItemArchived(i.id, archived: true)),
    );
    final tx = i.transaction;
    return switch (i.state) {
      OccurrenceState.upcoming => [
        row(
          AppIcons.pending,
          l.recurringItemSendNow,
          () => _act((r) => r.createFromItem(i.id, ItemTarget.pending)),
        ),
        archive,
      ],
      OccurrenceState.notCreated => [
        row(AppIcons.add, l.recurringItemCreate, _create),
        archive,
      ],
      OccurrenceState.archived => [
        row(AppIcons.add, l.recurringItemCreate, _create),
        row(
          AppIcons.unarchive,
          l.recurringItemRestore,
          () => _act((r) => r.setItemArchived(i.id, archived: false)),
        ),
      ],
      OccurrenceState.pending => [
        row(
          AppIcons.pending,
          l.recurringItemOpenPending,
          () => openPage(context, '/pending'),
        ),
      ],
      OccurrenceState.done => [
        if (tx != null)
          row(
            AppIcons.transactions,
            l.recurringItemOpenTx,
            () => openPage(context, '/transactions/${tx.id}'),
          ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final item = widget.item;
    final editing = isEditing;
    final parent = item.recurring;
    final seq = item.seq;
    final total = item.total;
    final recurringSlot = parent == null
        ? null
        : SplitRecurringSlot(
            name: parent.name,
            periodLabel: seq == null
                ? null
                : (total == null ? '$seq' : '$seq/$total'),
            onTap: () => openPage(context, '/recurring/${parent.id}'),
            editing: false,
          );

    return editScope(
      SavingOverlay(
        saving: isSaving,
        child: Scaffold(
          appBar: AppTopBar(
            title: _titleForType(l, item.type),
            showBack: true,
            editing: editing,
            onBack: handleBack,
          ),
          extendBodyBehindAppBar: true,
          body: Builder(
            builder: (context) => CompactHeroScope(
              heroKey: _heroKey,
              bar: _compactBar(context),
              child: DetailPageBody(
                onRefresh: widget.onRefresh,
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                topInset: MediaQuery.paddingOf(context).top + AppSpacing.md,
                bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
                hero: DraftForm(
                  controller: _c,
                  heroKey: _heroKey,
                  autofocus: false,
                  typeLocked: true,
                  cardsInHero: true,
                  allowSplits: false,
                  upcomingHint: editing,
                  editing: editing,
                  onEdit: enterEdit,
                  onEnterEdit: (f) => enterEdit(focus: f),
                  onViewTap: _longPressHint,
                  recurringSlot: recurringSlot,
                ),
                sections: [
                  (first) => SectionCard(
                    first: first,
                    title: l.recurringItemStatusTitle,
                    description: l.recurringItemStatusDescription,
                    children: [
                      DetailRow(
                        icon: AppIcons.scheduled,
                        label: _statusText(l, item),
                        trailing: OccurrenceStateChip(state: item.state),
                      ),
                      if (!editing) ..._actionRows(l, item),
                    ],
                  ),
                ],
                manage: editing
                    ? ManageSection(
                        deleteLabel: l.transactionDeleteThis,
                        onDelete: isSaving ? null : _delete,
                      )
                    : null,
                metaLines: detailMetaLines(
                  context,
                  createdAt: item.createdAt,
                  updatedAt: item.updatedAt,
                ),
              ),
            ),
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
          ? null
          : categoryDisplayName(AppLocalizations.of(context)!, category),
      categoryIcon: category?.iconCode,
      onTap: _scrollToTop,
    );
  }
}

String _titleForType(AppLocalizations l, TransactionType t) => switch (t) {
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};
