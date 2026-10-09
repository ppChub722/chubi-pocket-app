import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_pick_card.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/widgets/member_pick_card.dart';
import '../../../projects/presentation/widgets/project_common.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_maker_sheet.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../scheduled_transactions/domain/scheduled_enums.dart';
import '../../../scheduled_transactions/domain/scheduled_transaction.dart';
import 'account_picker_sheet.dart';
import 'splits_section.dart';

part 'draft_form_event.dart';
part 'draft_form_scheduled.dart';

/// The fields of one transaction draft — owned by whoever shows a
/// [DraftForm] (the `+` quick create sheet, one row of "เพิ่มร่าง"), so the
/// owner can read them back ([toDraft]) and listen for changes.
class DraftFormController extends ChangeNotifier {
  DraftFormController() {
    amount.addListener(notifyListeners);
    note.addListener(notifyListeners);
    description.addListener(notifyListeners);
    schedule.addListener(notifyListeners);
  }

  final amount = TextEditingController();
  final note = TextEditingController();

  /// Scheduled mode (a recurring template) — see draft_form_scheduled.dart.
  final schedule = ScheduleFields();

  // ── Event mode (a project row) ──
  /// The project member who paid / received.
  String? payerId;
  final description = TextEditingController();

  /// The row's project tags (names).
  final List<String> tagNames = [];
  final List<MemberSplitDraft> memberSplits = [];

  double get memberSplitSum =>
      memberSplits.fold(0, (a, s) => a + s.amountValue);

  void setPayer(String id) {
    payerId = id;
    // The payer can't also owe themself.
    for (final s in memberSplits.where((s) => s.memberId == id).toList()) {
      _dropSplit(s);
    }
    notifyListeners();
  }

  void toggleTagName(String name) {
    final i = tagNames.indexWhere((t) => t.toLowerCase() == name.toLowerCase());
    if (i >= 0) {
      tagNames.removeAt(i);
    } else {
      tagNames.add(name);
    }
    notifyListeners();
  }

  void addMemberSplit(String? memberId, {double? amount}) {
    final s = MemberSplitDraft(memberId);
    if (amount != null) s.amount.text = AmountField.format(amount);
    s.amount.addListener(notifyListeners);
    memberSplits.add(s);
    notifyListeners();
  }

  void setSplitMember(MemberSplitDraft s, String memberId) {
    s.memberId = memberId;
    notifyListeners();
  }

  void removeMemberSplit(MemberSplitDraft s) {
    _dropSplit(s);
    notifyListeners();
  }

  /// Everyone but the payer gets total / headcount (payer counted in).
  void splitEqually(List<String> memberIds) {
    final others = memberIds.where((id) => id != payerId).toList();
    if (amountValue <= 0 || others.isEmpty) return;
    final share =
        (amountValue / (others.length + 1) * 100).floorToDouble() / 100;
    for (final s in memberSplits.toList()) {
      _dropSplit(s);
    }
    for (final id in others) {
      addMemberSplit(id, amount: share);
    }
  }

  void _dropSplit(MemberSplitDraft s) {
    memberSplits.remove(s);
    // Its field may still be on screen this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => s.amount.dispose());
  }

  /// Loads a saved project row (+ its split children) for editing.
  void prefillProjectRow(ProjectTxTree tree) {
    final p = tree.parent;
    type = p.type == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    amount.text = AmountField.format(p.amount);
    date = DateTime.tryParse(p.date) ?? date;
    payerId = p.transactionMemberId;
    description.text = p.description ?? '';
    note.text = p.note ?? '';
    tagNames.addAll(p.tags);
    for (final c in tree.children) {
      addMemberSplit(c.transactionMemberId, amount: c.amount);
    }
  }

  /// The event fields as a comparable snapshot (the close guard).
  String eventSnapshot() => [
    type.name,
    amount.text,
    _ymd(date),
    payerId,
    description.text.trim(),
    note.text.trim(),
    tagNames.join('\u0000'),
    for (final s in memberSplits) '${s.memberId}=${s.amount.text}',
  ].join('|');

  TransactionType type = TransactionType.expense;
  Category? category;
  Account? account;
  Account? toAccount;
  bool accountTouched = false;
  DateTime date = DateTime.now();
  final Set<String> tagIds = {};
  List<SplitDraft> splits = const [];

  bool get isTransfer => type == TransactionType.transfer;
  double get amountValue => AmountField.parse(amount.text) ?? 0;

