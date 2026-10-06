import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/edit_mode/edit_mode_mixin.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../data/projects_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/project.dart';
import '../widgets/project_common.dart';
import '../widgets/project_tx_tiles.dart';

/// One form for adding (`/projects/:id/transactions/new`) and editing (pushed
/// with [editing]) a project row (§12c). A form is edit mode: nav hidden,
/// ยกเลิก · ↶ · บันทึก. On edit the type and payer are fixed (the API
/// doesn't change them). Pops `true` after saving.
class ProjectTransactionFormPage extends StatefulWidget {
  const ProjectTransactionFormPage({
    required this.projectId,
    this.editing,
    super.key,
  });

  final String projectId;
  final ProjectTxTree? editing;

  bool get isEdit => editing != null;

  @override
  State<ProjectTransactionFormPage> createState() =>
      _ProjectTransactionFormPageState();
}

enum _Field { amount, description, note, category }

class _ProjectTransactionFormPageState
    extends State<ProjectTransactionFormPage>
    with EditModeMixin<ProjectTransactionFormPage, _TxDraft> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = {for (final f in _Field.values) f: TextEditingController()};
  final Map<int, TextEditingController> _splitCtrl = {};
  int _splitSeq = 0;

  List<ProjectMember> _members = const [];
  List<(String, IconCode)> _pastCategories = const [];
  String _currency = 'THB';
  bool _loading = true;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      final p = e.parent;
      _currency = p.currency;
      initDraft(
        _TxDraft(
          type: p.type,
          memberId: p.transactionMemberId,
          amount: AmountField.format(p.amount),
          date: p.date,
          description: p.description ?? '',
          note: p.note ?? '',
          categoryName: p.categoryName ?? '',
          categoryIconCode: p.categoryIconCode,
          splits: [
            for (final c in e.children)
              _Split(_splitSeq++, c.transactionMemberId, AmountField.format(c.amount)),
          ],
        ),
        editing: true,
      );
    } else {
      initDraft(_TxDraft(date: _ymd(DateTime.now())), editing: true);
    }
    onDraftRestored();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in [..._ctrl.values, ..._splitCtrl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    try {
      final repo = context.read<ProjectsRepository>();
      final results = await Future.wait([
        repo.listMembers(widget.projectId),
        repo.listTransactions(widget.projectId, perPage: 100),
      ]);
      if (!mounted) return;
      final members = (results[0] as List<ProjectMember>)
          .where((m) => m.status != MemberStatus.left)
          .toList();
      final txs = results[1] as List<ProjectTransaction>;
      final seen = <String, (String, IconCode)>{};
      for (final t in txs) {
        if (t.categoryName != null && t.categoryIconCode != null) {
          seen.putIfAbsent('${t.categoryName}|${t.categoryIconCode!.icon}',
              () => (t.categoryName!, t.categoryIconCode!));
        }
      }
      setState(() {
        _members = members;
        _pastCategories = seen.values.toList();
        if (!widget.isEdit && txs.isNotEmpty) _currency = txs.first.currency;
        _loading = false;
      });
      // Default payer = me (else the first member) — part of the baseline,
      // not an undo step.
      if (!widget.isEdit && working.memberId == null && members.isNotEmpty) {
        final auth = context.read<AuthCubit>().state;
        final uid = auth is AuthAuthenticated ? auth.user.id : null;
        final me = members.where((m) => m.userId != null && m.userId == uid);
        initDraft(working.copyWith(memberId: (me.firstOrNull ?? members.first).id),
            editing: true);
        setState(() {});
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  // ── EditModeMixin hooks ─────────────────────────────────────────────

  @override
  bool get leaveOnCancel => true;

  @override
  void leavePage() => Navigator.of(context).pop(false);

  @override
  void onDraftRestored() {
    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_ctrl[_Field.amount]!, working.amount);
    sync(_ctrl[_Field.description]!, working.description);
    sync(_ctrl[_Field.note]!, working.note);
    sync(_ctrl[_Field.category]!, working.categoryName);
    for (final s in working.splits) {
      sync(_splitCtrl.putIfAbsent(s.key, TextEditingController.new), s.amount);
    }
  }

  ProjectMember? _member(String? id) =>
      _members.where((m) => m.id == id).firstOrNull;

  // ── Splits ──────────────────────────────────────────────────────────

  void _addSplit() {
    final used = {working.memberId, ...working.splits.map((s) => s.memberId)};
    final next = _members.where((m) => !used.contains(m.id)).firstOrNull;
    final s = _Split(_splitSeq++, next?.id, '');
    _splitCtrl[s.key] = TextEditingController();
    applyChange(working.copyWith(splits: [...working.splits, s]));
  }

  void _removeSplit(_Split s) => applyChange(working.copyWith(
      splits: working.splits.where((e) => e.key != s.key).toList()));

  void _setSplit(_Split s, {String? memberId, String? amount}) {
    List<_Split> replaced(_Split Function(_Split) f) =>
        [for (final e in working.splits) e.key == s.key ? f(e) : e];
    if (amount != null) {
      // Typing — grouped into one undo step per field burst.
      applyTextChange('split${s.key}',
          working.copyWith(splits: replaced((e) => _Split(e.key, e.memberId, amount))));
    } else {
      applyChange(working.copyWith(
          splits: replaced((e) => _Split(e.key, memberId, e.amount))));
    }
  }

  /// Everyone else gets total / headcount (payer included in the count).
  void _splitEqually() {
    final total = AmountField.parse(working.amount) ?? 0;
    final others = _members.where((m) => m.id != working.memberId).toList();
    if (total <= 0 || others.isEmpty) return;
    final share = (total / (others.length + 1) * 100).floorToDouble() / 100;
    final splits = [
      for (final m in others) _Split(_splitSeq++, m.id, AmountField.format(share)),
    ];
    for (final s in splits) {
      _splitCtrl[s.key] = TextEditingController(text: s.amount);
    }
    applyChange(working.copyWith(splits: splits));
  }

  double get _splitSum => working.splits
      .fold(0, (a, s) => a + (AmountField.parse(s.amount) ?? 0));

  // ── Pickers ─────────────────────────────────────────────────────────

  Future<void> _pickPayer() async {
    final l = AppLocalizations.of(context)!;
    final id = await showOptionSheet<String>(
      context,
      title: working.type == 'income' ? l.projectTxReceivedBy : l.projectTxPaidBy,
      selected: working.memberId,
      options: [
        for (final m in _members)
          SheetOption(
            value: m.id,
            label: m.displayName,
            leading: ProjectMemberAvatar(member: m, size: 28),
          ),
      ],
    );
    if (id == null || !mounted) return;
    // The payer can't also owe themself.
    applyChange(working.copyWith(
      memberId: id,
      splits: working.splits.where((s) => s.memberId != id).toList(),
    ));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(working.date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) applyChange(working.copyWith(date: _ymd(d)));
  }

  Future<void> _pickCategoryIcon() async {
    final l = AppLocalizations.of(context)!;
    final r = await showIconMakerSheet(
      context: context,
      type: IconType.projectTransaction,
      title: l.projectTxCategory,
      initial: working.categoryIconCode,
    );
    if (r is IconMakerSelected) {
      applyChange(working.copyWith(categoryIconCode: r.iconCode));
    }
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    commitTextSession();
    final l = AppLocalizations.of(context)!;
    final formOk = _formKey.currentState?.validate() ?? false;
    final w = working;
    final amount = AmountField.parse(w.amount) ?? 0;
    String? err;
    if (w.categoryName.trim().isEmpty || w.categoryIconCode == null) {
      err = l.projectTxCategoryRequired;
    } else if (_splitSum > amount + 0.005) {
      err = l.projectTxSplitsOver(
          moneyString(context, _splitSum, symbol: Currencies.symbolOf(_currency)));
    }
    setState(() => _formError = err);
    if (!formOk || err != null || w.memberId == null) return;

    final splits = [
      for (final s in w.splits)
        if (s.memberId != null && (AmountField.parse(s.amount) ?? 0) > 0)
          ProjectSplitInput(memberId: s.memberId!, amount: AmountField.parse(s.amount)!),
    ];
    final repo = context.read<ProjectsRepository>();
    FocusScope.of(context).unfocus();
    setSaving(true);
    try {
      if (widget.isEdit) {
        await repo.updateTransaction(
          widget.projectId,
          widget.editing!.parent.id,
          amount: amount,
          date: w.date,
          description: w.description.trim(),
          note: w.note.trim(),
          categoryName: w.categoryName.trim(),
          categoryIconCode: w.categoryIconCode,
          splits: splits,
        );
      } else {
        await repo.createTransaction(
          widget.projectId,
          transactionMemberId: w.memberId!,
          type: w.type,
          amount: amount,
          currency: _currency,
          date: w.date,
          description: w.description.trim(),
          note: w.note.trim().isEmpty ? null : w.note.trim(),
          categoryName: w.categoryName.trim(),
          categoryIconCode: w.categoryIconCode,
          splits: splits,
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      commitSaved(w);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setSaving(false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final w = working;
    final symbol = Currencies.symbolOf(_currency);
    final isExpense = w.type == 'expense';
    final payer = _member(w.memberId);
    final total = AmountField.parse(w.amount) ?? 0;
    final others = _members.where((m) => m.id != w.memberId).toList();

    return editScope(Scaffold(
      appBar: AppTopBar(
        title: widget.isEdit ? l.projectTxEditTitle : l.projectTxNewTitle,
        showBack: true,
        editing: true,
        onBack: handleBack,
      ),
      body: _loading
          ? const LoadingView()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.huge),
                children: [
                  if (!widget.isEdit) ...[
                    SelectCardGroup<String>(
                      selected: w.type,
                      onChanged: (t) => applyChange(w.copyWith(type: t)),
                      options: [
                        SelectCardOption(
                          value: 'expense',
                          label: l.projectTxTypeExpense,
                          icon: AppIcons.expense,
                          color: palette.expense,
                        ),
                        SelectCardOption(
                          value: 'income',
                          label: l.projectTxTypeIncome,
                          icon: AppIcons.income,
                          color: palette.income,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AmountField(
                    controller: _ctrl[_Field.amount]!,
                    autofocus: !widget.isEdit,
                    currencySymbol: symbol,
                    accent: isExpense ? palette.expense : palette.income,
                    onChanged: (v) =>
                        applyTextChange(_Field.amount, working.copyWith(amount: v)),
                    validator: (v) {
                      final n = AmountField.parse(v);
                      return (n == null || n <= 0) ? l.projectTxAmountRequired : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PickerTile(
                    label: isExpense ? l.projectTxPaidBy : l.projectTxReceivedBy,
                    value: payer?.displayName,
                    leading: payer == null
                        ? const Icon(AppIcons.member)
                        : ProjectMemberAvatar(member: payer, size: 24),
                    readOnly: widget.isEdit,
                    onTap: widget.isEdit ? null : _pickPayer,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _ctrl[_Field.description]!,
                    label: l.projectTxDescription,
                    prefixIcon: AppIcons.note,
                    maxLength: 200,
                    onChanged: (v) => applyTextChange(
                        _Field.description, working.copyWith(description: v)),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? l.projectTxDescriptionRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PickerTile(
                    label: l.projectTxDate,
                    value: projectTxDateLabel(context, w.date),
                    leading: const Icon(AppIcons.date),
                    onTap: _pickDate,
                  ),
                  SectionHeader(title: l.projectTxCategory),
                  if (_pastCategories.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final (name, code) in _pastCategories)
                          ChoiceChip(
                            avatar: Icon(
                              IconRegistry.get(code.icon,
                                  fallback: AppIcons.category),
                              size: 16,
                              color: code.accentColorFor(palette),
                            ),
                            label: Text(name),
                            selected: w.categoryName == name &&
                                w.categoryIconCode == code,
                            showCheckmark: false,
                            onSelected: (_) => applyChange(w.copyWith(
                                categoryName: name, categoryIconCode: code)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      EditableCircle(
                        size: 44,
                        onTap: _pickCategoryIcon,
                        child: IconBubble(
                          icon: IconRegistry.get(w.categoryIconCode?.icon,
                              fallback: AppIcons.iconPicker),
                          color: w.categoryIconCode?.accentColorFor(palette) ??
                              scheme.onSurfaceVariant,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          controller: _ctrl[_Field.category]!,
                          label: l.projectTxCategoryName,
                          maxLength: 50,
                          onChanged: (v) => applyTextChange(_Field.category,
                              working.copyWith(categoryName: v)),
                        ),
                      ),
                    ],
                  ),
                  if (others.isNotEmpty) ...[
                    SectionHeader(
                      title: l.projectTxSplits,
                      actionLabel: total > 0 ? l.projectTxSplitEqual : null,
                      onAction: total > 0 ? _splitEqually : null,
                    ),
                    Text(l.projectTxSplitsHint,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    for (final s in w.splits)
                      _SplitRow(
                        split: s,
                        members: others,
                        controller: _splitCtrl.putIfAbsent(
                            s.key, () => TextEditingController(text: s.amount)),
                        symbol: symbol,
                        onMember: (id) => _setSplit(s, memberId: id),
                        onAmount: (v) => _setSplit(s, amount: v),
                        onRemove: () => _removeSplit(s),
                      ),
                    if (w.splits.length < others.length)
                      AddTile(
                        label: l.projectTxAddSplit,
                        variant: AddTileVariant.row,
                        onTap: _addSplit,
                      ),
                    if (w.splits.isNotEmpty && total > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          l.projectTxPayerKeeps(moneyString(
                              context, (total - _splitSum).clamp(0, total),
                              symbol: symbol)),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _ctrl[_Field.note]!,
                    label: l.projectTxNote,
                    maxLines: 2,
                    maxLength: 500,
                    onChanged: (v) =>
                        applyTextChange(_Field.note, working.copyWith(note: v)),
                  ),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(_formError!,
                          style: TextStyle(color: scheme.error)),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: editActionBar(onSave: _save),
    ));
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.members,
    required this.controller,
    required this.symbol,
    required this.onMember,
    required this.onAmount,
    required this.onRemove,
  });

  final _Split split;
  final List<ProjectMember> members;
  final TextEditingController controller;
  final String symbol;
  final ValueChanged<String> onMember;
  final ValueChanged<String> onAmount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final member = members.where((m) => m.id == split.memberId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: OptionMenuAnchor<String>(
              selected: split.memberId,
              onSelected: onMember,
              options: [
                for (final m in members)
                  SheetOption(
                    value: m.id,
                    label: m.displayName,
                    leading: ProjectMemberAvatar(member: m, size: 24),
                  ),
              ],
              builder: (context, toggle) => PickerTile(
                label: AppLocalizations.of(context)!.projectRoleMember,
                value: member?.displayName,
                leading: member == null
                    ? const Icon(AppIcons.member)
                    : ProjectMemberAvatar(member: member, size: 24),
                onTap: toggle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 112,
            child: AppTextField(
              controller: controller,
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: null,
              onChanged: onAmount,
            ),
          ),
          AppIconButton(
            icon: AppIcons.clear,
            tooltip: AppLocalizations.of(context)!.commonDelete,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _Split {
  const _Split(this.key, this.memberId, this.amount);

  /// Stable per row (controller map key).
  final int key;
  final String? memberId;

  /// Text as typed.
  final String amount;

  @override
  bool operator ==(Object other) =>
      other is _Split &&
      other.key == key &&
      other.memberId == memberId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(key, memberId, amount);
}

class _TxDraft {
  const _TxDraft({
    this.type = 'expense',
    this.memberId,
    this.amount = '',
    this.date = '',
    this.description = '',
    this.note = '',
    this.categoryName = '',
    this.categoryIconCode,
    this.splits = const [],
  });

  final String type;
  final String? memberId;
  final String amount;
  final String date;
  final String description;
  final String note;
  final String categoryName;
  final IconCode? categoryIconCode;
  final List<_Split> splits;

  _TxDraft copyWith({
    String? type,
    String? memberId,
    String? amount,
    String? date,
    String? description,
    String? note,
    String? categoryName,
    IconCode? categoryIconCode,
    List<_Split>? splits,
  }) =>
      _TxDraft(
        type: type ?? this.type,
        memberId: memberId ?? this.memberId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        description: description ?? this.description,
        note: note ?? this.note,
        categoryName: categoryName ?? this.categoryName,
        categoryIconCode: categoryIconCode ?? this.categoryIconCode,
        splits: splits ?? this.splits,
      );

  @override
  bool operator ==(Object other) =>
      other is _TxDraft &&
      other.type == type &&
      other.memberId == memberId &&
      other.amount == amount &&
      other.date == date &&
      other.description == description &&
      other.note == note &&
      other.categoryName == categoryName &&
      other.categoryIconCode == categoryIconCode &&
      _listEq(other.splits, splits);

  static bool _listEq(List<_Split> a, List<_Split> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(type, memberId, amount, date, description,
      note, categoryName, categoryIconCode, Object.hashAll(splits));
}
