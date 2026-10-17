import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/category_label.dart';
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
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'account_picker_sheet.dart';
import 'event_pick.dart';
import 'pick_chip_rows.dart';
import 'splits_section.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';

part 'draft_form_event.dart';

/// The fields of one transaction draft — owned by whoever shows a
/// [DraftForm] (the `+` quick create sheet, one row of "เพิ่มร่าง"), so the
/// owner can read them back ([toDraft]) and listen for changes.
class DraftFormController extends ChangeNotifier {
  DraftFormController() {
    amount.addListener(notifyListeners);
    note.addListener(notifyListeners);
    description.addListener(notifyListeners);
  }

  final amount = TextEditingController();
  final note = TextEditingController();

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
    if (amount != null) s.amount.text = AmountInput.format(amount);
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
    amount.text = AmountInput.format(p.amount);
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

  /// A draft's event (`project_id`): an existing event the draft joins when
  /// it's confirmed. [projectName] is what to show until the events load.
  String? projectId;
  String? projectName;

  void setProject(String? id, {String? name}) {
    projectId = id;
    projectName = id == null ? null : name;
    notifyListeners();
  }

  bool get isTransfer => type == TransactionType.transfer;
  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  /// Anything beyond the basics: tags, splits, project tags / splits.
  bool get hasExtras =>
      tagIds.isNotEmpty ||
      projectId != null ||
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

  /// "ฉัน" in the split editor (owner 2026-10-11) — my own share. Once
  /// anyone is in the split, ฉัน + the people must equal [splitCap] to save
  /// ([splitsBalanced]).
  ///
  /// [meAuto] (the "อัตโนมัติ" chip, on by default): ฉัน is what's left
  /// ([splitCap] − the people, never below 0 — past that it's "แบ่งเกิน"),
  /// live as the others change. Typing an amount ([setMeAmount]) turns it
  /// off; the chip ([setMeAuto]) turns it back on and re-fills ฉัน. Null =
  /// no ฉัน (nobody to split with), or typed empty (counts as 0).
  double? get meAmount {
    if (splits.isEmpty) return null;
    if (!meAuto) return _meTyped;
    final left = splitLeft(splitCap, 0, splits);
    return left < 0 ? 0 : left;
  }

  bool meAuto = true;
  double? _meTyped;

  /// ฉัน typed by hand — auto goes off.
  void setMeAmount(double? v) {
    _meTyped = v;
    meAuto = false;
    notifyListeners();
  }

  /// The chip: on = what's left from now on; off = keep the number shown,
  /// as typed.
  void setMeAuto(bool on) {
    if (!on) _meTyped = meAmount;
    meAuto = on;
    notifyListeners();
  }

  /// [splitCap] − (ฉัน + the people's amounts): what's still to split.
  double get splitLeftover => splitLeft(splitCap, meAmount, splits);

  /// Nobody to split with, or it adds up exactly.
  bool get splitsBalanced => splits.isEmpty || splitLeftover.abs() <= 0.005;

