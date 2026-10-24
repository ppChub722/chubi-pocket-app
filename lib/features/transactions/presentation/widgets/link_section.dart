import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../domain/link_draft.dart';
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
    super.key,
  });

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
      bar: LinkModeBar<LinkMode>(
        key: const ValueKey('linkModeBar'),
        selected: mode == LinkMode.personal ? mode : LinkMode.split,
        onChanged: (m) => _c.setLinkMode(m, hasEvent: _hasEvent),
        tabs: [
          AppTab(
            value: LinkMode.personal,
            label: l.txLinkTabPersonal,
            icon: AppIcons.wallet,
          ),
          AppTab(
            value: LinkMode.split,
            label: l.txLinkTabSplit,
            icon: AppIcons.split,
          ),
        ],
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
      name: p.name,
      level: level,
      iconCode: p.person?.iconCode,
      size: SplitRow.avatarSize,
      reserveLinkSlot: true,
    );
  }

  /// "เพิ่มในอีเวนต์": the top row of the card; picking one turns the bill
  /// into an event bill.
  Widget _eventRow(AppLocalizations l) {
    final e = widget.event;
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
    );
  }

  /// The bill's people, as แบ่ง ([event] false: shares are what each owes me,
  /// or what I owe the payer) or as an event bill (shares of the bill).
  Widget _peopleCard(AppLocalizations l, {required bool event}) {
    final link = _c.link;
    final bill = _c.amountValue;
    final members = _c.eventMembers;
    final payer = event ? link.eventPayer : link.paidBy;
    void setPayer(LinkPerson? p) =>
        event ? _c.setEventPayer(p) : _c.setPaidBy(p);

    // A saved จ่ายแทน opens with its payer in the list.
    if (!event && payer != null && !_c.splitPeople.contains(payer)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _c.link.paidBy;
        if (!mounted || p == null || _c.splitPeople.contains(p)) return;
        _c.addPeople([p]);
      });
    }

    final isMember = widget.isEventMember;
    Widget? tagFor(LinkPerson p) =>
        event && (widget.eventIsNew || (isMember != null && !isMember(p)))
        ? AppChip(
            label: l.txLinkCardNewToEvent,
            size: ChipSize.mini,
            tone: AppChipTone.info,
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
    );

    BillPerson draftRow(SplitDraft d) {
      final named = d.personName.trim().isNotEmpty;
      final person = named ? _personOfDraft(d) : null;
      final paid = person != null && person == payer;
      return BillPerson(
        id: d,
        autofocusName: identical(d, _justAdded),
        name: d.personName,
        avatar: _mark(_personOfDraft(d)),
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
        onPay: person == null || paid ? null : () => setPayer(person),
        tag: person == null ? null : tagFor(person),
        onRemove: () {
          if (paid) setPayer(null);
          if (event && person != null) {
            _c.removeEventMember(person);
          } else {
            _c.setSplits([
              for (final s in _c.splits)
                if (!identical(s, d)) s,
            ]);
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
            amount: link.eventShareOf(p, bill, members),
            onAmount: (v) => _c.setEventShare(p, v),
            paid: p == payer,
            onPay: p == payer ? null : () => setPayer(p),
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
