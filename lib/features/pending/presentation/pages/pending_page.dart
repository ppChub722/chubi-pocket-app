import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../home/presentation/cubit/dashboard_cubit.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../saving_goals/presentation/cubit/saving_goals_cubit.dart';
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
      // Rows draw from each draft's `resolved`; these lists are only for the
      // edit sheet a row opens.
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  List<PendingTransaction> _visible(List<PendingTransaction> all) =>
      switch (_filter) {
        _Filter.all => all,
        _Filter.manual => all.where((p) => p.source.inManualBucket).toList(),
        _Filter.others => all.where((p) => !p.source.inManualBucket).toList(),
      };

  /// Confirms the ticked drafts that can go. A draft the server says can't
  /// be confirmed yet (`can_confirm` false) is never sent: alone, it opens
  /// the draft sheet to fill what is missing; among others it is skipped
  /// and counted as not done.
  Future<void> _submitSelected() async {
    final byId = {
      for (final p in context.read<PendingCubit>().state.items) p.id: p,
    };
    final blocked = [
      for (final id in _selected)
        if (byId[id] != null && !byId[id]!.canConfirm) byId[id]!,
    ];
    final ready = [
      for (final id in _selected)
        if (byId[id]?.canConfirm ?? true) id,
    ];
    if (ready.isEmpty && blocked.isNotEmpty) {
      await _open(blocked.first);
      return;
    }
    await _submit(ready, skipped: blocked.length);
  }

  Future<void> _submit(List<String> ids, {int skipped = 0}) async {
    final l = AppLocalizations.of(context)!;
    final pending = context.read<PendingCubit>();
    final accounts = context.read<AccountsCubit>();
    final goals = context.read<SavingGoalsCubit>();
    final dashboard = context.read<DashboardCubit>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final r = await pending.submit(ids);
      if (r.submitted.isNotEmpty) {
        accounts.patchBalances(r.accountBalances);
        // A saving draft makes no transaction row: the goals list and the
        // Home block go stale; the transaction lists re-fetch as before.
        goals.markStale();
        dashboard.markStale();
        await TransactionsCubit.bookChanged();
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selected.removeAll(r.submitted);
        _lastResult = (
          done: r.submitted.length,
          failed: r.failed.length + skipped,
        );
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
    try {
      await context.read<PendingCubit>().discardMany(ids);
      if (mounted) setState(() => _selected.removeAll(ids));
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<PendingCubit>().state;
    final all = state.items;
    final visible = _visible(all);
    // Counts are the server's summary from the last answer, as it is.
    final summary = state.summary;
    final manual = summary?.manual ?? 0;
    final others = summary?.notManual ?? 0;
    final total = summary?.count ?? 0;
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
                  submits: true,
                  onPressed: _submitSelected,
                ),
              ),
            ),
      // Pinned rows clear the floating bar; the list below them must not
      // add the bar height again.
      body: TabSwitchBody(
        child: ListPageBody(
          header: [
            if (visible.isNotEmpty)
              SelectionToolbar(
                selected: pickedVisible,
                total: visible.length,
                selectAllTooltip: l.pendingSelectAll,
                onSelectAll: () => setState(
                  () => pickedVisible == visible.length
                      ? _selected.removeAll(visible.map((p) => p.id))
                      : _selected.addAll(visible.map((p) => p.id)),
                ),
                trailing: [
                  if (canImportSlip)
                    AppChip(
                      icon: AppIcons.importSlip,
                      label: l.pendingImportSlip,
                      tone: AppChipTone.primary,
                      selected: true,
                      onTap: importSlip,
                    ),
                ],
                deleteTooltip: l.commonDelete,
                onDelete: () => _discardSelected(visible),
              ),
            if (others > 0)
              FilterBar(
                chips: [
                  for (final f in _Filter.values)
                    AppChip(
                      trailing: AppChipTrailing.dropdown,
                      label: switch (f) {
                        _Filter.all => l.pendingFilterAll(total),
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
                child: AppMessage(
                  message: l.pendingResult(result.done, result.failed),
                  tone: Tone.warning,
                  onClose: () => setState(() => _lastResult = null),
                ),
              ),
          ],
          loading:
              state.status == PendingStatus.initial ||
              state.status == PendingStatus.loading,
          error: state.error,
          isEmpty: visible.isEmpty,
          onRetry: context.read<PendingCubit>().load,
          // Rows are full-bleed (they pad themselves); the template's
          // bottomInset clears the floating chat button.
          topInset: 0,
          sidePadding: 0,
          // A hairline between rows (the default indent = a TxRow's text).
          rowDividers: true,
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
    );
  }

  /// A tap opens the draft in the `+` sheet (a 🐷 saving draft in its ออม
  /// form); confirming happens from the sheet.
  Future<void> _open(PendingTransaction p) async {
    await showQuickCreateSheet(context, draft: p);
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
            onOpen: () => _open(p),
          ),
        );
      }
    }
    return out;
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
    if (item.isSaving) {
      return PendingSavingRow(
        item: item,
        selected: selected,
        onToggle: onToggle,
        onOpen: onOpen,
      );
    }
    final d = item.draft;
    // Everything below comes from the draft's own `resolved` — no joins.
    final r = item.resolved;
    final category = r.category;
    final wallet = r.account;
    final toWallet = r.transferToAccount;
    // The draft's own title ("what for") first, else its category.
    final description = d.description?.trim() ?? '';
    final categoryName = category == null
        ? null
        : categoryDisplayName(l, category.toCategory());
    final title = description.isNotEmpty
        ? description
        : categoryName ?? l.pendingUntitled;
    final rowTags = r.tags;
    // Why it can't go yet: the server's `needs_input` (old API: the draft's
    // own gaps).
    final needs = item.needsInput;
    final warn = item.lastError != null
        ? pendingErrorText(l, item.lastError!)
        : needs != null
        ? (item.needs('type')
              ? l.pendingErrMissingType
              : item.needs('amount')
              ? l.pendingErrMissingAmount
              : null)
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
    // A sub-category carries its own icon, so no parent lookup.
    final Widget leading = category != null
        ? IconDisplay(
            type: IconType.category,
            size: 36,
            iconCode: category.iconCode,
          )
        : IconTile(
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
        label: _sourceLabel(l, item),
        // From a recurring item: 🔁 + its name · n/N (owner 2026-10-13).
        icon: item.source == PendingSource.recurring
            ? AppIcons.recurring
            : null,
        tone: item.source.isManual ? AppChipTone.info : AppChipTone.primary,
        selected: true,
        size: ChipSize.mini,
      ),
      category: description.isNotEmpty ? categoryName : null,
      extra: d.type == TransactionType.transfer
          ? '→ ${toWallet?.name ?? '?'}'
          : null,
      tags: [
        for (final t in rowTags)
          TextSpan(
            text: '#${t.name}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

  static String _sourceLabel(AppLocalizations l, PendingTransaction p) =>
      switch (p.source) {
        PendingSource.manual => l.pendingSourceManual,
        PendingSource.splitPaid => l.pendingSourceSplitPaid,
        PendingSource.projectCopy ||
        PendingSource.projectUpdate => l.pendingSourceProject,
        PendingSource.ocr => l.pendingSourceOcr,
        PendingSource.chat => l.pendingSourceChat,
        PendingSource.recurring =>
          p.recurringRef?.label(l.pendingSourceRecurring) ??
              l.pendingSourceRecurring,
        PendingSource.upcoming => l.pendingSourceUpcoming,
        PendingSource.other => l.pendingSourceOther,
      };
}

/// A 🐷 saving draft: the kit [SavingTxRow] in draft mode (wallet → goal, or
/// the spare bucket), a checkbox first, and why it can't go yet under it.
class PendingSavingRow extends StatelessWidget {
  const PendingSavingRow({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    super.key,
  });

  final PendingTransaction item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final d = item.draft;
    final wallet = item.resolved.account;
    final bucket = item.resolved.goal?.name ?? l.sgv2Spare;
    final note = d.note?.trim() ?? '';
    final needs = item.needsInput;
    final warn = item.lastError != null
        ? pendingErrorText(l, item.lastError!)
        : (needs != null ? item.needs('wallet') : wallet == null)
        ? l.pendingSavingNoWallet
        : (needs != null ? item.needs('amount') : (d.amount ?? 0) <= 0)
        ? l.pendingErrMissingAmount
        : null;
    final recurring = item.recurringRef;

    final row = SavingTxRow(
      kind: SavingTxKind.deposit,
      title: note.isNotEmpty ? note : bucket,
      amount: d.amount ?? 0,
      walletLabel: wallet?.name ?? l.transactionFormAccountNone,
      walletIcon: wallet == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: wallet.iconCode,
            ),
      to: bucket,
      draft: true,
      draftChips: [
        AppChip(
          label: l.sgv2KindSave,
          icon: AppIcons.savingDeposit,
          tone: AppChipTone.primary,
          selected: true,
          size: ChipSize.mini,
        ),
      ],
      source: item.source.isRecurring
          ? AppChip(
              label:
                  recurring?.label(l.pendingSourceRecurring) ??
                  l.pendingSourceRecurring,
              icon: item.source == PendingSource.recurring
                  ? AppIcons.recurring
                  : null,
              tone: AppChipTone.primary,
              selected: true,
              size: ChipSize.mini,
            )
          : null,
      select: SelectCheck(
        value: selected,
        tooltip: l.pendingSelectOne,
        onTap: onToggle,
      ),
      onTap: onOpen,
    );
    if (warn == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            warn,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.warning),
          ),
        ),
      ],
    );
  }
}
