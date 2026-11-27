import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../transactions/domain/refs.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart' show RecurringDetail;
import '../../domain/recurring_page.dart';
import '../../domain/rule_draft.dart';
import '../cubit/recurring_directory_cubit.dart';
import '../recurring_rows.dart' show recurringIconCode;
import '../widgets/rule_row.dart';
import 'rule_page.dart';

/// The tracking types, in the list chips' order (spec §1).
const recurringTrackingTypes = [
  'bill',
  'subscription',
  'installment',
  'credit_card',
  'person_debt',
  'income',
  'saving',
  'other',
];

String trackingTypeLabel(AppLocalizations l, String t) => switch (t) {
  'bill' => l.trackingBill,
  'subscription' => l.trackingSubscription,
  'installment' => l.trackingInstallment,
  'credit_card' => l.trackingCreditCard,
  'person_debt' => l.trackingPersonDebt,
  'income' => l.trackingIncome,
  'saving' => l.trackingSaving,
  _ => l.trackingOther,
};

/// The per-month amount of a rule (a schedule's rounds over the next year
/// / 12); null for an asked one.
double? ruleMonthly(RuleDraft d) {
  final a = d.amount;
  if (a == null || a <= 0 || (d.ask && d.canAsk)) return null;
  final from = d.rule.start;
  final rounds = recurrenceDates(
    d.rule,
    until: DateTime(from.year + 1, from.month, from.day - 1),
  );
  return a * rounds.length / 12;
}

/// Create a recurring, or edit its own fields (spec §3 create; mock Main):
/// hero (icon, name, description, read-only total per month) → ประเภท (a
/// tracking filter) → Rules | n (+ เพิ่ม rule, top right) → โน้ต. A new
/// recurring's rules are drafts until บันทึก saves everything in one call;
/// an existing one's rules open their own page. Edit adds พัก / เก็บถาวร /
/// ลบ at the end.
/// What a new recurring starts with when it is made from somewhere else
/// (quick create's "สร้างรายการประจำ": the tx's type, amount, category,
/// wallet and name become its first draft rule). [pick] = pop with the new
/// recurring's id (the picker picks it) instead of opening it.
class RecurringFormPreset {
  const RecurringFormPreset({
    this.type,
    this.amount,
    this.categoryId,
    this.accountId,
    this.name,
    this.pick = false,
  });

  /// From `/recurring/new?type=&amount=&category=&account=&name=&pick=1`.
  factory RecurringFormPreset.fromQuery(Map<String, String> q) =>
      RecurringFormPreset(
        type: q['type'],
        amount: double.tryParse(q['amount'] ?? ''),
        categoryId: q['category'],
        accountId: q['account'],
        name: q['name'],
        pick: q['pick'] == '1',
      );

  final String? type;
  final double? amount;
  final String? categoryId;
  final String? accountId;
  final String? name;
  final bool pick;
}

class RecurringFormPage extends StatefulWidget {
  const RecurringFormPage({
    this.id,
    this.preset = const RecurringFormPreset(),
    super.key,
  });

  /// null = a new recurring.
  final String? id;
  final RecurringFormPreset preset;

  @override
  State<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends State<RecurringFormPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PpForgeIconCode? _icon;
  String _tracking = 'other';
  final List<RuleDraft> _drafts = [];
  RecurringDetail? _detail;
  Object? _loadError;
  bool _saving = false;
  bool _dirty = false;
  bool _rulesMissing = false;

  bool get _isCreate => widget.id == null;
  RecurringPage? get _page => _detail?.page;

  @override
  void initState() {
    super.initState();
    if (!_isCreate) {
      unawaited(_load());
    } else {
      _applyPreset();
    }
  }

