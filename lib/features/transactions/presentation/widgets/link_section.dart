import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../domain/link_draft.dart';
import '../../domain/transaction_type.dart';
import 'draft_form.dart';
import 'splits_section.dart';

/// Quick create's "ผูกกับ": the รายการประจำ row, the full-width tabs
/// [ส่วนตัว | แบ่ง], then the tab's card. แบ่ง is the whole bill with people,
/// the same [BillPeopleCard] as the event bill sheet: "จ่าย" on a person says
/// who paid (จ่ายแทน), and an event added at the top of the card makes it an
/// event bill. Only the shown tab is saved.
class LinkSection extends StatefulWidget {
  const LinkSection({
    required this.controller,
    required this.event,
    this.eventIsNew = false,
    this.isEventMember,
    this.recurring,
    this.flat = false,
    this.summary,
    this.fixed = false,
    this.readOnly = false,
    super.key,
  });

  /// A saved bill being viewed (owner 2026-11-04): no switch row, the event
  /// row only when it has one ("อยู่ในอีเวนต์ X"), the people card read-only.
  final bool readOnly;

  /// An event's own bill (owner 2026-11-03): always a bill of that event, so
  /// no แบ่ง switch and the event row can't be changed.
  final bool fixed;

  /// Inside the แบ่ง card: the people card has no frame of its own.
  final bool flat;

  /// The share summary ("ส่วนของฉัน ฿x | ลูกหนี้ ฿y"), on the status line.
  final Widget? summary;

  final DraftFormController controller;

  /// The event row at the top of the card (name null = none picked).
  final SplitEventSlot event;

  /// A new event: everyone in the bill joins it (the "ใหม่" tag on each).
  final bool eventIsNew;

  /// An existing event: who is already in it (from its members). Null =
  /// not known (yet), so no tags.
  final bool Function(LinkPerson p)? isEventMember;

  final SplitRecurringSlot? recurring;

  @override
  State<LinkSection> createState() => _LinkSectionState();
}

class _LinkSectionState extends State<LinkSection> {
  DraftFormController get _c => widget.controller;

  bool get _hasEvent => widget.event.name != null;

  SplitDraft? _justAdded;

  static LinkPerson _personOfDraft(SplitDraft d) => LinkPerson(
    name: d.personName.trim(),
    contactId: d.contactId,
    person: d.person,
  );

  /// Pick somebody else for a row: it keeps its place, its share and the
  /// payer mark.
  Future<void> _changeDraftPerson(SplitDraft d) async {
    final r = await ContactPicker.one(
      context,
      selectedId: d.contactId,
      allowFreeText: true,
      allowCreate: true,
      initialName: d.personName.trim().isEmpty ? null : d.personName,
    );
    if (r == null || !mounted) return;
    final before = _personOfDraft(d);
    applyContactPick(d, r);
    _c.rekeyDraft(before, d);
  }

  /// "เพิ่มคน": a new row, its name ready to type (or tap the avatar to pick).
  void _addPerson() {
    final d = SplitDraft();
    _justAdded = d;
    _c.setSplits([..._c.splits, d]);
  }

  /// หารเท่ากัน on แบ่ง: each person the same, ฉัน the rest.
  void _splitEqually() {
    final n = _c.splits.length;
    if (n == 0 || _c.splitCap <= 0) return;
    final r = splitEquallyWithMe(_c.splitCap, n);
    for (final d in _c.splits) {
      d.owedAmount = r.each;
    }
    _c.setSplits(List.of(_c.splits));
    if (!_c.meAuto) _c.setMeAmount(r.me);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = _c.linkMode(hasEvent: _hasEvent);
    if (widget.fixed) return _peopleCard(l, event: true);
    final recurring = widget.recurring;
    return LinkSectionFrame(
      recurring: recurring == null
          ? null
          : RecurringLinkRow(
              slot: recurring,
              variant: SplitEventVariant.compact,
            ),
      card: mode == LinkMode.personal
          ? null
          : _peopleCard(l, event: mode == LinkMode.event),
      bar: widget.readOnly
          ? null
          : LinkSwitchRow(
              key: const ValueKey('linkSwitchRow'),
              label: l.txLinkTabSplit,
              value: mode != LinkMode.personal,
              // An event bill stays a bill until its event is removed.
              onChanged: _hasEvent && mode == LinkMode.event
                  ? null
                  : (on) => _c.setLinkMode(
                      on ? LinkMode.split : LinkMode.personal,
                      hasEvent: _hasEvent,
                    ),
            ),
    );
  }

