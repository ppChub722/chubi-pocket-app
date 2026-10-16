import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../recurring_item_actions.dart';
import '../recurring_rows.dart';
import '../recurring_writes.dart';
import 'recurring_settings_page.dart';

enum _Tab { produced, upcoming }

/// `/recurring/:id` — one recurring's items (owner 2026-10-13, part 2):
/// hero (✏️ → the settings page; status chip → พัก / ทำต่อ) → "ต่ออีก"
/// when it is ending → tabs [รายการ] (the produced items, linked 🔗 to a
/// draft / real tx; bulk like the pending page) and [ล่วงหน้า] (the upcoming
/// ones: a one-line summary until one was edited). Open = one call
/// (`getRecurring`, which also runs the due check — pull = recheck); every
/// action is one call whose result the page takes. Pops `true` when
/// anything changed.
class RecurringPage extends StatefulWidget {
  const RecurringPage({required this.id, super.key});

  final String id;

  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> {
  _Tab _tab = _Tab.produced;

  RecurringDetail? _detail;
  bool _loading = false;
  Object? _error;
  bool _busy = false;
  bool _changed = false;

  // Produced: page 1 comes with the detail; more pages on scroll.
  ItemPage _produced = const ItemPage();
  bool _producedMore = false;
  Object? _producedMoreError;
  final Set<String> _selected = {};

  // Upcoming: lazy, the first time the tab shows.
  ItemPage? _upcoming;
  bool _upcomingLoading = false;
  Object? _upcomingError;
  bool _upcomingMore = false;
  Object? _upcomingMoreError;
  bool _showUpcomingList = false;

  RecurringRepository get _repo => RecurringRepository.of(context);
  Recurring? get _recurring => _detail?.recurring;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _repo.get(widget.id);
      if (!mounted) return;
      _take(d);
      if (_upcoming != null) _loadUpcoming();
    } catch (e, st) {
      if (mounted) setState(() => _error = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The page takes a returned state (open, refresh, any recurring write).
  void _take(RecurringDetail d) {
    context.read<AccountsCubit>().patchBalances(d.balances);
    setState(() {
      _detail = d;
      _produced = d.produced;
      _selected.retainAll(d.produced.items.map((i) => i.id));
    });
  }

  Future<void> _loadMoreProduced() async {
    if (!_produced.hasMore || _producedMore) return;
    final current = _produced;
    setState(() {
      _producedMore = true;
      _producedMoreError = null;
    });
    try {
      final next = await _repo.items(
        widget.id,
        upcoming: false,
        page: current.page + 1,
      );
      if (mounted) setState(() => _produced = next.after(current));
    } catch (e, st) {
      if (mounted) {
        setState(() => _producedMoreError = ApiException.from(e, st));
      }
    } finally {
      if (mounted) setState(() => _producedMore = false);
    }
  }

  Future<void> _loadUpcoming() async {
    setState(() {
      _upcomingLoading = true;
      _upcomingError = null;
    });
    try {
      final page = await _repo.items(widget.id, upcoming: true);
      if (mounted) setState(() => _upcoming = page);
    } catch (e, st) {
      if (mounted) setState(() => _upcomingError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _upcomingLoading = false);
    }
  }

  Future<void> _loadMoreUpcoming() async {
    final current = _upcoming;
    if (current == null || !current.hasMore || _upcomingMore) return;
    setState(() {
      _upcomingMore = true;
      _upcomingMoreError = null;
    });
    try {
      final next = await _repo.items(
        widget.id,
        upcoming: true,
        page: current.page + 1,
      );
      if (mounted) setState(() => _upcoming = next.after(current));
    } catch (e, st) {
      if (mounted) {
        setState(() => _upcomingMoreError = ApiException.from(e, st));
      }
    } finally {
      if (mounted) setState(() => _upcomingMore = false);
    }
  }

  void _onTab(_Tab t) {
    setState(() => _tab = t);
    if (t == _Tab.upcoming && _upcoming == null && !_upcomingLoading) {
      _loadUpcoming();
    }
  }

  // ── Writes ──────────────────────────────────────────────────────────

  /// An item write: patch both lists in place. An item whose state moved
  /// between the tabs (e.g. sent to pending early) moves with it.
  void _applyItems(ItemWriteResult r) {
    _changed = true;
    final all = [..._produced.items, ...?_upcoming?.items];
    final known = {for (final i in all) i.id};
    final merged = [
      ...r.applyTo(all),
      for (final i in r.items)
        if (!known.contains(i.id)) i,
    ];
    final up = _upcoming;
    setState(() {
      _produced = ItemPage(
        items: [
          for (final i in merged)
            if (i.state != OccurrenceState.upcoming) i,
        ]..sort((a, b) => b.date.compareTo(a.date)),
        page: _produced.page,
        totalPages: _produced.totalPages,
      );
      if (up != null) {
        _upcoming = ItemPage(
          items: [
            for (final i in merged)
              if (i.state == OccurrenceState.upcoming) i,
          ]..sort((a, b) => a.date.compareTo(b.date)),
          page: up.page,
          totalPages: up.totalPages,
        );
      }
      _selected.removeAll(r.deletedIds);
    });
    _syncRecurring();
  }

  /// An item write does not return the setting, yet the header (next date,
  /// status, counts) moves with it, e.g. after the last installment. Re-read
  /// the setting quietly and keep the items the page already holds.
  Future<void> _syncRecurring() async {
    try {
      final d = await _repo.get(widget.id);
      if (!mounted) return;
      setState(
        () => _detail = RecurringDetail(
          recurring: d.recurring,
          produced: _detail?.produced ?? d.produced,
          balances: d.balances,
        ),
      );
    } on ApiException {
      // The next pull-to-refresh recovers.
    }
  }

  Future<void> _action(RecurringAction a) async {
    setState(() => _busy = true);
    try {
      final d = await _repo.action(widget.id, a);
      if (!mounted) return;
      _changed = true;
      HapticFeedback.mediumImpact();
      markRecurringChanged(context);
      _take(d);
      if (_upcoming != null) _loadUpcoming();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _batch(ItemBatchAction action) async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    ItemTarget? target;
    bool? deleteLinked;
    if (action == ItemBatchAction.create) {
      target = await askCreateTarget(context);
      if (target == null) return;
    } else if (action == ItemBatchAction.delete) {
      final linkedTx = _produced.items.any(
        (i) => _selected.contains(i.id) && i.transaction != null,
      );
      deleteLinked = await askDeleteLinked(
        context,
        linkedTx: linkedTx,
        count: ids.length,
      );
      if (deleteLinked == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final accounts = context.read<AccountsCubit>();
    try {
      final r = await _repo.batch(
        ids,
        action,
        target: target,
        deleteLinkedTx: deleteLinked,
      );
      accounts.patchBalances(r.balances);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      markRecurringChanged(context);
      _applyItems(r);
      setState(_selected.clear);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings() async {
    final result = await context.push<RecurringSettingsResult>(
      '/recurring/${widget.id}/settings',
    );
    if (!mounted || result == null) return;
    _changed = true;
    if (result.deleted) {
      context.pop(true);
      return;
    }
    final d = result.detail;
    if (d != null) _take(d);
    // A rule / value change rebuilds the upcoming items.
    if (_upcoming != null) _loadUpcoming();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final r = _recurring;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppTopBar(title: r?.name ?? l.recurringTitle, showBack: true),
        extendBodyBehindAppBar: true,
        body: r == null
            ? AsyncStateView.fallback(
                loading: _loading || _error == null,
                error: _error,
                onRetry: _load,
                notFound: EmptyView(
                  icon: AppIcons.empty,
                  title: l.recurringNotFound,
                  message: l.recurringNotFoundMessage,
                ),
              )
            : SavingOverlay(
                saving: _busy,
                child: TabbedDetailBody<_Tab>(
                  hero: _hero(l, r),
                  belowHero: [?_notice(l, r)],
                  compactBar: CompactHeroBar(
                    title: AppText(r.name, role: AppTextRole.title),
                    leading: r.isSaving
                        ? IconTile(
                            icon: AppIcons.savingDeposit,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          )
                        : IconDisplay(
                            type: IconType.category,
                            size: 28,
                            iconCode: r.iconCode ?? r.category?.iconCode,
                          ),
                    style: _style(r),
                  ),
                  tabs: [
                    AppTab(
                      value: _Tab.produced,
                      label: l.recurringTabProduced,
                      badgeCount: r.counts.notCreated,
                    ),
                    AppTab(
                      value: _Tab.upcoming,
                      label: l.recurringTabUpcomingShort,
                    ),
                  ],
                  selected: _tab,
                  onChanged: _onTab,
                  tabBuilder: (context, tab) => switch (tab) {
                    _Tab.produced => _producedTab(l, r),
                    _Tab.upcoming => _upcomingTab(l, r),
                  },
                ),
              ),
      ),
    );
  }

  /// Tint = the icon colour; the compact bar is the hero, small.
  HeroStyle _style(Recurring r) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeroStyle.tinted(
      color: (r.iconCode ?? r.category?.iconCode).tintFor(palette),
      glyph: AppIcons.scheduled,
    );
  }

  Widget _hero(AppLocalizations l, Recurring r) {
    final next = r.nextDate;
    return HeaderCard(
      heroStyle: _style(r),
      onEdit: _openSettings,
      topRow: [
        if (r.actions.pause || r.actions.resume)
          OptionMenuAnchor<RecurringAction>(
            options: [
              if (r.actions.pause)
                SheetOption(
                  value: RecurringAction.pause,
                  label: l.recurringPause,
                  leading: const AppIcon(AppIcons.pause),
                ),
              if (r.actions.resume)
                SheetOption(
                  value: RecurringAction.resume,
                  label: l.recurringResume,
                  leading: const AppIcon(AppIcons.resume),
                ),
            ],
            onSelected: _action,
            builder: (context, toggle) => _statusChip(l, r, onTap: toggle),
          )
        else
          _statusChip(l, r),
      ],
      leading: r.isSaving
          ? IconTile(
              icon: AppIcons.savingDeposit,
              color: Theme.of(context).colorScheme.primary,
              size: 52,
            )
          : IconDisplay(
              type: IconType.category,
              size: 52,
              iconCode: r.iconCode ?? r.category?.iconCode,
            ),
      title: AppText(r.name, role: AppTextRole.title, maxLines: 2),
      description: (r.description ?? '').trim().isEmpty
          ? null
          : AppText(r.description!, role: AppTextRole.caption, maxLines: 2),
      footer: MoneyText(
        signedOf(r.type, r.amount, saving: r.isSaving),
        tone: toneOf(r.type, saving: r.isSaving),
        style: AppTypography.of(context, AppTextRole.display),
      ),
      subtitle: AppText(
        [
          recurrenceLabel(
            l,
            r.rule,
            seq: r.progressTotal == null ? null : r.progressDone,
            total: r.progressTotal,
          ),
          if (next != null) dueLabel(l, date: next, daysUntil: r.daysUntil),
        ].join(' · '),
        role: AppTextRole.caption,
      ),
    );
  }

  /// The status chip; [onTap] (+ ▾) opens พัก / ทำต่อ.
  Widget _statusChip(AppLocalizations l, Recurring r, {VoidCallback? onTap}) {
    final (label, kind) = switch (r.status) {
      RecurringStatus.active => (l.recurringStatusActive, StatusKind.active),
      RecurringStatus.paused => (l.recurringStatusPaused, StatusKind.paused),
      RecurringStatus.archived => (
        l.recurringStatusArchived,
        StatusKind.archived,
      ),
    };
    return StatusChip(label: label, kind: kind, onTap: onTap);
  }

  /// Ending soon → "ต่ออีก"; paused → why nothing is produced.
  Widget? _notice(AppLocalizations l, Recurring r) {
    if (r.endingSoon && r.actions.extend) {
      return AppMessage(
        message: l.recurringEndingSoon(r.counts.upcoming),
        tone: Tone.warning,
        actions: [
          AppMessageAction(
            label: l.recurringExtend,
            onPressed: () => _action(RecurringAction.extend),
          ),
        ],
      );
    }
    if (r.status == RecurringStatus.paused) {
      return AppMessage(message: l.recurringPausedNotice);
    }
    return null;
  }

  Widget _producedTab(AppLocalizations l, Recurring r) {
    final items = _produced.items;
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: items.isEmpty,
      onRetry: _load,
      rowDividers: true,
      hasMore: _produced.hasMore,
      loadingMore: _producedMore,
      onLoadMore: _loadMoreProduced,
      loadMoreError: _producedMoreError,
      onRetryMore: _loadMoreProduced,
      header: [
        if (items.isNotEmpty)
          SelectionToolbar(
            selected: _selected.length,
            total: items.length,
            selectAllTooltip: l.recurringSelectAll,
            onSelectAll: () => setState(
              () => _selected.length == items.length
                  ? _selected.clear()
                  : _selected.addAll(items.map((i) => i.id)),
            ),
            actions: [
              SelectionAction(
                label: l.recurringItemCreate,
                icon: AppIcons.add,
                onTap: () => _batch(ItemBatchAction.create),
              ),
              SelectionAction(
                label: l.recurringItemArchive,
                icon: AppIcons.archive,
                onTap: () => _batch(ItemBatchAction.archive),
              ),
            ],
            deleteTooltip: l.commonDelete,
            onDelete: () => _batch(ItemBatchAction.delete),
          ),
      ],
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.recurringItemsEmpty,
        message: l.recurringItemsEmptyMessage,
        cta: AddTile(
          label: l.recurringAddItem,
          onTap: () => addRecurringItem(context, r, onChanged: _applyItems),
        ),
      ),
      children: [
        for (final group in groupItemsByDate(items)) ...[
          DateGroupHeader(label: itemDateLabel(context, group.date)),
          for (final item in group.items)
            RecurringItemActions(
              item: item,
              onChanged: _applyItems,
              onBusy: (b) => setState(() => _busy = b),
              builder: (context, open) => RecurringItemRow(
                item: item,
                select: SelectCheck(
                  value: _selected.contains(item.id),
                  onTap: () => setState(
                    () => _selected.contains(item.id)
                        ? _selected.remove(item.id)
                        : _selected.add(item.id),
                  ),
                ),
                onTap: open,
              ),
            ),
        ],
        AddTile(
          label: l.recurringAddItem,
          onTap: () => addRecurringItem(context, r, onChanged: _applyItems),
        ),
      ],
    );
  }

  Widget _upcomingTab(AppLocalizations l, Recurring r) {
    final page = _upcoming;
    final items = page?.items ?? const <RecurringItem>[];
    // Untouched: one line says it all (owner 2026-10-13); tap → the list.
    final summary = !r.editedAny && !_showUpcomingList && items.isNotEmpty;
    return ListPageBody(
      loading: page == null && _upcomingError == null,
      error: page == null ? _upcomingError : null,
      isEmpty: items.isEmpty,
      onRetry: _loadUpcoming,
      rowDividers: true,
      hasMore: !summary && (page?.hasMore ?? false),
      loadingMore: _upcomingMore,
      onLoadMore: _loadMoreUpcoming,
      loadMoreError: _upcomingMoreError,
      onRetryMore: _loadMoreUpcoming,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.recurringUpcomingEmpty,
        message: l.recurringUpcomingEmptyMessage,
      ),
      children: summary
          ? [
              ListRow(
                title: l.recurringUpcomingSummary(
                  r.name,
                  moneyString(context, r.amount),
                  recurrenceLabel(l, r.rule),
                ),
                subtitle: l.recurringUpcomingCount(r.counts.upcoming),
                trailing: const AppIcon(AppIcons.chevronRight),
                onTap: () => setState(() => _showUpcomingList = true),
              ),
            ]
          : [
              for (final group in groupItemsByDate(items)) ...[
                DateGroupHeader(label: itemDateLabel(context, group.date)),
                for (final item in group.items)
                  RecurringItemActions(
                    item: item,
                    onChanged: _applyItems,
                    onBusy: (b) => setState(() => _busy = b),
                    builder: (context, open) => RecurringItemRow(
                      item: item,
                      showState: false,
                      onTap: open,
                    ),
                  ),
              ],
            ],
    );
  }
}
