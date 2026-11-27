import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../institutions/presentation/widgets/institution_picker.dart';
import '../../../pending/domain/pending_transaction.dart' show TagRef;
import '../../../personal_debts/domain/debt_direction.dart';
import '../../../personal_debts/domain/debt_ledger.dart' show debtPersonKey;
import '../../../personal_debts/presentation/debt_wiring.dart'
    show debtPersonLevel;
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../../saving_goals/domain/saving_goals_overview.dart';
import '../../../saving_goals/presentation/widgets/saving_goal_picker.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../../transactions/domain/refs.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/category_pick_card.dart';
import '../../../transactions/presentation/widgets/pick_chip_rows.dart'
    show TagChipRow;
import '../../../transactions/presentation/widgets/debt_entry_form.dart'
    show DebtPick, showDebtPersonPicker;
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart' show RecurringDetail;
import '../../domain/recurring_page.dart';
import '../../domain/rule_draft.dart';
import '../cubit/recurring_directory_cubit.dart';

/// What opens the rule page besides its route: a draft of the create page
/// (edited here, handed back on บันทึก), or a page that makes a rule of its
/// own (its field prefilled, `อยู่ในรายการประจำ` on top).
class RulePageArgs {
  const RulePageArgs({
    this.draft,
    this.seq,
    this.recurringName,
    this.fromPage,
    this.crumbs = const [],
  });

  /// The create page's draft rule; บันทึก pops it back unsaved.
  final RuleDraft? draft;
  final int? seq;
  final String? recurringName;

  /// Made from another page: its new recurring's name ("ออมเป้าเที่ยว"),
  /// and the recurring it used before (the row's default the next time).
  final RuleFromPage? fromPage;

  /// The breadcrumb of where the user came from (not stored).
  final List<String> crumbs;
}

class RuleFromPage {
  const RuleFromPage({
    required this.newName,
    required this.preset,
    this.existingId,
    this.existingName,
    this.trackingType = 'other',
  });

  final String newName;
  final RuleDraft preset;
  final String? existingId;
  final String? existingName;
  final String trackingType;
}

/// One rule (spec §3 rule page, mock RuleSheet / RuleSheetPaused /
/// RuleVariants / RuleFromGoal): a page, never a sheet, so its pickers open
/// one sheet over it. Header (category icon, Rule n, status) → paused banner
/// → อยู่ในรายการประจำ → ประเภท → เงิน → หมวดหมู่ | กระเป๋า + แท็ก (quick
/// create look) → ช่วงเวลา → ถึงงวด → ลบ rule. No view mode: it edits.
class RulePage extends StatefulWidget {
  const RulePage({
    this.recurringId,
    this.ruleId,
    this.args = const RulePageArgs(),
    super.key,
  });

  /// null = made from another page (into a new or picked recurring);
  /// 'new' = a draft of the create page.
  final String? recurringId;

  /// null = a new rule.
  final String? ruleId;
  final RulePageArgs args;

  @override
  State<RulePage> createState() => _RulePageState();
}

class _RulePageState extends State<RulePage> {
  RuleDraft? _draft;
  RuleDraft? _initial;
  RecurringLine? _line;
  RecurringDetail? _detail;
  Object? _loadError;
  bool _saving = false;
  bool _walletMissing = false;
  bool _personMissing = false;
  bool _amountMissing = false;
  SavingGoalsOverview? _goals;
  bool _goalsAsked = false;

  /// From another page: the recurring the rule goes into (null = a new one).
  String? _intoId;
  late final TextEditingController _amountText;

  bool get _isDraft => widget.recurringId == 'new';
  bool get _fromPage => widget.recurringId == null;