  /// A fresh form (create, a loaded row, a restore): ฉัน on auto — a loaded
  /// row comes out balanced, as it was saved.
  void _seedMe() {
    meAuto = true;
    _meTyped = null;
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
    if (a != null && a > 0) amount.text = AmountInput.format(a);
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
    projectId = d.projectId;
    splits = [
      for (final s in d.splits)
        SplitDraft(
          personName: s['person_name'] as String?,
          contactId: s['contact_id'] as String?,
          owedAmount: (s['owed_amount'] as num?)?.toDouble(),
        ),
    ];
    _seedMe();
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
    amount.text = AmountInput.format(t.amount);
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
    _seedMe();
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
    amount.text = a == null ? '' : AmountInput.format(a);
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
    // Back to a saved state — balanced, as it was.
    _seedMe();
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
      savedPerson: s.person,
    );
    if (name != null) d.setPerson(name, contact: contact);
    return d;
  }

  /// The fields as a draft — no validation, anything may be empty.
  /// [keepIncomplete] (a draft saved for later): half-filled split rows —
  /// a name without an amount or the other way round — stay in it for
  /// finishing later; otherwise only complete rows go.
  PendingDraft toDraft({bool keepIncomplete = false}) {
    final d = description.text.trim();
    final n = note.text.trim();
    return PendingDraft(
      type: type,
      amount: AmountInput.parse(amount.text),
      accountId: account?.id,
      categoryId: isTransfer ? null : category?.id,
      date: _ymd(date),
      description: d.isEmpty ? null : d,
      note: n.isEmpty ? null : n,
      transferToAccountId: isTransfer ? toAccount?.id : null,
      tagIds: tagIds.toList(),
      splits: isTransfer
          ? const []
          : [
              for (final s in splits.where(
                (s) =>
                    s.isComplete ||
                    (keepIncomplete &&
                        (s.personName.trim().isNotEmpty ||
                            (s.owedAmount ?? 0) > 0)),
              ))
                s.toJson(),
            ],
      projectId: isTransfer ? null : projectId,
    );
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    description.dispose();
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
  double get amountValue => AmountInput.parse(amount.text) ?? 0;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "วันนี้" / "เมื่อวาน" / a short date.
/// Whether [d] (a day) is after today, on this device's calendar.
bool isAfterToday(DateTime d) {
  final now = DateTime.now();
  return DateTime(
    d.year,
    d.month,
    d.day,
  ).isAfter(DateTime(now.year, now.month, now.day));
}

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
    this.upcomingHint = false,
    this.onUpcomingHintTap,
    this.categoryLockedHint,
    this.readOnly = false,
    this.editing = true,
    this.onEnterEdit,
    this.onEdit,
    this.eventPending = false,
    this.eventSlot,
    this.recurringSlot,
    this.splitsReadOnly,
    this.splitsCollapsible = false,
    this.splitsInitiallyOpen = true,
    this.event,
    this.heroKey,
    this.chipLayout = false,
    this.cardsInHero = false,
    this.chipRows = false,
    this.missing = const {},
    super.key,
  });

  /// The pending drafts' layout (owner 2026-10-11, "เพิ่มร่าง" rows and
  /// "แก้ร่าง"): no category / wallet cards — a wallet chip row above a
  /// category chip row, each led by a dashed "เลือก…" chip for the full
  /// picker — then tags, the inline note, and a collapsible "หารกับ /
  /// อีเวนต์" section (an event is an existing one, `project_id`).
  final bool chipLayout;

  /// The transaction detail's layout (owner 2026-10-12): the big wallet ·
  /// category pick cards sit INSIDE the hero card (its footer), no category
  /// chip row below; the tag row stays outside the hero. Off = the cards
  /// under the hero (quick create, on hold).
  final bool cardsInHero;

  /// The EntryCard layout (owner 2026-10-12) WITHOUT the pending drafts'
  /// collapsible section behaviour: quick create. [chipLayout] implies it.
  /// The card holds type · date, description · amount, the wallet chip row
  /// and the category chip row; the tags row, the note and the splits sit
  /// below it.
  final bool chipRows;

  /// Rows of the [EntryCard] a draft still lacks (danger outline).
  final Set<EntryField> missing;

  /// Put on the [TxHeroCard] — the quick create watches where it scrolled
  /// to (its title row shows the amount once the card is out of view).
  final GlobalKey? heroKey;

  /// Non-null → event mode: the form is a project row (see [DraftEvent]).
  final DraftEvent? event;

  final bool typeLocked;
  final bool allowSplits;

  /// A date after today shows "รายการล่วงหน้า › จะเข้ารอยืนยันวันที่ …"
  /// under the date (owner 2026-10-13: saving it makes an upcoming item, not
  /// a transaction). Not for transfers (the BE refuses future transfers).
  final bool upcomingHint;

  /// The hint's tap (the recurring page, upcoming tab); null = not tappable.
  final VoidCallback? onUpcomingHintTap;

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

  /// An event is being picked / changed in this form (quick create with
  /// one chosen, the detail page moving the row into one): the splits go
  /// to the event's board with it — titled "หารในอีเวนต์". An event bill
  /// left where it is keeps "หารกับ", split from my share.
  final bool eventPending;

  /// The อีเวนต์ row of the "แบ่งรายการ" section ([SplitEventSection]) — a
  /// saved row's / a new transaction's event, held by the page. Null = no
  /// event row (the drafts' layout keeps the draft's own, [DraftFormController
  /// .projectId]).
  final SplitEventSlot? eventSlot;

  /// The รายการประจำ row of the same section (0.4.0); null = no such row.
  final SplitRecurringSlot? recurringSlot;

  /// The "แบ่งยอด" row when the people can't be edited here (view mode, or
  /// another member's row): a read-only list / the lock note.
  final Widget? splitsReadOnly;

  /// The section's heading toggles it: pending drafts closed by default, the
  /// quick create open. The transaction detail never collapses.
  final bool splitsCollapsible;
  final bool splitsInitiallyOpen;

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
  final _walletOrder = ChipOrder();
  final _toWalletOrder = ChipOrder();

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
      categories:
          maybeTxFormOptions(
            context,
            watch: false,
          )?.state.options?.categoryList ??
          context.read<CategoriesCubit>().state.categories,
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
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
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

  /// The upcoming hint under the date, when it applies
  /// ([DraftForm.upcomingHint]).
  Widget? _upcomingNote(BuildContext context) {
    if (!widget.upcomingHint || _c.isTransfer || !isAfterToday(_c.date)) {
      return null;
    }
    final l = AppLocalizations.of(context)!;
    return HintLine(
      icon: AppIcons.scheduled,
      linkLabel: l.quickUpcomingHintTitle,
      text: l.quickUpcomingHintText(
        DateFormatter.medium(
          _c.date,
          locale: Localizations.localeOf(context).toLanguageTag(),
        ),
      ),
      onTap: widget.onUpcomingHintTap,
    );
  }

  /// Tags "เพิ่มเติม": the full picker (search, "+ แท็กใหม่").
  Future<void> _moreTags() async {
    final next = await showTagPickerSheet(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next);
  }

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(
      context,
      initial: _c.date,
      first: DateTime(2000),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (r is AppDatePicked) _c.setDate(r.date);
  }

  /// The tags: the edit chip row, or the view strip (none when empty).
  /// [longPress] wraps the view strip (a long-press enters edit mode).
  List<Widget> _tagsBlock({
    required bool editing,
    Widget Function(Widget child)? longPress,
  }) {
    if (editing) {
      return [
        TagChipRow(
          selected: _c.tagIds,
          onToggle: _c.toggleTag,
          onMore: _moreTags,
          known: _c.knownTags,
          order: _tagOrder,
        ),
      ];
    }
    if (_c.tagIds.isEmpty) return const [];
    final strip = TxTagStrip(
      tags: [
        for (final id in _c.tagIds)
          ?((maybeTxFormOptions(context, watch: false)?.state.options?.tags ??
                      context.read<TagsCubit>().state.tags)
                  .where((t) => t.id == id)
                  .firstOrNull ??
              _c.knownTags[id]),
      ],
    );
    return [longPress == null ? strip : longPress(strip)];
  }

  /// The description's stand-in on the detail hero: the category's name
  /// (localised for system ones), else the type's label.
  String _titlePlaceholder(AppLocalizations l) {
    final c = _c.isTransfer ? null : _c.category;
    if (c != null) return categoryDisplayName(l, c);
    final foreign = _c.isTransfer ? null : _c.foreignCategoryName;
    if (foreign != null && foreign.isNotEmpty) return foreign;
    return switch (_c.type) {
      TransactionType.expense => l.transactionTypeExpense,
      TransactionType.income => l.transactionTypeIncome,
      TransactionType.transfer => l.transactionTypeTransfer,
    };
  }

  /// A card's tap: the picker in edit / create mode; in view mode it enters
  /// edit mode first, then opens the picker (the placeholder rule). Null =
  /// not tappable (read-only, or no way into edit mode).
  VoidCallback? _heroTap(VoidCallback pick, {bool locked = false}) {
    if (locked || widget.readOnly) return null;
    if (widget.editing) return pick;
    final enter = widget.onEnterEdit;
    if (enter == null) return null;
    return () {
      enter(null);
      pick();
    };
  }

  /// A wallet card: the picker in edit mode; in view mode a tap enters edit
  /// and opens it. One that isn't in this user's list (someone else's, on a
  /// shared wallet) still shows its name, just not tappable.
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
      onTap: _heroTap(onPick),
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
      onTap: _heroTap(_pickCategory, locked: widget.categoryLockedHint != null),
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
    final opts = maybeTxFormOptions(context);
    final accounts = opts == null
        ? context.watch<AccountsCubit>().state.accounts
        : (opts.state.options?.accountList ?? const <Account>[]);
    _c.applyDefaultAccount(widget.defaultAccount ?? accounts.firstOrNull);
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
        final entryLayout = widget.chipLayout || widget.chipRows;
        final categoryHint = widget.categoryLockedHint;
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entryLayout)
              EntryCard(
                key: widget.heroKey,
                type: _c.type,
                onTypeChanged: widget.typeLocked ? null : _c.setType,
                amount: _c.amount,
                title: _c.description,
                dateLabel: _dayLabel(context, _c.date),
                dateNote: _upcomingNote(context),
                onPickDate: _pickDate,
                autofocus: widget.autofocus && !widget.readOnly,
                compact: widget.compact,
                amountFocus: _amountFocus,
                titleFocus: _descriptionFocus,
                amountNote: !isTransfer && (!editing || widget.allowSplits)
                    ? _ShareLine.of(_c)
                    : null,
                missing: widget.missing,
                walletRow: _entryWalletRow(l, isTransfer: isTransfer),
                toWalletRow: isTransfer ? _entryToWalletRow(l) : null,
                categoryRow: isTransfer ? null : _entryCategoryRow(l),
              )
            else
              TxHeroCard(
                key: widget.heroKey,
                type: _c.type,
                onTypeChanged: widget.typeLocked ? null : _c.setType,
                amount: _c.amount,
                title: _c.description,
                // The detail hero: no description → the category's name (else
                // the type) stands in, italic and muted.
                titlePlaceholder: widget.cardsInHero
                    ? _titlePlaceholder(l)
                    : null,
                dateLabel: _dayLabel(context, _c.date),
                dateNote: _upcomingNote(context),
                onPickDate: _pickDate,
                editing: editing,
                autofocus: widget.autofocus && !widget.readOnly,
                compact: widget.compact,
                amountFocus: _amountFocus,
                titleFocus: _descriptionFocus,
                onEdit: widget.onEdit,
                onLongPressField: enterEdit,
                inline: true,
                // "ส่วนของคุณ" under the total — while editing only where
                // splits can be edited; in view whenever the people loaded.
                amountNote: !isTransfer && (!editing || widget.allowSplits)
                    ? _ShareLine.of(_c)
                    : null,
                footer: widget.cardsInHero
                    ? _cardsRow(l, isTransfer: isTransfer)
                    : null,
              ),
            if (entryLayout)
              ..._chipBody(l, isTransfer: isTransfer)
            else ...[
              // Category · wallet cards: inside the hero on the detail page
              // (cardsInHero), else under it (quick create). 16 from the hero.
              const SizedBox(height: HeroSpacing.after),
              if (!widget.cardsInHero)
                longPressable(_cardsRow(l, isTransfer: isTransfer)),
              if (editing) ...[
                if (!isTransfer && categoryHint != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      categoryHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                // One tap on a recent category picks it (owner 2026-10-10);
                // not on the detail page (its category sits in the hero).
                if (!widget.cardsInHero &&
                    !isTransfer &&
                    categoryHint == null) ...[
                  CategoryChipRow(
                    type: _c.type,
                    selected: _c.category,
                    onPick: _c.setCategory,
                    onMore: _pickCategory,
                    order: _categoryOrders.putIfAbsent(_c.type, ChipOrder.new),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Editing: [🏷 chips…] (not a "แท็ก" row in the sections).
                // View mode keeps the tag strip below. (The detail page
                // puts the tags after the note instead, see [_sections].)
                if (!widget.cardsInHero) ..._tagsBlock(editing: true),
              ] else if (!widget.cardsInHero && _c.tagIds.isNotEmpty) ...[
                ..._tagsBlock(editing: false, longPress: longPressable),
              ],
              ..._sections(l, editing: editing, isTransfer: isTransfer),
            ],
          ],
        );
        if (!widget.readOnly) return form;
        return IgnorePointer(child: Opacity(opacity: 0.6, child: form));
      },
    );
  }

  /// The wallet chip row of the entry card: a dashed "เลือกกระเป๋า" chip
  /// first, then the wallets most used. A transfer's is the source.
  Widget _entryWalletRow(AppLocalizations l, {required bool isTransfer}) =>
      WalletChipRow(
        selectedId: _c.account?.id,
        onPick: isTransfer
            ? _c.setAccount
            // Tapping the picked wallet again leaves it out (a wallet is
            // optional here).
            : (a) => _c.setAccount(_c.account?.id == a.id ? null : a),
        onMore: _pickAccount,
        order: _walletOrder,
        pickLabel: isTransfer ? l.draftPickWalletFrom : l.quickPickWallet,
        excludeId: isTransfer ? _c.toAccount?.id : null,
      );

  Widget _entryToWalletRow(AppLocalizations l) => WalletChipRow(
    selectedId: _c.toAccount?.id,
    onPick: _c.setToAccount,
    onMore: () => _pickAccount(to: true),
    order: _toWalletOrder,
    pickLabel: l.draftPickWalletTo,
    excludeId: _c.account?.id,
  );

  Widget _entryCategoryRow(AppLocalizations l) => CategoryChipRow(
    type: _c.type,
    selected: _c.category,
    onPick: _c.setCategory,
    onMore: _pickCategory,
    order: _categoryOrders.putIfAbsent(_c.type, ChipOrder.new),
    pickLabel: l.draftPickCategory,
  );

  /// The entry layout below the card (wallet · category are IN the card):
  ///
  ///   [🏷] [#a] [#b] [⋯]
  ///   โน้ต  [ … ]
  ///   หารกับ / อีเวนต์  (summary)                ⌄   (not a transfer)
  List<Widget> _chipBody(AppLocalizations l, {required bool isTransfer}) {
    const gap = SizedBox(height: AppSpacing.sm);
    return [
      const SizedBox(height: HeroSpacing.after),
      TagChipRow(
        selected: _c.tagIds,
        onToggle: _c.toggleTag,
        onMore: _moreTags,
        known: _c.knownTags,
        order: _tagOrder,
      ),
      gap,
      DraftFieldRow(
        label: l.commonNote,
        child: AppInput.inline(
          editing: true,
          controller: _c.note,
          focusNode: _noteFocus,
          maxLines: 5,
          maxLength: TextLimits.note,
          hint: l.txNoteAddHint,
        ),
      ),
      if (!isTransfer || widget.recurringSlot != null) ...[
        gap,
        ?_splitEventSection(
          l,
          editing: true,
          first: true,
          transfer: isTransfer,
        ),
      ],
    ];
  }

  /// Category + wallet cards, one row — a transfer [จาก] → [ไป].
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
            AppIconButton.flat(
              tooltip: editing ? l.quickSwap : null,
              dense: true,
              icon: AppIcons.arrowForward,
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

  /// The one "แบ่งรายการ" section (owner 2026-10-12): the "แบ่งยอด" row (the
  /// split editor, or [DraftForm.splitsReadOnly]) and the อีเวนต์ row. Null
  /// when there is nothing to show (a transfer only gets the recurring row).
  Widget? _splitEventSection(
    AppLocalizations l, {
    required bool editing,
    bool first = false,
    bool transfer = false,
  }) {
    final canEdit = editing && widget.allowSplits;
    // The quick forms (quick create + the drafts) get the compact look; the
    // detail page the full one.
    final compact = widget.chipLayout || widget.chipRows;
    final helper = widget.eventPending || _c.projectId != null
        ? l.txSplitInEventHelper
        // An event bill staying put: my splits sit on my share.
        : _c.savedInEvent
        ? l.txSplitFromMyShare
        : null;
    final splits = transfer
        ? null
        : canEdit
        ? SplitsSection(
            embedded: true,
            compact: compact,
            // "แบ่งยอด" — the row label; going into an event the people
            // become the event's (the helper says so).
            label: l.txSplitRowLabel,
            helper: compact ? null : helper,
            totalAmount: _c.splitCap,
            overText: _c.eventOthers > 0 ? l.txSplitExceedsShare : null,
            drafts: _c.splits,
            onChanged: _c.setSplits,
            me: _c.meAmount,
            onMeChanged: _c.setMeAmount,
            meAuto: _c.meAuto,
            onMeAutoChanged: _c.setMeAuto,
          )
        : widget.splitsReadOnly;
    // The drafts' layout keeps its event on the controller.
    final slot = transfer
        ? null
        : widget.chipLayout
        ? _draftEventSlot()
        : widget.eventSlot;
    if (splits == null && slot == null && widget.recurringSlot == null) {
      return null;
    }
    return SplitEventSection(
      first: first,
      variant: compact ? SplitEventVariant.compact : SplitEventVariant.full,
      helper: compact && canEdit ? helper : null,
      splits: splits,
      event: slot,
      recurring: widget.recurringSlot,
      // The drafts collapse it, closed; quick create, open.
      collapsible: widget.chipLayout || widget.splitsCollapsible,
      initiallyOpen: !widget.chipLayout && widget.splitsInitiallyOpen,
      summary: _splitSummary(l, slot),
    );
  }

  /// "แบ่ง 2 คน · ทริป…" — what a closed section says; null = nothing set.
  String? _splitSummary(AppLocalizations l, SplitEventSlot? slot) {
    final people = _c.splits
        .where((s) => s.personName.trim().isNotEmpty || (s.owedAmount ?? 0) > 0)
        .length;
    final parts = [
      if (people > 0) l.draftExtrasSplits(people),
      ?slot?.name,
      ?widget.recurringSlot?.name,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// A draft's event (`project_id`): an existing event only.
  SplitEventSlot _draftEventSlot() {
    final id = _c.projectId;
    final opts = maybeTxFormOptions(context);
    // Events from the form options when a form provides them, else the
    // events cache.
    final known = id == null
        ? null
        : opts != null
        ? opts.state.options?.events.where((e) => e.id == id).firstOrNull?.name
        : context
              .watch<ProjectsCubit>()
              .state
              .projects
              .where((p) => p.id == id)
              .firstOrNull
              ?.name;
    final name = id == null
        ? null
        : (known ??
              _c.projectName ??
              AppLocalizations.of(context)!.quickEventLabel);
    return SplitEventSlot(
      name: name,
      onTap: _pickDraftEvent,
      onClear: name == null ? null : () => _c.setProject(null),
    );
  }

  Future<void> _pickDraftEvent() async {
    final r = await showEventTargetSheet(
      context,
      suggestedName: '',
      selectedProjectId: _c.projectId,
      // A draft can only name an event that exists.
      allowCreate: false,
    );
    if (!mounted) return;
    if (r is ExistingEventTarget) {
      _c.setProject(r.project.id, name: r.project.name);
    }
  }

  /// [DraftForm.sectioned] — the detail page below the hero (and, in view
  /// mode, the [TxTagStrip] under it):
  ///
  ///   โน้ต   [ the input, wrapping in its column ]  (label left)
  ///   ▬▬▬▬
  ///   หารกับ        [+ เพิ่มคน] [หารเท่ากัน]   (edit: the split editor)
  ///   …[DraftForm.trailingRows]: the page's sections (view splits, event)
  ///
  /// The note always shows where it can be edited — empty, the long-press
  /// hint (owner 2026-10-11).
  List<Widget> _sections(
    AppLocalizations l, {
    required bool editing,
    required bool isTransfer,
  }) {
    final enter = widget.onEnterEdit;
    final first = <Widget>[
      if (editing || enter != null || _c.note.text.trim().isNotEmpty)
        // The detail standard's note: label above, the value below with the
        // editable-text indent rule (plain indented text in view, the frame
        // only while editing).
        DetailStacked(
          label: l.commonNote,
          child: AppInput.inline(
            editing: editing,
            controller: _c.note,
            focusNode: _noteFocus,
            maxLines: 5,
            maxLength: TextLimits.note,
            hint: l.txNoteAddHint,
            viewHint: AppLocalizations.of(context)!.commonLongPressToEdit,
            onEnterEdit: enter == null ? null : () => enter(_noteFocus),
          ),
        ),
    ];
    // The detail page's order (owner 2026-10-12): hero → groups without a
    // heading (the note, then the tags) → headed sections (แบ่งรายการ).
    final enterEdit = widget.onEnterEdit;
    final tags = widget.cardsInHero
        ? _tagsBlock(
            editing: editing,
            longPress: (child) => editing || enterEdit == null
                ? child
                : GestureDetector(
                    onLongPress: () => enterEdit(null),
                    child: child,
                  ),
          )
        : const <Widget>[];
    return [
      // The tags sit DIRECTLY under the card (owner 2026-10-12), then the
      // note, then the headed sections.
      // (The 16 px under the hero card is already in the legacy branch.)
      if (tags.isNotEmpty) ...[
        ...tags,
        const SizedBox(height: HeroSpacing.after),
      ],
      if (first.isNotEmpty) SectionCard(first: true, children: first),
      ?_splitEventSection(l, editing: editing, transfer: isTransfer),
    ];
  }
}

// ── Pieces ────────────────────────────────────────────────────────────

/// A transaction's tags in view mode, right under the hero: `🏷 [#a] [#b]`
/// — the tag icon leads, like the edit mode's chip row; the chips wrap.
class TxTagStrip extends StatelessWidget {
  const TxTagStrip({required this.tags, super.key});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: AppIcon(
            AppIcons.tag,
            size: AppIconSize.md,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in tags) tagAppChip(context, t, size: ChipSize.chip),
            ],
          ),
        ),
      ],
    );
  }
}

