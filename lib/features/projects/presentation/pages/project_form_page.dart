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
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../cubit/projects_cubit.dart';

/// `/projects/new` — create a project (edit happens in place on the detail
/// page, §12b). A form is edit mode: nav hidden, ยกเลิก · ↶ · บันทึก.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

enum _Field { name, type, description, planned }

class _ProjectFormPageState extends State<ProjectFormPage>
    with EditModeMixin<ProjectFormPage, _NewProject> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};

  @override
  void initState() {
    super.initState();
    initDraft(const _NewProject(), editing: true);
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  bool get leaveOnCancel => true;

  @override
  void leavePage() {
    if (context.canPop()) context.pop();
  }

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
    if (r is IconMakerSelected) applyChange(working.copyWith(iconCode: r.iconCode));
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = working;
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    final planned = AmountField.parse(w.planned);
    final cubit = context.read<ProjectsCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      final created = await cubit.create(
        name: w.name.trim(),
        type: opt(w.type),
        description: opt(w.description),
        iconCode: w.iconCode,
      );
      // planned_amount is only accepted on PUT (API §10).
      if (planned != null) await cubit.update(created.id, plannedAmount: planned);
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
    void onText(_Field f, String v) => applyTextChange(f, working.withText(f, v));
    return editScope(Scaffold(
      appBar: AppTopBar(
        title: l.projectNewTitle,
        showBack: true,
        editing: true,
        onBack: handleBack,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                EditableCircle(
                  size: 56,
                  onTap: _pickIcon,
                  child: IconDisplay(
                      type: IconType.project, size: 56, iconCode: working.iconCode),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _ctrl[_Field.name]!,
                    label: l.projectNameLabel,
                    autofocus: true,
                    maxLength: 100,
                    onChanged: (v) => onText(_Field.name, v),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? l.projectNameRequired : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ctrl[_Field.type]!,
              label: l.projectTypeLabel,
              hint: l.projectTypeHint,
              prefixIcon: AppIcons.project,
              maxLength: 50,
              onChanged: (v) => onText(_Field.type, v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ctrl[_Field.description]!,
              label: l.projectDescriptionLabel,
              prefixIcon: AppIcons.note,
              maxLines: 3,
              maxLength: 500,
              onChanged: (v) => onText(_Field.description, v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AmountField(
              controller: _ctrl[_Field.planned]!,
              label: l.projectFormPlannedLabel,
              onChanged: (v) => onText(_Field.planned, v),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = AmountField.parse(v);
                return (n == null || n <= 0) ? l.projectFormPlannedInvalid : null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l.projectFormPlannedHelper,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      bottomNavigationBar: editActionBar(onSave: _save),
    ));
  }
}

class _NewProject {
  const _NewProject({
    this.name = '',
    this.type = '',
    this.description = '',
    this.planned = '',
    this.iconCode,
  });

  final String name;
  final String type;
  final String description;
  final String planned;
  final IconCode? iconCode;

  String text(_Field f) => switch (f) {
        _Field.name => name,
        _Field.type => type,
        _Field.description => description,
        _Field.planned => planned,
      };

  _NewProject withText(_Field f, String v) => _NewProject(
        name: f == _Field.name ? v : name,
        type: f == _Field.type ? v : type,
        description: f == _Field.description ? v : description,
        planned: f == _Field.planned ? v : planned,
        iconCode: iconCode,
      );

  _NewProject copyWith({IconCode? iconCode}) => _NewProject(
        name: name,
        type: type,
        description: description,
        planned: planned,
        iconCode: iconCode ?? this.iconCode,
      );

  @override
  bool operator ==(Object other) =>
      other is _NewProject &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.planned == planned &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(name, type, description, planned, iconCode);
}
