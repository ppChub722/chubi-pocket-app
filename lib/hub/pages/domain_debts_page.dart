import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import 'package:pp_forge/hub.dart';

/// `/dev/domain/debts` — the debts rework pieces: PersonRow,
/// PersonBalanceRow, NetBalance, DebtSummaryCard and LedgerRow. Sample data
/// is Thai (what the debts pages pass from l10n).
Widget buildDebtsPage(BuildContext context) => const _DebtsPage();

const _owedToMe = 'ติดคุณ';
const _iOwe = 'คุณติด';
const _settled = 'หายกัน';

class _DebtsPage extends StatefulWidget {
  const _DebtsPage();

  @override
  State<_DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<_DebtsPage> {
  String? _picked = 'มาตาก';
  String? _filter;
  String _last = '—';

  void _note(String s) => setState(() => _last = s);

  Widget _list(List<Widget> rows) => PpForgeCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const PpForgeDivider.row(),
          r,
        ],
      ],
    ),
  );

  static const _walletIcon = Icon(PpForgeIcons.wallet, size: 12);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Last tap: $_last', style: text.bodySmall),
        const SizedBox(height: PpForgeSpacing.md),
        // ---- PersonRow ----
        HubDemo(
          title: 'PersonRow',
          note:
              'A member / contact row on PersonMark (40): typed name, contact, '
              'linked + 🔗. The 🔗 slot is kept on every row so the names line '
              'up. Optional caption, role chip (chip 28), trailing slot; '
              'pending fades it; onTap null = not tappable. ListRow height.',
          child: _list([
            PersonRow(
              name: 'มาตาก',
              level: PersonLevel.linked,
              caption: 'ผูกบัญชีแล้ว',
              role: 'เจ้าของ',
              roleTone: PpForgeChipTone.primary,
              onTap: () => _note('PersonRow มาตาก'),
            ),
            PersonRow(
              name: 'บี',
              level: PersonLevel.contact,
              caption: 'ผู้ติดต่อ',
              role: 'สมาชิก',
              trailing: PpForgeIconButton.flat(
                icon: PpForgeIcons.chevronRight,
                dense: true,
                onPressed: () => _note('PersonRow trailing'),
              ),
              onTap: () => _note('PersonRow บี'),
            ),
            const PersonRow(name: 'ลี', level: PersonLevel.name),
            const PersonRow(
              name: 'ต้น',
              level: PersonLevel.linked,
              caption: 'รอตอบรับคำเชิญ',
              role: 'สมาชิก',
              pending: true,
            ),
          ]),
        ),
        // ---- PersonBalanceRow ----
        HubDemo(
          title: 'PersonBalanceRow',
          note:
              'The debts people row (list + picker): PersonMark · name · sub '
              'line · NetBalance (row). Tap to pick: selected = the highlight '
              'tint, never a ✓. Same height as PersonRow / ListRow.',
          child: _list([
            for (final (name, level, net, sub) in const [
              ('มาตาก', PersonLevel.linked, 1200, 'ค้าง 2 รายการ'),
              ('บี', PersonLevel.contact, -450.5, 'ค้าง 1 รายการ'),
              ('ลี', PersonLevel.name, 0, 'ไม่มีรายการค้าง'),
            ])
              PersonBalanceRow(
                name: name,
                level: level,
                net: net,
                subtitle: sub,
                owedToMeLabel: _owedToMe,
                iOweLabel: _iOwe,
                settledLabel: _settled,
                selected: _picked == name,
                onTap: () => setState(() => _picked = name),
              ),
          ]),
        ),
        // ---- NetBalance ----
        HubDemo(
          title: 'NetBalance — row',
          note:
              '> 0 they owe me (income colour), < 0 I owe (expense colour, '
              'shown positive), 0 the settled caption only, muted, no amount. '
              'Right-aligned, amount over caption.',
          child: const HubRow(
            cells: [
              HubCell(
                caption: '+1200',
                child: NetBalance(
                  amount: 1200,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '-450.5',
                child: NetBalance(
                  amount: -450.5,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '0',
                child: NetBalance(
                  amount: 0,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: 'currencySymbol \$',
                child: NetBalance(
                  amount: 80,
                  currencySymbol: '\$',
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'NetBalance — hero',
          note: 'The person page hero footer: a large amount over the caption.',
          child: const HubRow(
            cells: [
              HubCell(
                caption: '+12500',
                child: NetBalance(
                  amount: 12500,
                  size: NetBalanceSize.hero,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '-3000',
                child: NetBalance(
                  amount: -3000,
                  size: NetBalanceSize.hero,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '0',
                child: NetBalance(
                  amount: 0,
                  size: NetBalanceSize.hero,
                  owedToMeLabel: _owedToMe,
                  iOweLabel: _iOwe,
                  settledLabel: _settled,
                ),
              ),
            ],
          ),
        ),
        HubPlayground(
          title: 'NetBalance',
          hug: Alignment.centerLeft,
          controls: [
            const PlayNum(
              'amount',
              min: -5000,
              max: 5000,
              step: 250,
              initialValue: 1250,
            ),
            PlayChoice<NetBalanceSize>('size', [
              for (final s in NetBalanceSize.values) (s.name, s),
            ]),
            const PlayText('owedToMeLabel', initialValue: _owedToMe),
            const PlayText('iOweLabel', initialValue: _iOwe),
            const PlayText('settledLabel', initialValue: _settled),
            const PlayText('currencySymbol', initialValue: '฿'),
          ],
          builder: (context, v) => NetBalance(
            amount: v<double>('amount'),
            size: v<NetBalanceSize>('size'),
            owedToMeLabel: v<String>('owedToMeLabel'),
            iOweLabel: v<String>('iOweLabel'),
            settledLabel: v<String>('settledLabel'),
            currencySymbol: v<String>('currencySymbol'),
          ),
        ),
        // ---- DebtSummaryCard ----
        HubDemo(
          title: 'DebtSummaryCard',
          note:
              'The people list summary: the signed net + the 👁 toggle, then '
              'two tappable totals. A tap filters the list; the active box is '
              'ringed in its colour (tap again to clear here).',
          child: DebtSummaryCard(
            owedToMe: 3000,
            iOwe: 1750,
            netLabel: 'ยอดสุทธิ',
            owedToMeLabel: _owedToMe,
            iOweLabel: _iOwe,
            owedToMeSelected: _filter == 'owed',
            iOweSelected: _filter == 'owe',
            onOwedToMeTap: () =>
                setState(() => _filter = _filter == 'owed' ? null : 'owed'),
            onIOweTap: () =>
                setState(() => _filter = _filter == 'owe' ? null : 'owe'),
          ),
        ),
        HubDemo(
          title: 'DebtSummaryCard — I owe more, display only',
          note: 'No tap callbacks: the boxes are display only.',
          child: const DebtSummaryCard(
            owedToMe: 500,
            iOwe: 2200,
            netLabel: 'ยอดสุทธิ',
            owedToMeLabel: _owedToMe,
            iOweLabel: _iOwe,
          ),
        ),
        // ---- LedgerRow ----
        HubDemo(
          title: 'LedgerRow',
          note:
              'One debt entry, by direction: paid ↗ (expense colour) / '
              'received ↙ (income colour); the amount is always positive. '
              'Line 2: date · wallet mini chip · paid mini chip · source. '
              'Never a category. TxRow geometry.',
          child: _list([
            LedgerRow(
              direction: LedgerDirection.paid,
              amount: 500,
              title: 'ฉันจ่ายให้มาตาก',
              dateLabel: '12 ต.ค.',
              walletLabel: 'กสิกร',
              walletIcon: _walletIcon,
              onTap: () => _note('LedgerRow paid'),
            ),
            LedgerRow(
              direction: LedgerDirection.received,
              amount: 300,
              title: 'มาตากจ่ายให้ฉัน',
              dateLabel: '10 ต.ค.',
              walletLabel: 'เงินสด',
              walletIcon: _walletIcon,
              paidLabel: 'จ่ายแล้ว',
              onTap: () => _note('LedgerRow received'),
            ),
            LedgerRow(
              direction: LedgerDirection.received,
              amount: 240,
              title: 'ค่าข้าวเที่ยง',
              dateLabel: '8 ต.ค.',
              sourceLabel: 'ทริปเชียงใหม่',
              onTap: () => _note('LedgerRow split'),
            ),
            LedgerRow(
              direction: LedgerDirection.paid,
              amount: 1200,
              title: 'ค่าตั๋วคอนเสิร์ต',
              dateLabel: '1 ต.ค.',
              paidLabel: 'จ่ายแล้ว',
              sourceLabel: 'ค่าตั๋วคอนเสิร์ต (หาร 3)',
            ),
          ]),
        ),
        HubPlayground(
          title: 'LedgerRow',
          controls: [
            PlayChoice<LedgerDirection>('direction', [
              for (final d in LedgerDirection.values) (d.name, d),
            ]),
            const PlayNum(
              'amount',
              min: 0,
              max: 5000,
              step: 250,
              initialValue: 500,
            ),
            const PlayText('title', initialValue: 'ฉันจ่ายให้มาตาก'),
            const PlayText('dateLabel', initialValue: '12 ต.ค.'),
            const PlayBool('wallet', initialValue: true),
            const PlayBool('paid'),
            const PlayText('sourceLabel'),
          ],
          builder: (context, v) => LedgerRow(
            direction: v<LedgerDirection>('direction'),
            amount: v<double>('amount'),
            title: v<String>('title'),
            dateLabel: v<String>('dateLabel'),
            walletLabel: v<bool>('wallet') ? 'กสิกร' : null,
            walletIcon: _walletIcon,
            paidLabel: v<bool>('paid') ? 'จ่ายแล้ว' : null,
            sourceLabel: v<String>('sourceLabel'),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
