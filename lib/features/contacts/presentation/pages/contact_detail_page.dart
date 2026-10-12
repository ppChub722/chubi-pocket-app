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

/// `/contacts/new`, `/contacts/:id` (+ `/edit`) — one page, view ⇄ edit,
/// category style (`ux-overhaul-plan.md` §6). Linked contacts lock name,
/// email and icon (they follow the linked user's account).
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

  Future<void> _load({bool enterEdit = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await context.read<ContactsRepository>().get(_id!);
      if (!mounted) return;
      final c = d.contact;
      setState(() {
        _setContact(c);
        _unlinked = d.unlinkedNames;
        _loading = false;
      });
      resetDraft(_ContactDraft.from(c));
      if (enterEdit) this.enterEdit();
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(e, st);
        _loading = false;
      });
    }
  }

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

  // ── Actions (view mode only — dimmed while editing) ────────────────

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

    // A save / delete in flight dims the page and blocks input.
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
        SavingOverlay(
          saving: isSaving,
          child: Scaffold(
            appBar: AppTopBar(
              // Edit mode keeps the page's title (owner QA T1) — the action bar
              // shows the mode.
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
                // Pull = the page's one load call; the body turns it off while
                // editing (a reload resets the draft) and in create.
                builder: (context) => DetailPageBody(
                  onRefresh: _isCreate ? null : _load,
                  physics: const AlwaysScrollableScrollPhysics(),
                  topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                  bottomInset:
                      AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
                  hero: _header(l),
                  sections: [
                    (first) => _fields(l, first: first),
                    (first) => _isCreate ? null : _actions(l, first: first),
                  ],
                  // Archive (amber) · delete (red) live at the bottom in edit
                  // mode (no top-bar actions); archive flips to restore.
                  manage: isEditing && !_isCreate
                      ? ManageSection(
                          archiveLabel: _contact!.isArchived
                              ? l.contactRestore
                              : l.contactArchive,
                          onArchive: isSaving ? null : _toggleArchive,
                          deleteLabel: l.contactDeleteThis,
                          onDelete: isSaving ? null : _delete,
                        )
                      : null,
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

  Widget _header(AppLocalizations l) {
    final editing = isEditing;
    final c = _contact;
    final iconEditable = editing && !_linked;
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeaderCard(
      glyph: AppIcons.contact,
      // The contact's own icon colour (the linked user's while linked).
      accent: (_linked ? c!.iconCode : working.iconCode).tintFor(
        palette,
        avatarName: c != null && !editing ? c.name : working.name,
      ),
      onEdit: editing ? null : enterEdit,
      // Status chips in the top row (rule 2) — except "linked", which sits in
      // the subtitle under the name (contact exception, owner 2026-10-12). With
      // no chip the row collapses: ✏️ level with the name.
      topRow: [
        if (c != null && c.isArchived)
          AppChip(
            label: l.contactArchivedBadge,
            icon: AppIcons.archive,
            tone: AppChipTone.warning,
            selected: true,
          ),
      ],
      // avatar → 🔗 → name (owner 2026-10-11): the badge sits outside the
      // circle, so the editable avatar keeps its shape.
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EditableCircle(
            size: 52,
            onTap: iconEditable ? _openIconMaker : null,
            onLongPress: editing || _linked
                ? null
                : () {
                    enterEdit();
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _openIconMaker(),
                    );
                  },
            // Linked: the account's icon wins (and isn't editable here).
            child: PersonMark(
              name: c != null && !editing ? c.name : working.name,
              level: PersonLevel.contact,
              iconCode: _linked ? c!.iconCode : working.iconCode,
              size: 52,
            ),
          ),
          if (_linked) ...[
            const SizedBox(width: AppSpacing.xs),
            const PersonLinkBadge(),
          ],
        ],
      ),
      // Edit: the stored name. View (and linked): the resolved name.
      title: HeroNameInput(
        key: ValueKey(editing && !_linked),
        editing: editing && !_linked,
        controller: editing && !_linked ? _ctrl[_Field.name]! : _viewName,
        focusNode: _focus[_Field.name],
        hint: l.contactNameHint,
        maxLength: TextLimits.name,
        onEnterEdit: _linked
            ? null
            : () => enterEdit(focus: _focus[_Field.name]),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) {
          final s = v?.trim() ?? '';
          if (s.isEmpty) return l.contactNameRequired;
          if (s.length > TextLimits.name) return l.contactNameTooLong;
          return null;
        },
      ),
      // The contact's own description (not the linked account's), so it stays
      // editable when linked.
      description: HeroDescription(
        controller: _ctrl[_Field.description]!,
        editing: editing,
        hint: l.contactDescriptionHint,
        maxLength: TextLimits.description,
        focusNode: _focus[_Field.description],
        onEnterEdit: () => enterEdit(focus: _focus[_Field.description]),
        onChanged: (v) => _onText(_Field.description, v),
      ),
      // Linked: the chip under the name (replaces the old "Contact" line);
      // unlinked: no subtitle.
      subtitle: c != null && c.isLinked
          ? Align(
              alignment: Alignment.centerLeft,
              child: AppChip(
                label: l.contactLinked,
                icon: AppIcons.link,
                tone: AppChipTone.success,
                selected: true,
                size: ChipSize.chip,
              ),
            )
          : null,
    );
  }

  Widget _fields(AppLocalizations l, {required bool first}) {
    final editing = isEditing;
    Widget field(
      _Field f,
      String label, {
      String? hint,
      bool locked = false,
      bool placeholderWhenEmpty = false,
      int maxLines = 1,
      int? maxLength,
      TextInputType? keyboard,
      FormFieldValidator<String>? validator,
    }) {
      // ONE field implementation for every detail page (DetailTextField):
      // view + nothing set = the one-row "not set" placeholder.
      return DetailTextField(
        label: label,
        controller: _ctrl[f]!,
        editing: editing,
        focusNode: _focus[f],
        locked: locked,
        placeholderWhenEmpty: placeholderWhenEmpty,
        notSetLabel: l.contactFieldNotSet,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboard,
        // Edit mode: say what goes here and that it's optional (the
        // name, in the header, is the only required one).
        hint: hint,
        viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
        onEnterEdit: () => enterEdit(focus: _focus[f]),
        onChanged: (v) => _onText(f, v),
        validator: validator,
      );
    }

    final email = field(
      _Field.email,
      l.contactEmailLabel,
      hint: l.contactEmailHint,
      locked: _linked,
      placeholderWhenEmpty: true,
      maxLength: TextLimits.email,
      keyboard: TextInputType.emailAddress,
      validator: (v) {
        final s = v?.trim() ?? '';
        if (s.isEmpty) return null;
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
            ? null
            : l.contactEmailInvalid;
      },
    );
    final nicknameEmpty = working.nickname.trim().isEmpty;
    return SectionCard(
      first: first,
      children: [
        // My own label: editable even when the name is locked (linked).
        field(
          _Field.nickname,
          l.contactNicknameLabel,
          hint: l.contactNicknameHint,
          placeholderWhenEmpty: true,
          maxLength: TextLimits.name,
        ),
        // On / off per contact; nothing to switch while there is no nickname.
        DetailRow(
          label: l.contactShowNicknameLabel,
          helper: l.contactShowNicknameHelper,
          trailing: AppSwitch(
            value: working.showNickname,
            onChanged: nicknameEmpty
                ? null
                : (v) => applyChange(working.copyWith(showNickname: v)),
          ),
        ),
        // Linked: the email follows the linked account — a 🔒 row (rule
        // 10), with the "why" under it while editing.
        if (_linked)
          DetailRow(
            label: l.contactEmailLabel,
            locked: true,
            helper: editing ? l.contactLinkedLockedHint : null,
            trailing: _ctrl[_Field.email]!.text.isEmpty
                ? DetailPlaceholder(l.contactFieldNotSet)
                : AppText(_ctrl[_Field.email]!.text),
          )
        else
          email,
        field(
          _Field.phone,
          l.contactPhoneLabel,
          hint: l.contactPhoneHint,
          placeholderWhenEmpty: true,
          maxLength: TextLimits.phone,
          keyboard: TextInputType.phone,
        ),
        field(
          _Field.note,
          l.commonNote,
          hint: l.contactNoteHint,
          maxLines: 3,
          maxLength: TextLimits.note,
        ),
      ],
    );
  }

  /// Absorb answered: patch the contact, drop the wired names from the list.
  void _onWired(AbsorbResult res, Set<String> names) {
    final gone = {for (final n in names) n.toLowerCase()};
    setState(
      () => _unlinked = [
        for (final u in _unlinked)
          if (!gone.contains(u.name.toLowerCase())) u,
      ],
    );
    _patch(res.contact);
  }

  Widget _actions(AppLocalizations l, {required bool first}) {
    final c = _contact!;
    final hasEmail = c.email?.isNotEmpty ?? false;
    return SectionCard(
      first: first,
      title: l.contactSectionActions,
      description: l.contactActionsSectionDescription,
      locked: isEditing,
      children: [
        if (c.isLinked)
          DetailRow(
            leading: const AppIcon(AppIcons.link),
            label: l.contactLinkTitle,
            helper: l.contactLinkLinked,
            trailing: AppButton(
              label: l.contactUnlink,
              variant: AppButtonVariant.text,
              submits: true,
              onPressed: _unlink,
            ),
          )
        else
          DetailRow(
            leading: const AppIcon(AppIcons.send),
            label: l.contactLinkRequest,
            helper: hasEmail
                ? l.contactLinkRequestHint
                : l.contactLinkNeedsEmail,
            showChevron: hasEmail,
            onTap: hasEmail ? _requestLink : null,
          ),
        _WireNamesRow(contact: c, names: _unlinked, onWired: _onWired),
        DetailRow(
          leading: const AppIcon(AppIcons.debt),
          label: l.contactDebts,
          showChevron: true,
          onTap: () => openPage(
            context,
            '/personal-debts/people/${Uri.encodeComponent('c:${c.id}')}',
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// "จับคู่ชื่อในรายการหาร" — typed split names not yet tied to a contact.
// ────────────────────────────────────────────────────────────────────

class _WireNamesRow extends StatelessWidget {
  const _WireNamesRow({
    required this.contact,
    required this.names,
    required this.onWired,
  });

  final Contact contact;
  final List<UnlinkedName> names;
  final void Function(AbsorbResult res, Set<String> names) onWired;

  Future<void> _open(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final wired = await showWireNamesSheet<(AbsorbResult, Set<String>)>(
      context,
      labels: WireNamesLabels(
        title: l.contactWireSheetTitle(contact.name),
        body: l.contactWireSheetBody,
        searchHint: l.contactWireSearch,
        saveLabel: l.contactWireSave,
      ),
      rows: [
        for (final n in names)
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
          if (context.mounted) {
            showAppSnackBar(context, e.message, tone: Tone.danger);
          }
          return null;
        }
      },
    );
    if (!context.mounted || wired == null) return;
    final (res, picked) = wired;
    if (res.absorbedCount > 0) {
      showAppSnackBar(
        context,
        l.contactWireDone(res.absorbedCount, res.contact.name),
        tone: Tone.success,
      );
    }
    onWired(res, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final splits = names.fold<int>(0, (a, n) => a + n.count);
    final has = names.isNotEmpty;
    return DetailRow(
      leading: const AppIcon(AppIcons.split),
      label: l.contactWireTitle,
      helper: has ? l.contactWireHint(names.length, splits) : l.contactWireNone,
      showChevron: has,
      onTap: has ? () => _open(context) : null,
    );
  }
}

// ────────────────────────────────────────────────────────────────────

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
