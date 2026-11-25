import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/institutions_repository.dart';
import '../../domain/institution.dart';
import '../widgets/institution_picker.dart' show institutionKindLabel;

/// An institution's page (0.4.3), the contact page's pattern: the hero (its
/// mark, name, description), its kind and contact details, the wallets
/// linked to it, its debt (opens its counterparty page), the note, then
/// archive / delete in edit mode and the meta lines. [id] null = create.
class InstitutionDetailPage extends StatefulWidget {
  const InstitutionDetailPage({this.id, super.key});

  final String? id;

  bool get isCreate => id == null;

  @override
  State<InstitutionDetailPage> createState() => _InstitutionDetailPageState();
}

enum _Field { name, description, phone, email, note }

class _InstitutionDraft extends Equatable {
  const _InstitutionDraft({
    this.name = '',
    this.kind = InstitutionKind.other,
    this.description = '',
    this.phone = '',
    this.email = '',
    this.note = '',
  });

  factory _InstitutionDraft.from(Institution i) => _InstitutionDraft(
    name: i.name,
    kind: i.kind,
    description: i.description ?? '',
    phone: i.phone ?? '',
    email: i.email ?? '',
    note: i.note ?? '',
  );

  final String name;
  final InstitutionKind kind;
  final String description;
  final String phone;
  final String email;
  final String note;

  _InstitutionDraft copyWith({
    String? name,
    InstitutionKind? kind,
    String? description,
    String? phone,
    String? email,
    String? note,
  }) => _InstitutionDraft(
    name: name ?? this.name,
    kind: kind ?? this.kind,
    description: description ?? this.description,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    note: note ?? this.note,
  );

  static String? _t(String v) => v.trim().isEmpty ? null : v.trim();

  InstitutionWrite toWrite(Institution? was) => InstitutionWrite(
    name: name.trim(),
    kind: kind,
    providerId: was?.providerId,
    iconCode: was?.iconCode,
    description: _t(description),
    phone: _t(phone),
    email: _t(email),
    note: _t(note),
  );

  @override
  List<Object?> get props => [name, kind, description, phone, email, note];
}

