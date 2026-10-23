import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';

class ArchivedAccountsPage extends StatefulWidget {
  const ArchivedAccountsPage({super.key});

  @override
  State<ArchivedAccountsPage> createState() => _ArchivedAccountsPageState();
}

class _ArchivedAccountsPageState extends State<ArchivedAccountsPage> {
  final Set<String> _busy = {};

  Future<void> _refresh() => context.read<AccountsCubit>().load();

  Future<void> _restore(Account a) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy.add(a.id));
    try {
      await context.read<AccountsCubit>().restore(a.id);
      if (!mounted) return;
      showAppSnackBar(context, l.accountRestored(a.name), tone: Tone.success);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy.remove(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.accountsArchivedTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, state) {
          final list = state.archivedAccounts;
          return ListPageBody(
            loading: state.status == AccountsStatus.loading && list.isEmpty,
            error: state.status == AccountsStatus.error ? state.error : null,
            isEmpty: list.isEmpty,
            onRetry: _refresh,
            sidePadding: 0,
            topInset: 0,
            empty: EmptyView(
              icon: AppIcons.archive,
              title: l.accountsArchivedEmpty,
              message: l.accountsArchivedEmptyMessage,
            ),
            children: [
              SectionCard(
                first: true,
                children: [
                  for (final a in list)
                    DetailRow(
                      leading: Opacity(
                        opacity: 0.6,
                        child: IconDisplay(
                          type: IconType.account,
                          size: AvatarMetrics.sizeMedium,
                          iconCode: a.iconCode,
                          fallbackColor: a.colorOf(context),
                        ),
                      ),
                      label: a.name,
                      helper: a.showsBalance
                          ? moneyString(context, a.balance)
                          : null,
                      trailing: !a.canEdit
                          ? null
                          : AppChip(
                              label: l.accountRestore,
                              icon: AppIcons.unarchive,
                              tone: AppChipTone.primary,
                              selected: true,
                              onTap: _busy.contains(a.id)
                                  ? null
                                  : () => _restore(a),
                            ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
