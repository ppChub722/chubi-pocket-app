import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell/app_top_bar.dart';
import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../budgets/presentation/budget_labels.dart' show budgetRowMoney;
import '../cubit/archived_cubit.dart';
import '../data/archived_repository.dart';
import '../domain/archived_hub.dart';

class ArchivedPage extends StatelessWidget {
  const ArchivedPage({
    super.key,
    @visibleForTesting this.cubit,
    @visibleForTesting this.topBar,
  });

  /// Tests: a ready cubit instead of the one built from [ApiClient].
  final ArchivedCubit? cubit;

  final PreferredSizeWidget? topBar;

  @override
  Widget build(BuildContext context) {
    final view = _ArchivedView(topBar: topBar);
    final given = cubit;
    if (given != null) return BlocProvider.value(value: given, child: view);
    return BlocProvider(
      create: (context) => ArchivedCubit(
        repository: ArchivedRepository(client: context.read<ApiClient>()),
      )..load(),
      child: view,
    );
  }
}

class _ArchivedView extends StatelessWidget {
  const _ArchivedView({this.topBar});

  final PreferredSizeWidget? topBar;

  String _title(AppLocalizations l, ArchivedKind k) => switch (k) {
    ArchivedKind.wallets => l.archivedGroupWallets,
    ArchivedKind.budgets => l.archivedGroupBudgets,
    ArchivedKind.goals => l.archivedGroupGoals,
    ArchivedKind.events => l.archivedGroupEvents,
    ArchivedKind.contacts => l.archivedGroupContacts,
    ArchivedKind.recurring => l.archivedGroupRecurring,
  };

  IconData _fallback(ArchivedKind k) => switch (k) {
    ArchivedKind.wallets => AppIcons.wallet,
    ArchivedKind.budgets => AppIcons.budget,
    ArchivedKind.goals => AppIcons.savingGoal,
    ArchivedKind.events => AppIcons.project,
    ArchivedKind.contacts => AppIcons.contact,
    ArchivedKind.recurring => AppIcons.recurring,
  };

  String? _secondary(BuildContext context, AppLocalizations l, ArchivedItem i) {
    final s = i.secondary;
    if (s == null) return null;
    final amount = budgetRowMoney(context, s.amount);
    return switch (s.kind) {
      ArchivedSecondaryKind.balance => l.archivedSecondaryBalance(amount),
      ArchivedSecondaryKind.limit => l.archivedSecondaryLimit(amount),
      ArchivedSecondaryKind.target => l.archivedSecondaryTarget(amount),
      ArchivedSecondaryKind.planned => l.archivedSecondaryPlanned(amount),
      ArchivedSecondaryKind.amount => l.archivedSecondaryAmount(amount),
    };
  }

  String? _helper(
    BuildContext context,
    AppLocalizations l,
    String locale,
    ArchivedItem i,
  ) {
    final parts = [
      ?_secondary(context, l, i),
      if (i.archivedAt != null)
        l.archivedOn(DateFormatter.medium(i.archivedAt!, locale: locale)),
    ];
    return parts.isEmpty ? null : parts.join(' | ');
  }

  Future<void> _restore(
    BuildContext context,
    ArchivedKind kind,
    ArchivedItem item,
  ) async {
    final l = AppLocalizations.of(context)!;
    final err = await context.read<ArchivedCubit>().restore(kind, item.id);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      err == null ? l.archivedRestored(item.name) : err.message,
      tone: err == null ? Tone.success : Tone.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final state = context.watch<ArchivedCubit>().state;
    final hub = state.hub;
    return Scaffold(
      appBar: topBar ?? AppTopBar(title: l.settingsArchived, showBack: true),
      extendBodyBehindAppBar: true,
      body: ListPageBody(
        loading: hub == null && state.error == null,
        error: hub == null ? state.error : null,
        isEmpty: hub == null || hub.total <= 0,
        onRetry: context.read<ArchivedCubit>().load,
        sidePadding: 0,
        topInset: 0,
        empty: EmptyView(
          icon: AppIcons.archive,
          title: l.archivedEmpty,
          message: l.archivedEmptyMessage,
        ),
        children: [
          if (hub != null)
            for (final kind in ArchivedKind.values)
              if (hub.of(kind).isNotEmpty)
                SectionCard(
                  first:
                      kind ==
                      ArchivedKind.values.firstWhere(
                        (k) => hub.of(k).isNotEmpty,
                      ),
                  title: _title(l, kind),
                  children: [
                    for (final item in hub.of(kind))
                      DetailRow(
                        key: ValueKey('archived-${kind.key}-${item.id}'),
                        leading: Opacity(
                          opacity: 0.6,
                          child: IconCodeWidget(
                            iconCode: item.iconCode,
                            size: AvatarMetrics.sizeMedium,
                            fallbackIcon: _fallback(kind),
                          ),
                        ),
                        label: item.name,
                        helper: _helper(context, l, locale, item),
                        onTap: () =>
                            openPage(context, kind.detailPath(item.id)),
                        trailing: item.canRestore
                            ? AppChip(
                                label: l.archivedRestore,
                                icon: AppIcons.unarchive,
                                tone: AppChipTone.primary,
                                selected: true,
                                onTap: state.busy.contains(item.id)
                                    ? null
                                    : () => _restore(context, kind, item),
                              )
                            : null,
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}
