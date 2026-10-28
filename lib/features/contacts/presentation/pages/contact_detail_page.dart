import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/quick_create_context.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/domain/refs.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../../../transactions/presentation/save_failure.dart';
import '../cubit/contacts_cubit.dart';
import '../widgets/contact_picker.dart';

class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({
    this.id,
    this.startEditing = false,
    this.popOnCreate = false,
    this.initialName,
    super.key,
  });

  final String? id;

  final bool startEditing;

  /// Create only, pushed over a picker: saving pops with the new [Contact] (the
  /// picker picks it) instead of turning into its page.
  final bool popOnCreate;

  /// Create mode: the name already typed elsewhere (a picker's name row).
  final String? initialName;

  bool get isCreate => id == null;

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

enum _Field { name, nickname, description, email, phone, note }

class _ContactDetailPageState extends State<ContactDetailPage>
    with EditModeMixin<ContactDetailPage, _ContactDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _focus = {for (final f in _Field.values) f: FocusNode()};

  Contact? _contact;
  bool _loading = false;
  ApiException? _error;

  List<UnlinkedName> _unlinked = const [];

  int _unlinkedNames = 0;
  int _unlinkedRecords = 0;

  final _viewName = TextEditingController();

  @override
  void initState() {
    super.initState();
    final name = widget.isCreate ? (widget.initialName ?? '') : '';
    _ctrl[_Field.name]!.text = name;
    initDraft(_ContactDraft(name: name), editing: widget.isCreate);
    if (!widget.isCreate) _load(enterEdit: widget.startEditing);
  }

  @override
  void dispose() {
    _viewName.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool enterEdit = false}) async {
    final first = _contact == null;
    if (first) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await context.read<ContactsRepository>().get(_id!);
      if (!mounted) return;
      final c = d.contact;
      setState(() {
        _setContact(c);
        _unlinked = d.unlinkedNames;
        _unlinkedNames = d.unlinkedNameCount;
        _unlinkedRecords = d.unlinkedRecordCount;
        _loading = false;
        _error = null;
      });
      resetDraft(_ContactDraft.from(c));
      if (enterEdit) this.enterEdit();
    } catch (e, st) {
      if (!mounted) return;
      final err = ApiException.from(e, st);
      if (first) {
        setState(() {
          _error = err;
          _loading = false;
        });
      } else {
        showAppSnackBar(context, err.message, tone: Tone.danger);
      }
    }
  }

  Future<void> _refresh() => _load();

  void _setContact(Contact c) {
    _contact = c;
    _viewName.text = c.name;
  }

  void _patch(Contact c) {
    setState(() => _setContact(c));
    resetDraft(_ContactDraft.from(c));
  }

  bool get _linked => _contact?.isLinked ?? false;

  String? get _id => _contact?.id ?? widget.id;
  bool get _isCreate => _id == null;

  @override
  bool get leaveOnCancel => _isCreate;

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    sync(_Field.name, working.name);
    sync(_Field.nickname, working.nickname);
    sync(_Field.email, working.email);
    sync(_Field.phone, working.phone);
    sync(_Field.description, working.description);
    sync(_Field.note, working.note);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.nickname => working.copyWith(nickname: v),
    _Field.email => working.copyWith(email: v),
    _Field.phone => working.copyWith(phone: v),
    _Field.description => working.copyWith(description: v),
    _Field.note => working.copyWith(note: v),
  });

  VoidCallback _enterOn(_Field f) =>
      () => enterEdit(focus: _focus[f]);

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<ContactsCubit>();
    final w = working.trimmed();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (_isCreate) {
        final created = await cubit.create(
          displayName: w.name,
          nickname: w.nickname.isEmpty ? null : w.nickname,
          showNickname: w.showNickname,
          email: w.email.isEmpty ? null : w.email,
          phone: w.phone.isEmpty ? null : w.phone,
          description: w.description.isEmpty ? null : w.description,
          note: w.note.isEmpty ? null : w.note,
          iconCode: w.iconCode,
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        if (widget.popOnCreate) {
          // Pop without the discard prompt — the picker takes it from here.
          commitSaved(_ContactDraft.from(created));
          Navigator.of(context).pop(created);
          return;
        }
        setState(() {
          _setContact(created);
          _unlinked = const [];
          _unlinkedNames = 0;
          _unlinkedRecords = 0;
        });
        commitSaved(_ContactDraft.from(created));
        context.replace('/contacts/${created.id}');
        return;
      }
      final updated = await cubit.update(
        _contact!.id,
        displayName: _linked ? null : w.name,
        nickname: w.nickname,
        showNickname: w.showNickname,
        email: _linked ? null : w.email,
        phone: w.phone,
        description: w.description,
        note: w.note,
        iconCode: _linked ? null : w.iconCode,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _setContact(updated));
      commitSaved(_ContactDraft.from(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _save);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = _contact!;
    setSaving(true);
    final ContactDeletePreview? preview;
    try {
      preview = (await context.read<ContactsRepository>().get(
        c.id,
        deletePreview: true,
      )).deletePreview;
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _delete);
      return;
    }
    if (!mounted) return;
    setSaving(false);
    final parts = preview == null
        ? const <String>[]
        : [
            if (preview.debtRecords > 0)
              l.fpM5ContactDeleteDebts(preview.debtRecords),
            if (preview.eventMembers > 0)
              l.fpM5ContactDeleteMembers(preview.eventMembers),
            if (preview.linked) l.fpM5ContactDeleteLinked,
          ];
    final ok = await showConfirmDialog(
      context,
      title: l.contactDeleteTitle(c.name),
      message: parts.isEmpty ? l.contactDeleteBody : parts.join(' | '),
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await context.read<ContactsCubit>().delete(c.id);
      if (!mounted) return;
      showAppSnackBar(context, l.contactDeleted(c.name), tone: Tone.success);
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showSaveFailure(context, e, retry: _delete);
    }
  }

  Future<void> _openIconMaker() async {
    final l = AppLocalizations.of(context)!;
    final result = await showIconMakerSheet(
      context: context,
      type: IconType.contact,
      title: l.contactNameLabel,
      initial: working.iconCode,
      previewBuilder: (code) => Center(
        child: UserAvatar(
          displayName: working.name.isEmpty ? '?' : working.name,
          iconCode: code,
          size: 56,
        ),
      ),
    );
    if (!mounted || result is! IconMakerSelected) return;
    applyChange(working.copyWith(iconCode: result.iconCode));
  }

  Future<void> _run(Future<Contact> Function() action, {String? done}) async {
    try {
      final c = await action();
      if (!mounted) return;
      if (done != null) showAppSnackBar(context, done, tone: Tone.success);
      _patch(c);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _unlink() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.contactUnlinkTitle(_contact!.name),
      message: l.contactUnlinkBody,
      confirmLabel: l.contactUnlink,
    );
    if (!ok || !mounted) return;
    await _run(
      () => context.read<ContactsCubit>().unlink(_contact!.id),
      done: l.contactUnlinked,
    );
  }

  Future<void> _requestLink() async {
    final l = AppLocalizations.of(context)!;
    try {
      final c = await context.read<ContactsCubit>().requestLink(_contact!.id);
      // Same toast on hit and miss — never reveals whether the email belongs to
      // a user.
      if (!mounted) return;
      showAppSnackBar(context, l.contactLinkRequested);
      _patch(c);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  /// The person's name is the hero's title: big and bold (owner 2026-10-23).
  TextStyle? get _nameStyle => Theme.of(
    context,
  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

  /// The account row's icon: a filled success circle when linked (the
  /// "active" look), the plain grey link icon when not.
  Widget _linkMark({required bool linked}) {
    final scheme = Theme.of(context).colorScheme;
    if (!linked) {
      return Icon(AppIcons.link, size: 22, color: scheme.onSurfaceVariant);
    }
    final success = Theme.of(context).extension<AppColors>()!.success;
    return IconTile(
      icon: AppIcons.link,
      color: success,
      size: 28,
      glyphSize: 16,
      style: IconTileStyle.solid,
    );
  }

  /// No email yet: open edit on the email field and say why.
  void _askEmailFirst() {
    final l = AppLocalizations.of(context)!;
    showAppSnackBar(context, l.contactLinkNeedsEmail);
    _enterOn(_Field.email)();
  }

  Future<void> _toggleArchive() async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ContactsCubit>();
    final c = _contact!;
    if (!c.isArchived) {
      final ok = await showConfirmDialog(
        context,
        title: l.contactArchiveConfirmTitle,
        message: l.contactArchiveHint,
        confirmLabel: l.contactArchive,
      );
      if (!ok || !mounted) return;
    }
    await _run(() => c.isArchived ? cubit.restore(c.id) : cubit.archive(c.id));
  }

  Future<void> _openWireNames() async {
    final l = AppLocalizations.of(context)!;
    final contact = _contact!;
    final wired = await ContactPicker.wireNames<(AbsorbResult, Set<String>)>(
      context,
      contactName: contact.name,
      names: _unlinked,
      onSave: (picked) async {
        try {
          final res = await context.read<ContactsCubit>().absorb(
            contact.id,
            picked.toList(),
          );
          return (res, picked);
        } on ApiException catch (e) {
          if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
          return null;
        }
      },
    );
    if (!mounted || wired == null) return;
    final (res, picked) = wired;
    if (res.absorbedCount > 0) {
      showAppSnackBar(
        context,
        l.contactWireDone(res.absorbedCount, res.contact.name),
        tone: Tone.success,
      );
    }
    _patch(res.contact);
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!_isCreate && _contact == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.moreContacts, showBack: true),
        extendBodyBehindAppBar: true,
        body: AsyncStateView.fallback(
          loading: _loading,
          error: _error,
          onRetry: _load,
          notFound: EmptyView(
            icon: AppIcons.contact,
            title: l.contactNotFound,
            message: '',
          ),
        ),
      );
    }

    return QuickCreatePresetScope(
      preset: _isCreate
          ? QuickCreatePreset.none
          : QuickCreatePreset.debt(
              person: EmbeddedPerson(
                name: _contact!.name,
                contactId: _contact!.id,
                iconCode: _contact!.iconCode,
                linked: _contact!.isLinked,
                linkedUserId: _contact!.linkedUser?.id,
              ),
            ),
      child: editScope(
        SavingOverlay(
          saving: isSaving,
          child: Scaffold(
            appBar: AppTopBar(
              // Titles never change with the mode — the action bar shows it.
              title: _isCreate ? l.contactTitleNew : _contact!.name,
              showBack: true,
              editing: isEditing,
              onBack: handleBack,
            ),
            extendBodyBehindAppBar: true,
            body: Form(
              key: _formKey,
              child: Builder(
                builder: (context) => DetailLayout(
                  onRefresh: _isCreate ? null : _refresh,
                  refreshEnabled: !isEditing,
                  topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  bottomInset:
                      AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                  hero: isEditing ? _editHero(l) : _viewHero(l),
                  info: isEditing ? _editInfo(l) : _viewInfo(l),
                  people: isEditing || _isCreate ? null : _linkSection(l),
                  note: _note(l),
                  endZone: isEditing && !_isCreate ? _endZone(l) : null,
                  metaLines: _isCreate
                      ? const []
                      : detailMetaLines(
                          context,
                          createdAt: _contact!.createdAt,
                          updatedAt: _contact!.updatedAt,
                        ),
                ),
              ),
            ),
            bottomNavigationBar: isEditing
                ? editActionBar(onSave: _save)
                : null,
          ),
        ),
      ),
    );
  }

  HeroStyle _heroStyle(String name, IconCode? icon) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeroStyle.tinted(
      color: icon.tintFor(palette, avatarName: name),
      glyph: AppIcons.contact,
    );
  }

  Widget _viewHero(AppLocalizations l) {
    final c = _contact!;
    // The avatar row is the top of the card, its buttons at the end, like the
    // wallet page; a header only when archived (owner 2026-10-23).
    return AppHeroCard(
      style: _heroStyle(c.name, c.iconCode),
      header: c.isArchived
          ? HeroHeader(
              leading: [
                AppChip(
                  label: l.contactArchivedBadge,
                  icon: AppIcons.archive,
                  tone: AppChipTone.warning,
                  selected: true,
                ),
              ],
            )
          : null,
      content: [
        HeroIdentity(
          alignTop: true,
          actions: [
            CardActionButton(
              icon: AppIcons.debt,
              tooltip: l.contactDebts,
              onTap: () => openPage(
                context,
                '/personal-debts/people/${Uri.encodeComponent('c:${c.id}')}',
              ),
            ),
            CardActionButton(
              key: const ValueKey('heroEdit'),
              icon: AppIcons.edit,
              tooltip: UiConfig.stringsOf(context).edit,
              onTap: enterEdit,
            ),
          ],
          icon: GestureDetector(
            onLongPress: _linked
                ? null
                : () {
                    enterEdit();
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _openIconMaker(),
                    );
                  },
            child: PersonMark(
              name: c.name,
              level: c.isLinked ? PersonLevel.linked : PersonLevel.contact,
              iconCode: c.iconCode,
              size: HeroIdentity.iconSize,
            ),
          ),
          name: HeroNameInput(
            editing: false,
            controller: _viewName,
            maxLength: TextLimits.name,
            style: _nameStyle,
            onEnterEdit: _linked ? null : _enterOn(_Field.name),
          ),
          description: HeroDescription(
            controller: _ctrl[_Field.description]!,
            editing: false,
            hint: l.contactDescriptionHint,
            maxLength: TextLimits.description,
            onEnterEdit: _enterOn(_Field.description),
          ),
        ),
        _businessCard(l, c),
      ],
    );
  }

  /// Email + phone in the hero, like a business card (owner 2026-10-23).
  /// Both always show; an empty one says it can be filled (long-press).
  Widget _businessCard(AppLocalizations l, Contact c) {
    final faint =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    HeroFact fact(String label, String? value, IconData icon) {
      final empty = value == null || value.trim().isEmpty;
      return HeroFact(
        label,
        empty ? l.commonLongPressToEdit : value,
        icon: icon,
        color: empty ? faint : null,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _enterOn(_Field.phone),
      child: HeroFactList(
        facts: [
          fact(l.contactEmailLabel, c.email, AppIcons.email),
          fact(l.contactPhoneLabel, c.phone, AppIcons.phone),
        ],
      ),
    );
  }

  Widget? _viewInfo(AppLocalizations l) {
    final c = _contact!;
    // Only a linked person has a nickname (their name comes from their
    // account); its switch sits right under it. Email / phone are in the hero.
    if (!c.isLinked) return null;
    final faint = Theme.of(context).colorScheme.onSurfaceVariant;
    final nickname = c.nickname;
    return SectionCard(
      children: [
        nickname == null || nickname.trim().isEmpty
            ? InfoRow(
                label: l.contactNicknameLabel,
                valueWidget: Text(
                  l.commonLongPressToEdit,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: faint),
                ),
                onLongPress: _enterOn(_Field.nickname),
              )
            : InfoRow(
                label: l.contactNicknameLabel,
                value: nickname,
                onLongPress: _enterOn(_Field.nickname),
              ),
        _viewNicknameSwitch(l, c),
      ],
    );
  }

  Widget _linkSection(AppLocalizations l) {
    final c = _contact!;
    final hasEmail = c.email?.isNotEmpty ?? false;

    final hasNames = _unlinkedNames > 0;
    // Linked: ONE row with the account as a set (name, @handle, email); a
    // tap offers to unlink. No leading icons (owner 2026-10-23).
    final u = c.linkedUser;
    final handle = u?.username;
    final account = u == null
        ? null
        : [
            if (handle != null && handle.isNotEmpty) '@$handle',
            if (hasEmail) c.email!,
          ].join(' | ');
    return SectionCard(
      title: l.fpContactsLinkSection,
      description: l.fpContactsLinkSectionDesc,
      children: [
        // Like the note row: an icon in front, here a filled "active" circle
        // once linked; ⋯ holds the one action (owner 2026-10-23).
        if (c.isLinked)
          AppListRow(
            leading: _linkMark(linked: true),
            title: l.contactLinkedAccount(u?.displayName ?? c.name),
            line2: account == null || account.isEmpty
                ? null
                : ListRowLine(parts: [account]),
            actions: [
              ListRowAction.menu<int>(
                tooltip: l.contactUnlink,
                options: [
                  SheetOption(
                    value: 0,
                    label: l.contactUnlink,
                    leading: const Icon(AppIcons.unlink, size: 18),
                    destructive: true,
                    submits: true,
                  ),
                ],
                onSelected: (_) => _unlink(),
              ),
            ],
          )
        // Always offered, so people know it exists; it needs their email
        // first (owner 2026-10-23).
        else
          AppDetailRow(
            leading: _linkMark(linked: false),
            label: l.contactLinkRequest,
            helper: hasEmail
                ? l.contactLinkRequestHint
                : l.contactLinkNeedsEmail,
            showChevron: true,
            onTap: hasEmail ? _requestLink : _askEmailFirst,
          ),
        AppDetailRow(
          label: l.contactWireTitle,
          helper: hasNames
              ? l.contactWireHint(_unlinkedNames, _unlinkedRecords)
              : l.contactWireNone,
          showChevron: hasNames,
          onTap: hasNames ? _openWireNames : null,
        ),
      ],
    );
  }

  Widget _note(AppLocalizations l) {
    if (!isEditing) {
      return NoteSection(
        label: l.commonNote,
        editing: false,
        text: _contact!.note,
        hint: l.commonLongPressToEdit,
        onLongPress: _enterOn(_Field.note),
      );
    }
    return NoteSection(
      label: l.commonNote,
      editing: true,
      controller: _ctrl[_Field.note]!,
      maxLength: TextLimits.note,
      editField: DetailStacked(
        label: l.commonNote,
        child: AppInput.inline(
          editing: true,
          controller: _ctrl[_Field.note]!,
          focusNode: _focus[_Field.note],
          maxLines: 3,
          maxLength: TextLimits.note,
          hint: l.contactNoteHint,
          onChanged: (v) => _onText(_Field.note, v),
        ),
      ),
    );
  }

  Widget _editHero(AppLocalizations l) {
    final c = _contact;
    final w = working;
    final name = c != null && _linked ? c.name : w.name;
    return AppHeroCard(
      style: _heroStyle(name, _linked ? c!.iconCode : w.iconCode),
      mode: HeroCardMode.edit,
      content: [
        HeroIdentity(
          icon: EditableCircle(
            size: 44,
            onTap: _linked ? null : _openIconMaker,
            child: PersonMark(
              name: name,
              level: _linked ? PersonLevel.linked : PersonLevel.contact,
              iconCode: _linked ? c!.iconCode : w.iconCode,
              size: 44,
            ),
          ),
          // A linked person's name comes from their account: shown with its
          // label, not typed, and it follows the nickname switch live.
          name: _linked ? _lockedName(l, c!, w) : _unlinkedNameInput(l),
          description: HeroDescription(
            controller: _ctrl[_Field.description]!,
            editing: true,
            hint: l.contactDescriptionHint,
            maxLength: TextLimits.description,
            focusNode: _focus[_Field.description],
            onChanged: (v) => _onText(_Field.description, v),
          ),
        ),
      ],
    );
  }

  Widget _unlinkedNameInput(AppLocalizations l) => HeroNameInput(
    editing: true,
    controller: _ctrl[_Field.name]!,
    focusNode: _focus[_Field.name],
    hint: l.contactNameHint,
    maxLength: TextLimits.name,
    style: _nameStyle,
    onChanged: (v) => _onText(_Field.name, v),
    validator: (v) {
      final s = v?.trim() ?? '';
      if (s.isEmpty) return l.contactNameRequired;
      if (s.length > TextLimits.name) return l.contactNameTooLong;
      return null;
    },
  );

  /// A linked person's name in the edit hero: its label like the other hero
  /// fields, read-only, and live — the nickname while "แสดงชื่อเล่น" is on,
  /// else the account's name (owner 2026-10-23).
  Widget _lockedName(AppLocalizations l, Contact c, _ContactDraft w) {
    final nick = w.nickname.trim();
    final shown = w.showNickname && nick.isNotEmpty
        ? nick
        : (c.linkedUser?.displayName ?? c.name);
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: HeroColors.maybeOf(context)?.text,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(l.contactNameLabel, style: labelStyle),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            shown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _nameStyle,
          ),
        ),
      ],
    );
  }

  Widget _editInfo(AppLocalizations l) {
    Widget field(
      _Field f,
      String label, {
      required String hint,
      required int maxLength,
      TextInputType? keyboard,
      FormFieldValidator<String>? validator,
      IconData? icon,
    }) => DetailTextField(
      label: label,
      controller: _ctrl[f]!,
      editing: true,
      focusNode: _focus[f],
      hint: hint,
      maxLength: maxLength,
      keyboardType: keyboard,
      onChanged: (v) => _onText(f, v),
      validator: validator,
      leading: icon == null ? null : AppIcon(icon),
    );
    final w = working;
    return SectionCard(
      children: [
        // Nickname + its switch: linked people only (owner 2026-10-23). With
        // the switch off the nickname isn't used, so its field greys out.
        if (_linked) ...[
          IgnorePointer(
            ignoring: !w.showNickname,
            child: Opacity(
              opacity: w.showNickname ? 1 : 0.45,
              child: field(
                _Field.nickname,
                l.contactNicknameLabel,
                hint: l.contactNicknameHint,
                maxLength: TextLimits.name,
              ),
            ),
          ),
          SettingToggleRow(
            label: l.contactShowNicknameLabel,
            value: w.showNickname,
            submits: false,
            onChanged: (v) => applyChange(w.copyWith(showNickname: v)),
          ),
          // The account's email: not editable; a small 🔗 after it says why.
          DetailStacked(
            label: l.contactEmailLabel,
            leading: const AppIcon(AppIcons.email),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    w.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: l.contactEmailFromAccount,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    AppIcons.link,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ] else
          field(
            _Field.email,
            l.contactEmailLabel,
            icon: AppIcons.email,
            hint: l.contactEmailHint,
            maxLength: TextLimits.email,
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                  ? null
                  : l.contactEmailInvalid;
            },
          ),
        field(
          _Field.phone,
          l.contactPhoneLabel,
          icon: AppIcons.phone,
          hint: l.contactPhoneHint,
          maxLength: TextLimits.phone,
          keyboard: TextInputType.phone,
        ),
      ],
    );
  }

  /// View mode: the "แสดงชื่อเล่น" switch, saved at once with only that field
  /// (owner 2026-10-21, like the other detail pages' settings).
  Widget _viewNicknameSwitch(AppLocalizations l, Contact c) =>
      LiveSetting<bool>(
        value: c.showNickname,
        save: (v) async {
          final updated = await context.read<ContactsCubit>().update(
            c.id,
            showNickname: v,
          );
          if (mounted) _patch(updated);
          return true;
        },
        failedMessage: (e) =>
            e is ApiException ? e.message : l.errorUnknownMessage,
        builder: (context, value, onChanged) => SettingToggleRow(
          label: l.contactShowNicknameLabel,
          value: value,
          onChanged: onChanged,
        ),
      );

  Widget _endZone(AppLocalizations l) {
    final c = _contact!;
    return EndZone(
      actions: [
        EndZoneAction(
          kind: EndZoneKind.archive,
          label: c.isArchived ? l.contactRestore : l.contactArchive,
          consequence: c.isArchived ? null : l.fpContactsArchiveConsequence,
          onTap: isSaving ? null : _toggleArchive,
        ),
        EndZoneAction(
          kind: EndZoneKind.delete,
          label: l.contactDeleteThis,
          consequence: l.fpContactsDeleteConsequence,
          onTap: isSaving ? null : _delete,
        ),
      ],
    );
  }
}

