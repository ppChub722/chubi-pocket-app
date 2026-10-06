import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';

/// `/accounts/archived` — archived wallets with "กู้คืน" (§10).
class ArchivedAccountsPage extends StatefulWidget {
  const ArchivedAccountsPage({super.key});

  @override
  State<ArchivedAccountsPage> createState() => _ArchivedAccountsPageState();
}

class _ArchivedAccountsPageState extends State<ArchivedAccountsPage> {
  late Future<List<Account>> _future = _fetch();
  final Set<String> _busy = {};

  Future<List<Account>> _fetch() =>
      context.read<AccountsCubit>().listArchived();

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    await f;
  }

  Future<void> _restore(Account a) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy.add(a.id));
    try {
      await context.read<AccountsCubit>().restore(a.id);
      if (!mounted) return;
      showAppSnackBar(context, l.accountRestored(a.name), tone: Tone.success);
      await _refresh();
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
      body: FutureBuilder<List<Account>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(children: [
              for (var i = 0; i < 3; i++) const SkeletonListTile(),
            ]);
          }
          final list = snap.data ?? const <Account>[];
          if (list.isEmpty) {
            return EmptyView(
              icon: AppIcons.archive,
              title: l.accountsArchivedEmpty,
              message: '',
            );
          }
          return PullToRefresh(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final a in list)
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    leading: Opacity(
                      opacity: 0.6,
                      child: IconDisplay(
                          type: IconType.account, size: 40, iconCode: a.iconCode),
                    ),
                    title: Text(a.name),
                    subtitle: MoneyText(a.balance),
                    trailing: _busy.contains(a.id)
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : AppButton(
                            label: l.accountRestore,
                            icon: AppIcons.unarchive,
                            variant: AppButtonVariant.tonal,
                            onPressed: () => _restore(a),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
