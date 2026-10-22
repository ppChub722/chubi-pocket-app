import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../domain/link_draft.dart';
import '../../domain/refs.dart';
import 'draft_form.dart';
import 'splits_section.dart';

/// Quick create's "ผูกกับ" (owner 2026-10-21, variant B): the รายการประจำ
/// row, then "ผูกกับ" + [ส่วนตัว | แบ่ง | จ่ายแทน | อีเวนต์] on one row, then
/// the active tab's card. The tabs edit ONE data set in [controller]; only
/// the active one is saved.
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

  static LinkPerson _personOf(ContactPick r) => switch (r) {
    ContactPicked(:final contact) => LinkPerson(
      name: contact.name,
      contactId: contact.id,
      person: EmbeddedPerson(
        name: contact.name,
        contactId: contact.id,
        iconCode: contact.iconCode,
        linked: contact.isLinked,
        linkedUserId: contact.linkedUser?.id,
      ),
    ),
    ContactNameTyped(:final name) ||
    ContactNamePicked(:final name) => LinkPerson(name: name.trim()),
  };

  static LinkPerson _personOfDraft(SplitDraft d) => LinkPerson(
    name: d.personName.trim(),
    contactId: d.contactId,
    person: d.person,
  );

  Future<void> _pickPaidBy() async {
    final now = _c.link.paidBy;
    final r = await ContactPicker.one(
      context,
      selectedId: now?.contactId,
      allowFreeText: true,
      allowCreate: true,
      initialName: now?.contactId == null ? now?.name : null,
    );
    if (r == null || !mounted) return;
    _c.setPaidBy(_personOf(r));
  }

  Future<void> _pickEventPayer() async {
    final l = AppLocalizations.of(context)!;
    final now = _c.link.eventPayer;
    final r = await ContactPicker.payer(
      context,
      title: l.txLinkCardWhoPaid,
      me: PickerNone(
        label: l.txLinkCardMe,
        leading: MyAvatar(fallbackName: l.txLinkCardMe),
      ),
      meSelected: now == null,
      selectedId: now?.contactId,
    );
    if (r == null || !mounted) return;
    _c.setEventPayer(switch (r) {
      PayerMe() => null,
      PayerPerson(:final pick) => _personOf(pick),
    });
  }

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
      LinkMode.split => SplitsSection(
        card: true,
        label: l.txLinkCardSplitTitle,
        totalAmount: _c.splitCap,
        drafts: _c.splits,
        onChanged: _c.setSplits,
        me: _c.meAmount,
        onMeChanged: _c.setMeAmount,
        meAuto: _c.meAuto,
        onMeAutoChanged: _c.setMeAuto,
      ),
      LinkMode.paid => _paidCard(l),
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
        label: l.txLinkTabLabel,
        selected: mode,
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
          AppTab(
            value: LinkMode.paid,
            label: l.txLinkTabPaid,
            icon: AppIcons.contact,
          ),
          AppTab(
            value: LinkMode.event,
            label: l.txLinkTabEvent,
            icon: AppIcons.project,
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

  Widget _pickChip(String label, VoidCallback onTap) =>
      SplitPickChip(label: label, onTap: onTap);

  Widget _remove(AppLocalizations l, VoidCallback onTap) => SplitRowAction(
    icon: AppIcons.close,
    tooltip: l.txSplitRemove,
    onTap: onTap,
  );

  // ── จ่ายแทน ──────────────────────────────────────────────────────────
  Widget _paidCard(AppLocalizations l) {
    final link = _c.link;
    final bill = _c.amountValue;
    final payer = link.paidBy;
    return ShareCard(
      key: const ValueKey('linkCardPaid'),
      title: l.txLinkCardPaidTitle,
      actions: [
        AppChip(
          label: l.txSplitEqually,
          enabled: payer != null && bill > 0,
          onTap: _c.paidEqually,
        ),
      ],
      rows: [
        SplitMeRow(
          label: l.txLinkCardMyPaid,
          amount: link.myPaid(bill),
          auto: link.myPaidAuto,
          onAutoChanged: _c.setMyPaidAuto,
          onChanged: _c.setMyPaid,
          card: true,
        ),
        if (payer == null)
          _pickChip(l.txLinkCardPickPayer, _pickPaidBy)
        else
          ShareRow(
            avatar: _mark(payer, onTap: _pickPaidBy),
            name: SplitRowName.picked(payer.name, onTap: _pickPaidBy),
            amount: ShareAmountField(
              value: link.paidAmountFor(bill),
              onChanged: _c.setPaidAmount,
            ),
            trailing: _remove(l, () => _c.setPaidBy(null)),
          ),
      ],
      status: payer == null
          ? null
          : linkCardStatus(context, -link.payDiff(bill), l.txLinkCardPaidOk),
    );
  }

  // ── อีเวนต์ ──────────────────────────────────────────────────────────
  Widget _eventCard(AppLocalizations l) {
    final link = _c.link;
    final bill = _c.amountValue;
    final members = _c.eventMembers;
    final payer = link.eventPayer;
    final event = widget.event;
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
    final inSplits = {for (final p in _c.splitPeople) p.key};
    final extras = [
      for (final p in members)
        if (!inSplits.contains(p.key)) p,
    ];
    return ShareCard(
      key: const ValueKey('linkCardEvent'),
      headerLeading: EventPickChip(
        name: event.name,
        onTap: event.onTap,
        onClear: event.onClear,
      ),
      rows: [
        ShareSubhead(title: l.txLinkCardWhoPaid),
        ShareRow(
          avatar: payer == null
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickEventPayer,
                  child: MyAvatar(fallbackName: l.txLinkCardMe),
                )
              : _mark(payer, onTap: _pickEventPayer),
          name: SplitRowName.picked(
            payer?.name ?? l.txLinkCardMe,
            onTap: _pickEventPayer,
          ),
          // One payer: they paid the whole bill.
          amount: ShareAmountField(value: bill, onChanged: null),
        ),
        ShareSubhead(
          title: l.txLinkCardWhoInBill,
          actions: [
            AppChip(
              label: l.txSplitEqually,
              enabled: members.isNotEmpty && bill > 0,
              onTap: _c.eventEqually,
            ),
            AppChip(
              icon: AppIcons.add,
              label: l.txSplitAddPerson,
              onTap: _addPerson,
            ),
          ],
        ),
        SplitMeRow(
          label: l.txLinkCardMe,
          amount: link.eventMine(bill, members),
          auto: link.eventMeAuto,
          onAutoChanged: _c.setEventMeAuto,
          onChanged: _c.setEventMeAmount,
          card: true,
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
            amount: ShareAmountField(
              value: link.eventShareOf(p, bill, members),
              onChanged: (v) => _c.setEventShare(p, v),
            ),
            trailing: _remove(l, () => _c.removeEventMember(p)),
            tag: tagFor(p),
          ),
      ],
      status: linkCardStatus(
        context,
        -link.eventDiff(bill, members),
        l.txLinkCardSplitOk,
      ),
    );
  }
}
