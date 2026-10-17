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

/// `/contacts/new`, `/contacts/:id` (+ `/edit`) — one page, view ⇄ edit
/// (0.4.0 reference §8). The page opens with ONE call (`GET /contacts/:id
/// ?include=unlinked_names`) and shows what the BE returns; every write
/// answers with the contact and patches the page (no re-GET).
///
/// View: a people hero (link state chip, 💸 + ✏️, avatar + name +
/// description, no money) → one box of facts → "เชื่อมบัญชี" → note → meta.
/// Edit is its own form: the hero's name / description / icon, one box of
/// ชื่อเล่น / อีเมล / เบอร์โทร, the "แสดงชื่อเล่น" setting, the note and the
/// end zone (archive / delete). Linked contacts follow their account: what
/// can't be edited (name, email, icon) is hidden in edit mode.
///
/// The link-request accept flows keep `ContactFormPage`.
class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({
    this.id,
    this.startEditing = false,
    this.popOnCreate = false,
    super.key,
  });

  /// Null = create.
  final String? id;

  /// `/contacts/:id/edit` opens straight in edit mode.
  final bool startEditing;

  /// Create only, pushed over a picker: saving pops with the new [Contact]
  /// (the picker picks it) instead of turning into its page.
  final bool popOnCreate;

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

  /// Split names still free to wire to this contact: from the detail GET
  /// (include=unlinked_names), trimmed locally after an absorb.
  List<UnlinkedName> _unlinked = const [];

  /// The BE's totals for the badge (names / records still free to wire).
  int _unlinkedNames = 0;
  int _unlinkedRecords = 0;

  /// View-mode title: the resolved name (the edit field edits the stored
  /// display_name).
  final _viewName = TextEditingController();

  @override
  void initState() {
    super.initState();
    initDraft(const _ContactDraft(), editing: widget.isCreate);
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

  /// The page's one load. The first one shows the skeleton / error; a later
  /// one (pull-to-refresh) keeps the data on screen — a failure is a message.
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

  /// A write response replaces the page's contact (no re-GET).
  void _patch(Contact c) {
    setState(() => _setContact(c));
    resetDraft(_ContactDraft.from(c));
  }

  bool get _linked => _contact?.isLinked ?? false;

  /// The contact's id — the route's, or the one just created here (create
  /// turns into the saved contact in place, see [_save]).
  String? get _id => _contact?.id ?? widget.id;
  bool get _isCreate => _id == null;

  // ── EditModeMixin hooks ─────────────────────────────────────────────

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

  /// View mode: long-press a value → edit mode with that field focused.
  VoidCallback _enterOn(_Field f) =>
      () => enterEdit(focus: _focus[f]);

  // ── Save / delete ───────────────────────────────────────────────────

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
        // Become the saved contact right here — edit → view in place, like
        // any other save. (A route swap flashed view mode, slid a new page
        // in and showed a loading skeleton first.) `replace` only fixes the
        // URL: same page key, so no transition and this state is kept.
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
      // Empty strings clear a field (the API keeps omitted ones as-is).
      final updated = await cubit.update(
        _contact!.id,
        displayName: _linked ? null : w.name,
        // '' clears the nickname (explicit null on the wire).
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
    final ok = await showConfirmDialog(
      context,
      title: l.contactDeleteTitle(c.name),
      message: l.contactDeleteBody,
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

  // ── Actions ─────────────────────────────────────────────────────────

  /// Runs a write that answers with the contact and patches the page from
  /// it (no re-GET).
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
      // Same toast on hit and miss — never reveals whether the email
      // belongs to a user.
      if (!mounted) return;
      showAppSnackBar(context, l.contactLinkRequested);
      _patch(c);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  /// Archive asks first (it leaves the pickers); restore just does it.
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

  /// "จับคู่ชื่อในรายการหาร": the sheet of typed split names; saving absorbs
  /// the picked ones and the answer patches the page.
  Future<void> _openWireNames() async {
    final l = AppLocalizations.of(context)!;
    final contact = _contact!;
    final wired = await showWireNamesSheet<(AbsorbResult, Set<String>)>(
      context,
      labels: WireNamesLabels(
        title: l.contactWireSheetTitle(contact.name),
        body: l.contactWireSheetBody,
        searchHint: l.contactWireSearch,
        saveLabel: l.contactWireSave,
      ),
      rows: [
        for (final n in _unlinked)
          WireNameRow(name: n.name, subtitle: l.contactWireCount(n.count)),
      ],
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
    // Absorb answered: patch the contact; the badge totals are the BE's, so
    // the page's one call re-runs (the data stays on screen).
    _patch(res.contact);
    unawaited(_load());
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!_isCreate && _contact == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.moreContacts, showBack: true),
        extendBodyBehindAppBar: true,
        // Skeleton → error + retry → not found (AsyncStateView); the template
        // skeleton clears the transparent top bar itself.
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

    // The + opens debt mode with this contact (once saved).
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
        // A save / delete in flight dims the page and blocks input.
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
              // Builder: its context sees the floating bar's height.
              child: Builder(
                builder: (context) => DetailLayout(
                  // Pull = the page's one load call; off in create and while
                  // editing (a reload resets the draft).
                  onRefresh: _isCreate ? null : _refresh,
                  refreshEnabled: !isEditing,
                  topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  bottomInset:
                      AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                  hero: isEditing ? _editHero(l) : _viewHero(l),
                  info: isEditing ? _editInfo(l) : _viewInfo(l),
                  settings: isEditing ? _editSettings(l) : null,
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

  /// "🔗 เชื่อมกับ @user แล้ว" / "ยังไม่เชื่อมกับผู้ใช้ในแอป".
  String _linkLabel(AppLocalizations l, Contact c) {
    final u = c.linkedUser;
    if (u == null) return l.fpContactsNotLinked;
    final handle = u.username;
    return l.fpContactsLinkedWith(
      handle == null || handle.isEmpty ? u.displayName : '@$handle',
    );
  }

  // ── View ────────────────────────────────────────────────────────────

  /// The people hero: link state chip (+ archived), 💸 + ✏️, avatar, name,
  /// description. No money on the card.
  Widget _viewHero(AppLocalizations l) {
    final c = _contact!;
    return HeroCard(
      style: _heroStyle(c.name, c.iconCode),
      chips: [
        if (c.isArchived)
          AppChip(
            label: l.contactArchivedBadge,
            icon: AppIcons.archive,
            tone: AppChipTone.warning,
            selected: true,
          ),
        AppChip(
          label: _linkLabel(l, c),
          icon: c.isLinked ? AppIcons.link : null,
          tone: c.isLinked ? AppChipTone.success : AppChipTone.neutral,
          selected: c.isLinked,
        ),
      ],
      links: [
        CardActionButton(
          icon: AppIcons.debt,
          tooltip: l.contactDebts,
          onTap: () => openPage(
            context,
            '/personal-debts/people/${Uri.encodeComponent('c:${c.id}')}',
          ),
        ),
      ],
      onEdit: enterEdit,
      // Linked: the account's icon wins (and isn't editable here).
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
          size: 40,
        ),
      ),
      name: HeroNameInput(
        editing: false,
        controller: _viewName,
        maxLength: TextLimits.name,
        onEnterEdit: _linked ? null : _enterOn(_Field.name),
      ),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: false,
        hint: l.contactDescriptionHint,
        maxLength: TextLimits.description,
        onEnterEdit: _enterOn(_Field.description),
      ),
    );
  }

  /// ONE box: ชื่อเล่น / อีเมล / เบอร์โทร — empty rows hidden, none = no box.
  Widget? _viewInfo(AppLocalizations l) {
    final c = _contact!;
    InfoRow? row(String label, String? value, _Field f) =>
        value == null || value.trim().isEmpty
        ? null
        : InfoRow(label: label, value: value, onLongPress: _enterOn(f));
    final rows = <InfoRow>[
      ?row(l.contactNicknameLabel, c.nickname, _Field.nickname),
      ?row(l.contactEmailLabel, c.email, _Field.email),
      ?row(l.contactPhoneLabel, c.phone, _Field.phone),
    ];
    return rows.isEmpty ? null : InfoBox(rows: rows);
  }

  /// เชื่อมบัญชี: send a request (email set, not linked) or unlink; match the
  /// typed split names.
  Widget _linkSection(AppLocalizations l) {
    final c = _contact!;
    final hasEmail = c.email?.isNotEmpty ?? false;

    final hasNames = _unlinkedNames > 0;
    return SectionCard(
      title: l.fpContactsLinkSection,
      description: l.fpContactsLinkSectionDesc,
      children: [
        if (c.isLinked)
          DetailRow(
            leading: const AppIcon(AppIcons.link),
            label: l.contactUnlink,
            helper: l.contactLinkLinked,
            showChevron: true,
            onTap: _unlink,
          )
        else if (hasEmail)
          DetailRow(
            leading: const AppIcon(AppIcons.send),
            label: l.contactLinkRequest,
            helper: l.contactLinkRequestHint,
            showChevron: true,
            onTap: _requestLink,
          ),
        DetailRow(
          leading: const AppIcon(AppIcons.split),
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

  // ── Edit / create ───────────────────────────────────────────────────

  /// Edit mode is its own form: the card keeps the icon, the name (not for a
  /// linked contact — it follows the account) and the description.
  Widget _editHero(AppLocalizations l) {
    final c = _contact;
    final w = working;
    final name = c != null && _linked ? c.name : w.name;
    return HeroCard(
      style: _heroStyle(name, _linked ? c!.iconCode : w.iconCode),
      editing: true,
      icon: EditableCircle(
        size: 44,
        onTap: _linked ? null : _openIconMaker,
        child: PersonMark(
          name: name,
          level: PersonLevel.contact,
          iconCode: _linked ? c!.iconCode : w.iconCode,
          size: 44,
        ),
      ),
      name: _linked
          ? null
          : HeroNameInput(
              editing: true,
              controller: _ctrl[_Field.name]!,
              focusNode: _focus[_Field.name],
              hint: l.contactNameHint,
              maxLength: TextLimits.name,
              onChanged: (v) => _onText(_Field.name, v),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return l.contactNameRequired;
                if (s.length > TextLimits.name) return l.contactNameTooLong;
                return null;
              },
            ),
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: true,
        hint: l.contactDescriptionHint,
        maxLength: TextLimits.description,
        focusNode: _focus[_Field.description],
        onChanged: (v) => _onText(_Field.description, v),
      ),
    );
  }

  /// ONE box: ชื่อเล่น, อีเมล (not for a linked contact), เบอร์โทร.
  Widget _editInfo(AppLocalizations l) {
    Widget field(
      _Field f,
      String label, {
      required String hint,
      required int maxLength,
      TextInputType? keyboard,
      FormFieldValidator<String>? validator,
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
    );
    return SectionCard(
      children: [
        field(
          _Field.nickname,
          l.contactNicknameLabel,
          hint: l.contactNicknameHint,
          maxLength: TextLimits.name,
        ),
        if (!_linked)
          field(
            _Field.email,
            l.contactEmailLabel,
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
          hint: l.contactPhoneHint,
          maxLength: TextLimits.phone,
          keyboard: TextInputType.phone,
        ),
      ],
    );
  }

  /// "แสดงชื่อเล่น" — part of the form (saved with it), edit mode only.
  Widget _editSettings(AppLocalizations l) => SettingsSection(
    title: l.settingsTitle,
    description: l.fpContactsSettingsDesc,
    children: [
      SettingToggleRow(
        label: l.contactShowNicknameLabel,
        value: working.showNickname,
        submits: false,
        onChanged: (v) => applyChange(working.copyWith(showNickname: v)),
      ),
    ],
  );

  /// เก็บถาวร (flips to กู้คืน) and ลบ — the existing confirm dialogs.
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
