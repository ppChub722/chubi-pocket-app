import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category_tree.dart';
import '../../../categories/presentation/category_label.dart';
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
      body: QuickCreatePresetScope(
        preset: QuickCreatePreset(onAdd: () => context.push('/pending/new')),
        child: TabSwitchBody(
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
                          AppChip(
                            trailing: AppChipTrailing.dropdown,
                            label: switch (f) {
                              _Filter.all => l.pendingFilterAll(all.length),
                              _Filter.manual => l.pendingFilterManual(manual),
                              _Filter.others => l.pendingFilterOthers(others),
                            },
                            selected: _filter == f,
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
                        child: ListView(
                          // Room under the last row for the floating chat button.
                          padding: EdgeInsets.only(
                            bottom: 96 + MediaQuery.paddingOf(context).bottom,
                          ),
                          children: [
                            ..._rows(context, visible),
                            // "เพิ่มร่าง" closes the list.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.md,
                                AppSpacing.lg,
                                0,
                              ),
                              child: AddTile(
                                label: l.pendingAdd,
                                variant: AddTileVariant.row,
                                onTap: () => context.push('/pending/new'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rows under day headers (the draft's date; undated first) — the same
  /// grouping as the transaction list, newest day first.
  List<Widget> _rows(BuildContext context, List<PendingTransaction> visible) {
    final l = AppLocalizations.of(context)!;
    final days = <String, List<PendingTransaction>>{};
    for (final p in visible) {
      days.putIfAbsent(p.draft.date ?? '', () => []).add(p);
    }
    final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
    // '' (no date) sorts last descending; show it first.
    if (keys.remove('')) keys.insert(0, '');
    final out = <Widget>[];
    for (final k in keys) {
      final d = DateFormatter.parseDay(k);
      if (k.isNotEmpty) {
        out.add(
          DateGroupHeader(
            label: d == null
                ? k
                : DateFormatter.friendly(
                    d,
                    today: l.commonToday,
                    yesterday: l.commonYesterday,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
          ),
        );
      }
      for (final p in days[k]!) {
        out.add(
          _PendingCard(
            item: p,
            selected: _selected.contains(p.id),
            onToggle: () => setState(
              () => _selected.contains(p.id)
                  ? _selected.remove(p.id)
                  : _selected.add(p.id),
            ),
            onOpen: () => showQuickCreateSheet(context, draft: p),
          ),
        );
      }
    }
    return out;
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
          if (onImportSlip != null) ...[
            AppChip(
              icon: AppIcons.importSlip,
              label: l.pendingImportSlip,
              tone: AppChipTone.primary,
              selected: true,
              onTap: onImportSlip,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          BulkDeleteButton(tooltip: l.commonDelete, onPressed: onDiscard),
        ],
      ),
    );
  }
}

/// One draft, as the shared [TxRow] (same as the transaction list): the
/// source as a mini chip on line 2, a checkbox first, and why it can't go
/// yet (last submit error, or a field it still needs) under it. The date is
/// in the day-group header, not here.
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
    final d = item.draft;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final catCubit = context.watch<CategoriesCubit>();
    final tags = context.watch<TagsCubit>().state.tags;

    final category = catCubit.state.categories
        .where((c) => c.id == d.categoryId)
        .firstOrNull;
    final wallet = accounts.where((a) => a.id == d.accountId).firstOrNull;
    final toWallet = accounts
        .where((a) => a.id == d.transferToAccountId)
        .firstOrNull;
    // The draft's own title ("what for") first, else its category.
    final description = d.description?.trim() ?? '';
    final categoryName = category == null
        ? null
        : categoryDisplayName(l, category);
    final title = description.isNotEmpty
        ? description
        : categoryName ?? l.pendingUntitled;
    final rowTags = [
      for (final id in d.tagIds) ?tags.where((t) => t.id == id).firstOrNull,
    ];
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
    final Widget leading = category != null
        ? IconDisplay(
            type: IconType.category,
            size: 36,
            iconCode: CategoryTree.resolveIconCode(
              category,
              catCubit.state.categories,
            ),
          )
        : IconBubble(
            icon: switch (d.type) {
              TransactionType.income => AppIcons.income,
              TransactionType.transfer => AppIcons.transfer,
              _ => AppIcons.expense,
            },
            color: switch (d.type) {
              TransactionType.expense => palette.expense,
              TransactionType.income => palette.income,
              _ => scheme.onSurfaceVariant,
            },
            size: 36,
          );

    return TxRow(
      leading: leading,
      title: title,
      amount: d.amount ?? 0,
      tone: tone,
      select: SelectCheck(
        value: selected,
        tooltip: l.pendingSelectOne,
        onTap: onToggle,
      ),
      walletLabel: wallet?.name ?? l.transactionFormAccountNone,
      walletIcon: wallet == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: wallet.iconCode,
            ),
      source: AppChip(
        label: _sourceLabel(l, item.source),
        tone: item.source.isManual ? AppChipTone.info : AppChipTone.primary,
        selected: true,
        size: PillSize.mini,
      ),
      category: description.isNotEmpty ? categoryName : null,
      extra: d.type == TransactionType.transfer
          ? '→ ${toWallet?.name ?? '?'}'
          : null,
      tags: [
        for (final t in rowTags)
          TextSpan(
            text: '#${t.name}',
            style: TextStyle(
              color: tagColor(t.iconCode, palette),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
      warning: warn,
      warningColor: palette.warning,
      onTap: onOpen,
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
