import 'dart:convert';

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
import 'pick_chip_rows.dart';
import 'splits_section.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
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

  /// A save was tried with no payer — the payer card shows why.
  bool payerMissing = false;

  void flagMissingPayer() {
    payerMissing = true;
    notifyListeners();
  }

  void setPayer(String id) {
    payerId = id;
    payerMissing = false;
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

  /// The category last picked under each type — a category belongs to one
  /// type, so switching away and back restores it (owner 2026-10-10).
  final Map<TransactionType, Category?> _categoryByType = {};

  /// Switching type keeps everything else (amount, wallets, tags, splits —
  /// a transfer just doesn't send splits); only the category follows the
  /// type.
  void setType(TransactionType t) {
    if (t == type) return;
    _categoryByType[type] = category;
    type = t;
    category = _categoryByType[t];
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

  /// The tag picker's result — the whole selection at once.
  void setTagIds(Set<String> ids) {
    tagIds
      ..clear()
      ..addAll(ids);
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
    savedSplits
      ..clear()
      ..addAll({for (final s in t.splits) s.debtId: s});
    splits = [for (final s in t.splits) _fromSaved(s, s.amount)];
    _savedMyShare = t.myShare;
    _shareBasis = _shareKey();
    // An event bill: what the other members carry on the event row =
    // amount − my_share − my own splits (forgiven ones never came off).
    final mine = t.myShare;
    final myOwn = t.splits
        .where((s) => s.status != 'cancelled')
        .fold<double>(0, (a, s) => a + s.amount);
    eventOthers = mine == null || t.projectId == null
        ? 0
        : (t.amount - mine - myOwn).clamp(0, t.amount).toDouble();
    savedInEvent = t.projectId != null;
  }

  /// The saved row is an event bill (its splits sit on my share).
  bool savedInEvent = false;

  /// An event bill's other members' part (0 off an event, or without
  /// `my_share`). My own splits share only what's left: Σ ≤ amount − this
  /// (the BE says SPLITS_EXCEED_SHARE otherwise).
  double eventOthers = 0;

  /// What my own splits may add up to.
  double get splitCap => amountValue - eventOthers;

  /// The row's `my_share` as loaded (null: a transfer, or a BE that
  /// doesn't send it) and the amount + splits it was worked out from.
  double? _savedMyShare;
  String? _shareBasis;

  String _shareKey() => [
    amount.text,
    for (final s in splits) jsonEncode(s.toUpdateJson()),
  ].join('|');

  /// "ส่วนของคุณ" as the server counts it — only while the amount and the
  /// splits are as loaded; an unsaved change → null (work it out from the
  /// draft instead), back to the server's after the save reloads.
  double? get savedMyShare =>
      _savedMyShare != null && _shareKey() == _shareBasis
      ? _savedMyShare
      : null;

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
    splits = [
      for (final m in d.splits)
        switch (savedSplits[m['debt_id']]) {
          // Back to the saved debt, with the person as it was at that
          // step (an unlinked one may have been renamed / linked since).
          final saved? => _fromSaved(
            saved,
            (m['owed_amount'] as num?)?.toDouble(),
            name: m['person_name'] as String?,
            contact: m['contact_id'] as String?,
          ),
          null => SplitDraft(
            personName: m['person_name'] as String?,
            contactId: m['contact_id'] as String?,
            owedAmount: (m['owed_amount'] as num?)?.toDouble(),
          ),
        },
    ];
    notifyListeners();
  }

  /// A saved transaction's splits as loaded, by debt — what a restore or a
  /// save compares against.
  final Map<String, TxSplit> savedSplits = {};

  /// A saved split as a row: who it was saved with, then — when [name] is
  /// given and the row isn't locked — the person it has now.
  static SplitDraft _fromSaved(
    TxSplit s,
    double? owed, {
    String? name,
    String? contact,
  }) {
    final d = SplitDraft(
      debtId: s.debtId,
      personName: s.personName,
      contactId: s.contactId,
      owedAmount: owed,
      settledAmount: s.settledAmount,
      cancelled: s.status == 'cancelled',
    );
    if (name != null && !d.identityLocked) d.setPerson(name, contact: contact);
    return d;
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
/// focus node, if it's a text field) and [onEdit] adds the hero's ✏️. The
/// category / wallet cards open nothing there (owner 2026-10-10: a tap in
/// view mode never leaves the page).
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
    this.trailingRows = const [],
    this.sectioned = false,
    this.eventPending = false,
    this.event,
    this.schedule,
    this.heroKey,
    super.key,
  });

  /// Put on the [TxHeroCard] — the quick create watches where it scrolled
  /// to (its title row shows the amount once the card is out of view).
  final GlobalKey? heroKey;

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

  /// What the page adds after the form's own rows. [sectioned]: whole
  /// detail sections ([SectionCard]s — the split list, the event row);
  /// otherwise labelled rows.
  final List<Widget> trailingRows;

  /// The detail page's layout below the hero (owner 2026-10-10, rules
  /// #16 / #17): [SectionCard]s — แท็ก (row) + โน้ต (stacked) first, the
  /// split editor as its own "หารกับ" section, then [trailingRows].
  /// Off: the quick create's compact rows.
  final bool sectioned;

  /// An event is being picked / changed in this form (quick create with
  /// one chosen, the detail page moving the row into one): the splits go
  /// to the event's board with it — titled "หารในอีเวนต์". An event bill
  /// left where it is keeps "หารกับ", split from my share.
  final bool eventPending;

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

  /// The chip rows' orders, fixed for the form's life (one per type for
  /// categories) — see [ChipOrder].
  final _categoryOrders = <TransactionType, ChipOrder>{};
  final _tagOrder = ChipOrder();

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

  /// Tags "เพิ่มเติม": the full picker (search, "+ แท็กใหม่").
  Future<void> _moreTags() async {
    final next = await showTagPickerSheet(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next);
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

  /// A wallet card: the picker in edit mode, not tappable in view mode.
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
    return WalletPickCard(
      account: account,
      label: label,
      placeholder: placeholder,
      dense: true,
      onTap: widget.editing ? onPick : null,
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
    return CategoryPickCard(
      category: c,
      label: l.transactionFormCategoryLabel,
      placeholder: l.transactionFormCategoryNone,
      dense: true,
      onTap: widget.editing && widget.categoryLockedHint == null
          ? _pickCategory
          : null,
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
        heroKey: widget.heroKey,
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
        heroKey: widget.heroKey,
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
              key: widget.heroKey,
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
              inline: true,
              // View mode: the same category · wallet cards as editing, inside
              // the card (owner 2026-10-10); they open their pages.
              footer: editing
                  ? null
                  : longPressable(_cardsRow(l, isTransfer: isTransfer)),
              // "ส่วนของคุณ" under the total — while editing only where
              // splits can be edited; in view whenever the people loaded.
              amountNote: !isTransfer && (!editing || widget.allowSplits)
                  ? _ShareLine.of(_c)
                  : null,
            ),
            if (editing) ...[
              // 16 from the hero to the next block (HeroSpacing.after).
              const SizedBox(height: HeroSpacing.after),
              _cardsRow(l, isTransfer: isTransfer),
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
              // One tap on a recent category picks it (owner 2026-10-10).
              if (editing && !isTransfer && categoryHint == null) ...[
                const SizedBox(height: AppSpacing.sm),
                CategoryChipRow(
                  type: _c.type,
                  selected: _c.category,
                  onPick: _c.setCategory,
                  onMore: _pickCategory,
                  order: _categoryOrders.putIfAbsent(_c.type, ChipOrder.new),
                ),
              ],
              // Sectioned (the detail page): tags live in section 1.
              if (!widget.sectioned) ...[
                const SizedBox(height: AppSpacing.sm),
                TagChipRow(
                  selected: _c.tagIds,
                  onToggle: _c.toggleTag,
                  onMore: _moreTags,
                  known: _c.knownTags,
                  order: _tagOrder,
                ),
              ],
            ] else if (!widget.sectioned && _c.tagIds.isNotEmpty) ...[
              // Right under the card, as chips with their icons, led by the
              // tag icon like the edit row (owner 2026-10-10).
              const SizedBox(height: AppSpacing.md),
              longPressable(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        AppIcons.tag,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final id in _c.tagIds)
                            ?_tagChip(
                              context
                                      .read<TagsCubit>()
                                      .state
                                      .tags
                                      .where((t) => t.id == id)
                                      .firstOrNull ??
                                  _c.knownTags[id],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ...widget.sectioned
                ? _sections(
                    l,
                    editing: editing,
                    isTransfer: isTransfer,
                    longPressable: longPressable,
                  )
                : _detailRows(l, editing: editing, isTransfer: isTransfer),
          ],
        );
        if (!widget.readOnly) return form;
        return IgnorePointer(child: Opacity(opacity: 0.6, child: form));
      },
    );
  }

  Widget? _tagChip(Tag? tag) => tag == null ? null : TagChip(tag: tag);

  /// Category + wallet cards, one row — a transfer [จาก] → [ไป]. Editing:
  /// under the hero, tapping opens the pickers; view mode: inside the hero
  /// (its footer), tapping opens the category's / wallet's page.
  Widget _cardsRow(AppLocalizations l, {required bool isTransfer}) {
    final editing = widget.editing;
    if (isTransfer) {
      // One row, money flows left → right (owner 2026-10-10). The arrow
      // never turns: tapping it swaps the wallets instead.
      return IntrinsicHeight(
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
      );
    }
    // Picked → the card takes the category's / wallet's own colour; blank
    // (both optional) → dashed. Same height both.
    return IntrinsicHeight(
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
    );
  }

  /// [DraftForm.sectioned] — the detail page below the hero:
  ///
  ///   แท็ก            [#a] [#b] …      (section 1, a row)
  ///   โน้ต                               (label on top, full width)
  ///   ▬▬▬▬
  ///   หารกับ        [+ เพิ่มคน] [หารเท่ากัน]   (edit: the split editor)
  ///   …[DraftForm.trailingRows]: the page's sections (view splits, event)
  ///
  /// View mode shows only what has something in it.
  List<Widget> _sections(
    AppLocalizations l, {
    required bool editing,
    required bool isTransfer,
    required Widget Function(Widget) longPressable,
  }) {
    final enter = widget.onEnterEdit;
    final tagsCubit = context.read<TagsCubit>();
    final first = <Widget>[
      if (editing || _c.tagIds.isNotEmpty)
        longPressable(
          DetailRow(
            label: l.txDetailTags,
            trailing: editing
                ? TagChipRow(
                    selected: _c.tagIds,
                    onToggle: _c.toggleTag,
                    onMore: _moreTags,
                    known: _c.knownTags,
                    order: _tagOrder,
                    leadingIcon: false,
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final id in _c.tagIds)
                        ?_tagChip(
                          tagsCubit.state.tags
                                  .where((t) => t.id == id)
                                  .firstOrNull ??
                              _c.knownTags[id],
                        ),
                    ],
                  ),
          ),
        ),
      if (editing || _c.note.text.trim().isNotEmpty)
        DetailStacked(
          label: l.commonNote,
          child: InlineField(
            editing: editing,
            controller: _c.note,
            focusNode: _noteFocus,
            maxLines: 5,
            maxLength: TextLimits.note,
            hint: l.txNoteAddHint,
            onEnterEdit: enter == null ? null : () => enter(_noteFocus),
          ),
        ),
    ];
    return [
      const SizedBox(height: HeroSpacing.after),
      if (first.isNotEmpty) SectionCard(first: true, children: first),
      if (editing && widget.allowSplits && !isTransfer)
        SplitsSection(
          // Going into an event with the row: they'll be the event's. Else
          // expense: they owe me; income: I owe them (spec §12).
          label: widget.eventPending
              ? l.txSplitInEvent
              : _c.type == TransactionType.income
              ? l.txSplitShareShort
              : l.txSplitWith,
          helper: widget.eventPending
              ? l.txSplitInEventHelper
              // An event bill staying put: my splits sit on my share.
              : _c.savedInEvent
              ? l.txSplitFromMyShare
              : null,
          totalAmount: _c.splitCap,
          overText: _c.eventOthers > 0 ? l.txSplitExceedsShare : null,
          drafts: _c.splits,
          onChanged: _c.setSplits,
          sectioned: true,
        ),
      ...widget.trailingRows,
    ];
  }

  /// โน้ต · หารกับ · อีเวนต์ under a hairline — always open while editing
  /// (owner 2026-10-10), labels lined up on the left; view mode shows only
  /// the ones with something in them.
  List<Widget> _detailRows(
    AppLocalizations l, {
    required bool editing,
    required bool isTransfer,
  }) {
    final enter = widget.onEnterEdit;
    final note = InlineField(
      editing: editing,
      controller: _c.note,
      focusNode: _noteFocus,
      maxLines: 5,
      maxLength: TextLimits.note,
      hint: l.txNoteAddHint,
      onEnterEdit: enter == null ? null : () => enter(_noteFocus),
    );
    final rows = <Widget>[
      if (editing)
        // One line, grows while typing.
        DraftFieldRow(label: l.commonNote, child: note)
      else if (_c.note.text.trim().isNotEmpty)
        // View: label on top, the text full width under it — the wallet
        // page's note (owner 2026-10-10).
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.commonNote, style: detailLabelStyle(context)),
            const SizedBox(height: AppSpacing.xs),
            note,
          ],
        ),
      // Full width: its own header row carries the label and the pills.
      if (editing && widget.allowSplits && !isTransfer)
        SplitsSection(
          // Expense: they owe me; income: I owe them (spec §12).
          label: _c.type == TransactionType.income
              ? l.txSplitShareShort
              : l.txSplitWith,
          // An event bill: only my share is mine to split.
          totalAmount: _c.splitCap,
          overText: _c.eventOthers > 0 ? l.txSplitExceedsShare : null,
          drafts: _c.splits,
          onChanged: _c.setSplits,
        ),
      if (!isTransfer && widget.extra != null) widget.extra!,
      ...widget.trailingRows,
    ];
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.md),
      // View mode runs on under the tags, no rule (owner 2026-10-10).
      if (editing) const Divider(height: 1),
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: r,
        ),
    ];
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