  /// Anything in the "more" section — it opens by itself when there is.
  bool get hasExtras =>
      tagIds.isNotEmpty ||
      splits.any((s) => s.isComplete) ||
      tagNames.isNotEmpty ||
      memberSplits.isNotEmpty;

  /// Anything typed or picked beyond the defaults.
  bool get hasContent =>
      amount.text.isNotEmpty ||
      note.text.trim().isNotEmpty ||
      description.text.trim().isNotEmpty ||
      hasExtras;

  void setType(TransactionType t) {
    type = t;
    category = null; // a category belongs to one type
    if (t == TransactionType.transfer) splits = const [];
    notifyListeners();
  }

  void setCategory(Category? c) {
    category = c;
    notifyListeners();
  }

  void setAccount(Account? a) {
    accountTouched = true;
    account = a;
    notifyListeners();
  }

  void setToAccount(Account a) {
    toAccount = a;
    notifyListeners();
  }

  void swapAccounts() {
    final f = account;
    account = toAccount;
    toAccount = f;
    accountTouched = true;
    notifyListeners();
  }

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }

  void toggleTag(String id) {
    if (!tagIds.remove(id)) tagIds.add(id);
    notifyListeners();
  }

  void setSplits(List<SplitDraft> s) {
    splits = s;
    notifyListeners();
  }

  /// The wallet to show until the user picks one — silent (no notify), it's
  /// called from build.
  void applyDefaultAccount(Account? a) {
    if (!accountTouched) account = a;
  }

  /// Loads a pending draft into the fields (wallet "none" stays none).
  void prefill(
    PendingDraft d, {
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    type = d.type ?? TransactionType.expense;
    final a = d.amount;
    if (a != null && a > 0) amount.text = AmountField.format(a);
    note.text = d.note ?? '';
    date = DateTime.tryParse(d.date ?? '') ?? date;
    accountTouched = true;
    account = accounts.where((x) => x.id == d.accountId).firstOrNull;
    toAccount = accounts
        .where((x) => x.id == d.transferToAccountId)
        .firstOrNull;
    category = categories.where((c) => c.id == d.categoryId).firstOrNull;
    tagIds.addAll(d.tagIds);
    splits = [
      for (final s in d.splits)
        SplitDraft(
          personName: s['person_name'] as String?,
          contactId: s['contact_id'] as String?,
          owedAmount: (s['owed_amount'] as num?)?.toDouble(),
        ),
    ];
  }

  /// Loads a saved transaction for editing. [toAccount] is the other side
  /// of a transfer (the caller finds it — it's a sibling row).
  void prefillTransaction(
    Transaction t, {
    required List<Account> accounts,
    required List<Category> categories,
    Account? toAccount,
  }) {
    type = t.type;
    amount.text = AmountField.format(t.amount);
    note.text = t.note ?? '';
    date = DateTime.tryParse(t.date) ?? date;
    accountTouched = true;
    account = accounts.where((x) => x.id == t.accountId).firstOrNull;
    this.toAccount = toAccount;
    category = categories.where((c) => c.id == t.categoryId).firstOrNull;
    tagIds.addAll(t.tags.map((x) => x.id));
  }

  /// The fields as a draft — no validation, anything may be empty.
  PendingDraft toDraft() {
    final n = note.text.trim();
    return PendingDraft(
      type: type,
      amount: AmountField.parse(amount.text),
      accountId: account?.id,
      categoryId: isTransfer ? null : category?.id,
      date: _ymd(date),
      note: n.isEmpty ? null : n,
      transferToAccountId: isTransfer ? toAccount?.id : null,
      tagIds: tagIds.toList(),
      splits: isTransfer
          ? const []
          : [for (final s in splits.where((s) => s.isComplete)) s.toJson()],
    );
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    description.dispose();
    schedule.dispose();
    for (final s in memberSplits) {
      s.amount.dispose();
    }
    super.dispose();
  }
}

/// One "หารกับ" row of a project row: a member and what they owe the payer.
class MemberSplitDraft {
  MemberSplitDraft(this.memberId);
  String? memberId;
  final amount = TextEditingController();
  double get amountValue => AmountField.parse(amount.text) ?? 0;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// One transaction's fields — the single form behind the `+` quick create,
/// "แก้ร่าง" and every row of "เพิ่มร่าง":
///
///   type · amount · category + wallet cards · date + note
///   ▸ รายละเอียดเพิ่ม (closed by default; opens by itself if it has
///     something): tags · split · [moreExtra]
///
/// Transfers swap the two cards for source → destination.
///
/// Editing a saved transaction: [typeLocked] (the API can't change it),
/// [allowSplits] false (splits are set at create only), [categoryLockedHint]
/// on another member's row (only the author picks its category), and
/// [readOnly] on an ex-member's locked row.
class DraftForm extends StatefulWidget {
  const DraftForm({
    required this.controller,
    this.compact = false,
    this.autofocus = true,
    this.defaultAccount,
    this.moreExtra,
    this.typeLocked = false,
    this.allowSplits = true,
    this.categoryLockedHint,
    this.readOnly = false,
    this.event,
    this.schedule,
    super.key,
  });

