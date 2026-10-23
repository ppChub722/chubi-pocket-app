import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker.dart' show askNewTagName;
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/category_pick_card.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../event_errors.dart';
import 'member_picker.dart';
import 'project_common.dart';
import 'project_tx_tiles.dart' show projectMemberLevel;

/// What the event sheet writes: a bill (expense / income) or a payback.
enum EventEntryKind { expense, income, payback }

/// The event's own sheet (owner 2026-10-23): a bill with everyone in it and
/// who paid, or a payback "A → B"; "ลงบัญชีของฉันด้วย" puts my part in my
/// books on save (resolve). [row] edits that bill / payback. A payback can
/// start from [from] → [to] for [amount] (the summary's "จ่ายแล้ว").
Future<bool> showEventBillSheet(
  BuildContext context, {
  required ProjectView view,
  ProjectTxTree? row,
  EventEntryKind kind = EventEntryKind.expense,
  String? from,
  String? to,
  double? amount,
  ValueChanged<EventPatch>? onPatch,
}) async {
  context.read<AccountsCubit>().loadIfNeeded();
  context.read<CategoriesCubit>().loadIfNeeded();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    enableDrag: false,
    builder: (_) => _EventBillSheet(
      view: view,
      row: row,
      kind: row == null
          ? kind
          : (row.parent.isPayback
                ? EventEntryKind.payback
                : (row.parent.type == 'income'
                      ? EventEntryKind.income
                      : EventEntryKind.expense)),
      from: from,
      to: to,
      amount: amount,
      onPatch: onPatch,
    ),
  );
  return saved ?? false;
}

/// One person in the bill: an event member, or someone added in the sheet.
class _Person {
  _Person({
    required this.key,
    required this.name,
    this.memberId,
    this.contactId,
    this.iconCode,
    this.level = PersonLevel.name,
    this.isMe = false,
    this.isNew = false,
  });

  factory _Person.member(ProjectMember m) => _Person(
    key: 'm:${m.id}',
    name: m.displayName,
    memberId: m.id,
    contactId: m.contactId,
    iconCode: m.iconCode,
    level: projectMemberLevel(m),
    isMe: m.isMe,
  );

  final String key;
  final String name;
  final String? memberId;
  final String? contactId;
  final IconCode? iconCode;
  final PersonLevel level;
  final bool isMe;

  /// Not an event member yet: added on save.
  final bool isNew;

  bool paidBack = false;

  Map<String, dynamic> get json => isMe
      ? const {'me': true}
      : memberId != null
      ? {'member_id': memberId}
      : contactId != null
      ? {'contact_id': contactId}
      : {'person_name': name};

  String get debtKey => contactId != null
      ? debtPersonKey(contactId: contactId)
      : debtPersonKey(name: name);
}

class _EventBillSheet extends StatefulWidget {
  const _EventBillSheet({
    required this.view,
    required this.kind,
    this.row,
    this.from,
    this.to,
    this.amount,
    this.onPatch,
  });

  final ProjectView view;
  final ProjectTxTree? row;
  final EventEntryKind kind;
  final String? from;
  final String? to;
  final double? amount;
  final ValueChanged<EventPatch>? onPatch;

  @override
  State<_EventBillSheet> createState() => _EventBillSheetState();
}

class _EventBillSheetState extends State<_EventBillSheet> {
  late EventEntryKind _kind = widget.kind;
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = DateTime.now();
  final _tagIds = <String>{};

  /// Event tags made in this sheet (the page learns them from the patch).
  final _madeTags = <BoardTag>[];

  final _people = <_Person>[];
  String? _payerKey;

  /// Shares the user typed (key → amount); everyone else splits the rest.
  final _typed = <String, double>{};

  late String? _fromKey;
  late String? _toKey;

  bool _books = false;
  bool _bookDebt = true;
  bool _bookTx = false;

  /// The row's parts in my books when the sheet opened (editing).
  List<String> _wasBooked = const [];
  Account? _account;
  Category? _category;
  bool _saving = false;

  ProjectView get _view => widget.view;
  bool get _editing => widget.row != null;
  bool get _payback => _kind == EventEntryKind.payback;
  bool get _booked => widget.row?.parent.myBooked ?? false;
  String? get _myKey => _view.me == null ? null : 'm:${_view.me!.id}';

  double get _total => AmountInput.parse(_amount.text.trim())?.toDouble() ?? 0;

  _Person? _person(String? key) {
    if (key == null) return null;
    for (final p in _people) {
      if (p.key == key) return p;
    }
    return null;
  }

  _Person? get _payer => _person(_payerKey);
  bool get _iPaid => _payer?.isMe ?? false;
  bool get _meInBill => _people.any((p) => p.isMe);

