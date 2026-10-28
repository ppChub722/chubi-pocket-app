import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../preferences/page_prefs.dart';
import '../../../users/presentation/refresh_me.dart';
import 'settings_money_page.dart' show saveMe, signedInUser;

/// "เรียง: ใกล้หมด | กรอง: ใช้งานอยู่": a page's remembered choices in one line.
String pagePrefSummary(
  AppLocalizations l,
  PagePrefPage page,
  Map<String, dynamic> pref,
) => [
  for (final f in page.fields)
    l.pagePrefValue(
      f.title(l),
      f.isSet
          ? (f.picks(pref).isEmpty ? l.pagePrefNone : '${f.picks(pref).length}')
          : f.option(f.pick(pref)).label(l),
    ),
].join(' | ');

/// Settings › ตัวกรองและการเรียง (0.4.1-2 P6): every page's remembered
/// sort / filter, one row each; a tap opens that page's choices.
class SettingsPagePrefsPage extends StatelessWidget {
  const SettingsPagePrefsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppTopBar(title: l.settingsGroupPagePrefs, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
                description: l.pagePrefsCaption,
                children: [
                  for (final page in pagePrefPages)
                    DetailRow(
                      key: ValueKey('page-pref-${page.id}'),
                      label: page.title(l),
                      helper: pagePrefSummary(l, page, user.pagePref(page.id)),
                      helperMaxLines: 1,
                      trailing: page.changed(user.pagePref(page.id))
                          ? AppBadge(label: l.pagePrefsChanged)
                          : null,
                      showChevron: true,
                      onTap: () =>
                          context.push('/settings/page-prefs/${page.id}'),
                    ),
                ],
              ),
            ],
            metaLines: [l.pagePrefsFootnote],
            manage: user.pagePrefs.isEmpty
                ? null
                : DetailRow(
                    leading: const AppIcon(AppIcons.reset),
                    label: l.pagePrefsResetAll,
                    onTap: () => _resetAll(context),
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
    final inset = MediaQuery.paddingOf(context);
    final page = pagePrefPage(pageId);
    return Scaffold(
      appBar: AppTopBar(title: page.title(l), showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          final pref = user.pagePref(pageId);
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
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
                ? DetailRow(
                    leading: const AppIcon(AppIcons.reset),
                    label: l.pagePrefsResetPage,
                    onTap: () =>
                        saveMe(context, (u) => u.setPagePref(pageId, null)),
                  )
                : null,
          );
        },
      ),
    );
  }
}
