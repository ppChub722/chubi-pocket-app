import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/project_common.dart';

/// `/projects/new` — create an event (edit happens in place on the detail
/// page, §12b). A form is edit mode: nav hidden, ยกเลิก · ↶ · บันทึก.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

enum _Field { name, description, note, planned }

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

  /// Start / end are optional; each bounds the other (end ≥ start).
  Future<void> _pickDate({required bool start}) async {
    final l = AppLocalizations.of(context)!;
    final w = working;
    final current = start ? w.startDate : w.endDate;
    final first = start ? null : w.startDate;
    final last = start ? w.endDate : null;
    var initial = current ?? DateTime.now();
    if (first != null && initial.isBefore(first)) initial = first;
    if (last != null && initial.isAfter(last)) initial = last;
    final r = await showAppDatePicker(
      context,
      title: start ? l.eventStartDateLabel : l.eventEndDateLabel,
      initial: initial,
      first: first,
      last: last,
      clearable: current != null,
    );
    if (!mounted || r == null) return;
    final picked = r is AppDatePicked ? r.date : null;
    applyChange(
      start
          ? w.copyWith(startDate: () => picked)
          : w.copyWith(endDate: () => picked),
    );
  }

  Future<void> _save() async {
    commitTextSession();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context)!;
    final w = working;
    final s = w.startDate;
    final e = w.endDate;
    if (s != null && e != null && e.isBefore(s)) {
      showAppSnackBar(context, l.eventDatesInvalid, tone: Tone.danger);
      return;
    }
    String? opt(String s) => s.trim().isEmpty ? null : s.trim();
    final planned = AmountInput.parse(w.planned);
    final cubit = context.read<ProjectsCubit>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      // One call: plan, dates and my tags included.
      final created = await cubit.create(
        name: w.name.trim(),
        description: opt(w.description),
        note: opt(w.note),
        startDate: s == null ? null : projectDay(s),
        endDate: e == null ? null : projectDay(e),
        plannedAmount: planned,
        tagIds: w.tagIds.toList(),
        iconCode: w.iconCode,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      context.pushReplacement('/projects/${created.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(
        context,
        eventErrorText(AppLocalizations.of(context)!, e),
        tone: Tone.danger,
      );
    }
  }

  /// MY tags on the new event (private to me).
  Future<void> _pickTags() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showTagPickerSheet(
      context,
      selected: working.tagIds,
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    applyChange(working.copyWith(tagIds: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    void onText(_Field f, String v) =>
        applyTextChange(f, working.withText(f, v));
    final palette = Theme.of(context).extension<AppColors>()!;
    final tags = context.watch<TagsCubit>();
    String? day(DateTime? d) =>
        d == null ? null : projectDateRange(context, projectDay(d), null);
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
              // My tags, right under the hero (detail-page order).
              tags: ChipRow(
                icon: AppIcons.tag,
                chips: [
                  for (final id in working.tagIds)
                    if (tags.byId(id) case final t?)
                      AppChip(
                        label: t.name,
                        icon: IconRegistry.get(
                          t.iconCode?.icon,
                          fallback: AppIcons.tag,
                        ),
                        color: EventTagRef(
                          t.name,
                          iconCode: t.iconCode,
                        ).colorOf(palette),
                        selected: true,
                        size: ChipSize.chip,
                        onTap: _pickTags,
                      ),
                ],
                onMore: _pickTags,
              ),
              sections: [
                (first) => SectionCard(
                  first: first,
                  children: [
                    DetailRow.pick(
                      label: l.eventStartDateLabel,
                      icon: AppIcons.date,
                      value: day(working.startDate),
                      emptyText: l.eventDateNone,
                      onTap: () => _pickDate(start: true),
                    ),
                    DetailRow.pick(
                      label: l.eventEndDateLabel,
                      icon: AppIcons.date,
                      value: day(working.endDate),
                      emptyText: l.eventDateNone,
                      onTap: () => _pickDate(start: false),
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
    this.description = '',
    this.note = '',
    this.planned = '',
    this.startDate,
    this.endDate,
    this.tagIds = const {},
    this.iconCode,
  });

  final String name;
  final String description;
  final String note;
  final String planned;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> tagIds;
  final IconCode? iconCode;

  String text(_Field f) => switch (f) {
    _Field.name => name,
    _Field.description => description,
    _Field.note => note,
    _Field.planned => planned,
  };

  _NewProject withText(_Field f, String v) => _NewProject(
    name: f == _Field.name ? v : name,
    description: f == _Field.description ? v : description,
    note: f == _Field.note ? v : note,
    planned: f == _Field.planned ? v : planned,
    startDate: startDate,
    endDate: endDate,
    tagIds: tagIds,
    iconCode: iconCode,
  );

  /// The dates take a getter so a pick can clear them (null).
  _NewProject copyWith({
    IconCode? iconCode,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    Set<String>? tagIds,
  }) => _NewProject(
    name: name,
    description: description,
    note: note,
    planned: planned,
    startDate: startDate == null ? this.startDate : startDate(),
    endDate: endDate == null ? this.endDate : endDate(),
    tagIds: tagIds ?? this.tagIds,
    iconCode: iconCode ?? this.iconCode,
  );

  @override
  bool operator ==(Object other) =>
      other is _NewProject &&
      other.name == name &&
      other.description == description &&
      other.note == note &&
      other.planned == planned &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      setEquals(other.tagIds, tagIds) &&
      other.iconCode == iconCode;

  @override
  int get hashCode => Object.hash(
    name,
    description,
    note,
    planned,
    startDate,
    endDate,
    Object.hashAllUnordered(tagIds),
    iconCode,
  );
}
