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
  late Future<List<Account>> _future = _fetch();
  final Set<String> _busy = {};

  /// Restored here: hidden from the list without a refetch.
  final Set<String> _restored = {};

  Future<List<Account>> _fetch() =>
      context.read<AccountsCubit>().listArchived();

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
    }
  }

  Future<void> _restore(Account a) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy.add(a.id));
    try {
      await context.read<AccountsCubit>().restore(a.id);
      if (!mounted) return;
      showAppSnackBar(context, l.accountRestored(a.name), tone: Tone.success);
      setState(() => _restored.add(a.id));
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
      body: FutureBuilder<List<Account>>(
        future: _future,
        builder: (context, snap) {
          final list = [
            for (final a in snap.data ?? const <Account>[])
              if (!_restored.contains(a.id)) a,
          ];
          return ListPageBody(
            loading: snap.connectionState != ConnectionState.done,
            error: snap.hasError
                ? ApiException.from(snap.error!, snap.stackTrace)
                : null,
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
