import 'refs.dart';

/// Quick create's "ผูกกับ" tabs (owner 2026-10-21). Only the ACTIVE one is
/// saved; the others keep what was typed until the sheet closes.
enum LinkMode {
  /// ส่วนตัว: a plain transaction.
  personal('personal'),

  /// แบ่ง: I paid, others owe me their shares (today's splits).
  split('split'),

  /// จ่ายแทน: someone else paid (all or part); I owe them.
  paid('paid'),

  /// อีเวนต์: a bill on an event board, one payer, members' shares.
  event('event');

  const LinkMode(this.wire);

  /// A row's read-only `link_mode` (B1); writes say it through `paid_by` /
  /// `splits` / the event call. Unknown → null.
  static LinkMode? parse(Object? v) =>
      values.where((m) => m.wire == v).firstOrNull;

  final String wire;
}

/// A person in the shared data set: a contact (id) or a typed name.
class LinkPerson {
  const LinkPerson({
    required this.name,
    this.contactId,
    this.person,
    this.memberId,
  });

  factory LinkPerson.of(EmbeddedPerson p) =>
      LinkPerson(name: p.name, contactId: p.contactId, person: p);

  final String name;
  final String? contactId;
  final EmbeddedPerson? person;

  /// An event member as a saved bill names them (B3 edit): sent as
  /// `member_id`.
  final String? memberId;

  /// The same person in every view (a contact by id, a member by id, a typed
  /// name by text).
  String get key => contactId != null
      ? 'c:$contactId'
      : memberId != null
      ? 'm:$memberId'
      : 'n:${name.trim().toLowerCase()}';

  bool get isTyped => contactId == null;

  /// Already this event member? A contact by the member's `contact_id` or
  /// its linked user; a typed name by the member's name (any case), as the
  /// BE matches it when adding.
  bool isMember({required String name, String? contactId, String? userId}) {
    final mine = this.contactId;
    if (mine != null) {
      if (contactId == mine) return true;
      final uid = person?.linkedUserId;
      return uid != null && userId == uid;
    }
    return name.trim().toLowerCase() == this.name.trim().toLowerCase();
  }

  /// The person on the wire (B1 / B2 / B3): a contact id, an event member
  /// id, else the typed name.
  Map<String, dynamic> toJson() => contactId != null
      ? {'contact_id': contactId}
      : memberId != null
      ? {'member_id': memberId}
      : {'person_name': name.trim()};

  @override
  bool operator ==(Object other) => other is LinkPerson && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

double _round(double v) => (v * 100).roundToDouble() / 100;

/// The จ่ายแทน and อีเวนต์ parts of the ONE data set behind the ผูกกับ tabs.
/// The แบ่ง part (people + their shares, my share with its A toggle) stays in
/// DraftFormController's `splits` / `meAmount`, and the other views read the
/// same people from it, so typed data survives switching tabs.
///
/// Pure: every number is computed from the bill passed in.
class LinkDraft {
  /// The tab the person picked; null = not picked yet (the form infers it).
  LinkMode? mode;

  // ── จ่ายแทน ──────────────────────────────────────────────────────────
  /// Who paid for me (one payer).
  LinkPerson? paidBy;

  /// What they paid; null = the whole bill.
  double? paidAmount;

  /// "ฉันจ่ายเอง (จากกระเป๋า)" fills itself with bill − what they paid
  /// until typed in.
  bool myPaidAuto = true;
  double? myPaidTyped;

  double paidAmountFor(double bill) => paidAmount ?? bill;

  double myPaid(double bill) => myPaidAuto
      ? _round((bill - paidAmountFor(bill)).clamp(0, double.infinity))
      : (myPaidTyped ?? 0);

  /// > 0 = เกินยอด, < 0 = ยังขาด, 0 = ✓ จ่ายครบแล้ว.
  double payDiff(double bill) =>
      _round(paidAmountFor(bill) + myPaid(bill) - bill);

