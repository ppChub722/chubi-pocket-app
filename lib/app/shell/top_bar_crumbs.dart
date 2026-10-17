import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';

class TopBarCrumb {
  const TopBarCrumb({
    required this.label,
    required this.path,
    required this.routeName,
  });

  final String label;
  final String path;

  final String routeName;
}

TopBarCrumb? defaultTopBarCrumb(BuildContext context) {
  final String path;
  try {
    path = GoRouterState.of(context).uri.path;
  } catch (_) {
    return null;
  }
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return null;
  final l = AppLocalizations.of(context)!;
  final (String label, String name)? hit = switch (segments.first) {
    'transactions' => (l.navTransactions, 'transactions'),
    'accounts' => (l.navAccounts, 'accounts'),
    'projects' => (l.navProjects, 'projects'),
    'contacts' => (l.moreContacts, 'contacts'),
    'personal-debts' => (l.moreDebts, 'personal-debts'),
    'categories' => (l.moreCategories, 'categories'),
    'budgets' => (l.moreBudgets, 'budgets'),
    'saving-goals' => (l.moreSavingGoals, 'saving-goals'),
    'recurring' => (l.moreRecurring, 'recurring'),
    'settings' => (l.settingsTitle, 'settings'),
    'notifications' => (l.moreNotifications, 'notifications'),
    'dev' => ('Dev', 'dev-hub'),
    _ => null,
  };
  if (hit == null) return null;
  return TopBarCrumb(
    label: hit.$1,
    path: '/${segments.first}',
    routeName: hit.$2,
  );
}

/// Back to [crumb]: pop to it when it's below us in the stack, otherwise
/// navigate there (deep link / arrived from another tab).
void goToCrumb(BuildContext context, TopBarCrumb crumb) {
  final router = GoRouter.of(context);
  var found = false;
  Navigator.of(context).popUntil((route) {
    if (route.settings.name == crumb.routeName) {
      found = true;
      return true;
    }
    return route.isFirst;
  });
  if (!found) router.go(crumb.path);
}
