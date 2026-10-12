import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../cubit/projects_cubit.dart';

/// `/projects/new` — create a project (edit happens in place on the detail
/// page, §12b). A form is edit mode: nav hidden, ยกเลิก · ↶ · บันทึก.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

enum _Field { name, type, description, note, planned }

class _ProjectFormPageState extends State<ProjectFormPage>
    with EditModeMixin<ProjectFormPage, _NewProject> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};

  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    initDraft(const _NewProject(), editing: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  bool get leaveOnCancel => true;

  @override
  void onDraftRestored() {
    for (final f in _Field.values) {
      final v = working.text(f);
      if (_ctrl[f]!.text != v) _ctrl[f]!.text = v;
    }
  }

  Future<void> _pickIcon() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.project,
      title: l.projectIconLabel,
      initial: working.iconCode,
    );
    if (r is IconMakerSelected) {
      applyChange(working.copyWith(iconCode: r.iconCode));
    }
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    final planned = AmountInput.parse(w.planned);
    final cubit = context.read<ProjectsCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final created = await cubit.create(
        name: w.name.trim(),
        type: opt(w.type),
        description: opt(w.description),
        note: opt(w.note),
        iconCode: w.iconCode,
      );
      // planned_amount is only accepted on PUT (API §10).
      if (planned != null) {
        await cubit.update(created.id, plannedAmount: planned);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      context.pushReplacement('/projects/${created.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    void onText(_Field f, String v) =>
        applyTextChange(f, working.withText(f, v));
    final palette = Theme.of(context).extension<AppColors>()!;
    return editScope(
      Scaffold(
        appBar: AppTopBar(
          title: l.projectNewTitle,
          showBack: true,
          editing: true,
          onBack: handleBack,
        ),
        extendBodyBehindAppBar: true,
        body: Form(
          key: _formKey,
          // Builder: the bar height is only in the body's MediaQuery.
          child: Builder(
            builder: (context) => DetailPageBody(
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset:
                  AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              hero: HeaderCard(
                accent: working.iconCode.tintFor(palette),
                glyph: AppIcons.project,
                leading: EditableCircle(
                  size: 48,
                  onTap: _pickIcon,
                  child: IconDisplay(
                    type: IconType.project,
                    size: 48,
                    iconCode: working.iconCode,
                  ),
                ),
                title: HeroNameInput(
                  editing: true,
                  controller: _ctrl[_Field.name]!,
                  focusNode: _nameFocus,
                  hint: l.commonName,
                  maxLength: TextLimits.name,
                  onChanged: (v) => onText(_Field.name, v),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? l.projectNameRequired
                      : null,
                ),
                description: HeroDescription(
                  controller: _ctrl[_Field.description]!,
                  editing: true,
                  hint: l.commonDescription,
                  maxLength: TextLimits.description,
                  onChanged: (v) => onText(_Field.description, v),
                ),
              ),
              sections: [
                (first) => SectionCard(
                  first: first,
                  children: [
                    DetailStacked(
                      label: l.projectTypeLabel,
                      child: AppInput.inline(
                        editing: true,
                        controller: _ctrl[_Field.type]!,
                        hint: l.projectTypeHint,
                        // No TextLimits constant for a project type.
                        maxLength: 50,
                        onChanged: (v) => onText(_Field.type, v),
                      ),
                    ),
                    DetailStacked(
                      label: l.commonNote,
                      child: AppInput.inline(
                        editing: true,
                        controller: _ctrl[_Field.note]!,
                        maxLines: 3,
                        maxLength: TextLimits.note,
                        onChanged: (v) => onText(_Field.note, v),
                      ),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  children: [
                    DetailStacked(
                      label: l.projectFormPlannedLabel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AmountInput(
                            controller: _ctrl[_Field.planned]!,
                            onChanged: (v) => onText(_Field.planned, v),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = AmountInput.parse(v);
                              return (n == null || n <= 0)
                                  ? l.projectFormPlannedInvalid
                                  : null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            l.projectFormPlannedHelper,
                            role: AppTextRole.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: editActionBar(onSave: _save),
      ),
    );
  }
}

class _NewProject {
  const _NewProject({
    this.name = '',
    this.type = '',
    this.description = '',
    this.note = '',
    this.planned = '',
    this.iconCode,
  });

  final String name;
  final String type;
  final String description;
  final String note;
  final String planned;
  final IconCode? iconCode;

  String text(_Field f) => switch (f) {
    _Field.name => name,
    _Field.type => type,
    _Field.description => description,
    _Field.note => note,
    _Field.planned => planned,
  };

  _NewProject withText(_Field f, String v) => _NewProject(
    name: f == _Field.name ? v : name,
    type: f == _Field.type ? v : type,
    description: f == _Field.description ? v : description,
    note: f == _Field.note ? v : note,
    planned: f == _Field.planned ? v : planned,
    iconCode: iconCode,
  );

  _NewProject copyWith({IconCode? iconCode}) => _NewProject(
    name: name,
    type: type,
    description: description,
    note: note,
    planned: planned,
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _NewProject &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.note == note &&
      other.planned == planned &&
      other.iconCode == iconCode;

  @override
  int get hashCode =>
      Object.hash(name, type, description, note, planned, iconCode);
}