  Widget _mark(LinkPerson p) {
    final level = p.contactId == null
        ? PersonLevel.name
        : (p.person?.linked ?? false)
        ? PersonLevel.linked
        : PersonLevel.contact;
    return PersonMark(
      level: level,
      avatar: p.person?.avatar,
      size: SplitRow.avatarSize,
      reserveLinkSlot: true,
    );
  }

  /// "เพิ่มในอีเวนต์": the top row of the card; picking one turns the bill
  /// into an event bill and shows "จดหนี้บิลนี้เลย" under it (off = the
  /// event's lump, which skips pairs booked here). My transaction is asked on
  /// the tx detail card ([EventBookRows]).
  Widget? _eventRow(AppLocalizations l) {
    final e = widget.event;
    final debts = _c.link.eventBookDebts;
    // The event's own bill: the event is on top of the sheet, only the debts
    // row stays here.
    if (widget.fixed) {
      return debts == null
          ? null
          : LinkSwitchRow(
              key: const ValueKey('linkBookDebtRow'),
              label: l.txLinkBookDebt,
              value: debts,
              onChanged: _c.setEventBookDebts,
            );
    }
    if (widget.readOnly) {
      return _hasEvent
          ? EventRow(
              key: const ValueKey('linkEventRow'),
              name: e.name,
              onTap: e.onTap,
              editing: false,
              variant: SplitEventVariant.compact,
              label: l.txLinkInEvent,
            )
          : null;
    }
    return EventRow(
      key: const ValueKey('linkEventRow'),
      name: e.name,
      onTap: e.onTap,
      onClear: e.onClear,
      locked: e.locked,
      editing: e.editing,
      onLongPress: e.onLongPress,
      variant: SplitEventVariant.compact,
      label: l.txLinkAddToEvent,
      footer: !_hasEvent || debts == null
          ? null
          : LinkSwitchRow(
              key: const ValueKey('linkBookDebtRow'),
              label: l.txLinkBookDebt,
              value: debts,
              onChanged: _c.setEventBookDebts,
            ),
    );
  }

