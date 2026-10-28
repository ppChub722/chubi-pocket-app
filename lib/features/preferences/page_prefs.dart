import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/logger/app_logger.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart' show AppIcons;
import '../auth/domain/user.dart';
import '../auth/presentation/cubit/auth_cubit.dart';
import '../users/data/users_repository.dart';

/// Remembered list choices per page (0.4.1-2 P6, owner: "remember the last
/// choice"): one `page_prefs` value on the account, changed from the page
/// itself or from Settings › ตัวกรองและการเรียง. Each page stores small
/// wire strings (its enum names) under the keys listed in [pagePrefPages];
/// tabs, periods, search and the toolbar's open state are NOT kept.

/// One option of a choice field: its wire value and label.
class PagePrefOption {
  const PagePrefOption(this.wire, this.label);

  final String wire;
  final String Function(AppLocalizations l) label;
}

/// One remembered choice of a page: a pick of [options] (first = default),
/// or, with [options] empty, a set of ids / tokens (collapsed parents,
/// colour / icon filters) that only the page itself sets.
class PagePrefField {
  const PagePrefField(this.key, this.title, this.options);

  const PagePrefField.set(this.key, this.title) : options = const [];

  final String key;
  final String Function(AppLocalizations l) title;
  final List<PagePrefOption> options;

  bool get isSet => options.isEmpty;
  String get defaultWire => options.isEmpty ? '' : options.first.wire;

  /// The stored pick, else the default (an unknown stored value = default).
  String pick(Map<String, dynamic> pref) {
    final v = pref[key];
    return options.any((o) => o.wire == v) ? v as String : defaultWire;
  }

  /// The stored set (empty = none).
  List<String> picks(Map<String, dynamic> pref) => [
    for (final v in (pref[key] as List?) ?? const []) ?v as String?,
  ];

  PagePrefOption option(String wire) =>
      options.firstWhere((o) => o.wire == wire, orElse: () => options.first);
}

class PagePrefPage {
  const PagePrefPage(this.id, this.title, this.icon, this.fields)
    : soon = false;

  /// A page that remembers nothing yet: shown as "เร็วๆ นี้", not tappable.
  const PagePrefPage.soon(this.id, this.title, this.icon)
    : fields = const [],
      soon = true;

  final String id;

  /// The page's name as เพิ่มเติม / the nav bar shows it.
  final String Function(AppLocalizations l) title;

  /// The module icon (เพิ่มเติม / the nav bar / the top chips).
  final IconData icon;
  final List<PagePrefField> fields;
  final bool soon;

  /// True when [pref] holds anything other than the defaults.
  bool changed(Map<String, dynamic> pref) => fields.any(
    (f) => f.isSet ? f.picks(pref).isNotEmpty : f.pick(pref) != f.defaultWire,
  );
}

String _sort(AppLocalizations l) => l.pagePrefSort;
String _filter(AppLocalizations l) => l.pagePrefFilter;
String _status(AppLocalizations l) => l.pagePrefStatus;

