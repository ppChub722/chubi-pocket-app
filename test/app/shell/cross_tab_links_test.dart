import 'dart:io';

import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guard for tab-per-page navigation (owner 2026-10-09): a plain
/// `push` of another tab's route stacks that page onto whatever tab is
/// open — the mess `openPage` exists to prevent. This scans `lib/` for
/// router calls and fails on:
///
/// - `push` / `pushReplacement` (`context.` or a captured `router.`) of a
///   route that belongs to another tab than the file's feature, or from a
///   file that's shown in several tabs (shared widgets, sheets);
/// - `go` to another tab's page that isn't the tab's root — a jump to a
///   page is `openPage` (a `go` to a tab root, "ดูทั้งหมด ›", is fine);
/// - a push / go whose target isn't a string literal — it can't be checked,
///   so it must be listed in [_reviewed] with the reason it's safe.
///
/// `openPage` / `pageOpener` calls aren't matched: they're the fix.
void main() {
  test('no plain push / go into another tab — use openPage', () {
    final problems = <String>[];
    for (final file in _dartFiles()) {
      final rel = file.path.replaceAll(r'\', '/');
      final home = _homeTab(rel);
      // Comment lines blanked (kept, so line numbers stay right).
      final source = file
          .readAsLinesSync()
          .map((l) => l.trimLeft().startsWith('//') ? '' : l)
          .join('\n');
      for (final m in _call.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        final where = '$rel:$line';
        final method = m.group(1)!;
        final target = m.group(2) ?? m.group(3);
        if (target == null) {
          if (!_reviewed.contains(where.split(':').first)) {
            problems.add('$where  $method(<not a literal>) — use openPage');
          }
          continue;
        }
        final tab = ShellTab.ofPath(target);
        if (tab == null) continue; // /dev, /auth — outside the shell
        final isGo = method == 'go';
        final isTabRoot = Uri.parse(target).pathSegments.length <= 1;
        if (isGo && isTabRoot) continue;
        if (home == tab && home != null) continue;
        problems.add(
          '$where  $method(\'$target\') — ${tab.name}\'s page from '
          '${home?.name ?? 'a shared file'}; use openPage',
        );
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the scan sees calls (it is not silently matching nothing)', () {
    const sample = '''
      context.push('/contacts/1');
      router.go('/transactions/2');
      context.pushReplacement('/projects/3');
      GoRouter.of(context).push('/budgets');
      context.push(location);
    ''';
    final found = _call.allMatches(sample).length;
    expect(found, 5);
  });

  test('ShellTab.ofPath knows every tab', () {
    expect(ShellTab.ofPath('/'), ShellTab.home);
    expect(ShellTab.ofPath('/browse?month=2026-10'), ShellTab.home);
    expect(ShellTab.ofPath('/transactions/abc'), ShellTab.transactions);
    expect(ShellTab.ofPath('/personal-debts/person'), ShellTab.debts);
    expect(ShellTab.ofPath('/scheduled-transactions/1'), ShellTab.scheduled);
    expect(ShellTab.ofPath('/saving-goals/new'), ShellTab.savingGoals);
    expect(ShellTab.ofPath('/settings/notifications'), ShellTab.settings);
    expect(ShellTab.ofPath('/dev/widgets'), isNull);
    expect(ShellTab.ofPath('/auth/login'), isNull);
    // Every tab is reachable by some path.
    for (final t in ShellTab.values) {
      expect(
        ['/', '/transactions', '/accounts', '/more', '/pending']
            .followedBy([
              '/notifications',
              '/settings',
              '/projects',
              '/contacts',
              '/budgets',
              '/scheduled-transactions',
              '/saving-goals',
              '/personal-debts',
              '/categories',
              '/tags',
            ])
            .map(ShellTab.ofPath)
            .contains(t),
        isTrue,
        reason: '$t has no path in ShellTab._segments',
      );
    }
  });
}

/// `context.push(` / `router.go(` / `GoRouter.of(context).push<T>(` …
/// group 1 = method, group 2 = a quoted path, group 3 = `Uri(path: '…')`.
final _call = RegExp(
  r'''(?:\bcontext|\brouter|GoRouter\.of\(\s*\w+\s*\))\s*\.\s*'''
  r'''(push|pushReplacement|go)\s*(?:<[^>(]*>)?\(\s*'''
  r'''(?:'([^'$]*)[^']*'|Uri\(\s*path:\s*'([^']*)'|)''',
);

/// Files whose non-literal targets were checked by hand, with why they're
/// safe. Keep it short — prefer a literal or `openPage`.
const _reviewed = {
  // Card → its own tab, opened fresh at its root (go to a tab root).
  'lib/app/shell/more_page.dart',
  // A tab's breadcrumb parent: always a root of the page's own tab.
  'lib/app/shell/top_bar_crumbs.dart',
};

Iterable<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) {
      final p = f.path.replaceAll(r'\', '/');
      return !p.startsWith('lib/dev/') && // dev screens, outside the shell
          !p.startsWith('lib/l10n/') &&
          !p.endsWith('lib/core/router/app_router.dart') &&
          !p.endsWith('lib/app/shell/tab_nav.dart'); // openPage itself
    });

/// The tab a file's pages and widgets live in, from its feature folder.
/// Null = shown in several tabs (shared widgets, the quick-create sheet,
/// every transactions file — rows and detail show up in the dashboard and
/// wallet tabs too): any push from there to a tab's route is cross-tab.
///
/// Blind spot: a feature widget reused on another feature's page. Such a
/// widget should navigate with `openPage`.
ShellTab? _homeTab(String path) {
  const features = {
    'home': ShellTab.home,
    'accounts': ShellTab.accounts,
    'pending': ShellTab.pending,
    'notifications': ShellTab.notifications,
    'settings': ShellTab.settings,
    'projects': ShellTab.projects,
    'contacts': ShellTab.contacts,
    'budgets': ShellTab.budgets,
    'scheduled_transactions': ShellTab.scheduled,
    'saving_goals': ShellTab.savingGoals,
    'personal_debts': ShellTab.debts,
    'categories': ShellTab.categories,
    'tags': ShellTab.tags,
  };
  final m = RegExp(r'lib/features/(\w+)/presentation/').firstMatch(path);
  return m == null ? null : features[m.group(1)];
}
