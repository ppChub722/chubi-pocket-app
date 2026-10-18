import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/category_label.dart';
import 'category_pick_card.dart';
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

class DraftFormController extends ChangeNotifier {
  DraftFormController() {
    amount.addListener(notifyListeners);
    note.addListener(notifyListeners);
    description.addListener(notifyListeners);
  }

  final amount = TextEditingController();
  final note = TextEditingController();

  final description = TextEditingController();

  String? payerId;

  final List<String> tagNames = [];
  final List<MemberSplitDraft> memberSplits = [];

  double get memberSplitSum =>
      memberSplits.fold(0, (a, s) => a + s.amountValue);

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
    WidgetsBinding.instance.addPostFrameCallback((_) => s.amount.dispose());
  }

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

  String? foreignCategoryName;
  String? foreignAccountName;

  final Map<String, Tag> knownTags = {};

  String? projectId;
  String? projectName;

  void setProject(String? id, {String? name}) {
    projectId = id;
    projectName = id == null ? null : name;
    notifyListeners();
  }

  bool get isTransfer => type == TransactionType.transfer;
  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  bool get hasExtras =>
      tagIds.isNotEmpty ||
      projectId != null ||
      splits.any((s) => s.isComplete) ||
      tagNames.isNotEmpty ||
      memberSplits.isNotEmpty;

  bool get hasContent =>
      amount.text.isNotEmpty ||
      note.text.trim().isNotEmpty ||
      description.text.trim().isNotEmpty ||
      hasExtras;

  final Map<TransactionType, Category?> _categoryByType = {};

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

  double? get meAmount {
    if (splits.isEmpty) return null;
    if (!meAuto) return _meTyped;
    final left = splitLeft(splitCap, 0, splits);
    return left < 0 ? 0 : left;
  }

  bool meAuto = true;
  double? _meTyped;

  void setMeAmount(double? v) {
    _meTyped = v;
    meAuto = false;
    notifyListeners();
  }

  void setMeAuto(bool on) {
    if (!on) _meTyped = meAmount;
    meAuto = on;
    notifyListeners();
  }

  double get splitLeftover => splitLeft(splitCap, meAmount, splits);

  bool get splitsBalanced => splits.isEmpty || splitLeftover.abs() <= 0.005;

  void _seedMe() {
    meAuto = true;
    _meTyped = null;
  }

  void applyDefaultAccount(Account? a) {
    if (!accountTouched) account = a;
  }

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
    // An event bill: what the other members carry on the event row = amount −
    // my_share − my own splits (forgiven ones never came off).
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

  bool savedInEvent = false;

  /// An event bill's other members' part (0 off an event, or without
  /// `my_share`).
  double eventOthers = 0;

  double get splitCap => amountValue - eventOthers;

  double? _savedMyShare;
  String? _shareBasis;

  String _shareKey() => [
    amount.text,
    for (final s in splits) jsonEncode(s.toUpdateJson()),
  ].join('|');

  double? get savedMyShare =>
      _savedMyShare != null && _shareKey() == _shareBasis
      ? _savedMyShare
      : null;

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
    _seedMe();
    notifyListeners();
  }

  final Map<String, TxSplit> savedSplits = {};

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

class MemberSplitDraft {
  MemberSplitDraft(this.memberId);
  String? memberId;
  final amount = TextEditingController();
  double get amountValue => AmountInput.parse(amount.text) ?? 0;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    this.onViewTap,
    this.onEdit,
    this.eventPending = false,
    this.eventSlot,
    this.recurringSlot,
    this.splitsReadOnly,
    this.event,
    this.heroKey,
    this.chipLayout = false,
    this.cardsInHero = false,
    this.chipRows = false,
    this.missing = const {},
    super.key,
  });

  final bool chipLayout;

  final bool cardsInHero;

  final bool chipRows;

  final Set<EntryField> missing;

  final GlobalKey? heroKey;

  final DraftEvent? event;

  final bool typeLocked;
  final bool allowSplits;

  final bool upcomingHint;

  final VoidCallback? onUpcomingHintTap;

  /// Non-null → the category card can't be changed; this says why.
  final String? categoryLockedHint;

  final bool readOnly;

  final bool editing;

  final ValueChanged<FocusNode?>? onEnterEdit;

  final VoidCallback? onViewTap;

  final VoidCallback? onEdit;

  final bool eventPending;

  final SplitEventSlot? eventSlot;

  final SplitRecurringSlot? recurringSlot;

  /// The "แบ่งยอด" row when the people can't be edited here (view mode, or
  /// another member's row): a read-only list / the lock note.
  final Widget? splitsReadOnly;

  final DraftFormController controller;

  final bool compact;
  final bool autofocus;

  final Account? defaultAccount;

  final Widget? extra;

  @override
  State<DraftForm> createState() => _DraftFormState();
}

class _DraftFormState extends State<DraftForm> {
  final _amountFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _noteFocus = FocusNode();

  final _categoryOrders = <TransactionType, ChipOrder>{};
  final _walletOrder = ChipOrder();

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