/// Every page with remembered choices (the server's page ids).
final List<PagePrefPage> pagePrefPages = [
  PagePrefPage(
    PagePrefIds.transactions,
    (l) => l.navTransactions,
    AppIcons.transactions,
    [
      PagePrefField('sort', _sort, [
        PagePrefOption('date_desc', (l) => l.transactionsSortNewest),
        PagePrefOption('date_asc', (l) => l.transactionsSortOldest),
        PagePrefOption('amount_desc', (l) => l.transactionsSortAmountHigh),
        PagePrefOption('amount_asc', (l) => l.transactionsSortAmountLow),
      ]),
      PagePrefField.set('types', (l) => l.transactionsFilterType),
      PagePrefField.set('wallets', (l) => l.transactionsFilterAccount),
      PagePrefField.set('categories', (l) => l.transactionsFilterCategory),
      PagePrefField.set('tags', (l) => l.transactionsFilterTag),
      PagePrefField.set('amount', (l) => l.txFilterAmount),
    ],
  ),
  PagePrefPage(
    PagePrefIds.notifications,
    (l) => l.notificationsTitle,
    AppIcons.notifications,
    [
      PagePrefField('filter', _filter, [
        PagePrefOption('all', (l) => l.notifTileAll),
        PagePrefOption('needsAnswer', (l) => l.notifTileNeedsAnswer),
        PagePrefOption('unread', (l) => l.notifTileUnread),
        PagePrefOption('hidden', (l) => l.notifTileHidden),
      ]),
    ],
  ),
  PagePrefPage(PagePrefIds.wallets, (l) => l.navAccounts, AppIcons.wallet, [
    PagePrefField('sort', _sort, [
      PagePrefOption('custom', (l) => l.accountsSortCustom),
      PagePrefOption('type', (l) => l.fpWalletsSortByType),
      PagePrefOption('balance', (l) => l.accountsSortBalance),
      PagePrefOption('name', (l) => l.accountsSortName),
    ]),
    PagePrefField('tile', _filter, [
      PagePrefOption('all', (l) => l.fpWalletsFilterAll),
      PagePrefOption('cash', (l) => l.fpWalletsFilterCash),
      PagePrefOption('card', (l) => l.fpWalletsFilterCard),
    ]),
  ]),
  PagePrefPage(PagePrefIds.budgets, (l) => l.moreBudgets, AppIcons.budget, [
    PagePrefField('filter', _status, [
      PagePrefOption('active', (l) => l.bgFilterActive),
      PagePrefOption('ended', (l) => l.bgFilterEnded),
      PagePrefOption('archived', (l) => l.bgFilterArchived),
    ]),
    PagePrefField('health', _filter, [
      PagePrefOption('all', (l) => l.bgTileAll),
      PagePrefOption('normal', (l) => l.bgTileOk),
      PagePrefOption('near', (l) => l.bgStatWarn),
      PagePrefOption('over', (l) => l.bgStatOver),
    ]),
    PagePrefField('sort', _sort, [
      PagePrefOption('risk', (l) => l.bgSortRisk),
      PagePrefOption('alphabetical', (l) => l.bgSortName),
      PagePrefOption('newest', (l) => l.bgSortNewest),
    ]),
  ]),
  PagePrefPage(
    PagePrefIds.goals,
    (l) => l.moreSavingGoals,
    AppIcons.savingGoal,
    [
      PagePrefField('filter', _status, [
        PagePrefOption('active', (l) => l.sgv2FilterActive),
        PagePrefOption('completed', (l) => l.sgv2FilterCompleted),
        PagePrefOption('archived', (l) => l.sgv2FilterArchived),
      ]),
      PagePrefField('chip', _filter, [
        PagePrefOption('all', (l) => l.fpGoalsFilterAll),
        PagePrefOption('short', (l) => l.fpGoalsFilterShort),
        PagePrefOption('done', (l) => l.fpGoalsReached),
        PagePrefOption('free', (l) => l.fpGoalsFilterFree),
      ]),
      PagePrefField('sort', _sort, [
        PagePrefOption('needFirst', (l) => l.fpGoalsSortNeed),
        PagePrefOption('created', (l) => l.fpM5GoalsSortCreated),
        PagePrefOption('deadline', (l) => l.fpM5GoalsSortDeadline),
        PagePrefOption('progress', (l) => l.fpM5GoalsSortProgress),
        PagePrefOption('remaining', (l) => l.fpM5GoalsSortRemaining),
        PagePrefOption('byName', (l) => l.fpM5GoalsSortName),
      ]),
    ],
  ),
  PagePrefPage(
    PagePrefIds.recurring,
    (l) => l.moreRecurring,
    AppIcons.recurring,
    [
      PagePrefField('status', _status, [
        PagePrefOption('all', (l) => l.recurringFilterAllStatus),
        PagePrefOption('toFill', (l) => l.fpRecurringAwaitingValue),
        PagePrefOption('toConfirm', (l) => l.occurrenceStateNotCreated),
        PagePrefOption('upcoming', (l) => l.occurrenceStateUpcoming),
        PagePrefOption('done', (l) => l.occurrenceStateDone),
        PagePrefOption('skipped', (l) => l.occurrenceStateArchived),
      ]),
      PagePrefField('kind', (l) => l.pagePrefKind, [
        PagePrefOption('all', (l) => l.recurringFilterAllKinds),
        PagePrefOption('subscription', (l) => l.fpRecurringKindSubscription),
        PagePrefOption('installment', (l) => l.fpRecurringKindInstallment),
        PagePrefOption('income', (l) => l.fpRecurringKindIncome),
        PagePrefOption('reminder', (l) => l.fpRecurringKindReminder),
        PagePrefOption('saving', (l) => l.fpRecurringKindSaving),
        PagePrefOption('debt', (l) => l.fpRecurringKindDebt),
      ]),
      PagePrefField('sort', _sort, [
        PagePrefOption('date', (l) => l.recurringSortDate),
        PagePrefOption('amount', (l) => l.recurringSortAmount),
        PagePrefOption('name', (l) => l.commonName),
      ]),
    ],
  ),
  PagePrefPage(PagePrefIds.events, (l) => l.moreProjects, AppIcons.project, [
    PagePrefField('sort', _sort, [
      PagePrefOption('newest', (l) => l.fpEventsSortRecent),
      PagePrefOption('oldest', (l) => l.fpEventsSortOldest),
      PagePrefOption('amount', (l) => l.fpEventsSortAmount),
    ]),
  ]),
  PagePrefPage(
    PagePrefIds.categories,
    (l) => l.moreCategories,
    AppIcons.category,
    [
      PagePrefField.set('collapsed', (l) => l.pagePrefCollapsed),
      PagePrefField.set('colors', (l) => l.iconMakerTabColor),
      PagePrefField.set('icons', (l) => l.iconMakerRoleIcon),
    ],
  ),
  PagePrefPage(PagePrefIds.tags, (l) => l.moreTags, AppIcons.tag, [
    PagePrefField('sort', _sort, [
      PagePrefOption('name', (l) => l.tagFormNameLabel),
      PagePrefOption('usage', (l) => l.tagsSortUsage),
      PagePrefOption('color', (l) => l.tagFormColorLabel),
      PagePrefOption('icon', (l) => l.tagFormIconLabel),
    ]),
    PagePrefField.set('colors', (l) => l.tagFormColorLabel),
    PagePrefField.set('icons', (l) => l.tagFormIconLabel),
  ]),
  PagePrefPage(PagePrefIds.contacts, (l) => l.moreContacts, AppIcons.contact, [
    PagePrefField('status', _status, [
      PagePrefOption('active', (l) => l.contactsFilterActive),
      PagePrefOption('archived', (l) => l.contactsFilterArchived),
      PagePrefOption('all', (l) => l.contactsFilterAll),
    ]),
    PagePrefField('link', (l) => l.pagePrefLink, [
      PagePrefOption('all', (l) => l.contactsFilterAll),
      PagePrefOption('linked', (l) => l.contactLinked),
      PagePrefOption('unlinked', (l) => l.contactsLinkUnlinked),
    ]),
    PagePrefField('sort', _sort, [
      PagePrefOption('recent', (l) => l.contactsSortRecent),
      PagePrefOption('nameAsc', (l) => l.contactsSortNameAsc),
      PagePrefOption('nameDesc', (l) => l.contactsSortNameDesc),
    ]),
  ]),
  PagePrefPage(PagePrefIds.debts, (l) => l.moreDebts, AppIcons.debt, [
    PagePrefField('filter', _filter, [
      PagePrefOption('all', (l) => l.debtsFilterAll),
      PagePrefOption('receivable', (l) => l.debtsOwedToMe),
      PagePrefOption('payable', (l) => l.debtsIOwe),
      PagePrefOption('overdue30', (l) => l.debtsOver30Label),
    ]),
  ]),
  PagePrefPage(PagePrefIds.pending, (l) => l.pendingTitle, AppIcons.pending, [
    PagePrefField('filter', _filter, [
      PagePrefOption('all', (l) => l.pagePrefAll),
      PagePrefOption('manual', (l) => l.pagePrefPendingManual),
      PagePrefOption('others', (l) => l.pagePrefPendingOthers),
    ]),
  ]),
];