/// A labelled text field under the hero of an event row / scheduled entry
/// (คำอธิบาย, โน้ต) — label on top, an [AppInput.inline] box below.
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
    // A headless group: plain on the page, the kit's label-on-top row.
    return SectionCard(
      first: true,
      children: [
        DetailStacked(
          label: label,
          child: AppInput.inline(
            editing: true,
            controller: controller,
            maxLength: maxLength,
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}

/// "ส่วนของคุณ ฿y · คนอื่นติดคุณ ฿x" under the hero's amount once the row
/// is split — the key number (owner 2026-10-10; reports count it). Income
/// splits are what I pass on: "· คุณติดคนอื่น ฿x" (owner 2026-10-11).
/// A negative share shows in the error colour.
///
/// y = the server's `my_share` while the form is as loaded (it also knows
/// an event share), x = amount − y. With unsaved split / amount changes
/// (or a BE without it): x = the event's others + the people, y = ฉัน as
/// typed (else what's left of the amount).
class _ShareLine extends StatelessWidget {
  const _ShareLine({
    required this.type,
    required this.mine,
    required this.others,
  });

  final TransactionType type;
  final double mine;
  final double others;

  /// Null while it's all mine.
  static Widget? of(DraftFormController c) {
    final saved = c.savedMyShare;
    if (saved != null) {
      final others = c.amountValue - saved;
      if (others <= 0.005) return null;
      return _ShareLine(type: c.type, mine: saved, others: others);
    }
    final others =
        c.eventOthers +
        c.splits.fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (others <= 0.005) return null;
    return _ShareLine(
      type: c.type,
      mine: c.meAmount ?? c.amountValue - others,
      others: others,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            '· ${type == TransactionType.income ? l.txShareYouOweOthers(othersText) : l.txShareOthersOweYou(othersText)}',
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
