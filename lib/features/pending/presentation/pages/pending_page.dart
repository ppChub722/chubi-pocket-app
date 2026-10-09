import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/overlay_nav.dart';
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
    final txCubit = context.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selected.toList();
    setState(() => _submitting = true);
    try {
      final r = await pending.submit(ids);
      if (r.submitted.isNotEmpty) {
        await Future.wait([accounts.load(), txCubit.load()]);
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
          onAction: () => pushFromOverlay(context, '/transactions'),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _discard(PendingTransaction p) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.pendingDiscardTitle,
      confirmLabel: l.quickDiscardConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<PendingCubit>().discard(p.id);
      setState(() => _selected.remove(p.id));
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<PendingCubit>().state;
    final all = state.items;
    final visible = _visible(all);
    final manual = all.where((p) => p.source.isManual).length;
    final others = all.length - manual;
    final pickedVisible = visible.where((p) => _selected.contains(p.id)).length;
    final result = _lastResult;
    // UI only for now — the slip scan itself isn't wired yet. Phone only:
    // no button at all on web (ML Kit has no web build).
    final importSlip = SlipQrReader.isSupported
        ? AddTile(
            label: l.pendingImportSlip,
            icon: AppIcons.importSlip,
            variant: AddTileVariant.row,
            onTap: () {},
          )
        : null;
    final lead = importSlip == null ? 0 : 1;

    return Scaffold(
      appBar: AppTopBar(title: l.pendingTitle, showBack: true),
      extendBodyBehindAppBar: true,
      // UI only for now — typing a draft in words isn't wired yet.
      floatingActionButton: ChatDial(
        hint: l.pendingChatHint,
        tooltip: l.pendingTypeIt,
        sendTooltip: l.pendingChatSend,
        closeTooltip: l.pendingChatClose,
      ),
      // One button, only while something is ticked.
      bottomNavigationBar: _selected.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SafeArea(
                top: false,
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
      body: Builder(
        builder: (context) => MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top),
              if (visible.isNotEmpty)
                _SelectAllRow(
                  label: l.pendingSelectAll,
                  value: pickedVisible == 0
                      ? false
                      : (pickedVisible == visible.length ? true : null),
                  count: '$pickedVisible/${visible.length}',
                  onTap: () => setState(
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
                        onTap: () => setState(() => _filter = f),
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
                        if (importSlip != null) ...[
                          importSlip,
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: visible.length + lead + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        // "นำเข้าสลิป" opens the list, "เพิ่มร่าง" closes it.
                        if (i == 0 && importSlip != null) return importSlip;
                        if (i == visible.length + lead) {
                          return AddTile(
                            label: l.pendingAdd,
                            variant: AddTileVariant.row,
                            onTap: () => context.push('/pending/new'),
                          );
                        }
                        final p = visible[i - lead];
                        return _PendingCard(
                          item: p,
                          selected: _selected.contains(p.id),
                          onToggle: () => setState(
                            () => _selected.contains(p.id)
                                ? _selected.remove(p.id)
                                : _selected.add(p.id),
                          ),
                          onOpen: () => showQuickCreateSheet(context, draft: p),
                          onDiscard: () => _discard(p),
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
    );
  }
}

/// The thin row under the top bar: ○ เลือกทั้งหมด … 2/5.
class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({
    required this.label,
    required this.value,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool? value;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            SelectCheck(value: value, onTap: onTap),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              count,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
    required this.onDiscard,
  });

  final PendingTransaction item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDiscard;

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
    final title = (d.note?.trim().isNotEmpty ?? false)
        ? d.note!.trim()
        : category?.name ?? l.pendingUntitled;
    final meta = <String>[
      if (d.type == TransactionType.transfer)
        '${wallet?.name ?? '?'} → ${toWallet?.name ?? '?'}'
      else ...[
        ?category?.name,
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
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                semanticLabel: l.pendingSelectOne,
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
              IconButton(
                tooltip: l.pendingDiscardTitle,
                icon: const Icon(AppIcons.delete, size: 20),
                onPressed: onDiscard,
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
