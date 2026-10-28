import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/nav_layout.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../preferences/page_prefs.dart';
import '../../../users/presentation/refresh_me.dart';
import 'settings_money_page.dart' show saveMe, signedInUser;

/// "ใช้งานอยู่ | ใกล้หมด": a page's remembered choices as bare values (owner
/// 2026-10-28), "|" between them. A set (collapsed parents, colours …) shows
/// only when it holds something: "ยุบหมวดแม่ 3". Null = nothing to show.
String? pagePrefSummary(
  AppLocalizations l,
  PagePrefPage page,
  Map<String, dynamic> pref,
) {
  final parts = [
    for (final f in page.fields)
      if (!f.isSet)
        f.option(f.pick(pref)).label(l)
      else if (f.picks(pref).isNotEmpty)
        l.pagePrefSetCount(f.title(l), f.picks(pref).length),
  ];
  return parts.isEmpty ? null : parts.join(' | ');
}

/// The module a page-prefs row belongs to.
ShellTab pagePrefModule(String pageId) => switch (pageId) {
  PagePrefIds.transactions => ShellTab.transactions,
  PagePrefIds.wallets => ShellTab.accounts,
  PagePrefIds.pending => ShellTab.pending,
  PagePrefIds.notifications => ShellTab.notifications,
  PagePrefIds.budgets => ShellTab.budgets,
  PagePrefIds.goals => ShellTab.savingGoals,
  PagePrefIds.recurring => ShellTab.recurring,
  PagePrefIds.debts => ShellTab.debts,
  PagePrefIds.events => ShellTab.projects,
  PagePrefIds.categories => ShellTab.categories,
  PagePrefIds.tags => ShellTab.tags,
  PagePrefIds.contacts => ShellTab.contacts,
  _ => ShellTab.home,
};

/// A row opens its page's choices only when the page remembers something and
/// its module is on; otherwise it shows disabled (owner 2026-10-28).
bool pagePrefRowEnabled(PagePrefPage page, NavLayout layout) =>
    !page.soon && layout.isOn(pagePrefModule(page.id));

/// Settings › ตัวกรองและการเรียง (0.4.1-2 P6): every page's remembered
/// sort / filter, one row each; a tap opens that page's choices.
class SettingsPagePrefsPage extends StatelessWidget {
  const SettingsPagePrefsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final layout = NavLayoutScope.of(context);
    return Scaffold(
      appBar: AppTopBar(title: l.settingsGroupPagePrefs, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          // Inside the Scaffold body: the inset includes the floating top bar.
          final inset = MediaQuery.paddingOf(context);
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            // The page legend, above the cards (inset like a card title).
            hero: DetailFootnote(l.pagePrefsCaption),
            // Grouped like เพิ่มเติม / the nav bar (owner 2026-10-28).
            sections: [
              for (final group in pagePrefGroups)
                (first) => SectionCard(
                  first: first,
                  title: group.title(l),
                  children: [
                    for (final page in group.pages)
                      if (page.soon)
                        LockedInEdit(
                          key: ValueKey('page-pref-${page.id}'),
                          locked: true,
                          child: DetailRow(
                            leading: AppIcon(page.icon),
                            label: page.title(l),
                            trailing: AppBadge(label: l.settingsComingSoon),
                          ),
                        )
                      else
                        LockedInEdit(
                          key: ValueKey('page-pref-${page.id}'),
                          // A module that is off: shown, not tappable.
                          locked: !pagePrefRowEnabled(page, layout),
                          child: DetailRow(
                            leading: AppIcon(page.icon),
                            label: page.title(l),
                            helper: pagePrefSummary(
                              l,
                              page,
                              user.pagePref(page.id),
                            ),
                            helperMaxLines: 1,
                            trailing: page.changed(user.pagePref(page.id))
                                ? AppBadge(label: l.pagePrefsChanged)
                                : null,
                            showChevron: pagePrefRowEnabled(page, layout),
                            onTap: () =>
                                context.push('/settings/page-prefs/${page.id}'),
                          ),
                        ),
                  ],
                ),
            ],
            footnote: l.pagePrefsFootnote,
            manage: user.pagePrefs.isEmpty
                ? null
                : SectionCard(
                    title: l.pagePrefsResetTitle,
                    children: [
                      DetailRow(
                        leading: const AppIcon(AppIcons.reset),
                        label: l.pagePrefsResetAll,
                        helper: l.pagePrefsResetAllHint,
                        onTap: () => _resetAll(context),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _resetAll(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.pagePrefsResetAll,
      message: l.pagePrefsResetAllBody,
      confirmLabel: l.pagePrefsResetAll,
    );
    if (ok && context.mounted) {
      await saveMe(context, (u) => u.resetPagePrefs());
    }
  }
}

/// One page's remembered choices: a dropdown per choice; id / colour sets
/// are only shown (the page itself sets them); reset this page.
class SettingsPagePrefPage extends StatelessWidget {
  const SettingsPagePrefPage({required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final page = pagePrefPage(pageId);
    return Scaffold(
      appBar: AppTopBar(title: page.title(l), showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          // Inside the Scaffold body: the inset includes the floating top bar.
          final inset = MediaQuery.paddingOf(context);
          final pref = user.pagePref(pageId);
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
                title: l.settingsGroupPagePrefs,
                children: [
                  for (final f in page.fields)
                    if (f.isSet)
                      DetailRow(
                        label: f.title(l),
                        helper: l.pagePrefsSetOnPage,
                        trailing: Text(
                          f.picks(pref).isEmpty
                              ? l.pagePrefNone
                              : '${f.picks(pref).length}',
                        ),
                      )
                    else
                      SettingDropdownRow<String>(
                        label: f.title(l),
                        value: f.option(f.pick(pref)).label(l),
                        selected: f.pick(pref),
                        onSelected: (wire) =>
                            rememberPagePref(context, pageId, {f.key: wire}),
                        options: [
                          for (final o in f.options)
                            SheetOption(value: o.wire, label: o.label(l)),
                        ],
                      ),
                ],
              ),
            ],
            manage: page.changed(pref)
                ? SectionCard(
                    title: l.pagePrefsResetTitle,
                    children: [
                      DetailRow(
                        leading: const AppIcon(AppIcons.reset),
                        label: l.pagePrefsResetPage,
                        onTap: () => _resetPage(context),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _resetPage(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.pagePrefsResetPage,
      message: l.pagePrefsResetPageBody,
      confirmLabel: l.pagePrefsResetPage,
    );
    if (ok && context.mounted) {
      await saveMe(context, (u) => u.setPagePref(pageId, null));
    }
  }
}