/// A labelled text field under the hero of an event row / scheduled entry
/// (คำอธิบาย, โน้ต) — label on top, an [InlineField] box below.
class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.label,
    required this.controller,
    required this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
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
          editing: true,
          controller: controller,
          maxLength: maxLength,
          maxLines: 4,
        ),
      ],
    );
  }
}

/// A labelled row under the transaction form's cards — โน้ต, หารกับ,
/// อีเวนต์: the label in a fixed column on the left so the fields line up.
class DraftFieldRow extends StatelessWidget {
  const DraftFieldRow({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  static const labelWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            // Lines up with the first line of a field / button beside it.
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// "ส่วนของคุณ ฿x · คนอื่นติด ฿y" under the hero's amount once the row is
/// split — the key number (owner 2026-10-10; reports count it). Income
/// splits are what I pass on: "· ของคนอื่น ฿y". Split past the total → my
/// share goes negative, in the error colour.
///
/// x = the server's `my_share` while the form is as loaded (it also knows
/// an event share), y = amount − x; with unsaved split / amount changes
/// (or a BE without it) both are worked out from the draft.
class _ShareLine extends StatelessWidget {
  const _ShareLine({
    required this.type,
    required this.total,
    required this.others,
  });

  final TransactionType type;
  final double total;
  final double others;

  /// Null while it's all mine.
  static Widget? of(DraftFormController c) {
    final mine = c.savedMyShare;
    final others = mine != null
        ? c.amountValue - mine
        : c.eventOthers +
              c.splits.fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (others <= 0.005) return null;
    return _ShareLine(type: c.type, total: c.amountValue, others: others);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mine = total - others;
    final over = mine < -0.005;
    final othersText = moneyString(context, others);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          l.txShareMine,
          style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.xs),
        MoneyText(
          mine,
          hideable: false,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: over ? scheme.error : txTypeColor(context, type),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '· ${type == TransactionType.income ? l.txShareOthers(othersText) : l.txShareOthersOwe(othersText)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