  /// A new recurring from quick create: its name and one draft rule.
  void _applyPreset() {
    final p = widget.preset;
    if (p.type == null) return;
    _name.text = p.name ?? '';
    final c = p.categoryId == null
        ? null
        : context.read<CategoriesCubit>().byId(p.categoryId!);
    final a = p.accountId == null
        ? null
        : context.read<AccountsCubit>().byId(p.accountId!);
    _drafts.add(
      RuleDraft.blank(RecurringKind.fromJson(p.type)).copyWith(
        amount: p.amount,
        category: c == null
            ? null
            : EmbeddedCategory(
                id: c.id,
                name: c.name,
                type: c.type,
                iconCode: c.iconCode,
                parentId: c.parentId,
              ),
        account: a == null
            ? null
            : AccountRef(
                id: a.id,
                name: a.name,
                iconCode: a.iconCode,
                type: a.type,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await RecurringRepository.of(context).get(widget.id!);
      if (!mounted) return;
      final j = d.page?.json ?? const {};
      setState(() {
        _detail = d;
        _loadError = null;
        _name.text = (j['name'] as String?) ?? '';
        _description.text = (j['description'] as String?) ?? '';
        _note.text = (j['note'] as String?) ?? '';
        _icon = j['icon_code'] is Map<String, dynamic>
            ? PpForgeIconCode.fromJson(j['icon_code'] as Map<String, dynamic>)
            : null;
        _tracking = d.page?.trackingType ?? 'other';
        _dirty = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _touch() => setState(() => _dirty = true);

  Future<void> _pickIcon() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.category,
      initial: _icon,
      title: l.recurringFieldIcon,
    );
    if (!mounted || r == null) return;
    if (r is PpForgeIconMakerSelected) {
      _icon = r.iconCode;
    } else if (r is PpForgeIconMakerRemoved) {
      _icon = null;
    }
    _touch();
  }

  /// A draft rule (create) or a saved one (edit) on its own page.
  Future<void> _openRule({int? index}) async {
    if (_isCreate) {
      final draft = index == null
          ? RuleDraft.blank(RecurringKind.expense)
          : _drafts[index];
      final r = await context.push<Object?>(
        '/recurring/new/rules/${index == null ? 'new' : 'draft'}',
        extra: RulePageArgs(
          draft: draft,
          seq: (index ?? _drafts.length) + 1,
          recurringName: _name.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        if (isRuleDraftDeleted(r) && index != null) {
          _drafts.removeAt(index);
        } else if (r is RuleDraft) {
          index == null ? _drafts.add(r) : _drafts[index] = r;
          _rulesMissing = false;
        }
        _dirty = true;
      });
      return;
    }
    final line = index == null ? null : _page!.lines[index];
    final r = await context.push<Object?>(
      '/recurring/${widget.id}/rules/${line?.id ?? 'new'}',
      extra: RulePageArgs(seq: line?.seq, recurringName: _page?.name),
    );
    if (!mounted) return;
    if (r is RecurringDetail) setState(() => _detail = r);
  }

  Future<void> _ruleMenu(int index, RuleRowMenu m) async {
    if (_isCreate) {
      if (m == RuleRowMenu.delete) setState(() => _drafts.removeAt(index));
      return;
    }
    final repo = RecurringRepository.of(context);
    final line = _page!.lines[index];
    try {
      final d = switch (m) {
        RuleRowMenu.pause => await repo.lineAction(
          widget.id!,
          line.id,
          RecurringAction.pause,
        ),
        RuleRowMenu.resume => await repo.lineAction(
          widget.id!,
          line.id,
          RecurringAction.resume,
        ),
        RuleRowMenu.delete => await repo.deleteLine(widget.id!, line.id),
      };
      if (mounted) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Map<String, dynamic> _own() => {
    'name': _name.text.trim(),
    'description': _description.text.trim().isEmpty
        ? null
        : _description.text.trim(),
    'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
    'icon_code': _icon?.toJson(),
    'tracking_type': _tracking,
  };

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final ok = _formKey.currentState?.validate() ?? false;
    if (_isCreate && _drafts.isEmpty) setState(() => _rulesMissing = true);
    if (!ok || (_isCreate && _drafts.isEmpty)) return;
    setState(() => _saving = true);
    try {
      final repo = RecurringRepository.of(context);
      final d = _isCreate
          ? await repo.createWithRules(recurring: _own(), rules: _drafts)
          : await repo.updateOwn(widget.id!, _own());
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().load());
      if (_isCreate && widget.preset.pick) {
        // the recurring picker picks it (owner 2026-11-04)
        Navigator.of(context).pop(d.page?.id);
      } else if (_isCreate) {
        context.pushReplacement('/recurring/${d.page?.id ?? ''}');
      } else {
        Navigator.of(context).pop(d);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _itemAction(RecurringAction a) async {
    try {
      final d = await RecurringRepository.of(context).action(widget.id!, a);
      if (mounted) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.recurringDeleteTitle,
      message: l.recurringDeleteKeepsWritten,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await RecurringRepository.of(context).delete(widget.id!);
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().load());
      context.go('/recurring');
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final loading = !_isCreate && _detail == null;
    return AppPage(
      topBar: AppTopBar(
        title: _isCreate ? l.recurringFormNewCrumb : _page?.name,
        showBack: true,
      ),
      bottomBar: loading
          ? null
          : ModeActionBar(
              canSave: !_saving && (_dirty || _isCreate),
              saving: _saving,
              cancelLabel: PpForgeConfig.stringsOf(context).cancel,
              saveLabel: PpForgeConfig.stringsOf(context).save,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _save,
            ),
      body: loading
          ? (_loadError != null
                ? ErrorView(error: _loadError!, onRetry: _load)
                : const Center(child: CircularProgressIndicator.adaptive()))
          : Form(key: _formKey, child: _body(l)),
    );
  }

  Widget _body(AppLocalizations l) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final rules = _isCreate
        ? [for (final d in _drafts) RuleRow(draft: d)]
        : [
            for (final line in _page!.lines)
              RuleRow.of(line, key: ValueKey('rule:${line.id}')),
          ];
    final firstCat = _isCreate
        ? _drafts.firstOrNull?.category?.iconCode
        : _page?.lines.firstOrNull?.view.category?.iconCode;
    final icon = recurringIconCode(
      kind: RecurringKind.expense,
      own: _icon,
      category: firstCat,
    );
    final monthly = _isCreate
        ? _drafts.fold<double>(0, (s, d) => s + (ruleMonthly(d) ?? 0))
        : _page?.monthTotal ?? 0;
    final status = _page?.status;
    return ListView(
      padding: AppPage.scrollPadding(context),
      children: [
        PpForgeHeroCard(
          key: const ValueKey('recurringFormHero'),
          style: HeroStyle.tinted(
            color: icon.tintFor(palette),
            glyph: AppIcons.scheduled,
          ),
          mode: HeroCardMode.edit,
          content: [
            HeroIdentity(
              icon: EditableCircle(
                size: 44,
                onTap: _pickIcon,
                child: IconDisplay(
                  type: IconType.category,
                  size: 44,
                  iconCode: icon,
                ),
              ),
              name: HeroNameInput(
                editing: true,
                controller: _name,
                hint: l.commonName,
                maxLength: TextLimits.name,
                onChanged: (_) => _touch(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.recurringNameRequired
                    : null,
              ),
              description: HeroDescription(
                controller: _description,
                editing: true,
                hint: l.commonDescription,
                maxLength: TextLimits.description,
                onChanged: (_) => _touch(),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PpForgeText(
                        l.recurringFormTotalLabel,
                        role: PpForgeTextRole.caption,
                      ),
                      PpForgeText(
                        l.recurringFormTotalHint,
                        role: PpForgeTextRole.caption,
                      ),
                    ],
                  ),
                ),
                PpForgeText(
                  l.recurringHomePerMonth(moneyString(context, monthly)),
                  key: const ValueKey('recurringFormMonthly'),
                  role: PpForgeTextRole.title,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          first: true,
          children: [
            SettingDropdownRow<String>(
              key: const ValueKey('recurringTracking'),
              label: l.recurringFieldKind,
              helper: l.recurringTrackingHelper,
              value: trackingTypeLabel(l, _tracking),
              selected: _tracking,
              options: [
                for (final t in recurringTrackingTypes)
                  SheetOption(value: t, label: trackingTypeLabel(l, t)),
              ],
              onSelected: (t) {
                _tracking = t;
                _touch();
              },
            ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.md),
        PpForgeListHeader(
          key: const ValueKey('recurringRulesHeader'),
          title: l.recurringRulesTitle,
          count: rules.length,
          actions: [
            ListHeaderAction.button(
              AppIcons.add,
              tooltip: l.recurringAddRule,
              onTap: status == RecurringStatus.archived ? null : _openRule,
            ),
          ],
        ),
        if (_rulesMissing)
          PpForgeText(
            l.recurringRulesRequired,
            role: PpForgeTextRole.caption,
            color: Theme.of(context).colorScheme.error,
          ),
        SectionCard(
          first: true,
          children: [
            for (final (i, row) in rules.indexed)
              RuleRow(
                key: row.key,
                draft: row.draft,
                line: row.line,
                onTap: () => _openRule(index: i),
                onMenu: (m) => _ruleMenu(i, m),
              ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          first: true,
          title: l.commonNote,
          children: [
            PpForgeInput(
              key: const ValueKey('recurringNote'),
              controller: _note,
              hint: l.recurringNoteHint,
              maxLines: 4,
              maxLength: TextLimits.note,
              onChanged: (_) => _touch(),
            ),
          ],
        ),
        if (!_isCreate && status != null) ...[
          const SizedBox(height: PpForgeSpacing.lg),
          Wrap(
            spacing: PpForgeSpacing.sm,
            runSpacing: PpForgeSpacing.sm,
            children: [
              if (status == RecurringStatus.active)
                PpForgeButton(
                  key: const ValueKey('recurringPause'),
                  label: l.recurringPause,
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () => _itemAction(RecurringAction.pause),
                ),
              if (status == RecurringStatus.paused)
                PpForgeButton(
                  key: const ValueKey('recurringResume'),
                  label: l.recurringResume,
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () => _itemAction(RecurringAction.resume),
                ),
              if (status != RecurringStatus.archived)
                PpForgeButton(
                  key: const ValueKey('recurringArchive'),
                  label: l.recurringArchive,
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () => _itemAction(RecurringAction.archive),
                )
              else
                PpForgeButton(
                  key: const ValueKey('recurringRestore'),
                  label: l.recurringRestore,
                  variant: PpForgeButtonVariant.outlined,
                  onPressed: () => _itemAction(RecurringAction.restore),
                ),
              PpForgeButton(
                key: const ValueKey('recurringDelete'),
                label: l.commonDelete,
                variant: PpForgeButtonVariant.destructiveOutlined,
                onPressed: _delete,
              ),
            ],
          ),
        ],
        const SizedBox(height: PpForgeSpacing.xl),
      ],
    );
  }
}
