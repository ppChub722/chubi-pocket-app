import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../domain/link_draft.dart';
import 'draft_form.dart';
import 'splits_section.dart';

/// Quick create's "ผูกกับ": the รายการประจำ row, the full-width tabs
/// [ส่วนตัว | แบ่ง], then the tab's card. แบ่ง is the whole bill with people:
/// "จ่าย" on a person says who paid (จ่ายแทน), and an event added to the card
/// makes it an event bill. Only the shown tab is saved.
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

  /// The อีเวนต์ card's event chip (name null = none picked).
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

  Future<void> _changeDraftPerson(SplitDraft d) async {
    final r = await ContactPicker.one(
      context,
      selectedId: d.contactId,
      allowFreeText: true,
      allowCreate: true,
      initialName: d.personName.trim().isEmpty ? null : d.personName,
    );
    if (r == null || !mounted) return;
    // The share typed for the old name follows the person.
    final before = _personOfDraft(d);
    final share = _c.link.eventShares.remove(before.key);
    applyContactPick(d, r);
    if (share != null) _c.link.eventShares[_personOfDraft(d).key] = share;
    _c.setSplits(List.of(_c.splits));
  }

  void _addPerson() {
    final d = SplitDraft();
    _justAdded = d;
    _c.setSplits([..._c.splits, d]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = _c.linkMode(hasEvent: _hasEvent);
    final recurring = widget.recurring;
    final card = switch (mode) {
      LinkMode.personal => null,
      LinkMode.split || LinkMode.paid => _splitCard(l),
      LinkMode.event => _eventCard(l),
    };
    return LinkSectionFrame(
      recurring: recurring == null
          ? null
          : RecurringLinkRow(
              slot: recurring,
              variant: SplitEventVariant.compact,
            ),
      card: card,
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

  Widget _mark(LinkPerson p, {VoidCallback? onTap}) {
    final level = p.contactId == null
        ? PersonLevel.name
        : (p.person?.linked ?? false)
        ? PersonLevel.linked
        : PersonLevel.contact;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: PersonMark(
        name: p.name,
        level: level,
        iconCode: p.person?.iconCode,
        size: SplitRow.avatarSize,
        reserveLinkSlot: true,
        tappable: onTap != null,
      ),
    );
  }

  Widget _remove(AppLocalizations l, VoidCallback onTap) => SplitRowAction(
    icon: AppIcons.close,
    tooltip: l.txSplitRemove,
    onTap: onTap,
  );

  // ── แบ่ง (and จ่ายแทน when someone else paid) ────────────────────────
  Widget _splitCard(AppLocalizations l) {
    final payer = _c.link.paidBy;
    // A saved จ่ายแทน opens with its payer in the list (no row, no chip).
    if (payer != null && !_c.splitPeople.contains(payer)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _c.link.paidBy;
        if (!mounted || p == null || _c.splitPeople.contains(p)) return;
        final d = SplitDraft()
          ..setPerson(p.name, contact: p.contactId, look: p.person);
        _c.setSplits([..._c.splits, d]);
      });
    }
    return SplitsSection(
      card: true,
      label: l.evbPeople(_c.splits.length + 1),
      totalAmount: _c.splitCap,
      drafts: _c.splits,
      onChanged: _c.setSplits,
      me: _c.meAmount ?? _c.amountValue,
      onMeChanged: _c.setMeAmount,
      meAuto: _c.meAuto,
      onMeAutoChanged: _c.setMeAuto,
      footer: _eventRow(),
      // "จ่าย" on every row: ฉัน by default, one person otherwise.
      payerChip: (d) {
        if (d == null) {
          return PayChip(
            label: l.evbPays,
            paid: payer == null,
            onTap: () => _c.setPaidBy(null),
          );
        }
        final person = d.personName.trim().isEmpty ? null : _personOfDraft(d);
        return PayChip(
          label: l.evbPays,
          paid: person != null && person == payer,
          onTap: person == null ? null : () => _c.setPaidBy(person),
        );
      },
    );
  }

  /// "อีเวนต์": the bill's event, added to the แบ่ง card; picking one turns
  /// the bill into an event bill.
  Widget _eventRow() {
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
      inCard: true,
    );
  }

  // ── แบ่ง with an event ───────────────────────────────────────────────
  Widget _eventCard(AppLocalizations l) {
    final link = _c.link;
    final bill = _c.amountValue;
    final members = _c.eventMembers;
    final payer = link.eventPayer;
    final isMember = widget.isEventMember;
    Widget? tagFor(LinkPerson p) =>
        widget.eventIsNew || (isMember != null && !isMember(p))
        ? AppChip(
            label: l.txLinkCardNewToEvent,
            size: ChipSize.mini,
            tone: AppChipTone.info,
            selected: true,
          )
        : null;
    Widget payChip(LinkPerson? p) => PayChip(
      label: l.evbPays,
      paid: p == null ? payer == null : payer == p,
      onTap: () => _c.setEventPayer(p),
    );
    final inSplits = {for (final p in _c.splitPeople) p.key};
    final extras = [
      for (final p in members)
        if (!inSplits.contains(p.key)) p,
    ];
    return ShareCard(
      key: const ValueKey('linkCardEvent'),
      title: l.evbPeople(members.length + 1),
      actions: [
        AppChip(
          label: l.txSplitEqually,
          enabled: members.isNotEmpty && bill > 0,
          onTap: _c.eventEqually,
          size: ChipSize.mini,
        ),
        AppChip(
          icon: AppIcons.add,
          label: l.txSplitAddPerson,
          onTap: _addPerson,
          size: ChipSize.mini,
        ),
      ],
      rows: [
        SplitMeRow(
          label: l.txLinkCardMe,
          amount: link.eventMine(bill, members),
          auto: link.eventMeAuto,
          onAutoChanged: _c.setEventMeAuto,
          onChanged: _c.setEventMeAmount,
          card: true,
          nameTrailing: payChip(null),
        ),
        for (final d in _c.splits)
          SplitDraftRow(
            key: ObjectKey(d),
            draft: d,
            card: true,
            autofocusName: identical(d, _justAdded),
            amount: link.eventShareOf(_personOfDraft(d), bill, members),
            onAmount: (v) => _c.setEventShare(_personOfDraft(d), v),
            tag: d.personName.trim().isEmpty ? null : tagFor(_personOfDraft(d)),
            nameTrailing: d.personName.trim().isEmpty
                ? null
                : payChip(_personOfDraft(d)),
            onChange: () => _c.setSplits(List.of(_c.splits)),
            onChangePerson: () => _changeDraftPerson(d),
            onRemove: () => d.personName.trim().isEmpty
                ? _c.setSplits([
                    for (final s in _c.splits)
                      if (!identical(s, d)) s,
                  ])
                : _c.removeEventMember(_personOfDraft(d)),
          ),
        for (final p in extras)
          ShareRow(
            key: ValueKey('linkEventExtra:${p.key}'),
            avatar: _mark(p),
            name: SplitRowName.picked(p.name),
            nameTrailing: payChip(p),
            amount: ShareAmountField(
              value: link.eventShareOf(p, bill, members),
              onChanged: (v) => _c.setEventShare(p, v),
            ),
            trailing: _remove(l, () => _c.removeEventMember(p)),
            tag: tagFor(p),
          ),
        _eventRow(),
      ],
      status: linkCardStatus(
        context,
        -link.eventDiff(bill, members),
        l.txLinkCardSplitOk,
      ),
    );
  }
}