  /// หารเท่ากัน on the จ่ายแทน card: half each, mine back on auto.
  void paidEqually(double bill) {
    paidAmount = _round(bill / 2);
    myPaidAuto = true;
    myPaidTyped = null;
  }

  // ── อีเวนต์ ──────────────────────────────────────────────────────────
  /// One payer; null = me.
  LinkPerson? eventPayer;

  /// Shares typed per person (key → amount); the rest share equally.
  final Map<String, double> eventShares = {};

  /// People (keys) who already paid the payer back ("คืนแล้ว"): the bill
  /// saves their payback with it.
  final Set<String> paidBack = {};

  bool eventMeAuto = true;
  double? eventMeTyped;

  /// People of a saved bill that aren't in แบ่ง (B3 edit: event members).
  final List<LinkPerson> eventExtra = [];

  /// Everyone in the bill but me: the แบ่ง people, plus whoever paid for me
  /// (carried over from จ่ายแทน), the event payer and a saved bill's people.
  /// Each once.
  List<LinkPerson> eventMembers(List<LinkPerson> splitPeople) {
    final seen = <String>{};
    return [
      for (final p in [...splitPeople, ?paidBy, ?eventPayer, ...eventExtra])
        if (seen.add(p.key)) p,
    ];
  }

  double eventEqualShare(double bill, List<LinkPerson> members) =>
      _round(bill / (members.length + 1));

  double eventShareOf(LinkPerson p, double bill, List<LinkPerson> members) =>
      eventShares[p.key] ?? eventEqualShare(bill, members);

  double eventOthers(double bill, List<LinkPerson> members) => _round(
    members.fold<double>(0, (a, p) => a + eventShareOf(p, bill, members)),
  );

  /// My share of the event bill: the remainder while ฉัน is on auto.
  double eventMine(double bill, List<LinkPerson> members) => eventMeAuto
      ? _round((bill - eventOthers(bill, members)).clamp(0, double.infinity))
      : (eventMeTyped ?? 0);

  double eventDiff(double bill, List<LinkPerson> members) =>
      _round(eventOthers(bill, members) + eventMine(bill, members) - bill);

  /// หารเท่ากัน on the อีเวนต์ card: drop typed shares, ฉัน back on auto.
  void eventEqually() {
    eventShares.clear();
    eventMeAuto = true;
    eventMeTyped = null;
  }

  // ── switching tabs (carry-over rules, owner 2026-10-21) ─────────────
  /// Picks [next]. Going to อีเวนต์ from จ่ายแทน makes that person the payer;
  /// from แบ่ง (or anything else) the payer is me.
  void switchTo(LinkMode next, {required LinkMode from}) {
    if (next == LinkMode.event && from != LinkMode.event) {
      eventPayer = from == LinkMode.paid ? paidBy : null;
    }
    mode = next;
  }

  // ── what each tab means ─────────────────────────────────────────────
  /// What leaves my wallet in [m] (the wallet card dims at 0).
  double walletOut(LinkMode m, double bill) => switch (m) {
    LinkMode.personal || LinkMode.split => bill,
    LinkMode.paid => myPaid(bill),
    LinkMode.event => eventPayer == null ? bill : 0,
  };

  /// `paid_by` on POST / PUT /transactions (B1): who paid and how much; the
  /// tx's `amount` stays the bill.
  Map<String, dynamic>? paidByJson(double bill) {
    final p = paidBy;
    if (p == null) return null;
    return {...p.toJson(), 'amount': paidAmountFor(bill)};
  }

  /// The bill's people beside `new_transaction` on POST /projects/quick and
  /// /projects/{id}/bills (B2): the payer (`{me: true}` or a person) and
  /// everyone in the bill, me too, with their share. The BE gives the payer
  /// the rest of the bill and adds non-members to the event.
  Map<String, dynamic> eventJson(double bill, List<LinkPerson> members) => {
    'payer': eventPayer?.toJson() ?? const {'me': true},
    'members': [
      {'me': true, 'share': eventMine(bill, members)},
      for (final p in members)
        {...p.toJson(), 'share': eventShareOf(p, bill, members)},
    ],
  };
}