  /// The bill's people, as แบ่ง ([event] false: shares are what each owes me,
  /// or what I owe the payer) or as an event bill (shares of the bill).
  Widget _peopleCard(AppLocalizations l, {required bool event}) {
    final link = _c.link;
    final bill = _c.amountValue;
    final members = _c.eventMembers;
    final payer = event ? link.eventPayer : link.paidBy;
    // An income: the payer is who received it (รับแทน); an event income is
    // always mine.
    final income = _c.type == TransactionType.income;
    final canPayOthers = !(event && income);
    void setPayer(LinkPerson? p) =>
        event ? _c.setEventPayer(p) : _c.setPaidBy(p);

    // A saved จ่ายแทน opens with its payer in the list.
    if (!event &&
        payer != null &&
        payer.name.isNotEmpty &&
        !_c.splitPeople.contains(payer)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _c.link.paidBy;
        if (!mounted || p == null || p.name.isEmpty) return;
        if (_c.splitPeople.contains(p)) return;
        _c.addPeople([p]);
      });
    }

    final isMember = widget.isEventMember;
    Widget? tagFor(LinkPerson p) =>
        event && (widget.eventIsNew || (isMember != null && !isMember(p)))
        ? PpForgeChip(
            label: l.txLinkCardNewToEvent,
            size: ChipSize.mini,
            tone: PpForgeChipTone.info,
            selected: true,
          )
        : null;

    final me = BillPerson(
      id: 'me',
      name: l.txSplitMe,
      isMe: true,
      avatar: MyAvatar(fallbackName: l.txLinkCardMe),
      amount: event ? link.eventMine(bill, members) : _c.meAmount ?? bill,
      auto: event ? link.eventMeAuto : _c.meAuto,
      onAmount: event ? _c.setEventMeAmount : _c.setMeAmount,
      onAuto: event ? _c.setEventMeAuto : _c.setMeAuto,
      paid: payer == null,
      onPay: payer == null ? null : () => setPayer(null),
      // Someone else paid: "คืน X แล้ว" on my row, my share from my wallet
      // and no debt (SA6, as in the bill form).
      canPaidBack: payer != null,
      paidBack: payer != null && link.mePaidBack,
      onPaidBack: _c.toggleMePaidBack,
    );

    // "คืนแล้ว" on anyone but the payer, whoever paid (a split bill holds
    // each one's payback, 0.4.1-2 SA6).
    const paidBackAllowed = true;

    BillPerson draftRow(SplitDraft d) {
      final named = d.personName.trim().isNotEmpty;
      // A row with no name yet can be marked too (it keeps the mark when the
      // name is typed); saving waits for the name.
      final person = _personOfDraft(d);
      final paid = person == payer;
      return BillPerson(
        id: d,
        autofocusName: identical(d, _justAdded),
        name: d.personName,
        avatar: _mark(_personOfDraft(d)),
        color: ProfileColors.of(
          context,
          person.person?.avatar ?? AvatarData.forName(d.personName),
        ),
        editableName: d.contactId == null,
        onName: (v) => _c.renameDraft(d, v),
        onChangePerson: () => _changeDraftPerson(d),
        amount: event
            ? link.eventShareOf(_personOfDraft(d), bill, members)
            : d.owedAmount,
        onAmount: (v) {
          if (event) {
            _c.setEventShare(_personOfDraft(d), v);
          } else {
            d.owedAmount = v;
            _c.setSplits(List.of(_c.splits));
          }
        },
        paid: paid,
        onPay: paid || !canPayOthers ? null : () => setPayer(person),
        canPaidBack: paidBackAllowed && !paid,
        paidBack: _c.isPaidBack(person),
        onPaidBack: () => _c.togglePaidBack(person),
        tag: named ? tagFor(person) : null,
        onRemove: () {
          if (paid) setPayer(null);
          if (event && named) {
            _c.removeEventMember(person);
          } else {
            _c.removeDraft(d);
          }
        },
      );
    }

    final inSplits = {for (final p in _c.splitPeople) p.key};
    final extras = event
        ? [
            for (final p in members)
              if (!inSplits.contains(p.key)) p,
          ]
        : const <LinkPerson>[];

    return BillPeopleCard(
      key: ValueKey(event ? 'linkCardEvent' : 'linkCardSplit'),
      flat: widget.flat,
      readOnly: widget.readOnly,
      statusLeading: widget.summary,
      payLabel: income ? l.evbReceives : null,
      top: _eventRow(l),
      title: l.evbPeople((event ? members.length : _c.splits.length) + 1),
      people: [
        me,
        for (final d in _c.splits) draftRow(d),
        for (final p in extras)
          BillPerson(
            id: p.key,
            name: p.name,
            avatar: _mark(p),
            color: ProfileColors.of(
              context,
              p.person?.avatar ?? AvatarData.forName(p.name),
            ),
            amount: link.eventShareOf(p, bill, members),
            onAmount: (v) => _c.setEventShare(p, v),
            paid: p == payer,
            onPay: p == payer || !canPayOthers ? null : () => setPayer(p),
            canPaidBack: paidBackAllowed && p != payer,
            paidBack: _c.isPaidBack(p),
            onPaidBack: () => _c.togglePaidBack(p),
            tag: tagFor(p),
            onRemove: () => _c.removeEventMember(p),
          ),
      ],
      onEqually: event
          ? (members.isNotEmpty && bill > 0 ? _c.eventEqually : null)
          : (_c.splits.isNotEmpty && _c.splitCap > 0 ? _splitEqually : null),
      onAdd: _addPerson,
      status: event
          ? linkCardStatus(
              context,
              -link.eventDiff(bill, members),
              l.txLinkCardSplitOk,
            )
          : linkCardStatus(
              context,
              splitLeft(_c.splitCap, _c.meAmount, _c.splits),
              l.txLinkCardSplitOk,
            ),
    );
  }
}

/// An event bill being added (owner 2026-11-03): "ลงรายการของฉันเลย" at the
/// top of the tx detail card (the card IS my transaction); off = no
/// transaction now and the rest of the card hides. Debts are their own
/// choice, under the event row.
class EventBookRows extends StatelessWidget {
  const EventBookRows({required this.controller, super.key});

  final DraftFormController controller;

  /// Shown only for a new event bill.
  static bool shows(DraftFormController c, LinkMode? mode) =>
      mode == LinkMode.event && c.link.eventBookDebts != null;

  @override
  Widget build(BuildContext context) => LinkSwitchRow(
    key: const ValueKey('linkBookMineRow'),
    label: AppLocalizations.of(context)!.txLinkBookMine,
    value: controller.link.eventBookMine,
    onChanged: controller.setEventBookMine,
  );
}