class _InstitutionDetailPageState extends State<InstitutionDetailPage>
    with EditModeMixin<InstitutionDetailPage, _InstitutionDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final _noteFocus = FocusNode();

  InstitutionDetail? _detail;
  ApiException? _error;
  bool _loading = false;
  bool _changed = false;
  String? _createdId;

  InstitutionsRepository get _repo => InstitutionsRepository.of(context);
  Institution? get _inst => _detail?.institution;

  @override
  void initState() {
    super.initState();
    initDraft(const _InstitutionDraft(), editing: widget.isCreate);
    if (!widget.isCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _detail == null;
      _error = null;
    });
    try {
      final d = await _repo.get(widget.id!);
      if (!mounted) return;
      setState(() => _detail = d);
      if (!isEditing) resetDraft(_InstitutionDraft.from(d.institution));
      onDraftRestored();
    } on ApiException catch (e) {
      if (mounted && _detail == null) setState(() => _error = e);
      if (mounted && _detail != null) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void onDraftRestored() {
    void sync(_Field f, String v) {
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }

    final w = working;
    sync(_Field.name, w.name);
    sync(_Field.description, w.description);
    sync(_Field.phone, w.phone);
    sync(_Field.email, w.email);
    sync(_Field.note, w.note);
  }

  void _onText(_Field f, String v) => applyTextChange(f, switch (f) {
    _Field.name => working.copyWith(name: v),
    _Field.description => working.copyWith(description: v),
    _Field.phone => working.copyWith(phone: v),
    _Field.email => working.copyWith(email: v),
    _Field.note => working.copyWith(note: v),
  });

  @override
  bool get leaveOnCancel => widget.isCreate;

  @override
  void leavePage() {
    if (context.canPop()) {
      context.pop(widget.isCreate ? _createdId : _changed);
    } else {
      super.leavePage();
    }
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final write = working.toWrite(_inst);
      final saved = widget.isCreate
          ? await _repo.create(write)
          : await _repo.update(widget.id!, write);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _changed = true;
      if (widget.isCreate) {
        // Back to where it was made from, with its id (a picker picks it).
        _createdId = saved.id;
        commitSaved(working);
        leavePage();
        return;
      }
      commitSaved(_InstitutionDraft.from(saved));
      unawaited(_load());
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showErrorSnackBarOn(pageMessenger!, e);
    }
  }

  Future<void> _archive({required bool restore}) async {
    final l = AppLocalizations.of(context)!;
    if (!restore) {
      final ok = await showConfirmDialog(
        context,
        title: l.recurringArchive,
        message: l.institutionArchiveBody,
        confirmLabel: l.recurringArchive,
      );
      if (!ok || !mounted) return;
    }
    setSaving(true);
    try {
      final i = await _repo.archive(widget.id!, restore: restore);
      if (!mounted) return;
      _changed = true;
      commitSaved(_InstitutionDraft.from(i));
      unawaited(_load());
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showErrorSnackBarOn(pageMessenger!, e);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.commonDelete,
      message: l.institutionDeleteBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setSaving(true);
    try {
      await _repo.delete(widget.id!);
      if (!mounted) return;
      _changed = true;
      commitSaved(working);
      leavePage();
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showErrorSnackBarOn(pageMessenger!, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!widget.isCreate && _detail == null) {
      return AppPage(
        topBar: AppTopBar(title: l.institutionTitle, showBack: true),
        body: AsyncStateView.fallback(
          loading: _loading || _error == null,
          error: _error,
          onRetry: _load,
          notFound: EmptyView(
            icon: AppIcons.bank,
            title: l.institutionTitle,
            message: l.institutionNotFound,
          ),
        ),
      );
    }
    final inst = _inst;
    return editScope(
      BusyScope(
        busy: isSaving,
        child: AppPage(
          topBar: AppTopBar(
            title: inst?.name ?? l.institutionNewTitle,
            showBack: true,
            editing: isEditing,
            onBack: handleBack,
          ),
          body: Form(
            key: _formKey,
            child: Builder(
              builder: (context) => DetailLayout(
                onRefresh: widget.isCreate ? null : _load,
                refreshEnabled: !isEditing,
                bottomInset:
                    PpForgeSpacing.huge + MediaQuery.paddingOf(context).bottom,
                compactBar: _compactBar(),
                hero: _hero(l),
                info: _info(l),
                note: NoteSection(
                  label: l.commonNote,
                  editing: isEditing,
                  text: inst?.note,
                  controller: _ctrl[_Field.note]!,
                  maxLength: TextLimits.note,
                  hint: l.commonLongPressToEdit,
                  onLongPress: () => enterEdit(focus: _noteFocus),
                  editField: DetailStacked(
                    label: l.commonNote,
                    child: PpForgeInput.inline(
                      editing: true,
                      controller: _ctrl[_Field.note]!,
                      focusNode: _noteFocus,
                      maxLines: 3,
                      maxLength: TextLimits.note,
                      onChanged: (v) => _onText(_Field.note, v),
                    ),
                  ),
                ),
                endZone: isEditing && inst != null ? _endZone(l, inst) : null,
                metaLines: inst == null
                    ? const []
                    : detailMetaLines(
                        context,
                        createdAt: inst.createdAt,
                        updatedAt: inst.updatedAt,
                      ),
              ),
            ),
          ),
          bottomBar: isEditing ? editActionBar(onSave: _save) : null,
        ),
      ),
    );
  }

  /// The hero, small (view mode only): the mark and the name.
  PpForgeCompactHeroCard? _compactBar() {
    final inst = _inst;
    if (inst == null || isEditing || widget.isCreate) return null;
    final color =
        InstitutionMark.parseHex(inst.provider?.color) ??
        Theme.of(context).colorScheme.primary;
    return PpForgeCompactHeroCard(
      style: HeroStyle.tinted(color: color),
      leading: InstitutionMark(
        name: inst.name.isEmpty ? '?' : inst.name,
        iconCode: inst.iconCode,
        shortName: inst.provider?.shortName,
        color: color,
        size: 28,
      ),
      title: PpForgeText(inst.name, role: PpForgeTextRole.title),
    );
  }

  Widget _hero(AppLocalizations l) {
    final inst = _inst;
    final editing = isEditing;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final color =
        InstitutionMark.parseHex(inst?.provider?.color) ??
        Theme.of(context).colorScheme.primary;
    final debt = _detail?.debt;
    final symbol = context.readUserCurrencySymbol;
    return PpForgeHeroCard(
      style: HeroStyle.tinted(color: color),
      mode: editing ? HeroCardMode.edit : HeroCardMode.view,
      content: [
        HeroIdentity(
          icon: InstitutionMark(
            name: working.name.isEmpty ? '?' : working.name,
            iconCode: inst?.iconCode,
            shortName: inst?.provider?.shortName,
            color: color,
            size: 44,
          ),
          name: editing
              ? HeroNameInput(
                  editing: true,
                  controller: _ctrl[_Field.name]!,
                  hint: l.commonName,
                  maxLength: TextLimits.name,
                  onChanged: (v) => _onText(_Field.name, v),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.recurringNameRequired
                      : null,
                )
              : Text(inst?.name ?? ''),
          description: editing || (inst?.description ?? '').isNotEmpty
              ? HeroDescription(
                  controller: _ctrl[_Field.description]!,
                  editing: editing,
                  hint: l.commonDescription,
                  maxLength: TextLimits.description,
                  onChanged: (v) => _onText(_Field.description, v),
                  onEnterEdit: enterEdit,
                )
              : null,
          actions: editing
              ? const []
              : [
                  CardActionButton(
                    icon: AppIcons.edit,
                    tooltip: PpForgeConfig.stringsOf(context).edit,
                    onTap: enterEdit,
                  ),
                ],
        ),
        if (!editing && debt != null)
          DebtAmountLine(
            key: const ValueKey('institutionDebt'),
            net: debt.net,
            owedToMeLabel: l.debtsOwedToMe,
            iOweLabel: l.debtsIOwe,
            settledLabel: l.debtsEven,
            currencySymbol: symbol,
          ),
        if (!editing && inst != null)
          HeroChipRow(
            chips: [
              PpForgeChip(
                label: institutionKindLabel(l, inst.kind),
                selected: true,
                tone: PpForgeChipTone.neutral,
              ),
              if (inst.archived)
                PpForgeChip(
                  label: l.recurringStatusArchived,
                  color: palette.expense,
                ),
            ],
          ),
      ],
    );
  }

  Widget _info(AppLocalizations l) {
    final inst = _inst;
    final editing = isEditing;
    final w = working;
    final d = _detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          first: true,
          children: [
            if (editing)
              SettingDropdownRow<InstitutionKind>(
                key: const ValueKey('institutionKind'),
                label: l.institutionKindLabel,
                value: institutionKindLabel(l, w.kind),
                selected: w.kind,
                submits: false,
                onSelected: (k) => applyChange(w.copyWith(kind: k)),
                options: [
                  for (final k in InstitutionKind.values)
                    SheetOption(value: k, label: institutionKindLabel(l, k)),
                ],
              ),
            DetailTextField(
              label: l.institutionPhone,
              controller: _ctrl[_Field.phone]!,
              editing: editing,
              notSetLabel: inst?.provider?.phone,
              keyboardType: TextInputType.phone,
              onChanged: (v) => _onText(_Field.phone, v),
              onEnterEdit: enterEdit,
            ),
            DetailTextField(
              label: l.institutionEmail,
              controller: _ctrl[_Field.email]!,
              editing: editing,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => _onText(_Field.email, v),
              onEnterEdit: enterEdit,
            ),
            if (!editing && inst?.website != null)
              PpForgeDetailRow(
                label: l.institutionWebsite,
                trailing: Text(inst!.website!),
              ),
          ],
        ),
        if (!editing && d != null) ...[
          SectionCard(
            key: const ValueKey('institutionDebtRow'),
            children: [
              PpForgeDetailRow(
                leading: const PpForgeIcon(AppIcons.debt),
                label: l.moreDebts,
                showChevron: true,
                onTap: () => openPage(
                  context,
                  '/personal-debts/people/${Uri.encodeComponent(d.debt.key)}',
                ),
              ),
            ],
          ),
          if (d.accounts.isNotEmpty)
            SectionCard(
              key: const ValueKey('institutionWallets'),
              title: l.institutionWallets,
              children: [
                for (final a in d.accounts)
                  PpForgeListRow(
                    key: ValueKey('institutionWallet-${a.id}'),
                    leading: IconDisplay(
                      type: IconType.account,
                      size: 36,
                      iconCode: a.iconCode,
                    ),
                    title: a.name,
                    onTap: () => openPage(context, '/accounts/${a.id}'),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _endZone(AppLocalizations l, Institution inst) => EndZone(
    actions: [
      EndZoneAction(
        kind: EndZoneKind.archive,
        label: inst.archived ? l.recurringRestore : l.recurringArchive,
        consequence: l.institutionArchiveBody,
        onTap: isSaving ? null : () => _archive(restore: inst.archived),
      ),
      EndZoneAction(
        kind: EndZoneKind.delete,
        label: l.commonDelete,
        consequence: l.institutionDeleteBody,
        onTap: isSaving ? null : _delete,
      ),
    ],
  );
}
