import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
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
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
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
import 'tx_hero_card.dart';

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

  /// What it was for — the record's title (the hero's big line). A
  /// project row's คำอธิบาย too.
  final description = TextEditingController();

  // ── Event mode (a project row) ──
  /// The project member who paid / received.
  String? payerId;

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

  /// A saved row's category / wallet that isn't in this user's lists
  /// (another member's, on a shared wallet) — shown by name, not editable.
  String? foreignCategoryName;
  String? foreignAccountName;

  /// A saved row's tags, for ones missing from this user's list.
  final Map<String, Tag> knownTags = {};

  bool get isTransfer => type == TransactionType.transfer;
  double get amountValue => AmountField.parse(amount.text) ?? 0;

  /// Anything beyond the basics: tags, splits, project tags / splits.
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
    description.text = d.description ?? '';
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
    description.text = t.description ?? '';
    note.text = t.note ?? '';
    date = DateTime.tryParse(t.date) ?? date;
    accountTouched = true;
    account = accounts.where((x) => x.id == t.accountId).firstOrNull;
    this.toAccount = toAccount;
    category = categories.where((c) => c.id == t.categoryId).firstOrNull;
    foreignAccountName = account == null ? t.account?.name : null;
    foreignCategoryName = category == null && !isTransfer
        ? t.category?.name
        : null;
    tagIds.addAll(t.tags.map((x) => x.id));
    knownTags.addAll({for (final x in t.tags) x.id: x.asTag});
  }

  /// Puts a saved transaction's fields back as [d] (undo / cancel on the
  /// detail page). Text controllers each notify; a caller listening for
  /// edits should ignore changes while this runs.
  void restoreTransaction(
    PendingDraft d, {
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    type = d.type ?? type;
    final a = d.amount;
    amount.text = a == null ? '' : AmountField.format(a);
    description.text = d.description ?? '';
    note.text = d.note ?? '';
    date = DateTime.tryParse(d.date ?? '') ?? date;
    account = accounts.where((x) => x.id == d.accountId).firstOrNull;
    toAccount = accounts
        .where((x) => x.id == d.transferToAccountId)
        .firstOrNull;
    category = categories.where((c) => c.id == d.categoryId).firstOrNull;
    tagIds
      ..clear()
      ..addAll(d.tagIds);
    notifyListeners();
  }

  /// The fields as a draft — no validation, anything may be empty.
  PendingDraft toDraft() {
    final d = description.text.trim();
    final n = note.text.trim();
    return PendingDraft(
      type: type,
      amount: AmountField.parse(amount.text),
      accountId: account?.id,
      categoryId: isTransfer ? null : category?.id,
      date: _ymd(date),
      description: d.isEmpty ? null : d,
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

/// "วันนี้" / "เมื่อวาน" / a short date.
String _dayLabel(BuildContext context, DateTime d) {
  final l = AppLocalizations.of(context)!;
  return DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );
}

/// One transaction's fields — the single form behind the `+` quick create,
/// "แก้ร่าง", every row of "เพิ่มร่าง" and the transaction detail page
/// (owner design 2026-10-10). Everything shows at once, no "more" toggle:
///
///   [TxHeroCard]: type chips · amount · ค่าอะไร (description) · date
///   โน้ต
///   category + wallet cards (a transfer: [จาก] → [ไป])
///   tags · หารกับ… · [extra]
///
/// Editing a saved transaction: [typeLocked] (the API can't change it),
/// [allowSplits] false (splits are set at create only), [categoryLockedHint]
/// on another member's row (only the author picks its category), and
/// [readOnly] on an ex-member's locked row.
///
/// [editing] false = the detail page's view mode: the same layout, nothing
/// editable. A long-press on a field calls [onEnterEdit] (with the field's
/// focus node, if it's a text field), [onEdit] adds the hero's ✏️, and the
/// category / wallet cards open their pages ([onOpenCategory] /
/// [onOpenAccount]).
class DraftForm extends StatefulWidget {
  const DraftForm({
    required this.controller,
    this.compact = false,
    this.autofocus = true,
    this.defaultAccount,
    this.extra,
    this.typeLocked = false,
    this.allowSplits = true,
    this.categoryLockedHint,
    this.readOnly = false,
    this.editing = true,
    this.onEnterEdit,
    this.onEdit,
    this.onOpenCategory,
    this.onOpenAccount,
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

  /// Everything shown, nothing editable (dimmed).
  final bool readOnly;

  /// False = view mode (the detail page outside edit mode).
  final bool editing;

  /// View mode: long-press on a field → enter edit, focusing that field.
  final ValueChanged<FocusNode?>? onEnterEdit;

  /// View mode: the hero's ✏️.
  final VoidCallback? onEdit;

  /// View mode: tapping the category / wallet card.
  final ValueChanged<Category>? onOpenCategory;
  final ValueChanged<Account>? onOpenAccount;

  final DraftFormController controller;

  /// Smaller amount — for several forms on one page.
  final bool compact;
  final bool autofocus;

  /// Wallet shown until the user picks one.
  final Account? defaultAccount;

  /// Extra tile at the bottom (the quick create's "เพิ่มเข้าอีเวนต์").
  final Widget? extra;

  @override
  State<DraftForm> createState() => _DraftFormState();
}

class _DraftFormState extends State<DraftForm> {
  final _amountFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  DraftFormController get _c => widget.controller;

  @override
  void dispose() {
    _amountFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: _c.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: _c.category,
      allowCreate: true,
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
      allowCreate: true,
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

  /// A wallet card: picker in edit mode, the wallet's page in view mode.
  /// One that isn't in this user's list (someone else's, on a shared
  /// wallet) still shows its name, just not tappable.
  Widget _walletCard({
    required Account? account,
    required String label,
    required String placeholder,
    required VoidCallback onPick,
    String? foreignName,
  }) {
    if (account == null && foreignName != null) {
      return PickCard(
        label: label,
        value: foreignName,
        leading: const PickCardEmptyIcon(AppIcons.bank, size: 32),
        dense: true,
        onTap: null,
      );
    }
    final open = widget.onOpenAccount;
    return WalletPickCard(
      account: account,
      label: label,
      placeholder: placeholder,
      dense: true,
      onTap: widget.editing
          ? onPick
          : (account == null || open == null ? null : () => open(account)),
    );
  }

  Widget _categoryCard(AppLocalizations l) {
    final c = _c.category;
    final foreign = _c.foreignCategoryName;
    if (c == null && foreign != null) {
      return PickCard(
        label: l.transactionFormCategoryLabel,
        value: foreign,
        leading: const PickCardEmptyIcon(AppIcons.category, size: 32),
        dense: true,
        onTap: null,
      );
    }
    final open = widget.onOpenCategory;
    return CategoryPickCard(
      category: c,
      label: l.transactionFormCategoryLabel,
      placeholder: l.transactionFormCategoryNone,
      dense: true,
      onTap: widget.editing
          ? (widget.categoryLockedHint == null ? _pickCategory : null)
          : (c == null || c.isSystem || open == null ? null : () => open(c)),
    );
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

    final editing = widget.editing;
    final enterEdit = widget.onEnterEdit;
    // View mode: a long-press anywhere on the cards enters edit mode too.
    Widget longPressable(Widget child) => editing || enterEdit == null
        ? child
        : GestureDetector(onLongPress: () => enterEdit(null), child: child);

    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final isTransfer = _c.isTransfer;
        final categoryHint = widget.categoryLockedHint;
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TxHeroCard(
              type: _c.type,
              onTypeChanged: widget.typeLocked ? null : _c.setType,
              amount: _c.amount,
              title: _c.description,
              dateLabel: _dayLabel(context, _c.date),
              onPickDate: _pickDate,
              editing: editing,
              autofocus: widget.autofocus && !widget.readOnly,
              compact: widget.compact,
              amountFocus: _amountFocus,
              titleFocus: _descriptionFocus,
              onEdit: widget.onEdit,
              onLongPressField: enterEdit,
            ),
            // View mode: an empty note only shows when it can be filled in.
            if (editing || enterEdit != null || _c.note.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _TextBlock(
                label: l.commonNote,
                controller: _c.note,
                maxLength: TextLimits.note,
                editing: editing,
                focusNode: _noteFocus,
                onEnterEdit: enterEdit,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (isTransfer)
              // One row, money flows left → right (owner 2026-10-10). The
              // arrow never turns: tapping it swaps the wallets instead.
              longPressable(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _walletCard(
                          account: _c.account,
                          label: l.quickFrom,
                          placeholder: l.quickPickWallet,
                          onPick: () => _pickAccount(),
                          foreignName: _c.foreignAccountName,
                        ),
                      ),
                      IconButton(
                        tooltip: editing ? l.quickSwap : null,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32),
                        icon: const Icon(AppIcons.arrowForward),
                        onPressed: editing ? _c.swapAccounts : null,
                      ),
                      Expanded(
                        child: _walletCard(
                          account: _c.toAccount,
                          label: l.quickTo,
                          placeholder: l.quickPickWallet,
                          onPick: () => _pickAccount(to: true),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Picked → the card takes the category's / wallet's own
              // colour; blank (both optional) → dashed. Same height both.
              longPressable(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _categoryCard(l)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _walletCard(
                          account: _c.account,
                          label: l.transactionFormAccountLabel,
                          placeholder: l.transactionFormAccountNone,
                          onPick: () => _pickAccount(),
                          foreignName: _c.foreignAccountName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (editing && !isTransfer && categoryHint != null)
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
            // View mode shows only the row's own tags — none, no block.
            if (editing || _c.tagIds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              longPressable(
                _TagsBlock(
                  selected: _c.tagIds,
                  onToggle: _c.toggleTag,
                  editing: editing,
                  known: _c.knownTags,
                ),
              ),
            ],
            if (!isTransfer) ...[
              if (editing && widget.allowSplits) ...[
                const SizedBox(height: AppSpacing.md),
                SplitsSection(
                  totalAmount: _c.amountValue,
                  drafts: _c.splits,
                  onChanged: _c.setSplits,
                  title: _c.type == TransactionType.income
                      ? l.transactionSplitShareTitle
                      : l.transactionSplitWithTitle,
                ),
              ],
              if (widget.extra != null) ...[
                const SizedBox(height: AppSpacing.sm),
                widget.extra!,
              ],
            ],
          ],
        );
        if (!widget.readOnly) return form;
        return IgnorePointer(child: Opacity(opacity: 0.6, child: form));
      },
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

/// A labelled text field under the hero — โน้ต, a scheduled entry's
/// คำอธิบาย. The same box in view and edit mode ([InlineField]); in view
/// mode a long-press calls [onEnterEdit] with this field's focus node.
class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.label,
    required this.controller,
    required this.maxLength,
    this.editing = true,
    this.focusNode,
    this.onEnterEdit,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final bool editing;
  final FocusNode? focusNode;
  final ValueChanged<FocusNode?>? onEnterEdit;

  @override
  Widget build(BuildContext context) {
    final enter = onEnterEdit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InlineField(
          editing: editing,
          controller: controller,
          focusNode: focusNode,
          maxLength: maxLength,
          maxLines: 4,
          onEnterEdit: enter == null ? null : () => enter(focusNode),
        ),
      ],
    );
  }
}

/// Tags: every tag as a toggle chip while editing; view mode shows only
/// the picked ones. [known] resolves picked tags that aren't in this
/// user's list (another member's, on a shared wallet).
class _TagsBlock extends StatelessWidget {
  const _TagsBlock({
    required this.selected,
    required this.onToggle,
    this.editing = true,
    this.known = const {},
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool editing;
  final Map<String, Tag> known;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mine = context.watch<TagsCubit>().state.tags;
    final List<Tag> tags = editing
        ? mine
        : [
            for (final id in selected)
              ?(mine.where((t) => t.id == id).firstOrNull ?? known[id]),
          ];
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
                TagChip(
                  tag: t,
                  selected: editing ? selected.contains(t.id) : null,
                  onTap: editing ? () => onToggle(t.id) : null,
                ),
            ],
          ),
      ],
    );
  }
}
