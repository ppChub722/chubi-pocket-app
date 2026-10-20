import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../data/recurring_link_repository.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../cubit/recurring_directory_cubit.dart';

/// One rule's occurrences around a tx date, and the one the BE would pick.
typedef OccurrenceLoader =
    Future<({List<RecurringItem> items, String? suggestedSlot})> Function(
      String ruleId,
      DateTime? txDate,
    );

/// The recurring a transaction links to, in two steps: the rule (nearest due
/// first, under น่าจะใช่ / รายการประจำ / เตือนจ่าย), then which of its
/// occurrences (งวดใกล้เคียง on top). A BE without occurrence slots stops at
/// the rule's present occurrence, unless a `loadOccurrences` is passed. With
/// [createRoute], "create a recurring" closes the sheet and opens it.
abstract final class RecurringPicker {
  static const _likely = 'likely';
  static const _recurring = 'recurring';
  static const _reminders = 'reminders';
  static const _create = 'create';

  static const _near = 'near';
  static const _due = 'due';
  static const _next = 'next';
  static const _past = 'past';
  static const _back = 'back';

  /// [txId] = the tx being linked: its own occurrence isn't "taken".
  static Future<LinkCandidate?> one(
    BuildContext context, {
    required TransactionType type,
    String? createRoute,
    String? selectedRuleId,
    String? selectedItemId,
    String? categoryId,
    double? amount,
    String? title,
    bool useRootNavigator = false,
    DateTime? txDate,
    String? txId,
    OccurrenceLoader? loadOccurrences,
  }) async {
    while (true) {
      final rule = await _rule(
        context,
        type: type,
        createRoute: createRoute,
        selectedRuleId: selectedRuleId,
        categoryId: categoryId,
        amount: amount,
        title: title,
        useRootNavigator: useRootNavigator,
      );
      final twoStep =
          rule?.occurrence.bySlot == true || loadOccurrences != null;
      if (rule == null || !twoStep || !context.mounted) return rule;
      final step = await _occurrence(
        context,
        rule,
        load: loadOccurrences ?? _repoLoader(context),
        useRootNavigator: useRootNavigator,
        selectedItemId: selectedItemId,
        txDate: txDate,
        txId: txId,
      );
      if (!step.back || !context.mounted) return step.pick;
    }
  }

  static OccurrenceLoader _repoLoader(BuildContext context) {
    final repo = RecurringRepository.of(context);
    return (ruleId, txDate) => repo.occurrences(ruleId, txDate: txDate);
  }

  static List<LinkCandidate> _byDue(List<LinkCandidate> all) =>
      [...all]..sort((a, b) => a.occurrence.date.compareTo(b.occurrence.date));

