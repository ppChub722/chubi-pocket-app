import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';

/// `/transactions/:id` (§9): header (category icon · name · date · big
/// amount), a lock banner for system rows (opening balance / adjustment —
/// no ✏️ / 🗑), then rows: wallet, category, balance after, tags, note,
/// split, recorded by, source project.
class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    // Deep links: make sure the cache is there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final tx = context.read<TransactionsCubit>().byId(widget.transactionId);
        if (tx != null) return _Loaded(tx: tx);
        final loading = state.status == TransactionsStatus.loading ||
            state.status == TransactionsStatus.initial;
        return Scaffold(
          appBar: AppTopBar(title: l.navTransactions, showBack: true),
          body: loading
              ? const LoadingView()
              : EmptyView(
                  icon: AppIcons.empty,
                  title: l.transactionDetailNotFound,
                  message: l.transactionDetailNotFoundMessage,
                ),
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final cat = tx.categoryId == null
        ? null
        : context.watch<CategoriesCubit>().byId(tx.categoryId!);
    // Opening balance / adjustment rows are bookkeeping — read-only.
    // Transfers carry a system category too but have their own cascade.
    final isSystemRow =
        tx.type != TransactionType.transfer && (cat?.isSystem ?? false);
    final accent = cat?.iconCode?.accentColorFor(palette) ??
        switch (tx.type) {
          TransactionType.expense => palette.expense,
          TransactionType.income => palette.income,
          TransactionType.transfer => scheme.onSurfaceVariant,
        };
    final day = DateFormatter.parseDay(tx.date);
    final dateLabel = day == null
        ? tx.date
        : DateFormatter.friendly(day,
            today: l.commonToday,
            yesterday: l.commonYesterday,
            locale: Localizations.localeOf(context).languageCode);
    final hasNote = tx.note?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppTopBar(
        title: _titleForType(l, tx.type),
        showBack: true,
        actions: isSystemRow
            ? const []
            : [
                AppBarAction(
                  icon: AppIcons.delete,
                  tooltip: l.transactionDetailDelete,
                  destructive: true,
                  onPressed: () => _confirmDelete(context, l),
                ),
                AppBarAction(
                  icon: AppIcons.edit,
                  tooltip: l.transactionDetailEdit,
                  onPressed: () => context.push('/transactions/${tx.id}/edit'),
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        children: [
          HeaderCard(
            accent: accent,
            leading: IconBubble(
              icon: IconRegistry.get(
                cat?.iconCode?.icon,
                fallback: switch (tx.type) {
                  TransactionType.expense => AppIcons.expense,
                  TransactionType.income => AppIcons.income,
                  TransactionType.transfer => AppIcons.transfer,
                },
              ),
              color: accent,
              size: 44,
            ),
            title: Text(tx.category?.name ?? (hasNote ? tx.note! : '—')),
            subtitle: Text(dateLabel),
            footer: MoneyText(
              tx.signedAmount,
              tone: tx.type == TransactionType.transfer
                  ? MoneyTone.plain
                  : MoneyTone.signed,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (isSystemRow) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
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
                    child: Text(l.transactionDetailSystemRowBanner,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            children: [
              DetailRow(
                leading:
                    Icon(tx.account == null ? AppIcons.noWallet : AppIcons.bank),
                label: tx.type == TransactionType.transfer && tx.isTransferIn
                    ? l.txDetailTransferTo
                    : l.txDetailAccount,
                trailing: Text(tx.account?.name ?? l.transactionFormAccountNone),
                showChevron: tx.account != null,
                onTap: tx.account == null
                    ? null
                    : () => context.push('/accounts/${tx.account!.id}'),
              ),
              if (tx.type != TransactionType.transfer) ...[
                const RowDivider(),
                DetailRow(
                  leading: const Icon(AppIcons.category),
                  label: l.txDetailCategory,
                  trailing:
                      Text(tx.category?.name ?? l.transactionFormCategoryNone),
                ),
              ],
              if (tx.accountBalanceAfter != null) ...[
                const RowDivider(),
                DetailRow(
                  label: l.txDetailBalanceAfter,
                  trailing: MoneyText(tx.accountBalanceAfter!),
                ),
              ],
              if (tx.tags.isNotEmpty) ...[
                const RowDivider(),
                DetailStacked(
                  label: l.txDetailTags,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final t in tx.tags)
                        AppBadge(label: t.name, icon: AppIcons.tag),
                    ],
                  ),
                ),
              ],
              if (hasNote) ...[
                const RowDivider(),
                DetailStacked(label: l.txDetailNote, child: Text(tx.note!)),
              ],
              if (tx.hasSplits) ...[
                const RowDivider(),
                DetailRow(
                  leading: const Icon(AppIcons.split),
                  label: l.txDetailSplits,
                  trailing: Text(l.txDetailHasSplits),
                ),
              ],
              if (tx.createdBy != null) ...[
                const RowDivider(),
                DetailRow(
                  leading: UserAvatar(
                    displayName: tx.createdBy!.displayName,
                    iconCode: tx.createdBy!.iconCode,
                    size: 24,
                  ),
                  label: l.txDetailRecordedBy,
                  trailing: Text(tx.createdBy!.displayName),
                ),
              ],
              if (tx.projectId != null) ...[
                const RowDivider(),
                DetailRow(
                  leading: const Icon(AppIcons.project),
                  label: l.txDetailSource,
                  trailing: Text(l.txDetailSourceProject),
                  showChevron: true,
                  onTap: () => context.push('/projects/${tx.projectId}'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l) async {
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
    try {
      await txCubit.remove(tx.id);
      // A transfer moves two balances — a full reload keeps it simple.
      await accountsCubit.load();
      if (context.mounted) {
        showAppSnackBar(context, l.txDeleted, tone: Tone.success);
      }
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }
}

String _titleForType(AppLocalizations l, TransactionType t) => switch (t) {
      TransactionType.expense => l.transactionTypeExpense,
      TransactionType.income => l.transactionTypeIncome,
      TransactionType.transfer => l.transactionTypeTransfer,
    };