  /// Non-null → event mode: the form is a project row (see [DraftEvent]).
  final DraftEvent? event;

  /// Non-null → scheduled mode: the form is a recurring template (see
  /// [DraftSchedule]); its fields are [DraftFormController.schedule].
  final DraftSchedule? schedule;

  final bool typeLocked;
  final bool allowSplits;

  /// Non-null → the category card can't be changed; this says why.
  final String? categoryLockedHint;

  /// Everything shown, nothing editable.
  final bool readOnly;

  final DraftFormController controller;

  /// Smaller amount — for several forms on one page.
  final bool compact;
  final bool autofocus;

  /// Wallet shown until the user picks one.
  final Account? defaultAccount;

  /// Extra tile at the bottom of the "more" section (the quick create's
  /// "เพิ่มเข้าอีเวนต์").
  final Widget? moreExtra;

  @override
  State<DraftForm> createState() => _DraftFormState();
}

class _DraftFormState extends State<DraftForm> {
  late bool _moreOpen = widget.controller.hasExtras;

  DraftFormController get _c => widget.controller;

  Future<void> _pickCategory() async {
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: _c.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: _c.category,
    );
    if (!mounted || r == null) return;
    _c.setCategory(r is CategoryPickerSelected ? r.category : null);
  }

  Future<void> _pickAccount({bool to = false}) async {
    final l = AppLocalizations.of(context)!;
    final accounts = context.read<AccountsCubit>().state.accounts;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: to ? _c.toAccount : _c.account,
      excludeId: to
          ? _c.account?.id
          : (_c.isTransfer ? _c.toAccount?.id : null),
      title: to ? l.quickTo : l.transactionFormAccountLabel,
      // Expense / income may be floating; a transfer needs real wallets.
      allowNone: !_c.isTransfer && !to,
    );
    if (!mounted || r == null) return;
    if (to) {
      if (r is AccountPickerSelected) _c.setToAccount(r.account);
    } else {
      _c.setAccount(r is AccountPickerSelected ? r.account : null);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _c.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) _c.setDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final event = widget.event;
    if (event != null) {
      return _EventForm(
        controller: _c,
        event: event,
        compact: widget.compact,
        autofocus: widget.autofocus && !widget.readOnly,
        locked: widget.typeLocked,
        readOnly: widget.readOnly,
        moreOpen: _moreOpen,
        onToggleMore: () => setState(() => _moreOpen = !_moreOpen),
        onPickDate: _pickDate,
      );
    }
    final accounts = context.watch<AccountsCubit>().state.accounts;
    _c.applyDefaultAccount(widget.defaultAccount ?? accounts.firstOrNull);
    final schedule = widget.schedule;
    if (schedule != null) {
      return _ScheduledForm(
        controller: _c,
        schedule: schedule,
        compact: widget.compact,
        autofocus: widget.autofocus && !widget.readOnly,
      );
    }

    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final isTransfer = _c.isTransfer;
        final extras =
            _c.tagIds.length + _c.splits.where((s) => s.isComplete).length;
        final categoryHint = widget.categoryLockedHint;
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeSwitch(
              type: _c.type,
              onChanged: widget.typeLocked ? null : _c.setType,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AmountInput(
              controller: _c.amount,
              type: _c.type,
              compact: widget.compact,
              autofocus: widget.autofocus && !widget.readOnly,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isTransfer) ...[
              WalletPickCard(
                account: _c.account,
                label: l.quickFrom,
                placeholder: l.quickPickWallet,
                onTap: () => _pickAccount(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l.quickSwap,
                  icon: const Icon(AppIcons.transfer),
                  onPressed: _c.swapAccounts,
                ),
              ),
              WalletPickCard(
                account: _c.toAccount,
                label: l.quickTo,
                placeholder: l.quickPickWallet,
                onTap: () => _pickAccount(to: true),
              ),
            ] else
              // Picked → the card takes the category's / wallet's own
              // colour; blank (both optional) → dashed.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CategoryPickCard(
                      category: _c.category,
                      label: l.transactionFormCategoryLabel,
                      placeholder: l.transactionFormCategoryNone,
                      onTap: categoryHint == null ? _pickCategory : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: WalletPickCard(
                      account: _c.account,
                      label: l.transactionFormAccountLabel,
                      placeholder: l.transactionFormAccountNone,
                      onTap: () => _pickAccount(),
                    ),
                  ),
                ],
              ),
            if (!isTransfer && categoryHint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  0,
                ),
                child: Text(
                  categoryHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                SizedBox(
                  width: 132,
                  child: _Pill(
                    icon: AppIcons.date,
                    label: DateFormatter.friendly(
                      _c.date,
                      today: l.commonToday,
                      yesterday: l.commonYesterday,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _c.note,
                    maxLength: 500,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l.quickNoteHint,
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _MoreToggle(
              label: l.quickMore,
              open: _moreOpen,
              count: extras,
              onTap: () => setState(() => _moreOpen = !_moreOpen),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_moreOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TagsBlock(
                            selected: _c.tagIds,
                            onToggle: _c.toggleTag,
                          ),
                          if (!isTransfer) ...[
                            if (widget.allowSplits) ...[
                              const SizedBox(height: AppSpacing.sm),
                              SplitsSection(
                                totalAmount: _c.amountValue,
                                drafts: _c.splits,
                                onChanged: _c.setSplits,
                                title: _c.type == TransactionType.income
                                    ? l.transactionSplitShareTitle
                                    : l.transactionSplitWithTitle,
                              ),
                            ],
                            if (widget.moreExtra != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              widget.moreExtra!,
                            ],
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        );
        if (!widget.readOnly) return form;
        return IgnorePointer(child: Opacity(opacity: 0.6, child: form));
      },
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({
    required this.type,
    required this.onChanged,
    this.allowTransfer = true,
  });
  final TransactionType type;

  /// Null = locked (editing a saved transaction).
  final ValueChanged<TransactionType>? onChanged;

  /// False for project rows (expense | income only).
  final bool allowTransfer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<TransactionType>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text(l.transactionTypeExpense),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text(l.transactionTypeIncome),
        ),
        if (allowTransfer)
          ButtonSegment(
            value: TransactionType.transfer,
            label: Text(l.transactionTypeTransfer),
          ),
      ],
      selected: {type},
      onSelectionChanged: onChanged == null ? null : (s) => onChanged!(s.first),
    );
  }
}

