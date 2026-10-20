import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/saving_goals_repository.dart';
import '../../domain/saving_goal.dart';
import '../../domain/saving_goals_overview.dart';

sealed class SavingBucketPick {
  const SavingBucketPick();

  /// null = the spare pot.
  String? get goalId;
}

class SavingGoalPicked extends SavingBucketPick {
  const SavingGoalPicked(this.goal);
  final SavingGoal goal;

  @override
  String get goalId => goal.id;
}

/// "ยังไม่จัดสรร" (the spare pot) was picked.
class SavingSparePicked extends SavingBucketPick {
  const SavingSparePicked();

  @override
  String? get goalId => null;
}

/// Where a saving goes or moves to: the spare pot and the active goals, as
/// two-column cards. [overview] = the goals to start from; without it they
/// are loaded.
abstract final class SavingGoalPicker {
  static const _spare = SavingGoalsRepository.spareId;

  static Future<SavingBucketPick?> one(
    BuildContext context, {
    String? selectedId,
    bool spareSelected = false,
    bool allowSpare = true,
    Set<String> excludeIds = const {},
    SavingGoalsOverview? overview,
    String? title,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final symbol = context.readUserCurrencySymbol;
    final repo = overview == null
        ? context.read<SavingGoalsRepository>()
        : null;
    var latest = overview;
    List<PickerItem> itemsOf(SavingGoalsOverview o) =>
        _items(l, o, allowSpare: allowSpare, excludeIds: excludeIds);

    final r = await showItemPicker(
      context,
      useRootNavigator: useRootNavigator,
      ItemPickerSheet(
        title: title ?? l.savingEntryPickGoal,
        items: overview == null ? const [] : itemsOf(overview),
        load: repo == null
            ? null
            : () async {
                try {
                  latest = await repo.list();
                } catch (e, st) {
                  throw ApiException.from(e, st);
                }
                return itemsOf(latest!);
              },
        layout: PickerLayout.cards,
        cardHeight: null,
        cardBuilder: (context, item, selected, onTap) => SavingGoalCard(
          pick: _pick(context, l, item, symbol),
          selected: selected,
          onTap: onTap ?? () {},
        ),
        selected: {if (spareSelected) _spare, ?selectedId},
        emptyText: l.sgv2EmptyFilteredTitle,
        noMatchText: l.multiPickNoMatch,
      ),
    );
    final id = r?.id;
    if (id == null) return null;
    if (id == _spare) return const SavingSparePicked();
    final goal = latest?.goals.where((g) => g.id == id).firstOrNull;
    return goal == null ? null : SavingGoalPicked(goal);
  }

  static List<PickerItem> _items(
    AppLocalizations l,
    SavingGoalsOverview o, {
    required bool allowSpare,
    required Set<String> excludeIds,
  }) => [
    if (allowSpare)
      PickerItem(
        id: _spare,
        title: l.savingEntrySpare,
        subtitle: l.sgv2SpareHint,
        data: o.spare,
      ),
    for (final g in o.goals)
      if (!excludeIds.contains(g.id))
        PickerItem(
          id: g.id,
          title: g.name,
          subtitle: g.description?.trim().isEmpty ?? true
              ? null
              : g.description!.trim(),
          data: g,
        ),
  ];

  static SavingGoalPick _pick(
    BuildContext context,
    AppLocalizations l,
    PickerItem item,
    String symbol,
  ) {
    String money(double v) => moneyString(context, v, symbol: symbol);
    return switch (item.data) {
      SavingGoal(:final iconCode, :final savedAmount, :final targetAmount) =>
        SavingGoalPick(
          id: item.id,
          name: item.title,
          icon: IconRegistry.get(iconCode?.icon, fallback: AppIcons.savingGoal),
          color: iconCode.tintFor(Theme.of(context).extension<AppColors>()!),
          amountText: money(savedAmount),
          targetText: targetAmount == null ? null : money(targetAmount),
          caption: item.subtitle,
        ),
      final data => SavingGoalPick(
        id: item.id,
        name: item.title,
        icon: AppIcons.quickSaving,
        color: ModuleColors.of(context).planning,
        amountText: data is SavingSpare ? money(data.amount) : null,
        caption: item.subtitle,
      ),
    };
  }
}
