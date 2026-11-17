import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../app/shell/quick_create_look.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';
import '../../../institutions/data/institutions_repository.dart';
import '../../../institutions/domain/institution.dart';
import '../../../institutions/presentation/widgets/institution_picker.dart'
    show institutionKindLabel;

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

enum _ContactSort { recent, nameAsc, nameDesc }

enum _LinkFilter { all, linked, unlinked }

class _ContactsPageState extends State<ContactsPage> {
  /// 0.4.3 section สถาบันการเงิน (loaded once; again after its page).
  List<Institution> _institutions = const [];

  Future<void> _loadInstitutions() async {
    try {
      final list = await InstitutionsRepository.of(context).list();
      if (mounted) setState(() => _institutions = list);
    } catch (_) {
      // The contacts still show; the section waits for the next load.
    }
  }

  /// Its page (same tab); the list reloads when this page loads again.
  Future<void> _openInstitution(String path) async => openPage(context, path);

  final _searchController = TextEditingController();
  String _query = '';
  _ContactSort _sort = _ContactSort.recent;
  _LinkFilter _link = _LinkFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInstitutions());
    });
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

  /// The centre button goes to this page's create page (owner 2026-11-12).
  @override
  Widget build(BuildContext context) => QuickCreatePresetScope(
    preset: QuickCreatePreset.create(
      QuickCreateLook.add(
        context,
        color: ModuleColors.of(context).library,
        icon: AppIcons.contact,
      ),
      _add,
    ),
    child: _page(context),
  );

  Widget _page(BuildContext context) {
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
              isEmpty: shown.isEmpty && _institutions.isEmpty,
              onRetry: ctx.read<ContactsCubit>().load,
              empty: _empty(l, state),
              sidePadding: 0,
              topInset: 0,
              header: [
                PpForgeListToolbar(
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
                    builder: (context, toggle) => PpForgeChip(
                      label: _sortLabel(l, _sort),
                      icon: AppIcons.sort,
                      trailing: PpForgeChipTrailing.dropdown,
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
                      builder: (context, toggle) => PpForgeChip(
                        label:
                            '${l.contactsStatusLabel}: ${statusLabels[state.statusFilter]}',
                        selected: state.statusFilter != 'active',
                        trailing: PpForgeChipTrailing.dropdown,
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
                      builder: (context, toggle) => PpForgeChip(
                        label:
                            '${l.contactsLinkLabel}: ${_linkLabel(l, _link)}',
                        selected: _link != _LinkFilter.all,
                        trailing: PpForgeChipTrailing.dropdown,
                        onTap: toggle,
                      ),
                    ),
                  ],
                ),
              ],
              children: [
                PpForgeListHeader(
                  key: const ValueKey('contactsPeople'),
                  title: l.debtsSectionPeople,
                  count: shown.length,
                ),
                for (var i = 0; i < shown.length; i++) ...[
                  _ContactRow(contact: shown[i]),
                  if (i < shown.length - 1) const PpForgeDivider.row(),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PpForgeSpacing.lg,
                    PpForgeSpacing.md,
                    PpForgeSpacing.lg,
                    0,
                  ),
                  child: AddTile(label: l.contactsAddNew, onTap: _add),
                ),
                ..._institutionSection(l),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The contacts page's สถาบันการเงิน: the institutions matching the search,
/// then + เพิ่มสถาบัน.
extension on _ContactsPageState {
  List<Widget> _institutionSection(AppLocalizations l) {
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final i in _institutions)
        if (q.isEmpty || i.name.toLowerCase().contains(q)) i,
    ];
    return [
      PpForgeListHeader(
        key: const ValueKey('contactsInstitutions'),
        title: l.debtsSectionInstitutions,
        count: shown.length,
      ),
      for (final i in shown)
        PpForgeListRow(
          key: ValueKey('institution-${i.id}'),
          leading: InstitutionMark(
            name: i.name,
            iconCode: i.iconCode,
            shortName: i.provider?.shortName,
            color: InstitutionMark.parseHex(i.provider?.color),
            size: 36,
          ),
          title: i.name,
          line2: ListRowLine(parts: [institutionKindLabel(l, i.kind)]),
          onTap: () => unawaited(_openInstitution('/institutions/${i.id}')),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          PpForgeSpacing.md,
          PpForgeSpacing.lg,
          0,
        ),
        child: AddTile(
          key: const ValueKey('institutionAdd'),
          label: l.institutionAdd,
          onTap: () => unawaited(_openInstitution('/institutions/new')),
        ),
      ),
    ];
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
    return PpForgeListRow(
      leading: PersonMark(
        level: contact.isLinked ? PersonLevel.linked : PersonLevel.contact,
        avatar: contact.avatar,
        size: 36,
      ),
      title: contact.name,
      line2: ListRowLine(parts: [sub]),
      dimmed: contact.isArchived,
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
