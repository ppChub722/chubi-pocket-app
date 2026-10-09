import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

/// `/contacts/new`, `/contacts/:id` (+ `/edit`) — one page, view ⇄ edit,
/// category style (`ux-overhaul-plan.md` §6). Linked contacts lock name,
/// email and icon (they follow the linked user's account).
///
/// The link-request accept flows keep `ContactFormPage`.
class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({this.id, this.startEditing = false, super.key});

  /// Null = create.
  final String? id;

  /// `/contacts/:id/edit` opens straight in edit mode.
  final bool startEditing;

  bool get isCreate => id == null;

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

enum _Field { name, email, phone, notes }

class _ContactDetailPageState extends State<ContactDetailPage>
    with EditModeMixin<ContactDetailPage, _ContactDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _focus = {for (final f in _Field.values) f: FocusNode()};

  Contact? _contact;
  bool _loading = false;
  ApiException? _error;

  /// Bumped after link/unlink/absorb so the wire-names row refetches.
  int _actionsVersion = 0;

  @override
  void initState() {
    super.initState();
    initDraft(const _ContactDraft(), editing: widget.isCreate);
    if (!widget.isCreate) _load(enterEdit: widget.startEditing);
  }

  @override
  void dispose() {
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
      final c = await context.read<ContactsRepository>().get(widget.id!);
      if (!mounted) return;
      setState(() {
        _contact = c;
        _loading = false;
        _actionsVersion++;
      });
      resetDraft(_ContactDraft.from(c));
      if (enterEdit) this.enterEdit();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool get _linked => _contact?.isLinked ?? false;

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => widget.isCreate;

  @override
  void leavePage() {
    if (context.canPop()) context.pop();
  }

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    sync(_Field.name, working.name);
    sync(_Field.email, working.email);
    sync(_Field.phone, working.phone);
    sync(_Field.notes, working.notes);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.email => working.copyWith(email: v),
    _Field.phone => working.copyWith(phone: v),
    _Field.notes => working.copyWith(notes: v),
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
      if (widget.isCreate) {
        final created = await cubit.create(
          displayName: w.name,
          email: w.email.isEmpty ? null : w.email,
          phone: w.phone.isEmpty ? null : w.phone,
          notes: w.notes.isEmpty ? null : w.notes,
          iconCode: w.iconCode,
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        commitSaved(w);
        context.pushReplacement('/contacts/${created.id}');
        return;
      }
      // Empty strings clear a field (the API keeps omitted ones as-is).
      final updated = await cubit.update(
        _contact!.id,
        displayName: _linked ? null : w.name,
        email: _linked ? null : w.email,
        phone: w.phone,
        notes: w.notes,
        iconCode: _linked ? null : w.iconCode,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _contact = updated);
      commitSaved(_ContactDraft.from(updated));
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = _contact!;
    final ok = await showConfirmDialog(
      context,
      title: l.contactDeleteTitle(c.effectiveName),
      message: l.contactDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await context.read<ContactsCubit>().delete(c.id);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.contactDeleted(c.effectiveName),
        tone: Tone.success,
      );
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
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

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    try {
      await action();
      if (!mounted) return;
      if (done != null) showAppSnackBar(context, done, tone: Tone.success);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _unlink() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.contactUnlinkTitle(_contact!.effectiveName),
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
      await context.read<ContactsCubit>().requestLink(_contact!.id);
      // Same toast on hit and miss — never reveals whether the email
      // belongs to a user.
      if (mounted) showAppSnackBar(context, l.contactLinkRequested);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _toggleArchive() async {
    final cubit = context.read<ContactsCubit>();
    final c = _contact!;
    await _run(() => c.isArchived ? cubit.restore(c.id) : cubit.archive(c.id));
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!widget.isCreate && _contact == null) {
      return Scaffold(
        appBar: AppTopBar(title: l.moreContacts, showBack: true),
        extendBodyBehindAppBar: true,
        body: _loading
            // The generic skeleton is a padded list — clear the bar.
            ? Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: const LoadingView(),
                ),
              )
            : _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : EmptyView(
                icon: AppIcons.contact,
                title: l.contactNotFound,
                message: '',
              ),
      );
    }

    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: widget.isCreate
              ? l.contactTitleNew
              : isEditing
              ? l.contactTitleEdit
              : _contact!.effectiveName,
          showBack: true,
          editing: isEditing,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: its context sees the floating bar's height.
          child: Builder(
            builder: (context) => ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              children: [
                _header(l),
                const SizedBox(height: AppSpacing.lg),
                _fields(l),
                if (!widget.isCreate) ...[
                  const SizedBox(height: AppSpacing.lg),
                  LockedInEdit(locked: isEditing, child: _actions(l)),
                ],
                // Delete lives at the bottom in edit mode (no top-bar actions).
                if (isEditing && !widget.isCreate)
                  DangerRow(
                    icon: AppIcons.delete,
                    label: l.contactDeleteThis,
                    onTap: isSaving ? null : _delete,
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isEditing ? editActionBar(onSave: _save) : null,
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final editing = isEditing;
    final c = _contact;
    final iconEditable = editing && !_linked;
    return HeaderCard(
      onEdit: editing ? null : enterEdit,
      leading: GestureDetector(
        onLongPress: editing || _linked
            ? null
            : () {
                enterEdit();
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _openIconMaker(),
                );
              },
        child: EditableCircle(
          size: 52,
          onTap: iconEditable ? _openIconMaker : null,
          child: UserAvatar(
            displayName: working.name.isEmpty ? '?' : working.name,
            // Linked: the account's icon wins (and isn't editable here).
            iconCode: _linked ? c!.effectiveIconCode : working.iconCode,
            size: 52,
          ),
        ),
      ),
      title: InlineTitleField(
        editing: editing && !_linked,
        controller: _ctrl[_Field.name]!,
        focusNode: _focus[_Field.name],
        hint: l.contactNameLabel,
        onEnterEdit: _linked
            ? null
            : () => enterEdit(focus: _focus[_Field.name]),
        onChanged: (v) => _onText(_Field.name, v),
        validator: (v) {
          final s = v?.trim() ?? '';
          if (s.isEmpty) return l.contactNameRequired;
          if (s.length > 100) return l.contactNameTooLong;
          return null;
        },
      ),
      subtitle: c == null || (!c.isLinked && !c.isArchived)
          ? null
          : Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (c.isLinked)
                  AppBadge(
                    label: l.contactLinkedBadge,
                    icon: AppIcons.link,
                    tone: Tone.info,
                  ),
                if (c.isArchived)
                  AppBadge(
                    label: l.contactArchivedBadge,
                    icon: AppIcons.archive,
                  ),
              ],
            ),
    );
  }

  Widget _fields(AppLocalizations l) {
    final editing = isEditing;
    Widget field(
      _Field f,
      String label, {
      bool locked = false,
      int maxLines = 1,
      int? maxLength,
      TextInputType? keyboard,
      FormFieldValidator<String>? validator,
    }) {
      return DetailStacked(
        label: label,
        child: InlineField(
          editing: editing && !locked,
          controller: _ctrl[f]!,
          focusNode: _focus[f],
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboard,
          onEnterEdit: locked ? null : () => enterEdit(focus: _focus[f]),
          onChanged: (v) => _onText(f, v),
          validator: validator,
        ),
      );
    }

    return SectionCard(
      children: [
        field(
          _Field.email,
          l.contactEmailLabel,
          locked: _linked,
          maxLength: 255,
          keyboard: TextInputType.emailAddress,
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.isEmpty) return null;
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)
                ? null
                : l.contactEmailInvalid;
          },
        ),
        if (_linked && editing)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l.contactLinkedLockedHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const RowDivider(),
        field(
          _Field.phone,
          l.contactPhoneLabel,
          maxLength: 50,
          keyboard: TextInputType.phone,
        ),
        const RowDivider(),
        field(_Field.notes, l.contactNotesLabel, maxLines: 3, maxLength: 500),
      ],
    );
  }

  Widget _actions(AppLocalizations l) {
    final c = _contact!;
    final hasEmail = c.effectiveEmail?.isNotEmpty ?? false;
    return SectionCard(
      title: l.contactSectionActions,
      children: [
        if (c.isLinked)
          DetailRow(
            leading: const Icon(AppIcons.link),
            label: l.contactLinkTitle,
            helper: l.contactLinkLinked,
            trailing: TextButton(
              onPressed: _unlink,
              child: Text(l.contactUnlink),
            ),
          )
        else
          DetailRow(
            leading: const Icon(AppIcons.send),
            label: l.contactLinkRequest,
            helper: hasEmail
                ? l.contactLinkRequestHint
                : l.contactLinkNeedsEmail,
            showChevron: hasEmail,
            onTap: hasEmail ? _requestLink : null,
          ),
        const RowDivider(),
        _WireNamesRow(
          key: ValueKey(_actionsVersion),
          contact: c,
          onWired: _load,
        ),
        const RowDivider(),
        DetailRow(
          leading: const Icon(AppIcons.debt),
          label: l.contactDebts,
          showChevron: true,
          onTap: () => context.push(
            Uri(
              path: '/personal-debts/person',
              queryParameters: {'contact': c.id, 'name': c.effectiveName},
            ).toString(),
          ),
        ),
        const RowDivider(),
        DetailRow(
          leading: Icon(c.isArchived ? AppIcons.unarchive : AppIcons.archive),
          label: c.isArchived ? l.contactRestore : l.contactArchive,
          helper: c.isArchived ? null : l.contactArchiveHint,
          onTap: _toggleArchive,
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// "จับคู่ชื่อในรายการหาร" — typed split names not yet tied to a contact.
// ────────────────────────────────────────────────────────────────────

class _WireNamesRow extends StatefulWidget {
  const _WireNamesRow({
    required this.contact,
    required this.onWired,
    super.key,
  });

  final Contact contact;
  final Future<void> Function() onWired;

  @override
  State<_WireNamesRow> createState() => _WireNamesRowState();
}

class _WireNamesRowState extends State<_WireNamesRow> {
  List<UnlinkedName>? _names;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final list = await context.read<ContactsCubit>().unlinkedNames();
      if (mounted) setState(() => _names = list);
    } on ApiException {
      // Not user-triggered — just show "none" instead of an error.
      if (mounted) setState(() => _names = const []);
    }
  }

  Future<void> _open() async {
    final l = AppLocalizations.of(context)!;
    final wired = await showAppSheet<int>(
      context,
      title: l.contactWireSheetTitle(widget.contact.effectiveName),
      builder: (_) => _WireNamesSheet(contact: widget.contact, names: _names!),
    );
    if (!mounted || wired == null || wired <= 0) return;
    showAppSnackBar(
      context,
      l.contactWireDone(wired, widget.contact.effectiveName),
      tone: Tone.success,
    );
    await widget.onWired();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final names = _names;
    final splits = names?.fold<int>(0, (a, n) => a + n.count) ?? 0;
    final has = names != null && names.isNotEmpty;
    return DetailRow(
      leading: const Icon(AppIcons.split),
      label: l.contactWireTitle,
      helper: names == null
          ? '…'
          : has
          ? l.contactWireHint(names.length, splits)
          : l.contactWireNone,
      showChevron: has,
      onTap: has ? _open : null,
    );
  }
}

class _WireNamesSheet extends StatefulWidget {
  const _WireNamesSheet({required this.contact, required this.names});

  final Contact contact;
  final List<UnlinkedName> names;

  @override
  State<_WireNamesSheet> createState() => _WireNamesSheetState();
}

class _WireNamesSheetState extends State<_WireNamesSheet> {
  final Set<String> _picked = {};
  String _query = '';
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final n = await context.read<ContactsCubit>().absorb(
        widget.contact.id,
        _picked.toList(),
      );
      if (mounted) Navigator.of(context).pop(n);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.names
        : widget.names.where((n) => n.name.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l.contactWireSheetBody,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          AppSearchBar(
            hint: l.contactWireSearch,
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final n in shown)
                  ListTile(
                    leading: SelectCheck(
                      value: _picked.contains(n.name),
                      onTap: _saving ? null : () => _toggle(n.name),
                    ),
                    title: Text(n.name),
                    subtitle: Text(l.contactWireCount(n.count)),
                    onTap: _saving ? null : () => _toggle(n.name),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              label: l.contactWireSave(_picked.length),
              expand: true,
              loading: _saving,
              onPressed: _picked.isEmpty ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String name) => setState(
    () => _picked.contains(name) ? _picked.remove(name) : _picked.add(name),
  );
}

// ────────────────────────────────────────────────────────────────────

class _ContactDraft {
  const _ContactDraft({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.notes = '',
    this.iconCode,
  });

  factory _ContactDraft.from(Contact c) => _ContactDraft(
    name: c.effectiveDisplayName,
    email: c.effectiveEmail ?? '',
    phone: c.phone ?? '',
    notes: c.notes ?? '',
    iconCode: c.iconCode,
  );

  final String name;
  final String email;
  final String phone;
  final String notes;
  final IconCode? iconCode;

  _ContactDraft trimmed() => _ContactDraft(
    name: name.trim(),
    email: email.trim(),
    phone: phone.trim(),
    notes: notes.trim(),
    iconCode: iconCode,
  );

  _ContactDraft copyWith({
    String? name,
    String? email,
    String? phone,
    String? notes,
    IconCode? iconCode,
  }) => _ContactDraft(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    notes: notes ?? this.notes,
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _ContactDraft &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.notes == notes &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(name, email, phone, notes, iconCode);
}
