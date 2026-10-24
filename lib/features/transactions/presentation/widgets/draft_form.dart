import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/category_label.dart';
import 'category_pick_card.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/widgets/member_pick_card.dart';
import '../../../projects/presentation/widgets/member_picker.dart';
import '../../../projects/presentation/widgets/project_common.dart';
import '../../../projects/presentation/cubit/project_directory_cubit.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../../domain/link_draft.dart';
import 'event_pick.dart';
import 'event_picker.dart';
import 'link_section.dart';
import 'pick_chip_rows.dart';
import 'splits_section.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';

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
    _applyEventMode(hasEvent: id != null);
    notifyListeners();
  }

  /// An event was picked or cleared elsewhere (the sheet's / the page's own
  /// state): the แบ่ง tab follows it.
  void eventChanged({required bool hasEvent}) {
    _applyEventMode(hasEvent: hasEvent);
    notifyListeners();
  }

  /// แบ่ง with an event is อีเวนต์; without one it is จ่ายแทน when someone
  /// else paid, else แบ่ง. What was typed goes with the bill: shares and my
  /// share one way, the payer the other.
  void _applyEventMode({required bool hasEvent}) {
    final from = link.mode;
    if (from == null || from == LinkMode.personal) return;
    final wasEvent = from == LinkMode.event;
    if (wasEvent && !hasEvent) {
      final payer = link.eventPayer;
      link.paidBy = payer?.memberId == null ? payer : null;
    }
    final to = hasEvent
        ? LinkMode.event
        : link.paidBy != null
        ? LinkMode.paid
        : LinkMode.split;
    if (to == from) return;
    if (to == LinkMode.event) {
      for (final s in splits) {
        final owed = s.owedAmount ?? 0;
        if (s.personName.trim().isEmpty || owed <= 0) continue;
        link.eventShares[_draftPerson(s).key] = owed;
      }
      if (!meAuto) {
        link
          ..eventMeAuto = false
          ..eventMeTyped = meAmount;
      }
    } else if (wasEvent) {
      for (final s in splits) {
        final share = link.eventShares[_draftPerson(s).key];
        if (share != null) s.owedAmount = share;
      }
      if (!link.eventMeAuto) {
        meAuto = false;
        _meTyped = link.eventMeTyped;
      }
    }
    link.switchTo(to, from: from);
  }

  static LinkPerson _draftPerson(SplitDraft s) => LinkPerson(
    name: s.personName.trim(),
    contactId: s.contactId,
    person: s.person,
  );

  /// The name of a typed row was edited: its share and the payer mark follow.
  void renameDraft(SplitDraft d, String name) {
    final before = _draftPerson(d);
    d.personName = name;
    rekeyDraft(before, d);
  }

  /// [d] is somebody else now (or renamed): what was keyed to [before] (its
  /// event share, being the payer) moves to the new person.
  void rekeyDraft(LinkPerson before, SplitDraft d) {
    final after = _draftPerson(d);
    if (before.key != after.key) {
      final share = link.eventShares.remove(before.key);
      if (share != null) link.eventShares[after.key] = share;
      if (link.paidBack.remove(before.key)) link.paidBack.add(after.key);
      if (link.paidBy?.key == before.key) link.paidBy = after;
      final payer = link.eventPayer;
      if (payer != null && payer.memberId == null && payer.key == before.key) {
        link.eventPayer = after;
      }
    }
    setSplits(List.of(splits));
  }

  /// A row taken off the bill.
  void removeDraft(SplitDraft d) {
    link.paidBack.remove(_draftPerson(d).key);
    setSplits([
      for (final s in splits)
        if (!identical(s, d)) s,
    ]);
  }

  bool isPaidBack(LinkPerson p) => link.paidBack.contains(p.key);

  /// "จ่าย" or "คืนแล้ว" was pressed on a row that has no name yet: it can be
  /// pressed, but the bill can't be saved until the name is there.
  bool markedWithoutName(LinkMode mode) {
    final payer = switch (mode) {
      LinkMode.event => link.eventPayer,
      LinkMode.paid => link.paidBy,
      _ => null,
    };
    if (payer != null && payer.name.trim().isEmpty) return true;
    final backApplies = mode == LinkMode.event || mode == LinkMode.split;
    return backApplies &&
        link.paidBack.contains(const LinkPerson(name: '').key);
  }

  void togglePaidBack(LinkPerson p) {
    if (!link.paidBack.remove(p.key)) link.paidBack.add(p.key);
    notifyListeners();
  }

  /// Who is marked "คืนแล้ว" with what they owe: แบ่ง when I paid (the debt is
  /// paid back at once), or [event] (a payback row in the event). Not the
  /// payer, nobody owing nothing.
  List<({LinkPerson person, double amount})> paidBackShares({
    required bool event,
  }) {
    final payer = event ? link.eventPayer : link.paidBy;
    final members = eventMembers;
    final bill = amountValue;
    final out = <({LinkPerson person, double amount})>[];
    for (final p in event ? members : splitPeople) {
      if (!link.paidBack.contains(p.key) || p == payer) continue;
      final double amount;
      if (event) {
        amount = link.eventShareOf(p, bill, members);
      } else {
        amount = splits
            .where((s) => _draftPerson(s) == p)
            .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
      }
      if (amount > 0.005) out.add((person: p, amount: amount));
    }
    return out;
  }

  /// What "จดหนี้ด้วย" records for an event bill, as the event bill sheet
  /// does: I paid → each one's share is owed to me (not the ones who paid
  /// back now); someone else paid → my share is owed to them.
  ({
    List<({LinkPerson person, double amount})> owedToMe,
    LinkPerson? payer,
    double myShare,
  })
  eventDebts() {
    final members = eventMembers;
    final bill = amountValue;
    final payer = link.eventPayer;
    return (
      owedToMe: [
        if (payer == null)
          for (final p in members)
            if (!isPaidBack(p) && link.eventShareOf(p, bill, members) > 0.005)
              (person: p, amount: link.eventShareOf(p, bill, members)),
      ],
      payer: payer,
      myShare: link.eventMine(bill, members),
    );
  }

  /// People added to the bill (the picker, or an event's members): they go
  /// after whoever is already there; the empty placeholder row makes way.
  void addPeople(List<LinkPerson> people) {
    bool blank(SplitDraft s) =>
        s.personName.trim().isEmpty && (s.owedAmount ?? 0) == 0;
    final keep = [
      for (final s in splits)
        if (!blank(s)) s,
    ];
    final have = {
      for (final s in keep)
        if (s.personName.trim().isNotEmpty) _draftPerson(s).key,
    };
    for (final p in people) {
      if (!have.add(p.key)) continue;
      keep.add(
        SplitDraft()..setPerson(p.name, contact: p.contactId, look: p.person),
      );
    }
    setSplits(keep.isEmpty ? [SplitDraft()] : keep);
  }

  /// An event's members, as people for [addPeople] (not me).
  static List<LinkPerson> peopleOfMembers(Iterable<ProjectMember> members) => [
    for (final m in members)
      if (!m.isMe)
        LinkPerson(
          name: m.displayName,
          contactId: m.contactId,
          person: m.contactId == null
              ? null
              : EmbeddedPerson(
                  name: m.displayName,
                  contactId: m.contactId,
                  iconCode: m.iconCode,
                  linked: m.isLinked,
                  linkedUserId: m.userId,
                ),
        ),
  ];

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

  // ── ผูกกับ tabs (owner 2026-10-21): ONE data set, four views ─────────
  /// The จ่ายแทน and อีเวนต์ parts; the แบ่ง part is [splits] / [meAmount].
  final link = LinkDraft();

  /// The แบ่ง people, as the other views read them.
  List<LinkPerson> get splitPeople => [
    for (final s in splits)
      if (s.personName.trim().isNotEmpty)
        LinkPerson(
          name: s.personName.trim(),
          contactId: s.contactId,
          person: s.person,
        ),
  ];

  /// The tab in use: the one picked, else what the form holds (an event →
  /// อีเวนต์, people → แบ่ง, else ส่วนตัว) so forms without the tabs keep
  /// working.
  LinkMode linkMode({required bool hasEvent}) =>
      pickedTab ??
      (hasEvent
          ? LinkMode.event
          : splits.any((s) => s.isComplete)
          ? LinkMode.split
          : LinkMode.personal);

  /// The tab picked; the tabs are an expense's only (income / transfer go by
  /// what the form holds).
  LinkMode? get pickedTab => type == TransactionType.expense ? link.mode : null;

  /// แบ่ง, จ่ายแทน and อีเวนต์ are one tab: [LinkMode.split] means "the bill
  /// with people", which is อีเวนต์ once an event is added, else จ่ายแทน when
  /// someone else paid, else แบ่ง.
  void setLinkMode(LinkMode next, {required bool hasEvent}) {
    final from = linkMode(hasEvent: hasEvent);
    final to = next != LinkMode.split
        ? next
        : hasEvent
        ? LinkMode.event
        : link.paidBy != null
        ? LinkMode.paid
        : LinkMode.split;
    if (to == from && link.mode != null) return;
    link.switchTo(to, from: from);
    // Opening the bill tab: ฉัน and the first (empty) person, ready to fill.
    if (next == LinkMode.split && from == LinkMode.personal && splits.isEmpty) {
      splits = [SplitDraft()];
    }
    notifyListeners();
  }

  List<LinkPerson> get eventMembers => link.eventMembers(splitPeople);

  /// "ส่วนของคุณ": my share of the bill in [m] (what I spend).
  double myShareFor(LinkMode m) => switch (m) {
    LinkMode.personal => amountValue,
    LinkMode.split || LinkMode.paid => meAmount ?? amountValue,
    LinkMode.event => link.eventMine(amountValue, eventMembers),
  };

  /// What leaves my wallet in [m]; 0 dims the wallet card.
  double walletOutFor(LinkMode m) => link.walletOut(m, amountValue);

  /// Whether [m]'s card adds up (its status line is ✓).
  bool linkBalanced(LinkMode m) => switch (m) {
    LinkMode.personal => true,
    LinkMode.split => splitsBalanced,
    LinkMode.paid =>
      link.paidBy != null &&
          link.payDiff(amountValue).abs() <= 0.005 &&
          splitsBalanced,
    LinkMode.event => link.eventDiff(amountValue, eventMembers).abs() <= 0.005,
  };

  /// The payer on the แบ่ง tab: null = me (แบ่ง), a person = จ่ายแทน.
  void setPaidBy(LinkPerson? p) {
    link.paidBy = p;
    if (p != null) link.paidBack.remove(p.key);
    if (link.mode == LinkMode.split || link.mode == LinkMode.paid) {
      link.mode = p == null ? LinkMode.split : LinkMode.paid;
    }
    notifyListeners();
  }

  /// `paid_by`: what they paid is my share of the bill (all of it with nobody
  /// else in the bill), unless a saved row kept a part amount.
  Map<String, dynamic>? get paidByBody {
    final p = link.paidBy;
    if (p == null) return null;
    return {
      ...p.toJson(),
      'amount': link.paidAmount ?? myShareFor(LinkMode.paid),
    };
  }

  /// The amount a save sends in [m]: จ่ายแทน records only my share (what
  /// they paid for me), the rest of the bill is theirs and others' business.
  double saveAmountFor(LinkMode? m) =>
      m == LinkMode.paid && link.paidAmount == null
      ? myShareFor(LinkMode.paid)
      : amountValue;

  void setPaidAmount(double? v) {
    link.paidAmount = v;
    notifyListeners();
  }

  void setMyPaid(double? v) {
    link
      ..myPaidTyped = v
      ..myPaidAuto = false;
    notifyListeners();
  }

  void setMyPaidAuto(bool on) {
    if (!on) link.myPaidTyped = link.myPaid(amountValue);
    link.myPaidAuto = on;
    notifyListeners();
  }

  void paidEqually() {
    link.paidEqually(amountValue);
    notifyListeners();
  }

  void setEventBookDebts(bool on) {
    link.eventBookDebts = on;
    notifyListeners();
  }

  void setEventPayer(LinkPerson? p) {
    if (p != null) link.paidBack.remove(p.key);
    link.eventPayer = p;
    notifyListeners();
  }

  void setEventShare(LinkPerson p, double? v) {
    if (v == null) {
      link.eventShares.remove(p.key);
    } else {
      link.eventShares[p.key] = v;
    }
    notifyListeners();
  }

  void setEventMeAmount(double? v) {
    link
      ..eventMeTyped = v
      ..eventMeAuto = false;
    notifyListeners();
  }

  void setEventMeAuto(bool on) {
    if (!on) link.eventMeTyped = link.eventMine(amountValue, eventMembers);
    link.eventMeAuto = on;
    notifyListeners();
  }

  void eventEqually() {
    link.eventEqually();
    notifyListeners();
  }

  /// Drops a person from the event bill: the payer goes back to me; a แบ่ง
  /// person leaves the shared list (every view).
  void removeEventMember(LinkPerson p) {
    link.eventShares.remove(p.key);
    link.paidBack.remove(p.key);
    link.eventExtra.removeWhere((e) => e.key == p.key);
    if (link.eventPayer?.key == p.key) link.eventPayer = null;
    if (link.paidBy?.key == p.key) link.paidBy = null;
    splits = [
      for (final s in splits)
        if (LinkPerson(name: s.personName.trim(), contactId: s.contactId).key !=
            p.key)
          s,
    ];
    notifyListeners();
  }

  /// What a save sends for [m]: only the active tab is saved. [useWallet] =
  /// the wallet is charged. The BE infers `link_mode`: จ่ายแทน sends `paid_by`
  /// (B1); อีเวนต์ sends `payer` + `members` to the bills call (B2). Before a
  /// tab is
  /// picked (forms without the tabs) it's today's body: complete splits, the
  /// wallet, no link fields.
  ({
    List<Map<String, dynamic>> splits,
    bool useWallet,
    Map<String, dynamic>? link,
  })
  linkSave(LinkMode m) {
    final complete = [
      for (final s in splits)
        if (s.isComplete) s.toJson(),
    ];
    if (isTransfer) return (splits: const [], useWallet: true, link: null);
    if (pickedTab == null) {
      return (splits: complete, useWallet: true, link: null);
    }
    final bill = amountValue;
    return switch (m) {
      LinkMode.personal => (splits: const [], useWallet: true, link: null),
      LinkMode.split => (splits: complete, useWallet: true, link: null),
      LinkMode.paid => (
        splits: const [],
        useWallet: link.myPaid(bill) > 0.005,
        link: {'paid_by': ?paidByBody},
      ),
      // B2: no splits; `payer` + `members` go beside new_transaction. Paid
      // by someone else = my share, no wallet.
      LinkMode.event => (
        splits: const [],
        useWallet: link.eventPayer == null,
        link: link.eventJson(bill, eventMembers),
      ),
    };
  }

  // ── editing a saved tx (0.4.0-3 B3) ────────────────────────────────
  /// Opens the tabs on the tab [t] was saved with, its จ่ายแทน / อีเวนต์
  /// data in place (the แบ่ง people come from [prefillTransaction]).
  void prefillLink(Transaction t) {
    link
      ..mode =
          t.linkMode ??
          (t.eventBill != null || t.projectId != null
              ? LinkMode.event
              : t.splitCount > 0
              ? LinkMode.split
              : LinkMode.personal)
      ..paidBy = null
      ..paidAmount = null
      ..myPaidAuto = true
      ..myPaidTyped = null
      ..eventPayer = null
      ..eventMeAuto = true
      ..eventMeTyped = null;
    link.eventShares.clear();
    link.eventExtra.clear();
    final paid = t.paidBy;
    if (paid != null) {
      link
        ..paidBy = LinkPerson.of(paid.person)
        ..paidAmount = paid.amount;
    }
    final bill = t.eventBill;
    for (final s in bill?.members ?? const <BillShare>[]) {
      if (s.member.isMe) continue;
      final p = LinkPerson(name: s.member.name, memberId: s.member.id);
      link.eventExtra.add(p);
      link.eventShares[p.key] = s.share;
    }
    final payer = bill?.payer;
    if (payer != null && !payer.isMe) {
      link.eventPayer = LinkPerson(name: payer.name, memberId: payer.id);
    }
  }

  /// A draft reopens on the tab it was saved with (0.4.0-3): จ่ายแทน's payer
  /// + amount, อีเวนต์'s payer + members (by member id, else contact / name).
  void prefillLinkFromDraft(PendingDraft d, DraftResolved r) {
    final mode = r.linkMode;
    if (mode == null || type != TransactionType.expense) return;
    link
      ..mode = mode
      ..paidBy = null
      ..paidAmount = null
      ..myPaidAuto = true
      ..myPaidTyped = null
      ..eventPayer = null
      ..eventMeAuto = true
      ..eventMeTyped = null;
    link.eventShares.clear();
    link.eventExtra.clear();
    final paid = r.paidBy;
    if (paid != null) {
      link
        ..paidBy = LinkPerson.of(paid.person)
        ..paidAmount = paid.amount;
    }
    LinkPerson person(ResolvedBillPerson p) => LinkPerson(
      name: p.name,
      contactId: p.memberId == null ? p.contactId : null,
      memberId: p.memberId,
    );
    final payer = r.billPayer;
    if (payer != null && !payer.me) link.eventPayer = person(payer);
    for (final m in r.billMembers) {
      if (m.me) continue;
      final p = person(m);
      link.eventExtra.add(p);
      link.eventShares[p.key] = m.share;
    }
  }

  /// The tab + its data, to tell at save whether the tab changed.
  String linkSnapshot(LinkMode m) =>
      jsonEncode({'mode': m.wire, 'data': _linkData(m, projectId: null)});

  /// The B3 PUT part for [m]: `link_mode` + that tab's data. The event tab
  /// needs the event's [projectId].
  Map<String, dynamic> linkEditJson(LinkMode m, {String? projectId}) => {
    'link_mode': m.wire,
    ..._linkData(m, projectId: projectId),
  };

  Map<String, dynamic> _linkData(LinkMode m, {required String? projectId}) {
    final bill = amountValue;
    return switch (m) {
      LinkMode.personal => const {},
      LinkMode.split => {
        'splits': [
          for (final s in splits)
            if (s.isComplete) s.toUpdateJson(),
        ],
      },
      LinkMode.paid => {'paid_by': ?paidByBody},
      LinkMode.event => {
        'event': {
          'project_id': ?projectId,
          ...link.eventJson(bill, eventMembers),
        },
      },
    };
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

  /// The draft as typed. Under the ผูกกับ tabs only the active tab's data
  /// goes in (0.4.0-3): แบ่ง = splits, จ่ายแทน = paid_by, อีเวนต์ =
  /// project_id ([eventProjectId] when the event lives outside the form) +
  /// payer + members.
  PendingDraft toDraft({bool keepIncomplete = false, String? eventProjectId}) {
    final tab = isTransfer ? null : pickedTab;
    if (tab != null) {
      final base = _draftBase(keepIncomplete: keepIncomplete);
      final bill = amountValue;
      final event = tab == LinkMode.event
          ? link.eventJson(bill, eventMembers)
          : null;
      return PendingDraft(
        type: base.type,
        amount: tab == LinkMode.paid ? saveAmountFor(tab) : base.amount,
        accountId: base.accountId,
        categoryId: base.categoryId,
        date: base.date,
        description: base.description,
        note: base.note,
        tagIds: base.tagIds,
        splits: tab == LinkMode.split ? base.splits : const [],
        projectId: tab == LinkMode.event ? (eventProjectId ?? projectId) : null,
        paidBy: tab == LinkMode.paid ? paidByBody : null,
        payer: (event?['payer'] as Map?)?.cast<String, dynamic>(),
        members: [
          for (final m in (event?['members'] as List?) ?? const [])
            (m as Map).cast<String, dynamic>(),
        ],
      );
    }
    return _draftBase(keepIncomplete: keepIncomplete);
  }

  PendingDraft _draftBase({bool keepIncomplete = false}) {
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
    this.linkTabs = false,
    this.linkEventIsNew = false,
    this.linkIsEventMember,
    this.accentColor,
    super.key,
  });

  /// The create mode's colour: washes the hero card, so red / green stay on
  /// the type chip alone.
  final Color? accentColor;

  /// The picked existing event's members, as a check ([LinkSection]).
  final bool Function(LinkPerson p)? linkIsEventMember;

  /// Quick create (new expense): the "ผูกกับ" tabs ([LinkSection]) instead
  /// of the split / event section; [eventSlot] feeds the อีเวนต์ card.
  final bool linkTabs;
  final bool linkEventIsNew;

  final bool chipLayout;

  final bool cardsInHero;

  final bool chipRows;

  final Set<EntryField> missing;

  final GlobalKey? heroKey;

  final DraftEvent? event;

  final bool typeLocked;
  final bool allowSplits;

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

  DraftFormController get _c => widget.controller;

  @override
  void dispose() {
    _amountFocus.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final r = await CategoryPicker.one(
      context,
      categories:
          maybeTxFormOptions(
            context,
            watch: false,
          )?.state.options?.categoryList ??
          context.read<CategoriesCubit>().state.categories,
      types: {
        _c.type == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense,
      },
      selectedId: _c.category?.id,
      allowNone: true,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _c.setCategory(r is CategoryPicked ? r.category : null);
  }

  Future<void> _pickAccount({bool to = false}) async {
    final l = AppLocalizations.of(context)!;
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await AccountPicker.one(
      context,
      accounts: accounts,
      selectedId: (to ? _c.toAccount : _c.account)?.id,
      excludeIds: {
        ?(to ? _c.account?.id : (_c.isTransfer ? _c.toAccount?.id : null)),
      },
      title: to ? l.quickTo : null,
      allowNone: !_c.isTransfer && !to,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    if (to) {
      if (r is AccountPicked) _c.setToAccount(r.account);
    } else {
      _c.setAccount(r is AccountPicked ? r.account : null);
    }
  }

  Future<void> _moreTags() async {
    final next = await TagPicker.many(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next.ids);
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
    final mode = _c.isTransfer ? null : _linkMode;
    return WalletPickCard(
      account: account,
      label: label,
      placeholder: placeholder,
      dense: true,
      muted: mode != null && _c.walletOutFor(mode) <= 0.005,
      note: _walletNote(AppLocalizations.of(context)!, mode),
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
        final linkMode = _linkMode;
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
                accentColor: widget.accentColor,
                amount: _c.amount,
                title: _c.description,
                dateLabel: _dayLabel(context, _c.date),
                onPickDate: _pickDate,
                autofocus: widget.autofocus && !widget.readOnly,
                compact: widget.compact,
                amountFocus: _amountFocus,
                titleFocus: _descriptionFocus,
                amountNote: linkMode != null
                    ? _ShareLine.ofLink(_c, linkMode, l)
                    : !isTransfer && (!editing || widget.allowSplits)
                    ? _ShareLine.of(_c)
                    : null,
                amountLabel: linkMode == null || linkMode == LinkMode.personal
                    ? null
                    : l.txLinkBillLabel,
                missing: widget.missing,
                showTitle: !isTransfer,
                titleHint: isTransfer
                    ? null
                    : (_c.type == TransactionType.income
                          ? l.txTitleHintIncome
                          : l.txTitleHintExpense),
                flowRow: isTransfer ? _transferFlow(l) : _entryCards(l),
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
                amountNote: linkMode != null
                    ? _ShareLine.ofLink(_c, linkMode, l)
                    : !isTransfer && (!editing || widget.allowSplits)
                    ? _ShareLine.of(_c)
                    : null,
                amountLabel: linkMode == null || linkMode == LinkMode.personal
                    ? null
                    : l.txLinkBillLabel,
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

  /// The ผูกกับ tab in use; null = no tabs here (not quick create's new
  /// expense).
  LinkMode? get _linkMode =>
      widget.linkTabs && _c.type == TransactionType.expense
      ? _c.linkMode(
          hasEvent: widget.chipLayout
              ? _c.projectId != null
              : widget.eventSlot?.name != null,
        )
      : null;

  /// The wallet card's line under ผูกกับ: nothing leaves it (dimmed), or
  /// only part of the bill does.
  String? _walletNote(AppLocalizations l, LinkMode? m) {
    if (m == null || m == LinkMode.personal || m == LinkMode.split) {
      return null;
    }
    final out = _c.walletOutFor(m);
    if (out <= 0.005) return l.txLinkWalletNotOut;
    if (out < _c.amountValue - 0.005) {
      return l.txLinkWalletPart(moneyString(context, out));
    }
    return null;
  }

  Widget _entryCards(AppLocalizations l) {
    final locked = widget.categoryLockedHint != null;
    final mode = _linkMode;
    final walletNote = _walletNote(l, mode);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CategoryPickCard(
              category: _c.category,
              label: l.transactionFormCategoryLabel,
              placeholder: l.transactionFormCategoryNone,
              dense: true,
              editable: !locked,
              onTap: locked ? null : _pickCategory,
            ),
          ),
          // As far apart as the cards sit from the hero's edge.
          SizedBox(width: HeroMetrics.of(context).padding.left),
          Expanded(
            child: WalletPickCard(
              account: _c.account,
              label: l.transactionFormAccountLabel,
              placeholder: l.transactionFormAccountNone,
              dense: true,
              editable: true,
              muted: mode != null && _c.walletOutFor(mode) <= 0.005,
              note: walletNote,
              onTap: () => _pickAccount(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transferFlow(AppLocalizations l) => FlowCards(
    from: WalletPickCard(
      account: _c.account,
      label: l.quickFrom,
      placeholder: l.quickPickWallet,
      dense: true,
      editable: true,
      onTap: () => _pickAccount(),
    ),
    to: WalletPickCard(
      account: _c.toAccount,
      label: l.quickTo,
      placeholder: l.quickPickWallet,
      dense: true,
      editable: true,
      onTap: () => _pickAccount(to: true),
    ),
    swapTooltip: l.quickSwap,
    onSwap: _c.swapAccounts,
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
      if (_linkMode != null) ...[
        gap,
        LinkSection(
          controller: _c,
          // A draft keeps its event on the form (project_id).
          event: widget.chipLayout
              ? _draftEventSlot()
              : (widget.eventSlot ?? const SplitEventSlot()),
          eventIsNew: widget.linkEventIsNew,
          isEventMember: widget.linkIsEventMember,
          recurring: widget.recurringSlot,
        ),
      ] else if (!isTransfer || widget.recurringSlot != null) ...[
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
          SizedBox(width: HeroMetrics.of(context).padding.left),
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
            helper: helper,
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
              .watch<ProjectDirectoryCubit>()
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
    final r = await EventPicker.one(
      context,
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
      if (editing && _linkMode != null) ...[
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: LinkSection(
            controller: _c,
            event: widget.eventSlot ?? const SplitEventSlot(),
            eventIsNew: widget.linkEventIsNew,
            isEventMember: widget.linkIsEventMember,
            recurring: widget.recurringSlot,
          ),
        ),
      ] else
        ?_splitEventSection(l, editing: editing, transfer: isTransfer),
    ];
  }
}

class TxTagStrip extends StatelessWidget {
  const TxTagStrip({required this.tags, super.key});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return IconChipStrip(
      icon: AppIcons.tag,
      chips: [
        for (final t in tags) tagAppChip(context, t, size: ChipSize.chip),
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
    this.owe,
  });

  final TransactionType type;
  final double mine;
  final double others;

  /// "ค้าง ลี ฿13": who I owe for this bill, and how much.
  final ({String name, double amount})? owe;

  /// Under ผูกกับ: my REAL share in [m] (owner 2026-10-21); ส่วนตัว has none.
  static Widget? ofLink(DraftFormController c, LinkMode m, AppLocalizations l) {
    final bill = c.amountValue;
    final link = c.link;
    switch (m) {
      case LinkMode.personal:
        return null;
      case LinkMode.split:
        return of(c);
      case LinkMode.paid:
        final payer = link.paidBy;
        if (payer == null || bill <= 0) return null;
        return _ShareLine(
          type: c.type,
          mine: bill,
          others: 0,
          owe: (name: payer.name, amount: link.paidAmountFor(bill)),
        );
      case LinkMode.event:
        if (bill <= 0) return null;
        final members = c.eventMembers;
        final mine = link.eventMine(bill, members);
        final payer = link.eventPayer;
        return _ShareLine(
          type: c.type,
          mine: mine,
          others: payer == null ? link.eventOthers(bill, members) : 0,
          owe: payer == null ? null : (name: payer.name, amount: mine),
        );
    }
  }

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
    final owe = this.owe;
    final String? tail = owe != null
        ? l.txLinkShareIOwe(owe.name, moneyString(context, owe.amount))
        : others > 0.005
        ? (type == TransactionType.income
              ? l.txShareYouOweOthers(othersText)
              : l.txShareOthersOweYou(othersText))
        : null;
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
        if (tail != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              '| $tail',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