  @override
  void initState() {
    super.initState();
    final members = [for (final m in _view.currentMembers) _Person.member(m)];
    final row = widget.row;
    if (row == null) {
      _people.addAll(members);
      _payerKey = _myKey ?? members.firstOrNull?.key;
      _fromKey = widget.from == null ? _myKey : 'm:${widget.from}';
      _toKey = widget.to == null ? null : 'm:${widget.to}';
      if (widget.amount != null) {
        _amount.text = AmountInput.format(widget.amount!);
      }
      _books = _payback ? _involved : true;
    } else {
      final p = row.parent;
      _amount.text = AmountInput.format(p.amount);
      _title.text = p.description ?? '';
      _note.text = p.note ?? '';
      _date = DateFormatter.parseDay(p.date) ?? DateTime.now();
      _tagIds.addAll(_view.tagIdsFor(p.tags));
      final payer = _Person.member(_view.memberOf(p));
      if (p.isPayback) {
        _fromKey = payer.key;
        final to = row.children.firstOrNull;
        _toKey = to == null ? null : 'm:${to.transactionMemberId}';
        _people.addAll(members);
      } else {
        _fromKey = _toKey = null;
        _people.add(payer);
        for (final c in row.children) {
          final m = _Person.member(_view.memberOf(c));
          _people.add(m);
          _typed[m.key] = c.amount;
        }
        _payerKey = payer.key;
      }
      _wasBooked = p.myBooks;
    }
    // A payback: จดหนี้ + รับคืน / จ่ายคืน both on (the debt and its money),
    // but no จดหนี้ when my books already hold that debt in full.
    _bookTx = _payback || _iPaid;
    if (_payback) _bookDebt = !_debtAlreadyBooked;
    // Editing shows the row as it is: the switch and ticks = what's linked.
    if (_wasBooked.isNotEmpty) {
      _books = true;
      _bookTx = _linked(_txKind);
      _bookDebt = _linked(ProjectTransaction.bookDebt);
    }
    _amount.addListener(_changed);
  }

  bool get _involved => _fromKey == _myKey || _toKey == _myKey;