  @override
  void initState() {
    super.initState();
    _amountText = TextEditingController();
    final a = widget.args;
    if (a.draft != null) {
      _setDraft(a.draft!);
    } else if (_fromPage && a.fromPage != null) {
      _intoId = a.fromPage!.existingId;
      _setDraft(a.fromPage!.preset);
      unawaited(context.read<RecurringDirectoryCubit>().loadIfNeeded());
    } else if (widget.ruleId == null) {
      _setDraft(RuleDraft.blank(RecurringKind.expense));
      unawaited(_load());
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _amountText.dispose();
    super.dispose();
  }

  void _setDraft(RuleDraft d) {
    _draft = d;
    _initial ??= d;
    final a = d.amount;
    _amountText.text = a == null || a <= 0 ? '' : AmountInput.format(a);
  }

  Future<void> _load() async {
    final id = widget.recurringId;
    if (id == null || _isDraft) return;
    try {
      final d = await RecurringRepository.of(context).get(id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        final line = d.page?.lines
            .where((l) => l.id == widget.ruleId)
            .firstOrNull;
        _line = line;
        if (line != null) {
          _initial = null;
          _setDraft(RuleDraft.fromLine(line));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  RuleDraft get w => _draft!;

  void _change(RuleDraft d) => setState(() => _draft = d);

  bool get _dirty => _draft != _initial;

  // ---- pickers ----

  Future<void> _pickType(RecurringKind k) async {
    var d = w.copyWith(type: k, clearPlan: true, clearRepays: true);
    if (k == RecurringKind.saving) d = d.copyWith(ask: false);
    if (k != RecurringKind.expense) d = d.copyWith(clearPaidBy: true);
    _change(d);
  }

  Future<void> _pickWallet({required bool to}) async {
    final l = AppLocalizations.of(context)!;
    final r = await AccountPicker.one(
      context,
      selectedId: to ? w.toAccount?.id : w.account?.id,
      excludeIds: {?(to ? w.account?.id : w.toAccount?.id)},
      title: to ? l.recurringFieldToWallet : null,
      // หนี้: no wallet = ledger-only rows; ค่าใช้จ่าย: a person may pay
      allowNone: w.type == RecurringKind.debt,
    );
    if (!mounted) return;
    if (r is AccountPickedNone) {
      _change(w.copyWith(clearAccount: true));
      return;
    }
    if (r is! AccountPicked) return;
    final ref = _accountRef(r.account);
    setState(() => _walletMissing = false);
    _change(
      to
          ? w.copyWith(toAccount: ref)
          : w.copyWith(account: ref, clearPaidBy: true),
    );
  }

  static AccountRef _accountRef(Account a) =>
      AccountRef(id: a.id, name: a.name, iconCode: a.iconCode, type: a.type);

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final r = await CategoryPicker.one(
      context,
      types: {
        w.type == RecurringKind.income
            ? CategoryType.income
            : CategoryType.expense,
      },
      selectedId: w.category?.id,
      allowNone: true,
      title: l.recurringFieldCategory,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _change(switch (r) {
      CategoryPicked(:final category) => w.copyWith(
        category: EmbeddedCategory(
          id: category.id,
          name: category.name,
          type: category.type,
          iconCode: category.iconCode,
        ),
      ),
      CategoryPickedNone() => w.copyWith(clearCategory: true),
    });
  }

  Future<void> _pickTags() async {
    final l = AppLocalizations.of(context)!;
    final picked = await TagPicker.many(
      context,
      selected: {for (final t in w.tags) t.id},
      title: l.transactionFormTagsLabel,
    );
    if (picked == null || !mounted) return;
    final tags = context.read<TagsCubit>();
    _change(
      w.copyWith(
        tags: [
          for (final id in picked.ids)
            TagRef(id: id, name: tags.byId(id)?.name ?? ''),
        ],
      ),
    );
  }

  void _loadGoals() {
    if (_goalsAsked) return;
    _goalsAsked = true;
    unawaited(
      context.read<SavingGoalsRepository>().list().then(
        (o) {
          if (mounted) setState(() => _goals = o);
        },
        onError: (Object _) {
          if (mounted) setState(() => _goals = const SavingGoalsOverview());
        },
      ),
    );
  }

  Future<void> _pickGoal() async {
    final r = await SavingGoalPicker.one(
      context,
      selectedId: w.goal?.id,
      spareSelected: w.goalPicked && w.goal == null,
      overview: _goals,
    );
    if (!mounted || r == null) return;
    SavingGoal? goal;
    for (final g in _goals?.goals ?? const <SavingGoal>[]) {
      if (g.id == r.goalId) goal = g;
    }
    _change(
      r.goalId == null
          ? w.copyWith(clearGoal: true, goalPicked: true)
          : w.copyWith(
              goal: SavingGoalRef(id: r.goalId!, name: goal?.name ?? ''),
              goalPicked: true,
            ),
    );
  }

  Future<void> _pickCounterparty() async {
    final l = AppLocalizations.of(context)!;
    final institution = await showChoiceDialog<bool>(
      context,
      title: l.recurringCounterpartyLabel,
      choices: [
        DialogChoice(value: false, label: l.recurringCounterpartyPerson),
        DialogChoice(value: true, label: l.recurringCounterpartyInstitution),
      ],
    );
    if (!mounted || institution == null) return;
    if (!institution) {
      final p = w.person;
      final picked = await showDebtPersonPicker(
        context,
        selected: p == null
            ? null
            : DebtPick(
                key: debtPersonKey(contactId: p.contactId, name: p.name),
                person: p,
              ),
      );
      if (picked == null || !mounted) return;
      setState(() => _personMissing = false);
      _change(w.copyWith(person: picked.person, clearInstitution: true));
      return;
    }
    final picked = await InstitutionPicker.one(
      context,
      selectedId: w.institution?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _personMissing = false);
    _change(w.copyWith(institution: picked, clearPerson: true, ask: false));
  }

  Future<void> _pickPaidBy() async {
    final p = w.paidBy;
    final picked = await showDebtPersonPicker(
      context,
      selected: p == null
          ? null
          : DebtPick(
              key: debtPersonKey(contactId: p.contactId, name: p.name),
              person: p,
            ),
    );
    if (picked == null || !mounted) return;
    setState(() => _walletMissing = false);
    _change(w.copyWith(paidBy: picked.person, clearAccount: true));
  }

  Future<void> _pickStart() async {
    final now = today();
    final current = w.rule.start;
    final picked = await PpForgeDatePicker.show(
      context,
      initial: current,
      first: current.isBefore(now) ? current : now,
      last: DateTime(now.year + 2, now.month, now.day),
    );
    if (!mounted || picked is! PpForgeDatePicked) return;
    final d = picked.date;
    final r = w.rule;
    _change(
      w.copyWith(
        rule: r.copyWith(
          start: d,
          weekdays: r.weekdays.length == 1 ? {d.weekday} : null,
          monthDays: r.monthDays.length == 1 ? {d.day} : null,
        ),
      ),
    );
  }

  Future<void> _openRepeat() async {
    final picked = await AppRecurrenceSheet.show(
      context,
      initial: w.rule,
      amount: w.ask ? null : w.amount,
    );
    if (!mounted || picked == null) return;
    _change(w.copyWith(rule: picked));
  }

  // ---- save / delete ----

  bool _valid() {
    final walletOk = switch (w.type) {
      RecurringKind.transfer => w.account != null && w.toAccount != null,
      RecurringKind.saving => w.account != null,
      RecurringKind.debt => true,
      _ => w.account != null || w.paidBy != null,
    };
    final personOk =
        w.type != RecurringKind.debt ||
        w.planId != null ||
        w.person != null ||
        w.institution != null;
    final amountOk =
        w.amountFollows || (w.ask && w.canAsk) || (w.amount ?? 0) > 0;
    setState(() {
      _walletMissing = !walletOk;
      _personMissing = !personOk;
      _amountMissing = !amountOk;
    });
    return walletOk && personOk && amountOk;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_valid()) return;
    final d = w;
    if (_isDraft) {
      Navigator.of(context).pop(d);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = RecurringRepository.of(context);
      final RecurringDetail done;
      if (_fromPage) {
        final from = widget.args.fromPage;
        done = await repo.createRule(
          rule: d,
          recurringId: _intoId,
          newRecurring: _intoId == null
              ? {
                  'name': from?.newName ?? '',
                  'tracking_type': from?.trackingType ?? 'other',
                }
              : null,
        );
      } else if (d.isNew) {
        done = await repo.addRule(widget.recurringId!, d);
      } else {
        done = await repo.updateRule(widget.recurringId!, d);
      }
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().load());
      Navigator.of(context).pop(done);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.ruleDelete,
      message: l.ruleDeleteConfirm,
      confirmLabel: l.ruleDelete,
      destructive: true,
    );
    if (ok != true || !mounted) return;
    if (_isDraft) {
      Navigator.of(context).pop(const _Deleted());
      return;
    }
    try {
      final done = await RecurringRepository.of(
        context,
      ).deleteLine(widget.recurringId!, widget.ruleId!);
      if (!mounted) return;
      unawaited(context.read<RecurringDirectoryCubit>().load());
      Navigator.of(context).pop(done);
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  Future<void> _resume() async {
    try {
      final d = await RecurringRepository.of(
        context,
      ).lineAction(widget.recurringId!, widget.ruleId!, RecurringAction.resume);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _line = d.page?.lines.where((l) => l.id == widget.ruleId).firstOrNull;
      });
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = _draft;
    final name =
        widget.args.recurringName ??
        _detail?.page?.name ??
        widget.args.fromPage?.newName ??
        '';
    final seq = _line?.seq ?? widget.args.seq;
    final title = d?.isNew ?? true ? l.ruleNewTitle : l.ruleTitle(seq ?? 1);
    return AppPage(
      topBar: AppTopBar(title: title, showBack: true),
      bottomBar: d == null
          ? null
          : ModeActionBar(
              canSave: !_saving && (_dirty || d.isNew),
              saving: _saving,
              cancelLabel: PpForgeConfig.stringsOf(context).cancel,
              saveLabel: PpForgeConfig.stringsOf(context).save,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _save,
            ),
      body: d == null
          ? (_loadError != null
                ? ErrorView(error: _loadError!, onRetry: _load)
                : const Center(child: CircularProgressIndicator.adaptive()))
          : _body(l, d, title, name),
    );
  }

  Widget _body(AppLocalizations l, RuleDraft d, String title, String name) {
    final scheme = Theme.of(context).colorScheme;
    final paused = _line?.status == RecurringStatus.paused;
    return ListView(
      padding: AppPage.scrollPadding(context),
      children: [
        _header(l, d, title, name, paused),
        if (paused) ...[
          const SizedBox(height: PpForgeSpacing.md),
          _pausedBanner(l),
        ],
        if (_fromPage && widget.args.fromPage != null) ...[
          const SizedBox(height: PpForgeSpacing.md),
          _intoRow(l),
        ],
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          first: true,
          children: [
            SettingDropdownRow<RecurringKind>(
              key: const ValueKey('ruleType'),
              label: l.recurringFieldKind,
              value: _typeLabel(l, d.type),
              selected: d.type,
              options: [
                for (final k in RecurringKind.values)
                  SheetOption(value: k, label: _typeLabel(l, k)),
              ],
              onSelected: d.amountFollows ? null : _pickType,
            ),
            if (d.type == RecurringKind.debt && d.planId == null)
              SettingDropdownRow<bool>(
                key: const ValueKey('ruleDebtKind'),
                label: l.ruleDebtRepay,
                value: d.debtRecord ? l.ruleDebtRecord : l.ruleDebtRepay,
                selected: d.debtRecord,
                options: [
                  SheetOption(value: false, label: l.ruleDebtRepay),
                  SheetOption(value: true, label: l.ruleDebtRecord),
                ],
                onSelected: (v) =>
                    _change(d.copyWith(debtRecord: v, ask: v ? false : null)),
              ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.md),
        _moneyCard(l, d, scheme),
        const SizedBox(height: PpForgeSpacing.md),
        _entryCards(l, d),
        const SizedBox(height: PpForgeSpacing.md),
        _periodSection(l, d),
        const SizedBox(height: PpForgeSpacing.md),
        _dueSection(l, d),
        if (!d.isNew || _isDraft) ...[
          const SizedBox(height: PpForgeSpacing.lg),
          PpForgeButton(
            key: const ValueKey('ruleDelete'),
            label: l.ruleDelete,
            kind: ButtonIconKind.delete,
            variant: PpForgeButtonVariant.destructiveOutlined,
            expand: true,
            onPressed: _delete,
          ),
        ],
        const SizedBox(height: PpForgeSpacing.xl),
      ],
    );
  }

  /// rule นี้พักอยู่ … [ทำต่อ] (mock RuleSheetPaused).
  Widget _pausedBanner(AppLocalizations l) => PpForgeMessage(
    key: const ValueKey('rulePaused'),
    tone: Tone.warning,
    message: l.rulePausedBanner,
    actions: [
      PpForgeMessageAction(label: l.recurringResume, onPressed: _resume),
    ],
  );

  Widget _header(
    AppLocalizations l,
    RuleDraft d,
    String title,
    String name,
    bool paused,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final cat = d.category;
    return Row(
      children: [
        IconDisplay(iconCode: cat?.iconCode, type: IconType.category, size: 40),
        const SizedBox(width: PpForgeSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: PpForgeText(title, role: PpForgeTextRole.title),
                  ),
                  const SizedBox(width: PpForgeSpacing.sm),
                  if (!d.isNew)
                    PpForgeChip(
                      key: const ValueKey('ruleStatus'),
                      label: paused ? l.ruleStatusPaused : l.ruleStatusActive,
                      tone: paused
                          ? PpForgeChipTone.neutral
                          : PpForgeChipTone.success,
                      size: ChipSize.chip,
                    ),
                ],
              ),
              if (name.isNotEmpty)
                PpForgeText(
                  [name, ?cat?.name].join(' · '),
                  role: PpForgeTextRole.caption,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// อยู่ในรายการประจำ [ ▾ ]: first time = "{name} · สร้างใหม่", later = that
  /// page's recurring; any other recurring can be picked.
  Widget _intoRow(AppLocalizations l) {
    final from = widget.args.fromPage!;
    final items = context.watch<RecurringDirectoryCubit>().state.rules;
    const newKey = '';
    final options = <SheetOption<String>>[
      SheetOption(value: newKey, label: l.ruleInRecurringNew(from.newName)),
      for (final r in items)
        if (r.status != RecurringStatus.archived)
          SheetOption(value: r.id, label: r.name),
    ];
    final current = _intoId ?? newKey;
    final label =
        options.where((o) => o.value == current).firstOrNull?.label ??
        from.existingName ??
        l.ruleInRecurringNew(from.newName);
    return SectionCard(
      first: true,
      children: [
        SettingDropdownRow<String>(
          key: const ValueKey('ruleInto'),
          label: l.ruleInRecurring,
          helper: l.ruleInRecurringHint,
          value: label,
          selected: current,
          options: options,
          onSelected: (v) => setState(() => _intoId = v.isEmpty ? null : v),
        ),
      ],
    );
  }

  String _typeLabel(AppLocalizations l, RecurringKind k) => switch (k) {
    RecurringKind.expense => l.ruleTypeExpense,
    RecurringKind.income => l.ruleTypeIncome,
    RecurringKind.transfer => l.ruleTypeTransfer,
    RecurringKind.saving => l.ruleTypeSaving,
    RecurringKind.debt => l.ruleTypeDebt,
  };

  /// เงิน: ยอดต่องวด + [คงที่ | ใส่ทุกงวด]; a plan / payback / saving show
  /// their rule as text (mock RuleVariants).
  Widget _moneyCard(AppLocalizations l, RuleDraft d, ColorScheme scheme) {
    final money = txWordsColor(
      context,
      d.type == RecurringKind.saving
          ? TransactionType.transfer
          : d.type.defaultType,
    );
    final followText = d.planId != null
        ? l.ruleAmountSchedule
        : d.repaysRuleId != null
        ? l.ruleAmountFollow(
            _detail?.page?.lines
                    .where((x) => x.id == d.repaysRuleId)
                    .firstOrNull
                    ?.seq ??
                1,
          )
        : d.type == RecurringKind.saving
        ? l.ruleAmountFixedOnly
        : null;
    final hint = _line?.prefillHint;
    return PpForgeHeroCard(
      key: const ValueKey('ruleMoney'),
      mode: HeroCardMode.edit,
      style: HeroStyle.tinted(color: money),
      content: [
        Row(
          children: [
            Expanded(
              child: PpForgeText(
                l.ruleAmountPerRound,
                role: PpForgeTextRole.caption,
              ),
            ),
            if (followText != null)
              PpForgeText(
                followText,
                key: const ValueKey('ruleAmountMode'),
                role: PpForgeTextRole.caption,
              )
            else if (d.canAsk)
              SegmentedChoice<bool>(
                key: const ValueKey('ruleAmountMode'),
                segments: [
                  ChoiceSegment(false, l.ruleAmountFixed),
                  ChoiceSegment(true, l.ruleAmountAsk),
                ],
                selected: d.ask,
                onChanged: (v) => _change(d.copyWith(ask: v)),
              ),
          ],
        ),
        if (d.planId == null && d.repaysRuleId == null)
          HeroAmountField(
            controller: _amountText,
            label: d.ask ? l.ruleAmountAskValue : l.ruleAmountPerRound,
            symbol: context.readUserCurrencySymbol,
            helper: hint != null
                ? l.rulePrefillHint(moneyString(context, hint))
                : null,
            onChanged: (v) {
              final n = AmountInput.parse(v);
              setState(() => _amountMissing = false);
              _change(
                n == null || n <= 0
                    ? d.copyWith(clearAmount: true)
                    : d.copyWith(amount: n),
              );
            },
            validator: (_) => _amountMissing ? l.ruleAmountRequired : null,
          ),
      ],
    );
  }

  /// หมวดหมู่ | กระเป๋า + แท็ก as quick create (mock RuleSheet); โอน / ออม /
  /// หนี้ = from → to.
  Widget _entryCards(AppLocalizations l, RuleDraft d) {
    final accounts = context.watch<AccountsCubit>();
    final account = accounts.byId(d.account?.id ?? '');
    final toAccount = accounts.byId(d.toAccount?.id ?? '');
    Widget wallet(Account? a, String label, {bool to = false}) =>
        WalletPickCard(
          key: ValueKey(to ? 'ruleToWallet' : 'ruleWallet'),
          account: a,
          label: label,
          placeholder: d.type == RecurringKind.debt && !to
              ? l.debtNoWallet
              : l.quickPickWallet,
          dense: true,
          editable: true,
          errorText: _walletMissing && a == null && d.paidBy == null
              ? l.ruleWalletRequired
              : null,
          onTap: () => _pickWallet(to: to),
        );
    final children = <Widget>[];
    switch (d.type) {
      case RecurringKind.transfer:
        children.add(
          FlowCards(
            from: wallet(account, l.fpRecurringFieldFromWallet),
            to: wallet(toAccount, l.recurringFieldToWallet, to: true),
          ),
        );
      case RecurringKind.saving:
        _loadGoals();
        SavingGoal? goal;
        for (final g in _goals?.goals ?? const <SavingGoal>[]) {
          if (g.id == d.goal?.id) goal = g;
        }
        children.add(
          FlowCards(
            from: wallet(account, l.transactionFormAccountLabel),
            to: SavingGoalPickCard(
              key: const ValueKey('ruleGoal'),
              goal: goal,
              spare: d.goalPicked && d.goal == null,
              spareAmount: _goals?.spare.amount,
              label: l.ruleIntoGoal,
              placeholder: d.goal?.name ?? l.savingEntryPickGoal,
              spareLabel: l.savingEntrySpare,
              dense: true,
              editable: true,
              onTap: _pickGoal,
            ),
          ),
        );
      case RecurringKind.debt:
        final p = d.person;
        final inst = d.institution;
        final person = PickCard(
          key: const ValueKey('rulePerson'),
          label: l.ruleCounterparty,
          value: d.planName ?? inst?.name ?? p?.name,
          placeholder: l.debtPickPerson,
          dense: true,
          editable: d.planId == null,
          accent: Theme.of(context).colorScheme.primary,
          errorText: _personMissing ? l.rulePersonRequired : null,
          leading: inst != null
              ? InstitutionMark(
                  name: inst.name,
                  iconCode: inst.iconCode,
                  size: 32,
                )
              : p == null
              ? const PickCardEmptyIcon(AppIcons.contact, size: 32)
              : PersonMark(
                  level: debtPersonLevel(p),
                  avatar: p.avatar,
                  size: 32,
                ),
          onTap: d.planId == null ? _pickCounterparty : null,
        );
        // the money's way: paid (they owe me) = me → them on a payback
        final out = d.debtRecord
            ? d.direction == DebtEntryDirection.paid
            : d.direction == DebtEntryDirection.received;
        final w = wallet(account, l.transactionFormAccountLabel);
        children.add(
          FlowCards(
            key: const ValueKey('ruleDebtFlow'),
            from: out ? w : person,
            to: out ? person : w,
            swapTooltip: l.quickSwap,
            onSwap: d.planId != null
                ? null
                : () => _change(
                    d.copyWith(
                      direction: d.direction == DebtEntryDirection.paid
                          ? DebtEntryDirection.received
                          : DebtEntryDirection.paid,
                    ),
                  ),
          ),
        );
      default:
        final category = context.watch<CategoriesCubit>().byId(
          d.category?.id ?? '',
        );
        final cat = CategoryPickCard(
          key: const ValueKey('ruleCategory'),
          category: category,
          label: l.recurringFieldCategory,
          placeholder: l.transactionFormCategoryNone,
          dense: true,
          editable: true,
          onTap: _pickCategory,
        );
        final source = d.paidBy != null
            ? PickCard(
                key: const ValueKey('rulePaidBy'),
                label: l.recurringSourcePaidBy,
                value: d.paidBy!.name,
                dense: true,
                editable: true,
                accent: Theme.of(context).colorScheme.primary,
                leading: PersonMark(
                  level: debtPersonLevel(d.paidBy!),
                  avatar: d.paidBy!.avatar,
                  size: 32,
                ),
                onTap: _pickPaidBy,
                trailing: PpForgeIconButton(
                  icon: AppIcons.close,
                  tooltip: l.commonRemove,
                  onPressed: () => _change(d.copyWith(clearPaidBy: true)),
                ),
              )
            : wallet(account, l.transactionFormAccountLabel);
        children.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cat),
                SizedBox(width: HeroMetrics.of(context).padding.left),
                Expanded(child: source),
              ],
            ),
          ),
        );
        if (d.type == RecurringKind.expense && d.paidBy == null) {
          children.add(
            Align(
              alignment: Alignment.centerRight,
              child: PpForgeButton(
                key: const ValueKey('rulePickPaidBy'),
                label: l.recurringSourcePaidBy,
                variant: PpForgeButtonVariant.text,
                size: PpForgeButtonSize.chip,
                onPressed: _pickPaidBy,
              ),
            ),
          );
        }
    }
    if (d.type != RecurringKind.saving && d.type != RecurringKind.debt) {
      children.add(
        TagChipRow(
          key: const ValueKey('ruleTags'),
          selected: {for (final t in d.tags) t.id},
          onRemove: (id) => _change(
            d.copyWith(
              tags: [
                for (final t in d.tags)
                  if (t.id != id) t,
              ],
            ),
          ),
          onMore: _pickTags,
        ),
      );
    }
    return EntrySectionCard(children: children);
  }

  /// ช่วงเวลา: เริ่ม / ทำซ้ำ (its chip + the end chip) and, with an end, the
  /// last round + count + total (mock RepeatRows).
  Widget _periodSection(AppLocalizations l, RuleDraft d) {
    final rule = d.rule;
    final dates = rule.freq == RecurrenceFreq.dates;
    final f = DateFormat.yMMMd(l.localeName);
    final end = rule.end;
    final endText = d.type == RecurringKind.saving && d.goal != null
        ? l.ruleEndGoal
        : d.type == RecurringKind.debt &&
              !d.debtRecord &&
              d.planId == null &&
              end.kind == RecurrenceEndKind.never
        ? l.ruleEndDebt
        : switch (end.kind) {
            RecurrenceEndKind.never => l.recurringEndNever,
            RecurrenceEndKind.afterCount => l.recurEndCount(end.count ?? 0),
            RecurrenceEndKind.onDate => l.recurEndUntil(f.format(end.date!)),
          };
    String? summary;
    if (dates) {
      summary = [
        for (final x in rule.dates) DateFormat.MMMd(l.localeName).format(x),
      ].join(', ');
    } else if (end.kind != RecurrenceEndKind.never) {
      final all = recurrenceDates(
        rule,
        until: DateTime(rule.start.year + 3, rule.start.month, rule.start.day),
      );
      if (all.isNotEmpty) {
        final amount = d.ask ? null : d.amount;
        summary = amount == null
            ? l.ruleEndSummary(f.format(all.last), all.length)
            : l.ruleEndSummaryTotal(
                f.format(all.last),
                all.length,
                moneyString(context, amount * all.length),
              );
      }
    }
    final card = SectionCard(
      first: true,
      title: l.ruleSectionPeriod,
      children: [
        if (!dates)
          PpForgeDetailRow(
            key: const ValueKey('ruleStart'),
            label: l.recurringFieldStart,
            trailing: Text(f.format(rule.start)),
            showChevron: true,
            onTap: _pickStart,
          ),
        PpForgeDetailRow.pick(
          key: const ValueKey('ruleRepeat'),
          label: l.recurringFieldRepeat,
          valueChips: [
            PpForgeChip(
              label: recurrenceLabel(l, rule, compact: true),
              icon: AppIcons.recurring,
              tone: PpForgeChipTone.primary,
              size: ChipSize.chip,
            ),
            if (!dates) PpForgeChip(label: endText, size: ChipSize.chip),
          ],
          emptyText: '',
          onTap: _openRepeat,
        ),
      ],
    );
    if (summary == null) return card;
    // the line under the card: the last round, how many, the total
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PpForgeSpacing.xs,
            PpForgeSpacing.xs,
            PpForgeSpacing.xs,
            0,
          ),
          child: PpForgeText(
            summary,
            key: const ValueKey('rulePeriodSummary'),
            role: PpForgeTextRole.caption,
          ),
        ),
      ],
    );
  }

  /// ถึงงวด: แจ้งเตือน / ยืนยันอัตโนมัติ. Without a switch of its own a rule
  /// shows the user's default; ใส่ทุกงวด never confirms by itself.
  Widget _dueSection(AppLocalizations l, RuleDraft d) {
    final notifyOn = d.notify ?? _line?.notifyOn ?? true;
    final asked = d.ask && d.canAsk;
    final autoOn = !asked && (d.autoAccept ?? _line?.autoAcceptOn ?? false);
    return SectionCard(
      first: true,
      title: l.ruleSectionDue,
      children: [
        SettingToggleRow(
          key: const ValueKey('ruleNotify'),
          label: l.ruleNotify,
          value: notifyOn,
          submits: false,
          onChanged: (v) => _change(d.copyWith(notify: v)),
        ),
        SettingToggleRow(
          key: const ValueKey('ruleAutoAccept'),
          label: l.ruleAutoAccept,
          caption: l.ruleAutoAcceptAskOff,
          value: autoOn,
          submits: false,
          onChanged: asked ? null : (v) => _change(d.copyWith(autoAccept: v)),
        ),
      ],
    );
  }
}

/// A draft rule the create page should drop (ลบ rule on an unsaved draft).
class _Deleted {
  const _Deleted();
}

/// What the rule page answers its opener with: the saved recurring, the
/// edited draft, or [ruleDraftDeleted].
bool isRuleDraftDeleted(Object? result) => result is _Deleted;
