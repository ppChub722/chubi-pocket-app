import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../data/slip_qr_reader.dart';
import '../../domain/pending_transaction.dart';
import '../cubit/pending_cubit.dart';
import '../pending_errors.dart';

/// `/pending` — รอยืนยัน (owner design 2026-10-08). Drafts waiting to be
/// confirmed: not transactions yet, not in any total. Tap one to edit it
/// in the `+` sheet; tick several and submit them together — each goes
/// through on its own, the ones that fail stay here with the reason.
class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

enum _Filter { all, manual, others }

class _PendingPageState extends State<PendingPage> {
  final Set<String> _selected = {};
  _Filter _filter = _Filter.all;
  bool _submitting = false;
  ({int done, int failed})? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PendingCubit>().load();
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  List<PendingTransaction> _visible(List<PendingTransaction> all) =>
      switch (_filter) {
        _Filter.all => all,
        _Filter.manual => all.where((p) => p.source.isManual).toList(),
        _Filter.others => all.where((p) => !p.source.isManual).toList(),
      };

  Future<void> _submitSelected() async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selected.toList();
    setState(() => _submitting = true);
    try {
      final r = await pending.submit(ids);
      if (r.submitted.isNotEmpty) {
        await Future.wait([accounts.load(), TransactionsCubit.bookChanged()]);
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selected.removeAll(r.submitted);
        _lastResult = (done: r.submitted.length, failed: r.failed.length);
      });
      if (r.submitted.isNotEmpty) {
        showAppSnackBarOn(
          messenger,
          l.pendingSubmittedCount(r.submitted.length),
          tone: Tone.success,
          actionLabel: l.pendingSeeTransactions,
          onAction: () => openPage(context, '/transactions'),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  /// The ticked drafts among [visible] (owner 2026-10-10: no per-card trash
  /// — tick first, then 🗑 in the top row).
  Future<void> _discardSelected(List<PendingTransaction> visible) async {
    final ids = [
      for (final p in visible)
        if (_selected.contains(p.id)) p.id,
    ];
    if (ids.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: ids.length == 1
          ? l.pendingDiscardTitle
          : l.pendingDiscardSelectedTitle(ids.length),
      confirmLabel: l.quickDiscardConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final cubit = context.read<PendingCubit>();
    for (final id in ids) {
      try {
        await cubit.discard(id);
        if (mounted) setState(() => _selected.remove(id));
      } on ApiException catch (e) {
        if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<PendingCubit>().state;
    final all = state.items;
    final visible = _visible(all);
    final manual = all.where((p) => p.source.isManual).length;
    final others = all.length - manual;
    final pickedVisible = visible.where((p) => _selected.contains(p.id)).length;
    final result = _lastResult;
    // UI only for now — the slip scan itself isn't wired yet. Phone only:
    // no button at all on web (ML Kit has no web build).
    final canImportSlip = SlipQrReader.isSupported;
    void importSlip() {}

    return Scaffold(
      appBar: AppTopBar(title: l.pendingTitle),
      extendBodyBehindAppBar: true,
      // UI only for now — typing a draft in words isn't wired yet.
      floatingActionButton: ChatDial(
        hint: l.pendingChatHint,
        tooltip: l.pendingTypeIt,
        sendTooltip: l.pendingChatSend,
        closeTooltip: l.pendingChatClose,
      ),
      // One button, only while something is ticked — it takes the shell
      // nav's place instead of stacking on it.
      bottomNavigationBar: _selected.isEmpty
          ? null
          : ShellChromeHider(
              child: PinnedBar(
                child: AppButton(
                  label: l.pendingSubmitSelected(_selected.length),
                  expand: true,
                  loading: _submitting,
                  onPressed: _submitSelected,
                ),
              ),
            ),
      // Pinned rows clear the floating bar; the list below them must not
      // add the bar height again.
      body: TabSwitchBody(
        child: Builder(
          builder: (context) => MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top),
                if (visible.isNotEmpty)
                  _ToolRow(
                    picked: pickedVisible,
                    total: visible.length,
                    selectAllTooltip: l.pendingSelectAll,
                    onDiscard: pickedVisible == 0
                        ? null
                        : () => _discardSelected(visible),
                    onImportSlip: canImportSlip ? importSlip : null,
                    onSelectAll: () => setState(
                      () => pickedVisible == visible.length
                          ? _selected.removeAll(visible.map((p) => p.id))
                          : _selected.addAll(visible.map((p) => p.id)),
                    ),
                  ),
                if (others > 0)
                  FilterBar(
                    chips: [
                      for (final f in _Filter.values)
                        FilterDropdownChip(
                          label: switch (f) {
                            _Filter.all => l.pendingFilterAll(all.length),
                            _Filter.manual => l.pendingFilterManual(manual),
                            _Filter.others => l.pendingFilterOthers(others),
                          },
                          active: _filter == f,
                          // Ticks the new filter hides are dropped, so
                          // "ยืนยันที่เลือก (n)" counts and sends only
                          // what's on screen (owner 2026-10-10).
                          onTap: () => setState(() {
                            _filter = f;
                            final shown = _visible(all).map((p) => p.id);
                            _selected.retainAll(shown);
                          }),
                        ),
                    ],
                  ),
                if (result != null && result.failed > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: MessageBanner(
                      message: l.pendingResult(result.done, result.failed),
                      tone: Tone.warning,
                      onClose: () => setState(() => _lastResult = null),
                    ),
                  ),
                Expanded(
                  child: AsyncStateView(
                    loading:
                        state.status == PendingStatus.initial ||
                        state.status == PendingStatus.loading,
                    error: state.error,
                    isEmpty: visible.isEmpty,
                    onRetry: context.read<PendingCubit>().load,
                    skeleton: ListView(
                      children: [
                        for (var i = 0; i < 4; i++) const SkeletonListTile(),
                      ],
                    ),
                    empty: EmptyView(
                      icon: AppIcons.empty,
                      title: l.pendingEmptyTitle,
                      message: l.pendingEmptyMessage,
                      cta: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canImportSlip) ...[
                            AddTile(
                              label: l.pendingImportSlip,
                              icon: AppIcons.importSlip,
                              variant: AddTileVariant.row,
                              onTap: importSlip,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          AddTile(
                            label: l.pendingAdd,
                            onTap: () => context.push('/pending/new'),
                          ),
                        ],
                      ),
                    ),
                    builder: (context) => PullToRefresh(
                      onRefresh: context.read<PendingCubit>().load,
                      child: ListView.separated(
                        // Room under the last row for the floating chat button.
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          96 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: visible.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          // "เพิ่มร่าง" closes the list.
                          if (i == visible.length) {
                            return AddTile(
                              label: l.pendingAdd,
                              variant: AddTileVariant.row,
                              onTap: () => context.push('/pending/new'),
                            );
                          }
                          final p = visible[i];
                          return _PendingCard(
                            item: p,
                            selected: _selected.contains(p.id),
                            onToggle: () => setState(
                              () => _selected.contains(p.id)
                                  ? _selected.remove(p.id)
                                  : _selected.add(p.id),
                            ),
                            onOpen: () =>
                                showQuickCreateSheet(context, draft: p),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The thin row under the top bar (owner 2026-10-10):
/// `[☐ 2/5] ……… [🗑 ลบ] [นำเข้าสลิป]` — 🗑 acts on the ticked drafts.
class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.picked,
    required this.total,
    required this.selectAllTooltip,
    required this.onSelectAll,
    required this.onDiscard,
    required this.onImportSlip,
  });

  final int picked;
  final int total;
  final String selectAllTooltip;
  final VoidCallback onSelectAll;

  /// Null = nothing ticked (the pill dims).
  final VoidCallback? onDiscard;

  /// Null = no slip scan on this platform (no pill).
  final VoidCallback? onImportSlip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SelectAllCount(
            selected: picked,
            total: total,
            tooltip: selectAllTooltip,
            onTap: onSelectAll,
          ),
          const Spacer(),
          ActionPill(
            icon: AppIcons.delete,
            label: l.commonDelete,
            destructive: true,
            onTap: onDiscard,
          ),
          if (onImportSlip != null) ...[
            const SizedBox(width: AppSpacing.xs),
            ActionPill(
              icon: AppIcons.importSlip,
              label: l.pendingImportSlip,
              onTap: onImportSlip,
            ),
          ],
        ],
      ),
    );
  }
}

/// One draft: source · date, title + amount, details, and why it can't go
/// yet (last submit error, or a field it still needs).
class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final PendingTransaction item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final d = item.draft;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final tags = context.watch<TagsCubit>().state.tags;

    final category = categories.where((c) => c.id == d.categoryId).firstOrNull;
    final wallet = accounts.where((a) => a.id == d.accountId).firstOrNull;
    final toWallet = accounts
        .where((a) => a.id == d.transferToAccountId)
        .firstOrNull;
    // The draft's own title ("what for") first, else its category.
    final description = d.description?.trim() ?? '';
    final title = description.isNotEmpty
        ? description
        : category?.name ?? l.pendingUntitled;
    final meta = <String>[
      if (d.type == TransactionType.transfer)
        '${wallet?.name ?? '?'} → ${toWallet?.name ?? '?'}'
      else ...[
        if (description.isNotEmpty) ?category?.name,
        wallet?.name ?? l.transactionFormAccountNone,
      ],
    ].join(' · ');
    final rowTags = [
      for (final id in d.tagIds) ?tags.where((t) => t.id == id).firstOrNull,
    ];
    final date = DateTime.tryParse(d.date ?? '');
    final warn = item.lastError != null
        ? pendingErrorText(l, item.lastError!)
        : d.type == null
        ? l.pendingErrMissingType
        : (d.amount ?? 0) <= 0
        ? l.pendingErrMissingAmount
        : null;
    final tone = switch (d.type) {
      TransactionType.expense => MoneyTone.expense,
      TransactionType.income => MoneyTone.income,
      _ => MoneyTone.plain,
    };

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: item.lastError != null
              ? palette.warning
              : scheme.outlineVariant,
          width: item.lastError != null ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  0,
                  AppSpacing.sm,
                  0,
                ),
                child: SelectCheck(
                  value: selected,
                  tooltip: l.pendingSelectOne,
                  onTap: onToggle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: _sourceLabel(l, item.source),
                          tone: item.source.isManual ? Tone.info : Tone.primary,
                          dense: true,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (date != null)
                          Text(
                            DateFormatter.friendly(
                              date,
                              today: l.commonToday,
                              yesterday: l.commonYesterday,
                              locale: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        MoneyText(
                          d.amount ?? 0,
                          tone: tone,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (rowTags.isNotEmpty)
                      TagShortList(tags: rowTags, style: textTheme.bodySmall),
                    if (warn != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            AppIcons.warning,
                            size: 14,
                            color: palette.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              warn,
                              style: textTheme.labelSmall?.copyWith(
                                color: palette.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sourceLabel(AppLocalizations l, PendingSource s) =>
      switch (s) {
        PendingSource.manual => l.pendingSourceManual,
        PendingSource.splitPaid => l.pendingSourceSplitPaid,
        PendingSource.projectCopy ||
        PendingSource.projectUpdate => l.pendingSourceProject,
        PendingSource.ocr => l.pendingSourceOcr,
        PendingSource.chat => l.pendingSourceChat,
        PendingSource.other => l.pendingSourceOther,
      };
}