  List<Widget> _tagsBlock({
    required bool editing,
    Widget Function(Widget child)? longPress,
  }) {
    if (editing) {
      return [
        TagChipRow(
          selected: _c.tagIds,
          onRemove: _c.toggleTag,
          onMore: _moreTags,
          known: _c.knownTags,
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

  VoidCallback? _heroTap(VoidCallback pick, {bool locked = false}) {
    if (locked || widget.readOnly) return null;
    if (widget.editing) return pick;
    if (widget.onEnterEdit == null) return null;
    return widget.onViewTap;
  }

  VoidCallback? _heroLongPress(VoidCallback pick, {bool locked = false}) {
    if (locked || widget.readOnly || widget.editing) return null;
    final enter = widget.onEnterEdit;
    if (enter == null) return null;
    return () {
      enter(null);
      pick();
    };
  }

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
      onLongPress: _heroLongPress(onPick),
      editable: widget.editing && !widget.readOnly,
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
      onLongPress: _heroLongPress(
        _pickCategory,
        locked: widget.categoryLockedHint != null,
      ),
      editable:
          widget.editing &&
          !widget.readOnly &&
          widget.categoryLockedHint == null,
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
                showTitle: !isTransfer,
                titleHint: isTransfer
                    ? null
                    : (_c.type == TransactionType.income
                          ? l.txTitleHintIncome
                          : l.txTitleHintExpense),
                flowRow: isTransfer ? _transferFlow(l) : null,
                walletRow: isTransfer
                    ? null
                    : _entryWalletRow(l, isTransfer: false),
                categoryRow: isTransfer ? null : _entryCategoryRow(l),
              )
            else
              TransactionHeroCard(
                key: widget.heroKey,
                type: _c.type,
                onTypeChanged: widget.typeLocked ? null : _c.setType,
                amount: _c.amount,
                title: _c.description,
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
                onLongPressDate: enterEdit == null
                    ? null
                    : () {
                        enterEdit(null);
                        _pickDate();
                      },
                inline: true,
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
              SizedBox(height: HeroMetrics.of(context).after),
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

  Widget _entryWalletRow(AppLocalizations l, {required bool isTransfer}) =>
      WalletChipRow(
        selectedId: _c.account?.id,
        onPick: isTransfer
            ? _c.setAccount
            : (a) => _c.setAccount(_c.account?.id == a.id ? null : a),
        onMore: _pickAccount,
        order: _walletOrder,
        pickLabel: isTransfer ? l.draftPickWalletFrom : l.quickPickWallet,
        excludeId: isTransfer ? _c.toAccount?.id : null,
      );

  Widget _transferFlow(AppLocalizations l) => FlowCards(
    from: WalletPickCard(
      account: _c.account,
      label: l.quickFrom,
      placeholder: l.quickPickWallet,
      dense: true,
      twoLine: true,
      editable: true,
      onTap: () => _pickAccount(),
    ),
    to: WalletPickCard(
      account: _c.toAccount,
      label: l.quickTo,
      placeholder: l.quickPickWallet,
      dense: true,
      twoLine: true,
      editable: true,
      onTap: () => _pickAccount(to: true),
    ),
    swapTooltip: l.quickSwap,
    onSwap: _c.swapAccounts,
  );

  Widget _entryCategoryRow(AppLocalizations l) => CategoryChipRow(
    type: _c.type,
    selected: _c.category,
    onPick: _c.setCategory,
    onMore: _pickCategory,
    order: _categoryOrders.putIfAbsent(_c.type, ChipOrder.new),
    pickLabel: l.draftPickCategory,
  );

  List<Widget> _chipBody(AppLocalizations l, {required bool isTransfer}) {
    const gap = SizedBox(height: AppSpacing.sm);
    return [
      SizedBox(height: HeroMetrics.of(context).after),
      TagChipRow(
        selected: _c.tagIds,
        onRemove: _c.toggleTag,
        onMore: _moreTags,
        known: _c.knownTags,
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

  Widget _cardsRow(AppLocalizations l, {required bool isTransfer}) {
    final editing = widget.editing;
    if (isTransfer) {
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

  Widget? _splitEventSection(
    AppLocalizations l, {
    required bool editing,
    bool first = false,
    bool transfer = false,
  }) {
    final canEdit = editing && widget.allowSplits;
    final compact = widget.chipLayout || widget.chipRows;
    final helper = widget.eventPending || _c.projectId != null
        ? l.txSplitInEventHelper
        : _c.savedInEvent
        ? l.txSplitFromMyShare
        : null;
    final splits = transfer
        ? null
        : canEdit
        ? SplitsSection(
            embedded: true,
            compact: compact,
            label: widget.chipLayout ? l.txSplitRowLabel : l.txSplitPeopleLabel,
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
      collapsible: false,
      initiallyOpen: true,
    );
  }

  SplitEventSlot _draftEventSlot() {
    final id = _c.projectId;
    final opts = maybeTxFormOptions(context);
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
      allowCreate: false,
    );
    if (!mounted) return;
    if (r is ExistingEventTarget) {
      _c.setProject(r.project.id, name: r.project.name);
    }
  }

  List<Widget> _sections(
    AppLocalizations l, {
    required bool editing,
    required bool isTransfer,
  }) {
    final enter = widget.onEnterEdit;
    final note = editing || enter != null || _c.note.text.trim().isNotEmpty
        ? NoteSection(
            first: true,
            label: l.commonNote,
            editing: editing,
            text: _c.note.text,
            hint: l.commonLongPressToEdit,
            onLongPress: enter == null ? null : () => enter(_noteFocus),
            editField: DetailStacked(
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
          )
        : null;
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
      if (tags.isNotEmpty) ...[
        ...tags,
        SizedBox(height: HeroMetrics.of(context).after),
      ],
      ?note,
      ?_splitEventSection(l, editing: editing, transfer: isTransfer),
    ];
  }
}

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

class _ShareLine extends StatelessWidget {
  const _ShareLine({
    required this.type,
    required this.mine,
    required this.others,
  });

  final TransactionType type;
  final double mine;
  final double others;

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