PagePrefPage pagePrefPage(String id) =>
    pagePrefPages.firstWhere((p) => p.id == id);

/// One section of Settings › ตัวกรองและการเรียง.
class PagePrefGroup {
  const PagePrefGroup(this.title, this.pages);

  final String Function(AppLocalizations l) title;
  final List<PagePrefPage> pages;
}

/// The settings page's sections: the app's own grouping (เพิ่มเติม and the
/// nav bar), same order, same titles and page names (owner 2026-10-28).
final List<PagePrefGroup> pagePrefGroups = [
  PagePrefGroup((l) => l.moreGroupMain, [
    PagePrefPage.soon('dashboard', (l) => l.navDashboard, AppIcons.dashboard),
    pagePrefPage(PagePrefIds.transactions),
    pagePrefPage(PagePrefIds.wallets),
    pagePrefPage(PagePrefIds.pending),
    pagePrefPage(PagePrefIds.notifications),
  ]),
  PagePrefGroup((l) => l.moreGroupPlan, [
    pagePrefPage(PagePrefIds.budgets),
    pagePrefPage(PagePrefIds.goals),
    pagePrefPage(PagePrefIds.recurring),
  ]),
  PagePrefGroup((l) => l.moreGroupOthers, [
    pagePrefPage(PagePrefIds.debts),
    pagePrefPage(PagePrefIds.events),
  ]),
  PagePrefGroup((l) => l.moreGroupSetup, [
    pagePrefPage(PagePrefIds.categories),
    pagePrefPage(PagePrefIds.tags),
    pagePrefPage(PagePrefIds.contacts),
  ]),
];