  static Future<LinkCandidate?> _rule(
    BuildContext context, {
    required TransactionType type,
    required String? createRoute,
    required String? selectedRuleId,
    required String? categoryId,
    required double? amount,
    required String? title,
    required bool useRootNavigator,
  }) async {
    final l = AppLocalizations.of(context)!;
    RecurringDirectoryCubit? cache;
    try {
      cache = context.read<RecurringDirectoryCubit>();
    } catch (_) {
      cache = null;
    }
    List<LinkCandidate> candidatesOf() => _byDue(
      cache?.candidates(type, categoryId: categoryId, amount: amount) ??
          const [],
    );
    var latest = candidatesOf();
    final start = latest;
    final feed = cache == null
        ? null
        : CubitFeed<RecurringDirectoryState, PickerData>(cache, (s) {
            latest = candidatesOf();
            return PickerData(
              _items(l, latest),
              loading:
                  s.status != RecurringDirectoryStatus.loaded &&
                  s.status != RecurringDirectoryStatus.error,
              error: s.error,
            );
          });
    unawaited(cache?.loadIfNeeded());
    try {
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: title ?? l.recurringPickerTitle,
          items: _items(l, latest),
          live: feed?.listenable,
          onRetry: cache?.load,
          onRefresh: cache == null
              ? null
              : syncRefreshOf(context, const {SyncSet.recurring}),
          selected: {?selectedRuleId},
          groups: [
            PickerGroup(_likely, l.recurringPickerGroupLikely),
            PickerGroup(_recurring, l.recurringPickerGroupRecurring),
            PickerGroup(_reminders, l.recurringPickerGroupReminders),
          ],
          actions: [
            if (createRoute != null)
              PickerAction(
                id: _create,
                label: l.recurringPickerCreate,
                icon: AppIcons.add,
                pinned: true,
              ),
          ],
          searchable: true,
          searchHint: l.recurringSearchHint,
          emptyText: l.recurringPickerEmpty,
          noMatchText: l.recurringNoMatch,
        ),
      );
      if (result == null) return null;
      if (result.action == _create) {
        if (context.mounted) openPage(context, createRoute!);
        return null;
      }
      final id = result.id;
      return latest.where((c) => c.setting.id == id).firstOrNull ??
          start.where((c) => c.setting.id == id).firstOrNull;
    } finally {
      unawaited(feed?.dispose());
    }
  }

  static List<PickerItem> _items(AppLocalizations l, List<LinkCandidate> all) =>
      [for (final c in all) _item(l, c)];

  static PickerItem _item(AppLocalizations l, LinkCandidate c) {
    final s = c.setting;
    final o = c.occurrence;
    final status = c.isReminder
        ? l.recurringPickerStatusReminder
        : switch (o.status) {
            'pending' => l.recurringPickerStatusPending,
            'not_created' || 'notCreated' => l.recurringPickerStatusNotCreated,
            _ => l.recurringPickerStatusUpcoming,
          };
    final period = l.recurringPickerPeriod(
      DateFormat.MMMd(l.localeName).format(o.date),
    );
    return PickerItem(
      id: s.id,
      title: s.name,
      subtitle: '${recurrenceLabel(l, s.rule)} | $period $status',
      group: c.likely ? _likely : (c.isReminder ? _reminders : _recurring),
      leading: c.isReminder
          ? const AppIcon(AppIcons.notifications)
          : IconDisplay(
              type: IconType.category,
              size: 36,
              iconCode: s.iconCode ?? s.category?.iconCode,
            ),
      trailing: _amount(l, s.type, o.amount),
    );
  }

  static Widget _amount(AppLocalizations l, TransactionType type, double? a) =>
      a == null
      ? AppText(l.recurringPickerAwaitingAmount, role: AppTextRole.caption)
      : MoneyText(
          a,
          tone: switch (type) {
            TransactionType.expense => MoneyTone.expense,
            TransactionType.income => MoneyTone.income,
            _ => MoneyTone.plain,
          },
        );

  /// Step 2. Picking an occurrence another tx holds asks "สลับ?" first; a no
  /// comes back here. `back` = the owner wants another rule.
  static Future<({LinkCandidate? pick, bool back})> _occurrence(
    BuildContext context,
    LinkCandidate rule, {
    required OccurrenceLoader load,
    required bool useRootNavigator,
    String? selectedItemId,
    DateTime? txDate,
    String? txId,
  }) async {
    final l = AppLocalizations.of(context)!;
    final setting = rule.setting;
    final byId = <String, RecurringItem>{};
    while (true) {
      if (!context.mounted) return (pick: null, back: false);
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: setting.name,
          items: const [],
          load: () async {
            final r = await load(setting.id, txDate);
            final open = [
              for (final i in r.items)
                if (i.state != OccurrenceState.archived) i,
            ];
            byId
              ..clear()
              ..addAll({for (final i in open) i.id: i});
            return [
              for (final i in open)
                _occItem(
                  l,
                  setting,
                  i,
                  nearest: i.slot == r.suggestedSlot,
                  txId: txId,
                ),
            ];
          },
          selected: {?selectedItemId},
          groups: [
            PickerGroup(_near, l.recurringPickerGroupNearest),
            PickerGroup(_due, l.occurrenceStateNotCreated),
            PickerGroup(_next, l.recurringPickerGroupNext),
            PickerGroup(_past, l.recurringPickerGroupPast),
          ],
          actions: [
            PickerAction(
              id: _back,
              label: l.recurringPickerOtherRule,
              icon: AppIcons.back,
              pinned: true,
            ),
          ],
        ),
      );
      if (result == null) return (pick: null, back: false);
      if (result.action == _back) return (pick: null, back: true);
      final item = byId[result.id];
      if (item == null || !context.mounted) return (pick: null, back: false);
      final taken = item.transaction;
      var replace = false;
      if (taken != null && taken.id != txId) {
        final swap = await showConfirmDialog(
          context,
          title: l.recurringLinkSwapTitle,
          message: l.recurringLinkSwapBody(
            taken.description ?? taken.accountName ?? setting.name,
          ),
          confirmLabel: l.recurringLinkSwapYes,
        );
        if (!swap) continue;
        replace = true;
      }
      return (
        pick: LinkCandidate(
          setting: setting,
          occurrence: LinkOccurrence.ofItem(item),
          likely: rule.likely,
          replace: replace,
        ),
        back: false,
      );
    }
  }

  static PickerItem _occItem(
    AppLocalizations l,
    Recurring s,
    RecurringItem i, {
    required bool nearest,
    String? txId,
  }) {
    final other = i.transaction?.id == txId ? null : i.transaction;
    return PickerItem(
      id: i.id,
      title: [
        i.state.label(l),
        if (i.seq != null && i.total != null) '${i.seq}/${i.total}',
      ].join(' | '),
      subtitle: other?.description ?? other?.accountName,
      group: nearest
          ? _near
          : switch (i.state) {
              OccurrenceState.notCreated || OccurrenceState.pending => _due,
              OccurrenceState.upcoming => _next,
              _ => _past,
            },
      leading: DateTile(date: i.date),
      trailing: _amount(l, s.type, i.amount),
    );
  }
}