Color _typeColor(BuildContext context, TransactionType t) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return switch (t) {
    TransactionType.expense => palette.expense,
    TransactionType.income => palette.income,
    TransactionType.transfer => Theme.of(context).colorScheme.onSurface,
  };
}

String _typeSign(TransactionType t) => switch (t) {
  TransactionType.expense => '−',
  TransactionType.income => '+',
  TransactionType.transfer => '',
};

/// The big centred amount — numeric keyboard, coloured by type.
class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.type,
    required this.compact,
    required this.autofocus,
    this.symbol = '฿',
  });
  final TextEditingController controller;
  final TransactionType type;
  final bool compact;
  final bool autofocus;

  /// Currency symbol (a project row uses the project's currency).
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _typeColor(context, type);
    final base = compact
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.displaySmall;
    final big = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [ThousandsInputFormatter()],
      style: big,
      cursorColor: Theme.of(context).colorScheme.primary,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: '0',
        hintStyle: big?.copyWith(color: color.withValues(alpha: 0.35)),
        prefixText: '${_typeSign(type)}$symbol ',
        prefixStyle: big?.copyWith(fontSize: (big.fontSize ?? 36) * 0.6),
        semanticCounterText: l.transactionFormAmountLabel,
      ),
    );
  }
}

/// A compact tappable field: icon · value · ▾.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// [label] is a placeholder (nothing picked yet).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: muted ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "รายละเอียดเพิ่ม ▾" — opens / closes the extra fields (pushes what's
/// below it down). [count] = how many extras are filled, shown while closed.
class _MoreToggle extends StatelessWidget {
  const _MoreToggle({
    required this.label,
    required this.open,
    required this.count,
    required this.onTap,
  });
  final String label;
  final bool open;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!open && count > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Badge(label: Text('$count')),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(AppIcons.expand, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tags = context.watch<TagsCubit>().state.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.tag, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l.transactionFormTagsLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (tags.isEmpty)
          Text(
            l.transactionFormTagsEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in tags)
                FilterChip(
                  label: Text('#${t.name}'),
                  selected: selected.contains(t.id),
                  showCheckmark: false,
                  onSelected: (_) => onToggle(t.id),
                ),
            ],
          ),
      ],
    );
  }
}
