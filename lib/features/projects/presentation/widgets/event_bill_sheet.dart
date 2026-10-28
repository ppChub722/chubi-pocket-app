import 'dart:async';
import 'dart:convert';

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
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_picker.dart'
    show TagPicker, askNewTagName;
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/category_pick_card.dart';
import '../../../transactions/presentation/widgets/event_pick.dart';
import '../../../transactions/presentation/widgets/event_picker.dart';
import '../../../transactions/presentation/widgets/pick_chip_rows.dart'
    show TagChipRow;
import '../../data/projects_repository.dart';
import '../../domain/event_bill.dart';
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
/// [booksOnly] (with [row]): only the "my books" card; saving puts my part in
/// my books and leaves the bill as it is (any member may).
Future<bool> showEventBillSheet(
  BuildContext context, {
  required ProjectView view,
  ProjectTxTree? row,
  EventEntryKind kind = EventEntryKind.expense,
  String? from,
  String? to,
  double? amount,
  ValueChanged<EventPatch>? onPatch,
  bool booksOnly = false,
}) async {
  // An existing bill opens from its own answer (my copy, rights, version):
  // the same form as from anywhere else (SA2).
  if (row != null) {
    return openEventBill(
      context,
      row.parent.id,
      onPatch: onPatch,
      booksOnly: booksOnly,
    );
  }
  return _showSheet(
    context,
    (_) => _EventBillSheet(
      view: view,
      kind: kind,
      from: from,
      to: to,
      amount: amount,
      onPatch: onPatch,
    ),
  );
}

/// 0.4.1-2 SA2 — THE bill form for an existing shared bill (event bill or
/// split bill), opened from anywhere by its id ([ptId]; a split row's id
/// answers its bill): ONE call (GET /event-bills/{pt_id}) on open. True =
/// saved or deleted.
Future<bool> openEventBill(
  BuildContext context,
  String ptId, {
  ValueChanged<EventPatch>? onPatch,
  bool booksOnly = false,
}) => _showSheet(
  context,
  (_) =>
      _EventBillLoadSheet(ptId: ptId, onPatch: onPatch, booksOnly: booksOnly),
);

Future<bool> _showSheet(BuildContext context, WidgetBuilder builder) async {
  context.read<AccountsCubit>().loadIfNeeded();
  context.read<CategoriesCubit>().loadIfNeeded();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    enableDrag: false,
    builder: builder,
  );
  return saved ?? false;
}

EventEntryKind _kindOf(ProjectTransaction p) => p.isPayback
    ? EventEntryKind.payback
    : (p.type == 'income' ? EventEntryKind.income : EventEntryKind.expense);

/// The board the form works on, built from the bill's own answer.
ProjectView _viewOf(EventBillView b) => ProjectView(
  project: Project(
    id: b.event.id,
    ownerUserId: '',
    name: b.isSplit ? '' : b.event.name,
    status: ProjectStatusWire.parse(b.event.status),
    canAddBill: b.rights.canEdit,
  ),
  members: b.members,
  txs: [b.tree.parent, ...b.tree.children],
  summary: null,
  currentUserId: null,
  eventTags: b.tags,
);

/// Loads the bill, then shows the form: a skeleton on the first load, a
/// full error + retry when it fails; 409 BILL_CHANGED swaps in the newer
/// bill it carries.
class _EventBillLoadSheet extends StatefulWidget {
  const _EventBillLoadSheet({
    required this.ptId,
    this.onPatch,
    this.booksOnly = false,
  });

  final String ptId;
  final ValueChanged<EventPatch>? onPatch;
  final bool booksOnly;

  @override
  State<_EventBillLoadSheet> createState() => _EventBillLoadSheetState();
}

class _EventBillLoadSheetState extends State<_EventBillLoadSheet> {
  EventBillView? _bill;
  Object? _error;

  /// Bumped when a newer bill replaces the form (its typed state resets).
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final b = await context.read<ProjectsRepository>().getEventBill(
        widget.ptId,
      );
      if (mounted) setState(() => _bill = b);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _replace(EventBillView b) => setState(() {
    _bill = b;
    _version++;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = _bill;
    if (b == null) {
      return QuickCreateSheetShell(
        title: l.evbEditBill,
        saveLabel: l.commonSave,
        closeTooltip: UiConfig.stringsOf(context).close,
        onCloseBlocked: () {},
        body: _error != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: ErrorView(error: _error!, onRetry: _load),
              )
            : const EntryCardSkeleton(),
      );
    }
    final rows = b.tree;
    return _EventBillSheet(
      key: ValueKey(_version),
      view: _viewOf(b),
      row: rows,
      bill: b,
      kind: _kindOf(rows.parent),
      onPatch: widget.onPatch,
      onChanged: _replace,
      // No right to edit the bill: my book only (as ⤓ ลงบัญชี).
      booksOnly: widget.booksOnly || !b.rights.canEdit,
    );
  }
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
  String name;
  final String? memberId;
  final String? contactId;
  final IconCode? iconCode;
  final PersonLevel level;
  final bool isMe;