  /// A payback with me in it, whose debt my books already show in full
  /// (they owe me at least it, or I owe them at least it).
  bool get _debtAlreadyBooked {
    if (!_involved) return false;
    final iPay = _fromKey == _myKey;
    final other = _person(iPay ? _toKey : _fromKey);
    if (other == null) return false;
    final now = _netWith(other);
    return iPay ? now <= -_total + 0.005 : now >= _total - 0.005;
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  // ---------- shares ----------

  /// Everyone's share: typed ones as typed, the rest split what's left; the
  /// payer takes the cents.
  Map<String, double> get _shares {
    final total = _total;
    final free = [
      for (final p in _people)
        if (!_typed.containsKey(p.key) || p.key == _payerKey) p.key,
    ];
    final typedSum = _typed.entries
        .where((e) => e.key != _payerKey)
        .fold<double>(0, (s, e) => s + e.value);
    final left = total - typedSum;
    final each = free.isEmpty
        ? 0.0
        : (left / free.length * 100).floorToDouble() / 100;
    final out = <String, double>{};
    for (final p in _people) {
      if (p.key == _payerKey) continue;
      out[p.key] = _typed[p.key] ?? each;
    }
    final others = out.values.fold<double>(0, (s, v) => s + v);
    if (_payerKey != null) out[_payerKey!] = total - others;
    return out;
  }

  double _shareOf(_Person p) => _shares[p.key] ?? 0;

  /// I paid: who owes me their share (not the ones who paid back now).
  List<_Person> get _debtors => [
    for (final p in _people)
      if (p.key != _payerKey && !p.paidBack && _shareOf(p) > 0.005) p,
  ];

  void _splitEqual() => setState(_typed.clear);

  void _setPayer(_Person p) => setState(() {
    _payerKey = p.key;
    p.paidBack = false;
    _typed.remove(p.key);
    if (!_editing && !_booked) _books = p.isMe;
    // I paid: the bill as my tx + the others as my debtors. Someone else
    // paid: a debt to them; my share as a tx only when ticked.
    _bookDebt = true;
    _bookTx = p.isMe;
  });

  void _remove(_Person p) => setState(() {
    _people.remove(p);
    _typed.remove(p.key);
    if (_payerKey == p.key) _payerKey = _people.firstOrNull?.key;
  });

  Future<void> _addPeople() async {
    final l = AppLocalizations.of(context)!;
    final inBill = {for (final p in _people) ?p.memberId};
    final r = await ContactPicker.people(
      context,
      title: l.txSplitAddPerson,
      membersLabel: l.evbMembersSection,
      confirmLabel: l.evbAddPeopleConfirm,
      selectedMemberIds: inBill,
      members: [
        for (final m in _view.currentMembers)
          PickerMember(
            id: m.id,
            name: m.displayName,
            iconCode: m.iconCode,
            level: projectMemberLevel(m),
            contactId: m.contactId,
          ),
      ],
    );
    if (r == null || !mounted) return;
    setState(() {
      final keep = r.memberIds.toSet();
      // Members are the picker's ticks: unticked members leave the bill.
      _people.removeWhere(
        (p) => p.memberId != null && !keep.contains(p.memberId) && !p.isMe,
      );
      for (final id in r.memberIds) {
        if (_people.any((p) => p.memberId == id)) continue;
        final m = _view.currentMembers.where((m) => m.id == id).firstOrNull;
        if (m != null) _people.add(_Person.member(m));
      }
      for (final pick in r.picks) {
        final added = switch (pick) {
          ContactPicked(:final Contact contact) => _Person(
            key: 'c:${contact.id}',
            name: contact.name,
            contactId: contact.id,
            iconCode: contact.iconCode,
            level: contact.isLinked ? PersonLevel.linked : PersonLevel.contact,
            isNew: true,
          ),
          ContactNamePicked(:final name) ||
          ContactNameTyped(:final name) => _Person(
            key: 'n:${name.trim().toLowerCase()}',
            name: name,
            isNew: true,
          ),
        };
        if (!_people.any((p) => p.key == added.key)) _people.add(added);
      }
      if (_person(_payerKey) == null) _payerKey = _people.firstOrNull?.key;
    });
  }

  // ---------- pickers ----------

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(
      context,
      initial: _date,
      first: DateTime(2000),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (r is AppDatePicked && mounted) setState(() => _date = r.date);
  }

  Future<void> _pickAccount() async {
    final r = await AccountPicker.one(context, selectedId: _account?.id);
    if (r is AccountPicked && mounted) setState(() => _account = r.account);
  }

  Future<void> _pickCategory() async {
    final l = AppLocalizations.of(context)!;
    final r = await CategoryPicker.one(
      context,
      types: {
        _kind == EventEntryKind.income
            ? CategoryType.income
            : CategoryType.expense,
      },
      selectedId: _category?.id,
      allowNone: true,
      noneLabel: l.projectResolveCategoryNone,
      title: l.projectResolveCategory,
    );
    if (!mounted) return;
    if (r is CategoryPicked) setState(() => _category = r.category);
    if (r is CategoryPickedNone) setState(() => _category = null);
  }

  Future<void> _pickFromTo({required bool from}) async {
    final l = AppLocalizations.of(context)!;
    final key = from ? _fromKey : _toKey;
    final m = await EventMemberPicker.one(
      context,
      members: _view.currentMembers,
      selectedId: key?.substring(2),
      title: from ? l.quickFrom : l.quickTo,
    );
    if (m == null || !mounted) return;
    setState(() {
      if (from) {
        _fromKey = 'm:${m.id}';
        if (_toKey == _fromKey) _toKey = null;
      } else {
        _toKey = 'm:${m.id}';
        if (_fromKey == _toKey) _fromKey = null;
      }
      if (!_editing) _books = _involved;
    });
  }

  void _swap() => setState(() {
    final f = _fromKey;
    _fromKey = _toKey;
    _toKey = f;
  });

  // ---------- my books ----------

  double get _myShare =>
      _myKey == null || !_meInBill ? 0 : (_shares[_myKey!] ?? 0);

  /// My balance with [p] in the debts (> 0: they owe me).
  double _netWith(_Person p) {
    final dir = context.read<DebtDirectoryCubit?>();
    final key = p.debtKey;
    for (final b in dir?.state.people ?? const <PersonBalance>[]) {
      if (b.key == key) return b.net;
    }
    return 0;
  }

  String _sideText(AppLocalizations l, double net) {
    final money = moneyString(context, net.abs());
    if (net > 0.005) return '${l.debtRoleDebtor} $money';
    if (net < -0.005) return '${l.debtRoleCreditor} $money';
    return l.evbNoDebt;
  }

  Widget _pickCards(AppLocalizations l, {required bool walletOptional}) =>
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_payback) ...[
              Expanded(
                child: CategoryPickCard(
                  category: _category,
                  label: l.transactionFormCategoryLabel,
                  placeholder: l.transactionFormCategoryNone,
                  dense: true,
                  editable: true,
                  onTap: _pickCategory,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: WalletPickCard(
                account: _account,
                label: l.transactionFormAccountLabel,
                placeholder: walletOptional
                    ? l.evbNoWallet
                    : l.transactionFormAccountNone,
                dense: true,
                editable: true,
                onTap: _pickAccount,
              ),
            ),
          ],
        ),
      );

  /// The person a debt / repayment is with: avatar, name, [what] (their state
  /// before → after), and what this save does: a bill adds [amount] to the
  /// debt (เพิ่มหนี้), a payback takes it off (ลดหนี้). No [amount]: already in
  /// my books, nothing changes.
  Widget _personLine(
    _Person p,
    String what, {
    required bool up,
    required double? amount,
  }) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _personAvatar(p),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                p.name,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                what,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (amount != null)
          AppChip(
            label:
                '${up ? l.evbDebtUp : l.evbDebtDown} '
                '${moneyString(context, amount)}',
            tone: up ? AppChipTone.warning : AppChipTone.success,
            selected: true,
            size: ChipSize.mini,
          ),
      ],
    );
  }

  /// [kind] of this row was in my books when the sheet opened.
  bool _linked(String kind) => _wasBooked.contains(kind);

  String get _txKind =>
      _payback ? ProjectTransaction.bookRepay : ProjectTransaction.bookTx;

  /// A person's state: before → after, or just now when nothing changes.
  String _change(AppLocalizations l, double now, double delta) =>
      delta.abs() < 0.005
      ? _sideText(l, now)
      : '${_sideText(l, now)} → ${_sideText(l, now + delta)}';

  Widget? _myBooks(AppLocalizations l) {
    final involved =
        _booked || (_payback ? _involved : (_iPaid || _meInBill));
    if (!involved || _view.me == null) return null;
    // A part already linked changes nothing in my books (no pickers, no
    // before → after); unticking it unlinks it.
    final debtLinked = _linked(ProjectTransaction.bookDebt);
    final txLinked = _linked(_txKind);
    final rows = <Widget>[];
    if (_books) {
      if (_payback) {
        final other = _person(_fromKey == _myKey ? _toKey : _fromKey);
        final iPay = _fromKey == _myKey;
        if (other != null) {
          // จดหนี้ puts the event's debt in my books (they owe me / I owe
          // them); รับคืน / จ่ายคืน is the money that clears it. Both = even.
          final now = _netWith(other);
          final record = _bookDebt && !debtLinked
              ? (iPay ? -_total : _total)
              : 0.0;
          final repay = _bookTx && !txLinked ? (iPay ? _total : -_total) : 0.0;
          final after = now + record + repay;
          rows.addAll([
            BookOptionCard(
              icon: AppIcons.debt,
              title: l.evbRecordDebt,
              subtitle: iPay
                  ? l.evbBookDebtLine(other.name)
                  : l.evbTheyOweMe(other.name),
              amount: MoneyText(_total),
              checked: _bookDebt,
              onChanged: (v) => setState(() => _bookDebt = v),
              child: _personLine(
                other,
                _change(l, now, record),
                up: true,
                amount: debtLinked ? null : _total,
              ),
            ),
            BookOptionCard(
              icon: AppIcons.transfer,
              title: iPay ? l.debtPay : l.debtRepayReceive,
              subtitle: txLinked
                  ? l.evbBooked
                  : (_account?.name ?? l.evbNoWallet),
              amount: MoneyText(_total),
              checked: _bookTx,
              onChanged: (v) => setState(() => _bookTx = v),
              child: txLinked ? null : _pickCards(l, walletOptional: true),
            ),
            DebtResultBox(
              nowLabel: l.debtResultNow(other.name),
              before: _sideText(l, now),
              afterLabel: l.debtResultAfterSave,
              after: _sideText(l, after),
              walletLabel: _account?.name ?? l.transactionFormAccountLabel,
              walletValue: _account == null || !_bookTx || txLinked
                  ? l.debtWalletNotUsed
                  : '${iPay ? '−' : '+'}${moneyString(context, _total)}',
            ),
          ]);
        }
      } else if (_iPaid) {
        final debtors = _debtors;
        final owed = debtors.fold<double>(0, (s, p) => s + _shareOf(p));
        rows.addAll([
          BookOptionCard(
            icon: AppIcons.receipt,
            title: l.evbBookTx,
            subtitle: txLinked
                ? l.evbBooked
                : l.evbPaidFrom(
                    _account?.name ?? l.transactionFormAccountLabel,
                  ),
            amount: MoneyText(_total),
            checked: _bookTx,
            onChanged: (v) => setState(() => _bookTx = v),
            child: txLinked ? null : _pickCards(l, walletOptional: true),
          ),
          if (debtors.isNotEmpty)
            BookOptionCard(
              icon: AppIcons.debt,
              title: l.evbBookDebt,
              subtitle: l.evbDebtorsLine(debtors.length),
              amount: MoneyText(owed),
              checked: _bookDebt,
              onChanged: (v) => setState(() => _bookDebt = v),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, p) in debtors.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _personLine(
                      p,
                      _change(
                        l,
                        _netWith(p),
                        debtLinked ? 0 : _shareOf(p),
                      ),
                      up: true,
                      amount: debtLinked ? null : _shareOf(p),
                    ),
                  ],
                ],
              ),
            ),
        ]);
      } else {
        final payer = _payer;
        final share = _myShare;
        final now = payer == null ? 0.0 : _netWith(payer);
        final owe = debtLinked ? 0.0 : share;
        rows.addAll([
          BookOptionCard(
            icon: AppIcons.debt,
            title: l.evbBookDebt,
            subtitle: l.evbBookDebtLine(payer?.name ?? ''),
            amount: MoneyText(share),
            checked: _bookDebt,
            onChanged: (v) => setState(() => _bookDebt = v),
            child: payer == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _personLine(
                        payer,
                        _change(l, now, -owe),
                        up: true,
                        amount: debtLinked ? null : share,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DebtResultBox(
                        nowLabel: l.debtResultNow(payer.name),
                        before: _sideText(l, now),
                        afterLabel: l.debtResultAfterSave,
                        after: _sideText(l, now - owe),
                        walletLabel: l.transactionFormAccountLabel,
                        walletValue: l.debtWalletNotUsed,
                      ),
                    ],
                  ),
          ),
          BookOptionCard(
            icon: AppIcons.receipt,
            title: l.evbBookTx,
            subtitle: txLinked ? l.evbBooked : l.evbBookTxLine,
            amount: MoneyText(share),
            checked: _bookTx,
            onChanged: (v) => setState(() => _bookTx = v),
            child: txLinked ? null : _pickCards(l, walletOptional: true),
          ),
        ]);
      }
    }
    return ShareCard(
      title: l.evbMyBooks,
      actions: [
        AppSwitch(
          value: _books,
          onChanged: (v) => setState(() => _books = v),
          semanticLabel: l.evbMyBooks,
        ),
      ],
      rows: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          r,
        ],
      ],
    );
  }

  // ---------- body ----------

  /// Avatars only: no 🔗 badge on a linked member (as on the bill rows).
  Widget _personAvatar(_Person p) {
    final level = p.level == PersonLevel.linked
        ? PersonLevel.contact
        : p.level;
    return p.isMe
        ? ProjectMemberAvatar(
            name: p.name,
            iconCode: p.iconCode,
            level: level,
            size: SplitRow.avatarSize,
          )
        : PersonMark(
            name: p.name,
            level: level,
            iconCode: p.iconCode,
            size: SplitRow.avatarSize,
          );
  }

  Widget _peopleCard(AppLocalizations l) {
    final shares = _shares;
    final others = _people
        .where((p) => p.key != _payerKey)
        .fold<double>(0, (s, p) => s + (shares[p.key] ?? 0));
    final over = others - _total;
    final ordered = [?_payer, ..._people.where((p) => p.key != _payerKey)];
    Widget row(_Person p) {
      final payer = p.key == _payerKey;
      return ShareRow(
        key: ValueKey('evbPerson:${p.key}'),
        avatar: _personAvatar(p),
        name: Row(
          children: [
            Flexible(
              child: p.isMe
                  ? SplitRowName.muted(l.txLinkCardMe)
                  : SplitRowName.picked(p.name),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppChip(
              label: l.evbPays,
              icon: payer ? AppIcons.check : null,
              selected: payer,
              dashed: !payer,
              size: ChipSize.mini,
              onTap: payer ? null : () => _setPayer(p),
            ),
            if (!payer && _payer != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AppChip(
                label: l.evbPaidBack,
                icon: p.paidBack ? AppIcons.check : null,
                selected: p.paidBack,
                dashed: !p.paidBack,
                tone: AppChipTone.info,
                size: ChipSize.mini,
                onTap: () => setState(() => p.paidBack = !p.paidBack),
              ),
            ],
          ],
        ),
        amount: ShareAmountField(
          value: shares[p.key],
          auto: !payer && !_typed.containsKey(p.key),
          onChanged: payer
              ? null
              : (v) => setState(() {
                  if (v == null) {
                    _typed.remove(p.key);
                  } else {
                    _typed[p.key] = v;
                  }
                }),
        ),
        trailing: SplitRowAction(
          icon: AppIcons.close,
          tooltip: l.commonRemove,
          onTap: _people.length > 1 ? () => _remove(p) : null,
        ),
        tag: p.isNew
            ? AppChip(
                label: l.txLinkCardNewToEvent,
                size: ChipSize.mini,
                tone: AppChipTone.info,
              )
            : null,
      );
    }

    return ShareCard(
      title: l.evbPeople(_people.length),
      actions: [
        AppChip(
          label: l.txSplitEqually,
          onTap: _typed.isEmpty ? null : _splitEqual,
          size: ChipSize.mini,
        ),
        AppChip(
          label: l.txSplitAddPerson,
          icon: AppIcons.add,
          onTap: _addPeople,
          size: ChipSize.mini,
        ),
      ],
      rows: [
        ConstrainedBox(
          // About five rows; more scroll inside the card.
          constraints: const BoxConstraints(maxHeight: 5 * 56),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [for (final p in ordered) row(p)],
          ),
        ),
      ],
      status: _total <= 0
          ? null
          : over > 0.005
          ? ShareStatus(l.txLinkCardOver(moneyString(context, over)), ok: false)
          : ShareStatus(l.txLinkCardSplitOk, ok: true),
    );
  }

  /// A new event tag, made now (shared with every member) and ticked.
  Future<void> _newTag() async {
    final l = AppLocalizations.of(context)!;
    final name = await askNewTagName(context, maxLength: 40);
    if (name == null || !mounted) return;
    try {
      final tag = await context.read<ProjectsRepository>().createEventTag(
        _view.project.id,
        name,
      );
      if (!mounted) return;
      setState(() {
        _madeTags.add(tag);
        _tagIds.add(tag.id);
      });
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, eventErrorText(l, e), tone: Tone.danger);
      }
    }
  }

  Widget _tagsRow(AppLocalizations l) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return ChipRow(
      icon: AppIcons.tag,
      chips: [
        for (final t in [..._view.eventTags, ..._madeTags])
          AppChip(
            label: t.name,
            icon: IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
            color: EventTagRef(t.name, iconCode: t.iconCode).colorOf(palette),
            selected: _tagIds.contains(t.id),
            onTap: () => setState(() {
              if (!_tagIds.remove(t.id)) _tagIds.add(t.id);
            }),
          ),
        AppChip(
          label: l.fpEventsTagAdd,
          icon: AppIcons.add,
          dashed: true,
          onTap: _newTag,
        ),
      ],
    );
  }

  Widget _hero(AppLocalizations l) {
    final paybackColor = ModuleColors.of(context).planning;
    final type = _kind == EventEntryKind.income
        ? TransactionType.income
        : TransactionType.expense;
    final dateLabel = DateFormatter.friendly(
      _date,
      today: l.commonToday,
      yesterday: l.commonYesterday,
      locale: Localizations.localeOf(context).languageCode,
    );
    Widget personCard(String? key, String label, bool from) {
      final p = _person(key);
      return PickCard(
        label: label,
        value: p?.name,
        placeholder: l.quickEventNone,
        leading: p == null ? const AppIcon(AppIcons.member) : _personAvatar(p),
        dense: true,
        editable: true,
        onTap: () => _pickFromTo(from: from),
      );
    }

    return TransactionHeroCard(
      inline: true,
      type: type,
      amount: _amount,
      title: _title,
      dateLabel: dateLabel,
      onPickDate: _pickDate,
      allowTransfer: false,
      onTypeChanged: (t) => setState(
        () => _kind = t == TransactionType.income
            ? EventEntryKind.income
            : EventEntryKind.expense,
      ),
      extraTypeSelected: _payback,
      extraTypeChip: _editing && !_payback
          ? null
          : AppChip(
              label: l.evbTypePayback,
              icon: _payback ? AppIcons.transfer : null,
              color: paybackColor,
              selected: _payback,
              dashed: !_payback,
              onTap: _payback
                  ? null
                  : () => setState(() {
                      _kind = EventEntryKind.payback;
                      _fromKey ??= _myKey;
                      _books = _involved;
                      _bookDebt = _bookTx = true;
                    }),
            ),
      accentColor: _payback ? paybackColor : null,
      showTitle: !_payback,
      titleHint: l.txTitleHintExpense,
      amountLabel: _payback ? l.projectResolveAmount : l.txLinkBillLabel,
      footer: _payback
          ? FlowCards(
              from: personCard(_fromKey, l.quickFrom, true),
              to: personCard(_toKey, l.quickTo, false),
              onSwap: _swap,
              swapTooltip: l.recurringLinkSwapYes,
            )
          : null,
    );
  }

  // ---------- save ----------

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final total = _total;
    if (total <= 0) return;
    if (_payback && (_fromKey == null || _toKey == null)) return;
    if (!_payback && _payer == null) return;
    final repo = context.read<ProjectsRepository>();
    final txRepo = context.read<TransactionsRepository>();
    final debts = context.read<PersonalDebtsRepository>();
    final accounts = context.read<AccountsCubit>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final patch = _payback
          ? await _savePayback(repo, debts, total)
          : await _saveBill(repo, txRepo, debts, accounts, total);
      if (patch != null) widget.onPatch?.call(patch);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, eventErrorText(l, e), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// What to make in my books once the row is saved. New: what's ticked.
  /// Editing: a linked part unticked is unlinked (it stays in my books); a
  /// part ticked again takes its old rows back, and only the ones the server
  /// can't find are made anew.
  Future<({bool tx, bool debt, EventPatch? patch})> _syncBooks(
    ProjectsRepository repo,
    String rowId,
  ) async {
    final wantTx = _books && _bookTx;
    final wantDebt = _books && _bookDebt;
    if (!_editing) return (tx: wantTx, debt: wantDebt, patch: null);
    final want = {_txKind: wantTx, ProjectTransaction.bookDebt: wantDebt};
    final link = [
      for (final e in want.entries)
        if (e.value && !_linked(e.key)) e.key,
    ];
    final unlink = [
      for (final e in want.entries)
        if (!e.value && _linked(e.key)) e.key,
    ];
    if (link.isEmpty && unlink.isEmpty) {
      return (tx: false, debt: false, patch: null);
    }
    final r = await repo.setMyBooks(
      _view.project.id,
      rowId,
      link: link,
      unlink: unlink,
    );
    bool make(String kind) =>
        link.contains(kind) && !r.relinked.contains(kind);
    return (
      tx: make(_txKind),
      debt: make(ProjectTransaction.bookDebt),
      patch: r.patch,
    );
  }

  String get _day => projectDay(_date);
  String? get _desc => _title.text.trim().isEmpty ? null : _title.text.trim();
  String? get _noteText => _note.text.trim().isEmpty ? null : _note.text.trim();

  Future<EventPatch?> _saveBill(
    ProjectsRepository repo,
    TransactionsRepository txRepo,
    PersonalDebtsRepository debts,
    AccountsCubit accounts,
    double total,
  ) async {
    final projectId = _view.project.id;
    final type = _kind == EventEntryKind.income ? 'income' : 'expense';
    final payer = _payer!;
    final ordered = [payer, ..._people.where((p) => p != payer)];
    final resolved = await repo.resolvePeople(projectId, [
      for (final p in ordered) p.json,
    ]);
    final ids = {
      for (final (i, p) in ordered.indexed) p.key: resolved.memberIds[i],
    };
    final shares = _shares;
    final splits = [
      for (final p in ordered.skip(1))
        if ((shares[p.key] ?? 0) > 0.005)
          ProjectSplitInput(memberId: ids[p.key]!, amount: shares[p.key]!),
    ];
    final payerId = ids[payer.key]!;
    EventPatch patch;
    String rowId;
    ({bool tx, bool debt, EventPatch? patch}) books;
    var made = false;
    if (!_editing && _books && _iPaid && _bookTx) {
      // My tx is the whole bill on my wallet, linked to the new bill.
      final res = await repo.addBills(
        projectId,
        newTransaction: {
          'type': type,
          'amount': total,
          'date': _day,
          'account_id': ?_account?.id,
          'category_id': ?_category?.id,
          'description': ?_desc,
          'note': ?_noteText,
        },
        people: {
          'payer': const {'me': true},
          'members': [
            for (final p in ordered)
              {'member_id': ids[p.key], 'share': shares[p.key] ?? 0},
          ],
        },
      );
      accounts.patchBalances(res.accountBalances);
      patch = res.patch!;
      rowId = patch.row.firstWhere((r) => r.isParent).id;
      books = (tx: false, debt: _books && _bookDebt, patch: null);
      if (_tagIds.isNotEmpty) {
        patch = await repo.updateTransaction(
          projectId,
          rowId,
          tagIds: _tagIds.toList(),
        );
      }
    } else {
      patch = _editing
          ? await repo.updateTransaction(
              projectId,
              widget.row!.parent.id,
              amount: total,
              date: _day,
              description: _desc ?? '',
              note: _noteText ?? '',
              tagIds: _tagIds.toList(),
              splits: splits,
            )
          : await repo.createTransaction(
              projectId,
              transactionMemberId: payerId,
              type: type,
              amount: total,
              date: _day,
              description: _desc,
              note: _noteText,
              tagIds: _tagIds.toList(),
              splits: splits,
            );
      rowId = _editing
          ? widget.row!.parent.id
          : patch.row.firstWhere((r) => r.isParent).id;
      books = await _syncBooks(repo, rowId);
      if (books.patch case final p?) patch = p;
      if (_iPaid) {
        if (books.tx) {
          made = true;
          final created = await txRepo.create(
            type: type == 'income'
                ? TransactionType.income
                : TransactionType.expense,
            accountId: _account?.id,
            amount: total,
            date: _day,
            categoryId: _category?.id,
            description: _desc,
            note: _noteText,
            sourceProjectTransactionId: rowId,
          );
          accounts.patchBalances(created.accountBalances);
        }
      } else if (_meInBill) {
        final share = _myShare;
        final myRow = patch.row
            .where(
              (r) =>
                  r.parentProjectTransactionId == rowId &&
                  r.transactionMemberId == _view.me!.id,
            )
            .firstOrNull;
        if (books.debt && share > 0) {
          made = true;
          await debts.createEntry(
            payer.debtKey,
            direction: DebtEntryDirection.received,
            amount: share,
            description: _desc,
            note: _noteText,
            personName: payer.name,
            billId: rowId,
          );
        }
        if (books.tx && share > 0) {
          made = true;
          final created = await txRepo.create(
            type: TransactionType.expense,
            accountId: _account?.id,
            amount: share,
            date: _day,
            categoryId: _category?.id,
            description: _desc,
            note: _noteText,
            sourceProjectTransactionId: myRow?.id ?? rowId,
          );
          accounts.patchBalances(created.accountBalances);
        }
      }
    }
    // I paid: each other share is my debtor (not the ones who paid back now).
    if (_iPaid && books.debt) {
      made = made || _debtors.isNotEmpty;
      for (final p in _debtors) {
        await debts.createEntry(
          p.debtKey,
          direction: DebtEntryDirection.paid,
          amount: _shareOf(p),
          description: _desc,
          note: _noteText,
          personName: p.name,
          billId: rowId,
        );
      }
    }
    // The row's my_books after what was just made (a no-op call = its patch).
    if (made) patch = (await repo.setMyBooks(projectId, rowId)).patch;
    // "คืนแล้ว": each one paid the payer back on the spot → a payback row.
    for (final p in ordered.skip(1).where((p) => p.paidBack)) {
      final amount = shares[p.key] ?? 0;
      if (amount <= 0.005) continue;
      patch = await repo.createTransaction(
        projectId,
        transactionMemberId: ids[p.key]!,
        type: 'payback',
        amount: amount,
        date: _day,
        splits: [ProjectSplitInput(memberId: payerId, amount: amount)],
      );
      if (_books && _iPaid) {
        final backId = patch.row.firstWhere((r) => r.isParent).id;
        await debts.createRepayment(
          p.debtKey,
          kind: DebtRepaymentKind.receive,
          amount: amount,
          accountId: _account?.id,
          date: _date,
          personName: p.name,
          billId: backId,
        );
      }
    }
    return patch;
  }

  Future<EventPatch?> _savePayback(
    ProjectsRepository repo,
    PersonalDebtsRepository debts,
    double total,
  ) async {
    final projectId = _view.project.id;
    final from = _person(_fromKey)!;
    final to = _person(_toKey)!;
    final resolved = await repo.resolvePeople(projectId, [from.json, to.json]);
    final fromId = resolved.memberIds[0], toId = resolved.memberIds[1];
    final splits = [ProjectSplitInput(memberId: toId, amount: total)];
    var patch = _editing
        ? await repo.updateTransaction(
            projectId,
            widget.row!.parent.id,
            transactionMemberId: fromId,
            amount: total,
            date: _day,
            note: _noteText ?? '',
            splits: splits,
          )
        : await repo.createTransaction(
            projectId,
            transactionMemberId: fromId,
            type: 'payback',
            amount: total,
            date: _day,
            note: _noteText,
            splits: splits,
          );
    final rowId = _editing
        ? widget.row!.parent.id
        : patch.row.firstWhere((r) => r.isParent).id;
    final books = await _syncBooks(repo, rowId);
    if (books.patch case final p?) patch = p;
    if (_involved && (books.debt || books.tx)) {
      final iPay = from.isMe;
      final other = iPay ? to : from;
      // จดหนี้ first (the debt the payback clears), then the money.
      if (books.debt) {
        await debts.createEntry(
          other.debtKey,
          direction: iPay
              ? DebtEntryDirection.received
              : DebtEntryDirection.paid,
          amount: total,
          date: _date,
          note: _noteText,
          personName: other.name,
          billId: rowId,
        );
      }
      if (books.tx) {
        await debts.createRepayment(
          other.debtKey,
          kind: iPay ? DebtRepaymentKind.pay : DebtRepaymentKind.receive,
          amount: total,
          accountId: _account?.id,
          date: _date,
          note: _noteText,
          personName: other.name,
          billId: rowId,
        );
      }
      patch = (await repo.setMyBooks(projectId, rowId)).patch;
    }
    return patch;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final row = widget.row;
    if (row == null) return;
    final ok = await showConfirmDialog(
      context,
      title: l.projectTxDeleteTitle,
      message: '',
      confirmLabel: l.projectTxDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final patch = await context.read<ProjectsRepository>().deleteTransaction(
        _view.project.id,
        row.parent.id,
      );
      widget.onPatch?.call(patch);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, eventErrorText(l, e), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final books = _myBooks(l);
    const gap = SizedBox(height: AppSpacing.sm);
    final canSave =
        !_saving &&
        _total > 0 &&
        (_payback
            ? _fromKey != null && _toKey != null
            : _payer != null &&
                  _people
                              .where((p) => p.key != _payerKey)
                              .fold<double>(0, (s, p) => s + _shareOf(p)) -
                          _total <=
                      0.005);
    return QuickCreateSheetShell(
      title: _payback
          ? (_editing ? l.evbEditPayback : l.evbNewPayback)
          : (_editing ? l.evbEditBill : l.evbNewBill),
      subtitle: _view.project.name,
      saveLabel: l.commonSave,
      closeTooltip: UiConfig.stringsOf(context).close,
      deleteTooltip: l.projectTxDelete,
      deleteLabel: l.projectTxDelete,
      saving: _saving,
      onSave: canSave ? _save : null,
      onDelete: _editing && !(widget.row?.parent.locked ?? false)
          ? _delete
          : null,
      onCloseBlocked: () {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(l),
          gap,
          if (!_payback) ...[_tagsRow(l), gap],
          DraftFieldRow(
            label: l.commonNote,
            child: AppInput.inline(
              editing: true,
              controller: _note,
              maxLines: 3,
              maxLength: TextLimits.note,
              hint: l.txNoteAddHint,
            ),
          ),
          gap,
          if (!_payback) ...[_peopleCard(l), gap],
          ?books,
        ],
      ),
    );
  }
}
