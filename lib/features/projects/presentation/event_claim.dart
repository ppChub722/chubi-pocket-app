import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/projects_repository.dart';
import '../domain/claim.dart';
import 'widgets/project_tx_tiles.dart' show projectTxDateLabel;

/// "ลงสมุดของฉัน" from an event (V6 / V7 lump, V9 / V10 claim); the confirm
/// is ONE call (the rest rides `effects`). True = claimed.
///
/// - **With a person** ([memberId], or my [contactId] / a typed [personName]
///   — the server finds the member): their bills with me, unclaimed ones
///   ticked, grouped by who owes whom; the picked ones become one debt + my
///   copies. [onlyBillId] = that bill only.
/// - **Join** ([linkTransactionId] and no person): ONE bill of the event
///   that someone else paid and I hold no copy of; my tx becomes its copy.
Future<bool> showClaimSheet(
  BuildContext context, {
  required String projectId,
  String? memberId,
  String? contactId,
  String? personName,
  String? memberName,
  String? onlyBillId,
  String? linkTransactionId,
}) async {
  final l = AppLocalizations.of(context)!;
  final repo = context.read<ProjectsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final join =
      linkTransactionId != null &&
      memberId == null &&
      contactId == null &&
      personName == null;
  List<ClaimableBill> bills;
  try {
    bills = await repo.claimable(
      projectId,
      memberId: memberId,
      contactId: contactId,
      personName: personName,
    );
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, errorText(l, e), tone: Tone.danger);
    return false;
  }
  bills = [
    for (final b in bills)
      if ((onlyBillId == null || b.ptId == onlyBillId) && (!join || b.joinable))
        b,
  ];
  if (bills.every((b) => b.claimed)) {
    showAppSnackBarOn(messenger, l.evbClaimNothing);
    return false;
  }
  if (!context.mounted) return false;
  final symbol = context.readUserCurrencySymbol;
  final name = memberName ?? bills.first.other.name;
  String groupOf(ClaimableBill b) =>
      b.isDebtType ? 'back' : (b.theyOweMe ? 'owed' : 'owe');
  // Multi-payer: "จ่าย ลี ฿700, ปอนด์ ฿500"; one payer = nothing extra.
  String? payersOf(ClaimableBill b) => b.payers.length < 2
      ? null
      : l.evbPayersLine(
          [
            for (final p in b.payers)
              '${p.member.name} ${moneyString(context, p.amount, symbol: symbol)}',
          ].join(', '),
        );
  String titleOf(ClaimableBill b) => b.description?.trim().isNotEmpty ?? false
      ? b.description!.trim()
      : l.evbClaimUntitled;
  var claimed = false;

  Future<bool> claim(String member, List<String> ids) async {
    try {
      await repo.claimBills(
        projectId,
        memberId: member,
        billIds: ids,
        linkTransactionId: linkTransactionId,
      );
      claimed = true;
      return true;
    } on ApiException catch (e) {
      showAppSnackBarOn(messenger, switch (e.code) {
        'CLAIM_MIXED_DIRECTION' => l.evbClaimMixed,
        'BILL_ALREADY_BOOKED' => l.evbClaimAlready,
        _ => errorText(l, e),
      }, tone: Tone.danger);
      return false;
    }
  }

  if (join) {
    final byId = {for (final b in bills) b.ptId: b};
    await showItemPicker(
      context,
      ItemPickerSheet(
        title: l.evbJoinTitle,
        searchable: bills.length > 6,
        items: [
          for (final b in bills)
            PickerItem(
              id: b.ptId,
              title: titleOf(b),
              subtitle: [
                projectTxDateLabel(context, b.date),
                payersOf(b) ?? l.evbJoinPaidBy(b.other.name),
              ].join(' | '),
              trailing: MoneyText(b.amount, symbol: symbol),
            ),
        ],
        onConfirm: (r) async {
          final b = byId[r.ids.firstOrNull];
          if (b == null) return false;
          final ok = await claim(b.other.id, [b.ptId]);
          if (ok) {
            showAppSnackBarOn(messenger, l.evbJoined, tone: Tone.success);
          }
          return ok;
        },
      ),
    );
    return claimed;
  }

  final member = bills.first.other.id;
  await showItemPicker(
    context,
    ItemPickerSheet(
      title: l.evbClaimTitle(name),
      multi: true,
      searchable: false,
      groups: [
        PickerGroup('owed', l.evbClaimTheyOwe(name)),
        PickerGroup('owe', l.evbClaimIOwe(name)),
        PickerGroup('back', l.evbClaimPaybacks),
      ],
      items: [
        for (final b in bills)
          PickerItem(
            id: b.ptId,
            title: titleOf(b),
            subtitle: b.claimed
                ? l.evbClaimDone
                : [
                    projectTxDateLabel(context, b.date),
                    ?payersOf(b),
                  ].join(' | '),
            group: groupOf(b),
            enabled: !b.claimed,
            trailing: MoneyText(
              b.amount,
              tone: b.theyOweMe ? MoneyTone.income : MoneyTone.expense,
              symbol: symbol,
            ),
          ),
      ],
      selected: {
        for (final b in bills)
          if (!b.claimed) b.ptId,
      },
      minPicks: 1,
      note: l.evbClaimNote,
      confirmLabel: l.evbClaimConfirm,
      onConfirm: (r) async {
        final ok = await claim(member, r.ids);
        if (ok) {
          showAppSnackBarOn(messenger, l.evbClaimed(name), tone: Tone.success);
        }
        return ok;
      },
    ),
  );
  return claimed;
}