class _ContactDraft {
  const _ContactDraft({
    this.name = '',
    this.nickname = '',
    this.showNickname = true,
    this.description = '',
    this.email = '',
    this.phone = '',
    this.note = '',
    this.iconCode,
  });

  factory _ContactDraft.from(Contact c) => _ContactDraft(
    name: c.displayName,
    nickname: c.nickname ?? '',
    showNickname: c.showNickname,
    description: c.description ?? '',
    email: c.email ?? '',
    phone: c.phone ?? '',
    note: c.note ?? '',
    iconCode: c.iconCode,
  );

  final String name;
  final String nickname;
  final bool showNickname;
  final String description;
  final String email;
  final String phone;
  final String note;
  final IconCode? iconCode;

  _ContactDraft trimmed() => _ContactDraft(
    name: name.trim(),
    nickname: nickname.trim(),
    showNickname: showNickname,
    description: description.trim(),
    email: email.trim(),
    phone: phone.trim(),
    note: note.trim(),
    iconCode: iconCode,
  );

  _ContactDraft copyWith({
    String? name,
    String? nickname,
    bool? showNickname,
    String? description,
    String? email,
    String? phone,
    String? note,
    IconCode? iconCode,
  }) => _ContactDraft(
    name: name ?? this.name,
    nickname: nickname ?? this.nickname,
    showNickname: showNickname ?? this.showNickname,
    description: description ?? this.description,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    note: note ?? this.note,
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _ContactDraft &&
      other.name == name &&
      other.nickname == nickname &&
      other.showNickname == showNickname &&
      other.description == description &&
      other.email == email &&
      other.phone == phone &&
      other.note == note &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(
    name,
    nickname,
    showNickname,
    description,
    email,
    phone,
    note,
    iconCode,
  );
}