  /// Not an event member yet: added on save.
  final bool isNew;

  bool paidBack = false;

  /// A name that was typed (no member, no contact): the row lets it be edited.
  bool get typed => !isMe && memberId == null && contactId == null;

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
    this.bill,
    this.onChanged,
    this.from,
    this.to,
    this.amount,
    this.onPatch,
    this.booksOnly = false,
    super.key,
  });

  final ProjectView view;
  final ProjectTxTree? row;

  /// The bill's own answer (an existing bill): rights, my copy, version.
  final EventBillView? bill;

  /// 409 BILL_CHANGED: the newer bill to show instead.
  final ValueChanged<EventBillView>? onChanged;
  final EventEntryKind kind;
  final String? from;
  final String? to;
  final double? amount;
  final ValueChanged<EventPatch>? onPatch;
  final bool booksOnly;

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

  /// The (first) payer: pays what the other payers leave, and keeps the
  /// "rest of the bill" share as before.
  String? _payerKey;

  /// 0.4.1-2 multi-payer: the OTHER payers with what each paid (key →
  /// amount); empty = one payer, today's look.
  final _morePayers = <String, double>{};

  bool get _multiPayer => _morePayers.isNotEmpty;

  /// What the first payer paid: the bill minus the other payers.
  double get _firstPaid =>
      _total - _morePayers.values.fold<double>(0, (s, v) => s + v);

  bool _isPayer(_Person p) =>
      p.key == _payerKey || _morePayers.containsKey(p.key);

  /// "ฝน" / "ฝน, ลี": every payer, for "จ่ายโดย …" / "คืน … แล้ว".
  String get _payerNames => [for (final p in _payers) p.name].join(', ');

  /// The payers, the first one first.
  List<_Person> get _payers => [
    ?_payer,
    for (final k in _morePayers.keys) ?_person(k),
  ];

  /// Shares the user typed (key → amount); everyone else splits the rest.
  final _typed = <String, double>{};

  late String? _fromKey;
  late String? _toKey;

  bool _books = false;
  bool _bookDebt = true;
  bool _bookTx = false;

  /// A payback's จดหนี้ was ticked / unticked by hand (else the server
  /// decides, E5).
  bool _debtTouched = false;

  /// The row's parts in my books when the sheet opened (editing).
  List<String> _wasBooked = const [];
  Account? _account;
  Category? _category;
  bool _saving = false;

  /// My copy's own fields (SA3, never synced): my personal tags and my
  /// private note.
  final _myTagIds = <String>{};
  final _knownTags = <String, Tag>{};
  final _privateNote = TextEditingController();

  /// S17 / SA9: where the bill moves on save (another event, a new one, or
  /// out of its event into a split bill); null = it stays.
  EventTarget? _moveTo;

  ProjectView get _view => widget.view;
  bool get _editing => widget.row != null;

  /// A new bill picks its payer; an existing one when the BE allows it
  /// (owner Q-B4, `rights.can_change_payer`; not on a payback).
  bool get _canChangePayer =>
      !_editing || (widget.bill?.rights.canChangePayer ?? false);

  bool get _isSplit => widget.bill?.isSplit ?? false;
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

  /// I'm among the payers (all or part of the bill).
  bool get _iPaid =>
      (_payer?.isMe ?? false) ||
      (_myKey != null && _morePayers.containsKey(_myKey));

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
          // "คืนแล้ว" as saved: an unticked one would remove its payback.
          final m = _Person.member(_view.memberOf(c))..paidBack = c.paidBack;
          _people.add(m);
          _typed[m.key] = c.amount;
        }
        _payerKey = payer.key;
        // Several payers: the first is the bill's member (the biggest); the
        // others with what they paid (one who has no share joins at 0).
        for (final x in p.payers) {
          if (x.member.id == payer.memberId) continue;
          final m = _person('m:${x.member.id}');
          final who = m ?? _Person.member(_view.member(x.member.id));
          if (m == null) {
            _people.add(who);
            _typed[who.key] = 0;
          }
          _morePayers[who.key] = x.amount;
        }
      }
      _wasBooked = p.myBooks;
    }
    // A payback: จดหนี้ + รับคืน / จ่ายคืน both on (the debt and its money);
    // whether จดหนี้ is needed comes from the BE preview ([_debtOn]).
    _bookTx = _payback || _iPaid;
    // Editing shows the row as it is: the switch and ticks = what's linked.
    if (_wasBooked.isNotEmpty) {
      _books = true;
      _bookTx = _linked(_txKind);
      _bookDebt = _linked(ProjectTransaction.bookDebt);
    }
    // ⤓ ลงบัญชี: what's linked stays, the rest ticked as for a new bill.
    if (widget.booksOnly) {
      _books = true;
      _bookTx = _bookTx || _payback || _iPaid;
      _bookDebt = true;
    }
    if (!_payback) _initMyCopy();
    _amount.addListener(_changed);
  }

  /// A bill's copy (SA3): always in my book (tx + debts) unless I
  /// disconnected it; my own fields start from my copy transaction.
  void _initMyCopy() {
    final copy = widget.bill?.myCopy;
    _books = copy?.connected ?? true;
    _bookTx = _bookDebt = true;
    final tx = copy?.transaction;
    if (tx == null) return;
    _category = tx.category?.toCategory();
    final accountId = tx.accountId;
    if (accountId != null) {
      _account = context.read<AccountsCubit>().byId(accountId);
    }
    for (final t in tx.tags) {
      _myTagIds.add(t.id);
      _knownTags[t.id] = t.asTag;
    }
    _privateNote.text = copy?.privateNote ?? '';
  }

  bool get _involved => _fromKey == _myKey || _toKey == _myKey;

  void _changed() => setState(() {});

  // ---------- the BE preview (?preview=true) behind the before → after ----

  /// What the save would move, for the body now on screen (E8); null = none
  /// yet (no before → after lines until it comes; the app has no estimate of
  /// its own, SA4).
  EventBillBookPreview? _preview;
  String? _previewAsked;
  Timer? _previewTimer;

  /// The body [_preview] answers; != [_previewKey] = a newer one is on its way.
  String? _previewFor;

  /// The body the preview is for; null = nothing to preview (my book off, or
  /// the bill not complete yet).
  String? get _previewKey {
    if (!_books || _view.me == null || _total <= 0) return null;
    if (_payback ? (_fromKey == null || _toKey == null) : _payer == null) {
      return null;
    }
    return jsonEncode({'bill': _billBody, 'books': _booksBody});
  }

  /// After each build: a changed body asks the BE again (debounced); a
  /// failure drops the lines (none rather than wrong ones).
  void _schedulePreview() {
    final want = _previewKey;
    if (want == _previewAsked) return;
    _previewAsked = want;
    _previewTimer?.cancel();
    if (want == null) return;
    _previewTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final p = await context.read<ProjectsRepository>().previewEventBill(
          ptId: widget.row?.parent.id,
          projectId: _view.project.id,
          bill: _billBody,
          myBooks: _booksBody,
        );
        if (mounted && _previewAsked == want) {
          setState(() {
            _preview = p;
            _previewFor = want;
          });
        }
      } catch (_) {
        if (mounted && _previewAsked == want) {
          setState(() {
            _preview = null;
            _previewFor = null;
          });
        }
      }
    });
  }

  /// A payback's จดหนี้ as the save would do it: the BE's default until the
  /// user ticks it by hand (no second debt when my book holds it, E5).
  bool get _debtOn =>
      _payback &&
          !_debtTouched &&
          !_linked(ProjectTransaction.bookDebt) &&
          _preview != null
      ? _preview!.debtDefault
      : _bookDebt;

  @override
  void dispose() {
    _previewTimer?.cancel();
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    _privateNote.dispose();
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
  void _splitEqual() => setState(_typed.clear);

  /// The new payer; my copy follows its role by itself (SA3: the whole bill
  /// when I paid, my share "จ่ายโดย X" when someone else did).
  void _setPayer(_Person p) => setState(() {
    _payerKey = p.key;
    p.paidBack = false;
    _typed.remove(p.key);
  });

  void _remove(_Person p) => setState(() {
    _people.remove(p);
    _typed.remove(p.key);
    _morePayers.remove(p.key);
    if (_payerKey == p.key) _payerKey = _people.firstOrNull?.key;
  });

  // ---------- payers (0.4.1-2 multi-payer) ----------

  /// "+ เพิ่มคนจ่าย": someone in the bill paid a part too (starts at 0, the
  /// first payer pays the rest).
  Future<void> _addPayer() async {
    final l = AppLocalizations.of(context)!;
    final r = await showItemPicker(
      context,
      ItemPickerSheet(
        title: l.evbAddPayer,
        items: [
          for (final p in _people)
            if (!_isPayer(p))
              PickerItem(id: p.key, title: p.name, leading: _personAvatar(p)),
        ],
      ),
    );
    final key = r?.id;
    if (key == null || !mounted) return;
    setState(() {
      _morePayers[key] = 0;
      _person(key)?.paidBack = false;
    });
  }

  void _setPaid(_Person p, double? v) =>
      setState(() => _morePayers[p.key] = v ?? 0);

  /// A payer leaves the คนจ่าย list (stays in the bill); the first payer's
  /// place goes to the next one.
  void _removePayer(_Person p) => setState(() {
    if (p.key != _payerKey) {
      _morePayers.remove(p.key);
      return;
    }
    final next = _morePayers.keys.firstOrNull;
    if (next == null) return;
    _morePayers.remove(next);
    _payerKey = next;
    _typed.remove(next);
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
      // Members are the picker's ticks: unticked members leave the bill (a
      // payer that can't change stays).
      _people.removeWhere(
        (p) =>
            p.memberId != null &&
            !keep.contains(p.memberId) &&
            !p.isMe &&
            !(!_canChangePayer && p.key == _payerKey),
      );
      for (final id in r.memberIds) {
        if (_people.any((p) => p.memberId == id)) continue;
        final m = _view.currentMembers.where((m) => m.id == id).firstOrNull;
        if (m != null) _people.add(_Person.member(m));
      }
      for (final pick in r.picks) {
        final added = _personOfPick(pick);
        if (!_people.any((p) => p.key == added.key)) _people.add(added);
      }
      if (_person(_payerKey) == null) _payerKey = _people.firstOrNull?.key;
    });
  }

  static _Person _personOfPick(ContactPick pick) => switch (pick) {
    ContactPicked(:final Contact contact) => _Person(
      key: 'c:${contact.id}',
      name: contact.name,
      contactId: contact.id,
      iconCode: contact.iconCode,
      level: contact.isLinked ? PersonLevel.linked : PersonLevel.contact,
      isNew: true,
    ),
    ContactNamePicked(:final name) || ContactNameTyped(:final name) => _Person(
      key: 'n:${name.trim().toLowerCase()}',
      name: name,
      isNew: true,
    ),
  };

  /// Pick somebody else for a row: it keeps its place, its share and the
  /// payer mark.
  Future<void> _changePerson(_Person p) async {
    final r = await ContactPicker.one(
      context,
      selectedId: p.contactId,
      allowFreeText: true,
      allowCreate: true,
      initialName: p.typed ? p.name : null,
    );
    if (r == null || !mounted) return;
    final next = _personOfPick(r);
    if (_people.any((x) => x.key == next.key && x != p)) return;
    setState(() {
      final i = _people.indexOf(p);
      if (i < 0) return;
      _people[i] = next;
      if (_payerKey == p.key) _payerKey = next.key;
      final share = _typed.remove(p.key);
      if (share != null) _typed[next.key] = share;
      final paid = _morePayers.remove(p.key);
      if (paid != null) _morePayers[next.key] = paid;
    });
  }

  // ---------- pickers ----------

  Future<void> _pickDate() async {
    final r = await AppDatePicker.show(
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

  /// My balance with [p] before → after the save (> 0: they owe me), from the
  /// BE preview only (SA4); null = no preview yet. A person the save doesn't
  /// touch is not in the answer: unchanged at 0.
  ({double before, double after})? _balanceWith(_Person p) {
    final preview = _preview;
    if (preview == null) return null;
    return preview.people[p.debtKey] ?? (before: 0, after: 0);
  }

  /// What the save does to [_account], from the preview ("−฿100"); a wallet
  /// the preview doesn't list doesn't move.
  String _walletLine(AppLocalizations l) {
    final id = _account?.id;
    final w = id == null ? null : _preview?.wallets[id];
    final delta = w == null ? 0.0 : w.after - w.before;
    if (delta.abs() < 0.005) return l.debtWalletNotUsed;
    return '${delta < 0 ? '−' : '+'}${moneyString(context, delta.abs())}';
  }

  String _sideText(AppLocalizations l, double net) {
    final money = moneyString(context, net.abs());
    if (net > 0.005) return '${l.debtRoleDebtor} $money';
    if (net < -0.005) return '${l.debtRoleCreditor} $money';
    return l.evbNoDebt;
  }

  /// Category (bills) + wallet; [paidBy] = someone else paid and I haven't
  /// paid them back: the wallet slot reads "จ่ายโดย X" and takes no wallet.
  Widget _pickCards(
    AppLocalizations l, {
    required bool walletOptional,
    _Person? paidBy,
  }) => IntrinsicHeight(
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
            account: paidBy == null ? _account : null,
            label: l.transactionFormAccountLabel,
            placeholder: walletOptional
                ? l.evbNoWallet
                : l.transactionFormAccountNone,
            dense: true,
            editable: paidBy == null,
            paidBy: paidBy == null ? null : l.evbPaidByName(_payerNames),
            paidByAvatar: paidBy == null ? null : _personAvatar(paidBy),
            onTap: paidBy == null ? _pickAccount : null,
          ),
        ),
      ],
    ),
  );

  /// The person a debt / repayment is with: avatar, name, their state before
  /// → after, and what this save does to the debt (เพิ่มหนี้ / ลดหนี้), all
  /// from the BE preview; no preview yet = the name only, no change = no chip.
  Widget _personLine(_Person p) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final b = _balanceWith(p);
    final delta = b == null ? 0.0 : b.after - b.before;
    final changes = delta.abs() >= 0.005;
    final up = b != null && b.after.abs() > b.before.abs();
    final what = b == null
        ? null
        : changes
        ? '${_sideText(l, b.before)} → ${_sideText(l, b.after)}'
        : _sideText(l, b.before);
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
              if (what != null)
                Text(
                  what,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (changes)
          AppChip(
            label:
                '${up ? l.evbDebtUp : l.evbDebtDown} '
                '${moneyString(context, delta.abs())}',
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

  /// The before → after box for [p] (preview only); none until the first
  /// preview, dimmed while a newer one is on its way.
  Widget? _resultBox(AppLocalizations l, _Person p, {required bool wallet}) {
    final b = _balanceWith(p);
    if (b == null) return null;
    return DebtResultBox(
      nowLabel: l.debtResultNow(p.name),
      before: _sideText(l, b.before),
      afterLabel: l.debtResultAfterSave,
      after: _sideText(l, b.after),
      walletLabel: wallet
          ? (_account?.name ?? l.transactionFormAccountLabel)
          : l.transactionFormAccountLabel,
      walletValue: wallet ? _walletLine(l) : l.debtWalletNotUsed,
      loading: _previewFor != _previewKey,
    );
  }

  Widget? _myBooks(AppLocalizations l) =>
      _payback ? _paybackBooks(l) : _myCopy(l);

  /// 0.4.1-2 SA3 — MY copy of the bill: booked whenever I'm in it (my
  /// transaction + my debts of it, one value with the bill); only the
  /// category, the wallet, my tags and my private note are mine. Someone
  /// else paid → the wallet slot reads "จ่ายโดย X" until I tick "คืน X แล้ว".
  /// A copy I disconnected offers "เชื่อมใหม่".
  Widget? _myCopy(AppLocalizations l) {
    final me = _myKey == null ? null : _person(_myKey);
    final involved = _iPaid || me != null || widget.bill?.myCopy != null;
    if (!involved || _view.me == null) return null;
    if (!_books) {
      return ShareCard(
        title: l.evbMyCopy,
        rows: [
          AppMessage(
            message: l.evbCopyDisconnected,
            actions: [
              AppMessageAction(
                label: l.evbReconnect,
                onPressed: () => setState(() => _books = true),
              ),
            ],
          ),
        ],
      );
    }
    final payer = _payer;
    final paidByOther = !_iPaid && payer != null && !(me?.paidBack ?? false);
    final rows = <Widget>[
      if (widget.bill?.myCopy case final copy?
          when copy.connected && copy.inSync == false)
        AppMessage(
          message: l.evbCopyOutOfSync,
          tone: Tone.warning,
          actions: [
            AppMessageAction(label: l.evbApplyBill, onPressed: _applyBill),
          ],
        ),
      _pickCards(l, walletOptional: true, paidBy: paidByOther ? payer : null),
      if (!_iPaid && payer != null && me != null)
        LinkSwitchRow(
          label: l.evbPaidBackName(_payerNames),
          value: me.paidBack,
          onChanged: (v) => setState(() => me.paidBack = v),
        ),
      TagChipRow(
        selected: _myTagIds,
        known: _knownTags,
        onRemove: (id) => setState(() => _myTagIds.remove(id)),
        onMore: _pickMyTags,
      ),
      DraftFieldRow(
        label: l.evbPrivateNote,
        child: AppInput.inline(
          editing: true,
          controller: _privateNote,
          maxLines: 2,
          maxLength: TextLimits.note,
          hint: l.evbPrivateNoteHint,
        ),
      ),
      ?_debtSummary(l),
    ];
    return ShareCard(
      title: l.evbMyCopy,
      rows: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          r,
        ],
      ],
    );
  }

  /// SA5 — the debts this save moves, from the BE preview only, plus the
  /// people ticked "คืนแล้ว"; none before the first preview.
  Widget? _debtSummary(AppLocalizations l) {
    final preview = _preview;
    if (preview == null) return null;
    final lines = <BillDebtLine>[];
    for (final p in _people) {
      if (p.isMe) continue;
      final b = _balanceWith(p);
      final delta = b == null ? 0.0 : b.after - b.before;
      if (b != null && delta.abs() >= 0.005) {
        final up = b.after.abs() > b.before.abs();
        lines.add(
          BillDebtLine(
            avatar: _personAvatar(p),
            name: p.name,
            state: '${_sideText(l, b.before)} → ${_sideText(l, b.after)}',
            chip:
                '${up ? l.evbDebtUp : l.evbDebtDown} '
                '${moneyString(context, delta.abs())}',
            chipTone: up ? AppChipTone.warning : AppChipTone.success,
          ),
        );
      } else if (p.paidBack && !_isPayer(p)) {
        lines.add(
          BillDebtLine(
            avatar: _personAvatar(p),
            name: p.name,
            chip: l.evbPaidBack,
            chipTone: AppChipTone.success,
          ),
        );
      }
    }
    if (lines.isEmpty) return null;
    return BillDebtSummary(lines: lines, loading: _previewFor != _previewKey);
  }

  Future<void> _pickMyTags() async {
    final next = await TagPicker.many(context, selected: _myTagIds);
    if (next == null || !mounted) return;
    setState(() {
      for (final t in next.tags) {
        _knownTags[t.id] = t;
      }
      _myTagIds
        ..clear()
        ..addAll(next.ids);
    });
  }

  /// "อัปเดตตาม": my copy takes the bill as it is now (S7, one call); the
  /// form reloads with it.
  Future<void> _applyBill() async {
    final l = AppLocalizations.of(context)!;
    final row = widget.row;
    if (row == null) return;
    final repo = context.read<ProjectsRepository>();
    setState(() => _saving = true);
    try {
      await repo.applyEventBill(row.parent.id);
      final fresh = await repo.getEventBill(row.parent.id);
      if (mounted) widget.onChanged?.call(fresh);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(context, eventErrorText(l, e), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// A payback's book: จดหนี้ (the debt it clears) + รับคืน / จ่ายคืน (the
  /// money), as before 0.4.1-2 (V11 widens the debt-type bill).
  Widget? _paybackBooks(AppLocalizations l) {
    final involved = _booked || _involved;
    if (!involved || _view.me == null) return null;
    // A part already linked changes nothing in my books (no pickers); the
    // before → after lines come from the BE preview; unticking it unlinks it.
    final txLinked = _linked(_txKind);
    final rows = <Widget>[];
    if (_books) {
      {
        final other = _person(_fromKey == _myKey ? _toKey : _fromKey);
        final iPay = _fromKey == _myKey;
        if (other != null) {
          // จดหนี้ puts the event's debt in my books (they owe me / I owe
          // them); รับคืน / จ่ายคืน is the money that clears it. Both = even.
          final box = _resultBox(l, other, wallet: true);
          rows.addAll([
            BookOptionCard(
              icon: AppIcons.debt,
              title: l.evbRecordDebt,
              subtitle: iPay
                  ? l.evbBookDebtLine(other.name)
                  : l.evbTheyOweMe(other.name),
              amount: MoneyText(_total),
              checked: _debtOn,
              onChanged: (v) => setState(() {
                _bookDebt = v;
                _debtTouched = true;
              }),
              child: _personLine(other),
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
            ?box,
          ]);
        }
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
    final level = p.level == PersonLevel.linked ? PersonLevel.contact : p.level;
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
    // ฉัน first, the rest as added: choosing who paid never moves a row.
    final ordered = [
      ..._people.where((p) => p.isMe),
      ..._people.where((p) => !p.isMe),
    ];
    BillPerson row(_Person p) {
      final payer = p.key == _payerKey;
      // A payer that can't change: no จ่าย, no other person, no ✕ for that
      // row.
      final payerFixed = payer && !_canChangePayer;
      return BillPerson(
        id: p.key,
        name: p.name,
        avatar: _personAvatar(p),
        isMe: p.isMe,
        editableName: p.typed && !payerFixed,
        onName: (v) => setState(() => p.name = v),
        onChangePerson: payerFixed ? null : () => _changePerson(p),
        amount: shares[p.key],
        auto: !payer && !_typed.containsKey(p.key),
        onAmount: payer
            ? null
            : (v) => setState(() {
                if (v == null) {
                  _typed.remove(p.key);
                } else {
                  _typed[p.key] = v;
                }
              }),
        // Several payers: who paid is the คนจ่าย card's; here only shares.
        paid: payer && !_multiPayer,
        onPay: payer || !_canChangePayer || _multiPayer
            ? null
            : () => _setPayer(p),
        canPaidBack: !_isPayer(p) && _payer != null,
        paidBack: p.paidBack,
        onPaidBack: () => setState(() => p.paidBack = !p.paidBack),
        tag: p.isNew
            ? AppChip(
                label: l.txLinkCardNewToEvent,
                size: ChipSize.mini,
                tone: AppChipTone.info,
              )
            : null,
        onRemove: _people.length > 1 && !payerFixed ? () => _remove(p) : null,
      );
    }

    return BillPeopleCard(
      title: l.evbPeople(_people.length),
      people: [for (final p in ordered) row(p)],
      onEqually: _typed.isEmpty ? null : _splitEqual,
      onAdd: _addPeople,
      maxRows: 5,
      status: _total <= 0
          ? null
          : over > 0.005
          ? ShareStatus(l.txLinkCardOver(moneyString(context, over)), ok: false)
          : ShareStatus(l.txLinkCardSplitOk, ok: true),
    );
  }

  /// 0.4.1-2 multi-payer — "คนจ่าย" above "คนหาร": one payer = a "+ เพิ่ม
  /// คนจ่าย" row (the จ่าย mark stays on the people rows, today's look);
  /// several = their own card, each with what they paid (Σ = the bill; the
  /// first pays the rest).
  Widget? _payersSection(AppLocalizations l) {
    if (_payback || _payer == null) return null;
    final canAdd = _canChangePayer && _people.any((p) => !_isPayer(p));
    if (!_multiPayer) {
      if (!canAdd) return null;
      return DraftFieldRow(
        label: l.evbPayersLabel,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: l.evbAddPayer,
            icon: AppIcons.add,
            dashed: true,
            onTap: _addPayer,
          ),
        ),
      );
    }
    final first = _firstPaid;
    return BillPeopleCard(
      title: l.evbPayers(_morePayers.length + 1),
      addLabel: l.evbAddPayer,
      showEqually: false,
      onAdd: canAdd ? _addPayer : () {},
      people: [
        for (final p in _payers)
          BillPerson(
            id: 'pay:${p.key}',
            name: p.name,
            avatar: _personAvatar(p),
            isMe: p.isMe,
            amount: p.key == _payerKey ? first : _morePayers[p.key],
            // The first payer pays what the others leave.
            auto: p.key == _payerKey,
            onAmount: p.key == _payerKey || !_canChangePayer
                ? null
                : (v) => _setPaid(p, v),
            onRemove: _canChangePayer ? () => _removePayer(p) : null,
          ),
      ],
      status: _total <= 0
          ? null
          : first < 0.005
          ? ShareStatus(
              l.txLinkCardOver(moneyString(context, -first)),
              ok: false,
            )
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

  /// ONE call, ONE DB transaction (0.4.1-1 E8): the bill (or payback), the
  /// payback rows of the people marked "คืนแล้ว" and my book. The server
  /// books "คืนแล้ว" and who owes whom (E2–E5); the app sends the ticks.
  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_total <= 0) return;
    if (_payback && (_fromKey == null || _toKey == null)) return;
    if (!_payback && _payer == null) return;
    final repo = context.read<ProjectsRepository>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final row = widget.row;
      // My edit of the bill is my book too (linked = synced): the BE makes
      // my copy follow the bill I save (0.4.1-2).
      final r = row != null
          ? await repo.rebookEventBill(
              row.parent.id,
              bill: _billBody,
              myBooks: _booksBody,
              // Someone saved it since the form loaded → 409 BILL_CHANGED.
              expectedUpdatedAt: widget.bill?.updatedAt,
              move: _moveBody,
            )
          : await repo.bookEventBill(
              projectId: _view.project.id,
              bill: _billBody!,
              myBooks: _booksBody,
            );
      // Wallets and people follow the answer's effects (B2) by themselves.
      widget.onPatch?.call(r.patch);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final details = e.details ?? const <String, dynamic>{};
      final newer = e.code == 'BILL_CHANGED' ? details['bill'] : null;
      if (newer is Map && widget.onChanged != null) {
        // "บิลถูกแก้แล้ว โหลดใหม่": the bill as it is now replaces the form.
        showAppSnackBar(context, l.evbBillChanged, tone: Tone.warning);
        widget.onChanged!(EventBillView.fromJson(newer.cast()));
        return;
      }
      showAppSnackBar(context, eventErrorText(l, e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// EventBillMove for [_moveTo]: the people come along, every copy stays
  /// connected (same bill).
  Map<String, dynamic>? get _moveBody => switch (_moveTo) {
    null => null,
    ExistingEventTarget(:final project) => {'project_id': project.id},
    NewEventTarget(:final name) => {
      'new_event': {'name': name},
    },
    RemoveFromEvent() => const {'split': true},
  };

  /// The bill's event (or "บิลแบ่งจ่าย"), and where it will move.
  String _eventName(AppLocalizations l) => switch (_moveTo) {
    null => _isSplit ? l.evbSplitBill : _view.project.name,
    ExistingEventTarget(:final project) => project.name,
    NewEventTarget(:final name) => l.quickEventNewNamed(name),
    RemoveFromEvent() => l.evbSplitBill,
  };

  Future<void> _pickMove() async {
    final r = await EventPicker.one(
      context,
      suggestedName: _title.text.trim(),
      // Out of an event = a split bill ("เอาออกจากอีเวนต์").
      currentProjectId: _isSplit ? null : _view.project.id,
      showClosed: false,
    );
    if (r == null || !mounted) return;
    final back = switch (r) {
      ExistingEventTarget(:final project) => project.id == _view.project.id,
      RemoveFromEvent() => _isSplit,
      NewEventTarget() => false,
    };
    setState(() => _moveTo = back ? null : r);
  }

  String get _day => projectDay(_date);
  String? get _desc => _title.text.trim().isEmpty ? null : _title.text.trim();
  String? get _noteText => _note.text.trim().isEmpty ? null : _note.text.trim();

  /// The bill as `EventBillInput`; null = my book only (⤓ ลงบัญชี). Every
  /// person but the payer with their share (the payer's is the rest) and
  /// "คืนแล้ว"; a payback = from → to.
  Map<String, dynamic>? get _billBody {
    if (widget.booksOnly) return null;
    if (_payback) {
      return {
        'kind': 'payback',
        'amount': _total,
        'date': _day,
        'note': _noteText,
        'from': _person(_fromKey)!.json,
        'to': _person(_toKey)!.json,
      };
    }
    final payer = _payer!;
    final shares = _shares;
    return {
      'kind': _kind == EventEntryKind.income ? 'income' : 'expense',
      'amount': _total,
      'date': _day,
      'description': _desc,
      'note': _noteText,
      'tag_ids': _tagIds.toList(),
      // An existing bill takes its payers only when they may change (Q-B4).
      // Several payers (0.4.1-2): `payers` + EVERY share listed (Σ = the
      // bill); one payer: `payer`, whose share is the rest.
      if (_canChangePayer && _multiPayer)
        'payers': [
          for (final p in _payers)
            {
              ...p.json,
              'amount': p.key == payer.key ? _firstPaid : _morePayers[p.key],
            },
        ]
      else if (_canChangePayer)
        'payer': payer.json,
      'members': [
        for (final p in _people)
          if (_multiPayer || p.key != payer.key)
            {
              ...p.json,
              'share': shares[p.key] ?? 0,
              'paid_back': !_isPayer(p) && p.paidBack,
            },
      ],
    };
  }

  /// What my book should hold of the bill (`EventBillBooks`); on an edit a
  /// linked part unticked is unlinked by the server, its rows stay. A
  /// payback's debt the user didn't touch = null: the server decides (no
  /// second debt when my book already holds it, E5).
  Map<String, dynamic> get _booksBody => _payback
      ? {
          'on': _books,
          'tx': _bookTx,
          'debt': !_debtTouched && !_linked(ProjectTransaction.bookDebt)
              ? null
              : _bookDebt,
          'account_id': _account?.id,
        }
      // A bill's copy (SA3): tx + debts together; only my own fields vary
      // (the wallet is ignored while "จ่ายโดย X").
      : {
          'on': _books,
          'tx': true,
          'debt': true,
          'account_id': _account?.id,
          'category_id': _category?.id,
          'tag_ids': _myTagIds.toList(),
          'private_note': _privateNote.text.trim().isEmpty
              ? null
              : _privateNote.text.trim(),
        };

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
      // One call (0.4.1-2): the bill, my copy and debts of it; the others'
      // copies by their switch. A split bill answers no event patch.
      final r = await context.read<ProjectsRepository>().deleteEventBill(
        row.parent.id,
      );
      final patch = r.patch;
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

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final books = _myBooks(l);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _schedulePreview();
    });
    const gap = SizedBox(height: AppSpacing.sm);
    if (widget.booksOnly) {
      final p = widget.row!.parent;
      return QuickCreateSheetShell(
        title: l.evbBookMine,
        subtitle: p.description ?? (_isSplit ? null : _view.project.name),
        saveLabel: l.commonSave,
        saveIcon: AppIcons.save,
        closeTooltip: UiConfig.stringsOf(context).close,
        saving: _saving,
        onSave: !_saving && _total > 0 && books != null ? _save : null,
        onCloseBlocked: () {},
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?books],
        ),
      );
    }
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
                      0.005 &&
                  // Several payers: each paid something, the first too.
                  (!_multiPayer ||
                      (_firstPaid > 0.005 &&
                          _morePayers.values.every((v) => v > 0.005))));
    return QuickCreateSheetShell(
      title: _payback
          ? (_editing ? l.evbEditPayback : l.evbNewPayback)
          : (_editing ? l.evbEditBill : l.evbNewBill),
      subtitle: _isSplit ? l.evbSplitBill : _view.project.name,
      saveLabel: l.commonSave,
      closeTooltip: UiConfig.stringsOf(context).close,
      deleteTooltip: l.projectTxDelete,
      deleteLabel: l.projectTxDelete,
      saving: _saving,
      onSave: canSave ? _save : null,
      onDelete:
          _editing &&
              (widget.bill?.rights.canDelete ??
                  !(widget.row?.parent.locked ?? false))
          ? _delete
          : null,
      onCloseBlocked: () {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(l),
          gap,
          // A split bill has no event tags.
          if (!_payback && !_isSplit) ...[_tagsRow(l), gap],
          // S17: move to another event / out into a split bill (one save).
          if (widget.bill?.rights.canMove ?? false) ...[
            DraftFieldRow(
              label: l.quickEventLabel,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppChip(
                  label: _eventName(l),
                  icon: AppIcons.project,
                  dashed: true,
                  selected: _moveTo != null,
                  onTap: _pickMove,
                ),
              ),
            ),
            gap,
          ],
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
          if (_payersSection(l) case final payers?) ...[payers, gap],
          if (!_payback) ...[_peopleCard(l), gap],
          ?books,
        ],
      ),
    );
  }
}
