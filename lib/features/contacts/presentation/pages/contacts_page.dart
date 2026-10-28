import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

enum _ContactSort { recent, nameAsc, nameDesc }

enum _LinkFilter { all, linked, unlinked }

class _ContactsPageState extends State<ContactsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _ContactSort _sort = _ContactSort.recent;
  _LinkFilter _link = _LinkFilter.all;

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContactsCubit>().loadIfNeeded(keepFilter: true);
      }
    });
  }

  /// The status / link / sort remembered on the account (status lives in
  /// the cubit and filters locally, so setting it fetches nothing).
  void _restorePrefs() {
    final pref = readPagePref(context, PagePrefIds.contacts);
    final fields = pagePrefPage(PagePrefIds.contacts).fields;
    String pick(String key) =>
        fields.firstWhere((f) => f.key == key).pick(pref);
    context.read<ContactsCubit>().setStatusFilter(pick('status'));
    _link = _LinkFilter.values.asNameMap()[pick('link')] ?? _link;
    _sort = _ContactSort.values.asNameMap()[pick('sort')] ?? _sort;
  }

  void _remember(Map<String, Object?> patch) =>
      unawaited(rememberPagePref(context, PagePrefIds.contacts, patch));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _filter(List<Contact> all) {
    final q = _query.trim().toLowerCase();
    final hits = all.where((c) {
      final linkOk = switch (_link) {
        _LinkFilter.all => true,
        _LinkFilter.linked => c.isLinked,
        _LinkFilter.unlinked => !c.isLinked,
      };
      return linkOk &&
          (q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.displayName.toLowerCase().contains(q) ||
              (c.nickname?.toLowerCase().contains(q) ?? false) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              (c.email?.toLowerCase().contains(q) ?? false) ||
              (c.phone?.contains(q) ?? false));
    }).toList();
    int byName(Contact a, Contact b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return switch (_sort) {
      _ContactSort.recent => hits,
      _ContactSort.nameAsc => [...hits]..sort(byName),
      _ContactSort.nameDesc => [...hits]..sort((a, b) => byName(b, a)),
    };
  }

  String _sortLabel(AppLocalizations l, _ContactSort s) => switch (s) {
    _ContactSort.recent => l.contactsSortRecent,
    _ContactSort.nameAsc => l.contactsSortNameAsc,
    _ContactSort.nameDesc => l.contactsSortNameDesc,
  };

  void _add() => context.push('/contacts/new');

  String _linkLabel(AppLocalizations l, _LinkFilter f) => switch (f) {
    _LinkFilter.all => l.contactsFilterAll,
    _LinkFilter.linked => l.contactLinked,
    _LinkFilter.unlinked => l.contactsLinkUnlinked,
  };

  EmptyView _empty(AppLocalizations l, ContactsState state) {
    final statusFilter = state.statusFilter;
    if (state.contacts.isEmpty && statusFilter == 'active') {
      return EmptyView(
        icon: AppIcons.contact,
        title: l.contactsEmptyTitle,
        message: l.contactsEmptyMessage,
        cta: AddTile(label: l.contactsAddNew, onTap: _add),
      );
    }
    final searching = _query.trim().isNotEmpty;
    final linkFiltered = _link != _LinkFilter.all;
    final archived = !searching && !linkFiltered && statusFilter == 'archived';
    final (icon, title, message) = searching
        ? (
            AppIcons.search,
            l.contactsNoMatch,
            linkFiltered
                ? l.contactsNoMatchFilterMessage
                : l.contactsNoMatchMessage,
          )
        : linkFiltered
        ? (
            AppIcons.link,
            l.contactsNoFilterMatch,
            l.contactsNoFilterMatchMessage,
          )
        : archived
        ? (
            AppIcons.archive,
            l.contactsArchivedEmptyTitle,
            l.contactsArchivedEmptyMessage,
          )
        : (AppIcons.contact, l.contactsNoMatch, '');
    // A new contact is active and unlinked — only offer it where it would show
    // up.
    final canAdd = statusFilter != 'archived' && _link != _LinkFilter.linked;
    return EmptyView(
      icon: icon,
      title: title,
      message: message,
      cta: canAdd ? AddTile(label: l.contactsAddNew, onTap: _add) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusLabels = {
      'active': l.contactsFilterActive,
      'archived': l.contactsFilterArchived,
      'all': l.contactsFilterAll,
    };
    return Scaffold(
      appBar: AppTopBar(title: l.moreContacts, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<ContactsCubit, ContactsState>(
          builder: (ctx, state) {
            final shown = _filter(state.contacts);
            return ListPageBody(
              // Only the FIRST load shows the skeleton: a reload keeps the rows
              // (a skeleton would kill a pull-to-refresh).
              loading:
                  (state.status == ContactsStatus.initial ||
                      state.status == ContactsStatus.loading) &&
                  state.contacts.isEmpty,
              error: state.contacts.isEmpty ? state.error : null,
              isEmpty: shown.isEmpty,
              onRetry: ctx.read<ContactsCubit>().load,
              empty: _empty(l, state),
              sidePadding: 0,
              topInset: 0,
              header: [
                AppListToolbar(
                  search: ListToolbarSearch(
                    controller: _searchController,
                    hint: l.contactsSearchHint,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  trailing: OptionMenuAnchor<_ContactSort>(
                    selected: _sort,
                    onSelected: (v) {
                      setState(() => _sort = v);
                      _remember({'sort': v.name});
                    },
                    options: [
                      for (final s in _ContactSort.values)
                        SheetOption(value: s, label: _sortLabel(l, s)),
                    ],
                    builder: (context, toggle) => AppChip(
                      label: _sortLabel(l, _sort),
                      icon: AppIcons.sort,
                      trailing: AppChipTrailing.dropdown,
                      onTap: toggle,
                    ),
                  ),
                  filters: [
                    OptionMenuAnchor<String>(
                      selected: state.statusFilter,
                      onSelected: (v) {
                        ctx.read<ContactsCubit>().setStatusFilter(v);
                        _remember({'status': v});
                      },
                      options: [
                        for (final e in statusLabels.entries)
                          SheetOption(value: e.key, label: e.value),
                      ],
                      builder: (context, toggle) => AppChip(
                        label:
                            '${l.contactsStatusLabel}: ${statusLabels[state.statusFilter]}',
                        selected: state.statusFilter != 'active',
                        trailing: AppChipTrailing.dropdown,
                        onTap: toggle,
                      ),
                    ),
                    OptionMenuAnchor<_LinkFilter>(
                      selected: _link,
                      onSelected: (v) {
                        setState(() => _link = v);
                        _remember({'link': v.name});
                      },
                      options: [
                        for (final f in _LinkFilter.values)
                          SheetOption(value: f, label: _linkLabel(l, f)),
                      ],
                      builder: (context, toggle) => AppChip(
                        label:
                            '${l.contactsLinkLabel}: ${_linkLabel(l, _link)}',
                        selected: _link != _LinkFilter.all,
                        trailing: AppChipTrailing.dropdown,
                        onTap: toggle,
                      ),
                    ),
                  ],
                ),
              ],
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  _ContactRow(contact: shown[i]),
                  if (i < shown.length - 1) const AppDivider.row(),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: AddTile(label: l.contactsAddNew, onTap: _add),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final sub = [
      contact.description?.trim() ?? '',
      contact.email?.trim() ?? '',
    ].where((s) => s.isNotEmpty).join(' | ');
    return AppListRow(
      leading: PersonMark(
        name: contact.name,
        level: contact.isLinked ? PersonLevel.linked : PersonLevel.contact,
        iconCode: contact.iconCode,
        size: 36,
      ),
      title: contact.name,
      line2: ListRowLine(parts: [sub]),
      dimmed: contact.isArchived,
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
