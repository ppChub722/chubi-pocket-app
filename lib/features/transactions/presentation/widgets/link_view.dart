import 'package:flutter/material.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import 'splits_section.dart';

/// The tx detail's ผูกกับ in VIEW mode (0.4.0-3): one summary row per link,
/// "จ่ายโดย ลี ฿13 | ฉันจ่ายเอง ฿110 ›", "บิลอีเวนต์ ลีจ่าย | 5 คน ›"; ›
/// opens that card read-only. Nothing to show → nothing.
class LinkViewRows extends StatelessWidget {
  const LinkViewRows({
    required this.tx,
    this.onOpenEvent,
    this.onApplyEvent,
    super.key,
  });

  final Transaction tx;
  final VoidCallback? onOpenEvent;

  /// The bill and my tx differ (B3 in_sync false): "อัปเดตตามอีเวนต์".
  final VoidCallback? onApplyEvent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final paid = tx.paidBy;
    final bill = tx.eventBill;
    final payer = bill?.payer;
    final members = bill?.members ?? const <BillShare>[];
    String money(double v) => moneyString(context, v);
    final rows = [
      if (paid != null)
        InfoRow(
          key: const ValueKey('linkViewPaid'),
          label: l.txLinkViewPaidLabel,
          value: [
            '${paid.person.name} ${money(paid.amount)}',
            if (paid.myPaid > 0.005) l.txLinkViewMyPaid(money(paid.myPaid)),
          ].join(' | '),
          showChevron: true,
          onTap: () => _show(context, _paidCard(context, l, paid)),
        ),
      if (bill != null && payer != null)
        InfoRow(
          key: const ValueKey('linkViewEvent'),
          label: l.txLinkViewEventLabel,
          value: [
            payer.isMe ? l.txLinkViewIPaid : l.txLinkViewTheyPaid(payer.name),
            l.txLinkViewPeople(members.length),
          ].join(' | '),
          showChevron: true,
          onTap: () => _show(context, _eventCard(context, l, bill, payer)),
        ),
      if (bill?.inSync == false && onApplyEvent != null)
        InfoRow(
          key: const ValueKey('linkViewApplyEvent'),
          label: l.txLinkOutOfSyncLabel,
          value: l.txLinkApplyEvent,
          showChevron: true,
          onTap: onApplyEvent,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    // Not first: the kit's section gap above it.
    return InfoBox(rows: rows);
  }

  static Future<void> _show(BuildContext context, Widget card) =>
      showAppSheet<void>(context, padded: true, builder: (_) => card);

  static Widget _amount(double v) =>
      ShareAmountField(value: v, onChanged: null);

  static Widget _memberMark(BillMemberRef m, AppLocalizations l) => m.isMe
      ? MyAvatar(fallbackName: l.txLinkCardMe)
      : PersonMark(
          name: m.name,
          level: m.userId != null ? PersonLevel.linked : PersonLevel.name,
          iconCode: m.iconCode,
          size: SplitRow.avatarSize,
          reserveLinkSlot: true,
        );

  Widget _paidCard(BuildContext context, AppLocalizations l, TxPaidBy p) {
    void openPerson() {
      Navigator.of(context, rootNavigator: true).pop();
      openPage(context, debtPersonPath(p.key));
    }

    return ShareCard(
      key: const ValueKey('linkViewPaidCard'),
      title: l.txLinkCardPaidTitle,
      rows: [
        ShareRow(
          avatar: MyAvatar(fallbackName: l.txLinkCardMe),
          name: SplitRowName.muted(l.txLinkCardMyPaid),
          amount: _amount(p.myPaid),
        ),
        ShareRow(
          avatar: PersonMark(
            name: p.person.name,
            level: p.person.contactId == null
                ? PersonLevel.name
                : p.person.linked
                ? PersonLevel.linked
                : PersonLevel.contact,
            iconCode: p.person.iconCode,
            size: SplitRow.avatarSize,
            reserveLinkSlot: true,
          ),
          name: SplitRowName.picked(p.person.name, onTap: openPerson),
          amount: _amount(p.amount),
        ),
      ],
      status: ShareStatus(l.txLinkCardPaidOk, ok: true),
    );
  }

  Widget _eventCard(
    BuildContext context,
    AppLocalizations l,
    EventBillLink bill,
    BillMemberRef payer,
  ) {
    final open = onOpenEvent;
    String nameOf(BillMemberRef m) => m.isMe ? l.txLinkCardMe : m.name;
    return ShareCard(
      key: const ValueKey('linkViewEventCard'),
      headerLeading: EventPickChip(
        name: bill.event.name,
        editing: false,
        onTap: open == null
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                open();
              },
      ),
      rows: [
        ShareSubhead(title: l.txLinkCardWhoPaid),
        ShareRow(
          avatar: _memberMark(payer, l),
          name: SplitRowName.picked(nameOf(payer)),
          amount: _amount(bill.billAmount),
        ),
        ShareSubhead(title: l.txLinkCardWhoInBill),
        for (final m in bill.members ?? const <BillShare>[])
          ShareRow(
            avatar: _memberMark(m.member, l),
            name: m.member.isMe
                ? SplitRowName.muted(l.txLinkCardMe)
                : SplitRowName.picked(m.member.name),
            amount: _amount(m.share),
          ),
      ],
      status: ShareStatus(l.txLinkCardSplitOk, ok: true),
    );
  }
}
