import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/wallet_member.dart';
import '../cubit/accounts_cubit.dart';
import '../wallet_errors.dart';

/// The wallet settings bottom sheet (reached via the ... overflow menu) —
/// spec §14.
///
/// - **Members** — always available (inviting the first member is how a
///   personal wallet converts to shared). Pushes the members screen.
/// - **Report scope** — every wallet (spec §14/5), bound to the caller's
///   own membership via `PUT /v1/accounts/:id/report-scope`. Shared
///   wallets offer none / own / all; personal wallets hide `own` (with a
///   single member, "own" and "all" are the same thing) and offer just
///   none / all. State reflects the server's `my_report_scope`
///   (auto-`none` right after conversion; personal wallets backfilled
///   to `all`).
Future<void> showWalletSettingsSheet(
  BuildContext context, {
  required String accountId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<AccountsCubit>(),
      child: _WalletSettingsSheet(accountId: accountId),
    ),
  );
}

class _WalletSettingsSheet extends StatelessWidget {
  const _WalletSettingsSheet({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final account = context.read<AccountsCubit>().byId(accountId);
        if (account == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.walletSettingsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.group_outlined),
                title: Text(l.walletMembersTitle),
                subtitle: Text(
                  account.isShared
                      ? l.walletMembersCount(account.members.length)
                      : l.walletSettingsMembersSubtitlePersonal,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/accounts/$accountId/members');
                },
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.walletReportScopeTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.walletReportScopeHelper,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<WalletReportScope>(
                segments: [
                  ButtonSegment(
                    value: WalletReportScope.none,
                    label: Text(l.walletReportScopeNone),
                  ),
                  // "own" only makes sense with more than one member —
                  // on a personal wallet it's identical to "all".
                  if (account.isShared)
                    ButtonSegment(
                      value: WalletReportScope.own,
                      label: Text(l.walletReportScopeOwn),
                    ),
                  ButtonSegment(
                    value: WalletReportScope.all,
                    label: Text(l.walletReportScopeAll),
                  ),
                ],
                selected: {_effectiveScope(account.myReportScope, account.isShared)},
                onSelectionChanged: (selection) =>
                    _onScopeChanged(context, l, selection.first),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  /// A leftover `own` on a wallet that is no longer shared renders as
  /// `all` — the `own` segment isn't offered, and SegmentedButton requires
  /// the selected value to be among the segments.
  WalletReportScope _effectiveScope(WalletReportScope? scope, bool isShared) {
    final s = scope ?? WalletReportScope.none;
    if (!isShared && s == WalletReportScope.own) return WalletReportScope.all;
    return s;
  }

  Future<void> _onScopeChanged(
    BuildContext context,
    AppLocalizations l,
    WalletReportScope scope,
  ) async {
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cubit.setReportScope(accountId: accountId, scope: scope);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.walletReportScopeSaved)));
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(walletErrorMessage(l, e))));
    }
  }
}