/// [page]'s remembered choices (empty = its defaults), read once (pages read
/// it when they open; no rebuild on change).
Map<String, dynamic> readPagePref(BuildContext context, String page) =>
    switch (context.read<AuthCubit>().state) {
      AuthAuthenticated(:final user) => user.pagePref(page),
      _ => const {},
    };

/// Remembers [patch] (merged into [page]'s stored choices) with ONE
/// `PUT /users/me`; the answer updates the signed-in user. A failure is only
/// logged: the page already shows the choice, it just isn't remembered.
Future<void> rememberPagePref(
  BuildContext context,
  String page,
  Map<String, Object?> patch,
) async {
  final auth = context.read<AuthCubit>();
  final users = context.read<UsersRepository>();
  final next = mergePagePref(readPagePref(context, page), patch);
  if (next == null) return;
  try {
    auth.updateUser(await users.setPagePref(page, next));
  } catch (_) {
    AppLogger.instance.warn('page_prefs.save_failed page=$page');
  }
}

/// [current] with [patch] laid over it (the last choice wins, other keys
/// stay); null when nothing would change, so no call is made.
Map<String, dynamic>? mergePagePref(
  Map<String, dynamic> current,
  Map<String, Object?> patch,
) {
  final next = {...current, ...patch};
  return _sameMap(current, next) ? null : next;
}

bool _sameMap(Map<String, dynamic> a, Map<String, dynamic> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && _same(e.value, b[e.key]));

bool _same(Object? a, Object? b) => a is List && b is List
    ? a.length == b.length &&
          [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x)
    : a == b;
