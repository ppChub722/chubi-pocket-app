import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/period_summary_card.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart' show SharedWalletIconBadge;
import '../widgets/wallet_settings_sheet.dart';

/// `/accounts/:id` (§10): header (icon · name · type · balance, credit
/// utilization, "ปรับยอด"), members (shared) + wallet settings, info rows
/// (description, note, billing), period summary, the latest rows →
/// "ดูทั้งหมด ›". ✏️ (owner only — the BE checks) opens the edit form,
/// where archive lives.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final account = context.read<AccountsCubit>().byId(accountId);
        if (account != null) return _Loaded(account: account);
        return Scaffold(
          appBar: AppTopBar(title: l.navAccounts, showBack: true),
          body: state.status == AccountsStatus.loading
              ? const LoadingView()
              : EmptyView(
                  icon: AppIcons.empty,
                  title: l.accountDetailNotFound,
                  message: l.accountDetailNotFoundMessage,
                ),
        );
      },
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({required this.account});
  final Account account;

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> {
  Account get account => widget.account;

  @override
  void initState() {
    super.initState();
    // The global list is shared — scope it to this wallet for the preview.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionsCubit>().load(accountId: account.id);
      }
    });
  }

  bool _isOwner(BuildContext context) {
    if (!account.isShared) return true;
    final auth = context.read<AuthCubit>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : null;
    return account.members
        .any((m) => m.userId == uid && m.isActive && m.role == WalletRole.owner);
  }

  Future<void> _adjustBalance() async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<_AdjustBalanceResult>(
      context: context,
      builder: (_) => _AdjustBalanceDialog(account: account),
    );
    if (result == null || !mounted) return;
    final cubit = context.read<AccountsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final router = GoRouter.of(context);
    try {
      final outcome = await cubit.adjustBalance(
        id: account.id,
        newBalance: result.newBalance,
        note: result.note,
      );
      await txCubit.load(accountId: account.id);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.accountAdjustBalanceSuccess,
        tone: Tone.success,
        actionLabel: l.accountAdjustBalanceViewTransaction,
        onAction: () =>
            router.push('/transactions/${outcome.adjustmentTransactionId}'),
      );
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final a = account;
    final hasDesc = a.description?.trim().isNotEmpty ?? false;
    final hasNote = a.note?.trim().isNotEmpty ?? false;
    final hasBilling = a.type.isCredit &&
        (a.statementDate != null ||
            a.paymentDueDate != null ||
            a.minimumPayment != null);
    final rows = context.select<TransactionsCubit, List>(
        (c) => c.forAccount(a.id).take(5).toList());

    return Scaffold(
      appBar: AppTopBar(
        title: a.name,
        showBack: true,
        actions: [
          if (_isOwner(context))
            AppBarAction(
              icon: AppIcons.edit,
              tooltip: l.accountDetailEdit,
              onPressed: () => context.push('/accounts/${a.id}/edit'),
            ),
        ],
      ),
      body: PullToRefresh(
        onRefresh: () async {
          await Future.wait([
            context.read<AccountsCubit>().load(),
            context.read<TransactionsCubit>().load(accountId: a.id),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
          children: [
            _Header(account: a, onAdjust: _adjustBalance),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              children: [
                if (a.isShared && a.members.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: MemberStrip(
                      members: [
                        for (final m in a.members.where((m) => m.isActive || m.pending))
                          PersonRef(
                            name: m.displayName,
                            iconCode: m.iconCode,
                            isOwner: m.role == WalletRole.owner,
                            pending: m.pending,
                          ),
                      ],
                      avatarSize: 40,
                      onMemberTap: (_) =>
                          context.push('/accounts/${a.id}/members'),
                    ),
                  ),
                  const RowDivider(),
                ],
                DetailRow(
                  leading: const Icon(AppIcons.settings),
                  label: l.walletSettingsTitle,
                  showChevron: true,
                  onTap: () =>
                      showWalletSettingsSheet(context, accountId: a.id),
                ),
                if (hasDesc) ...[
                  const RowDivider(),
                  DetailStacked(
                      label: l.accountDetailDescription,
                      child: Text(a.description!.trim())),
                ],
                if (hasNote) ...[
                  const RowDivider(),
                  DetailStacked(
                      label: l.accountDetailNote, child: Text(a.note!.trim())),
                ],
                if (hasBilling) ...[
                  const RowDivider(),
                  if (a.statementDate != null)
                    DetailRow(
                      leading: const Icon(AppIcons.date),
                      label: l.accountDetailStatementDate,
                      trailing: Text(l.accountDetailDayOfMonth(a.statementDate!)),
                    ),
                  if (a.paymentDueDate != null)
                    DetailRow(
                      leading: const Icon(AppIcons.scheduled),
                      label: l.accountDetailPaymentDue,
                      trailing: Text(l.accountDetailDayOfMonth(a.paymentDueDate!)),
                    ),
                  if (a.minimumPayment != null)
                    DetailRow(
                      leading: const Icon(AppIcons.cash),
                      label: l.accountDetailMinimumPayment,
                      trailing: MoneyText(a.minimumPayment!),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PeriodSummaryCard(accountId: a.id),
            SectionHeader(
              title: l.accountDetailTransactionsTitle,
              actionLabel: rows.isEmpty ? null : l.accountDetailSeeAll,
              onAction: () => context.push('/accounts/${a.id}/transactions'),
            ),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(l.transactionsEmptyAccountMessage,
                          textAlign: TextAlign.center),
                    )
                  : Column(
                      children: [
                        for (final t in rows)
                          TransactionTile(
                              transaction: t, showAccount: false, showDate: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account, required this.onAdjust});

  final Account account;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final a = account;
    final accent = a.iconCode?.accentColorFor(palette) ?? palette.primary;
    final icon = IconDisplay(type: IconType.account, size: 52, iconCode: a.iconCode);
    return HeaderCard(
      accent: accent,
      leading: a.isShared ? SharedWalletIconBadge(size: 52, child: icon) : icon,
      title: Text(a.name),
      subtitle: Text([
        _typeLabel(context, a.type),
        a.currency,
        if (a.isShared) l.walletSharedLabel,
      ].join(' · ')),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: MoneyText(
                  a.balance,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: accent),
                ),
              ),
              AppButton(
                label: l.accountDetailAdjustBalance,
                icon: AppIcons.reset,
                variant: AppButtonVariant.tonal,
                onPressed: onAdjust,
              ),
            ],
          ),
          if (a.creditUtilization != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ProgressRow(
              value: a.creditUtilization!,
              color: accent,
              label: l.accountDetailCreditAvailable(
                moneyString(context, (a.creditLimit ?? 0) - a.balance.abs()),
                moneyString(context, a.creditLimit ?? 0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _typeLabel(BuildContext context, AccountType type) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case AccountType.cash:
      return l.accountTypeCash;
    case AccountType.bank:
      return l.accountTypeBank;
    case AccountType.eWallet:
      return l.accountTypeEWallet;
    case AccountType.creditCard:
      return l.accountTypeCreditCard;
    case AccountType.payLater:
      return l.accountTypePayLater;
  }
}

/// Result of the adjust-balance dialog. Returned via `Navigator.pop` so
/// the caller can issue the API call from outside the dialog's lifecycle.
class _AdjustBalanceResult {
  const _AdjustBalanceResult({required this.newBalance, this.note});
  final double newBalance;
  final String? note;
}

class _AdjustBalanceDialog extends StatefulWidget {
  const _AdjustBalanceDialog({required this.account});
  final Account account;

  @override
  State<_AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<_AdjustBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: widget.account.balance.toString(),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.accountAdjustBalanceTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.accountAdjustBalanceBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l.accountAdjustBalanceCurrentLabel}: ${CurrencyFormatter.format(widget.account.balance)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _balanceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: l.accountAdjustBalanceNewLabel,
                prefixText: '฿ ',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null) {
                  return l.accountAdjustBalanceInvalidAmount;
                }
                if (parsed == widget.account.balance) {
                  return l.accountAdjustBalanceNoChange;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.accountAdjustBalanceNoteLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final newBalance = double.parse(_balanceController.text.trim());
            final note = _noteController.text.trim();
            Navigator.of(context).pop(_AdjustBalanceResult(
              newBalance: newBalance,
              note: note.isEmpty ? null : note,
            ));
          },
          child: Text(l.accountAdjustBalanceConfirm),
        ),
      ],
    );
  }
}
