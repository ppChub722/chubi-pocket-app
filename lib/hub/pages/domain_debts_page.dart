import 'package:flutter/material.dart';

import '../../features/transactions/domain/transaction_type.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/debts` — the debts pieces: NetBalance, the debt hero pieces
/// and the debt pages' rows (AppListRow). Sample data is Thai (what the debts
/// pages pass from l10n).
Widget buildDebtsPage(BuildContext context) => const _DebtsPage();

const _owedToMe = 'รอรับ';
const _iOwe = 'รอจ่าย';
const _settled = 'หายกัน';

class _DebtsPage extends StatefulWidget {
  const _DebtsPage();

  @override
  State<_DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<_DebtsPage> {
  String _last = '—';
  bool _towardMe = true;
  bool _settle = false;
  bool _moneyMoves = false;
  final _amount = TextEditingController(text: '1232');
  final _origin = TextEditingController(text: 'ให้ ลี ยืม');

  @override
  void dispose() {
    _amount.dispose();
    _origin.dispose();
    super.dispose();
  }

  void _note(String s) => setState(() => _last = s);

  Widget _list(List<Widget> rows) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const AppDivider.row(),
          r,
        ],
      ],
    ),
  );

  Widget _person() => PickCard(
    label: 'กับใคร',
    value: 'ลี ทดสอบ',
    dense: true,
    editable: true,
    reserveSubtitle: true,
    accent: Theme.of(context).colorScheme.primary,
    leading: const PersonMark(name: 'ลี', level: PersonLevel.linked, size: 32),
    onTap: () => _note('person card'),
  );

  Widget _me() => _moneyMoves
      ? WalletPickCard(
          account: null,
          label: 'กระเป๋า',
          placeholder: 'เลือกกระเป๋า',
          dense: true,
          editable: true,
          onTap: () => _note('wallet card'),
        )
      : const MeFlowCard(label: 'ฉัน', name: 'ปอนด์');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Last tap: $_last', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        // ---- Debt pages (owner 2026-10-22, mocks DebtPerson / DebtEntry) ----
        HubDemo(
          title: 'Debt person + entry pieces',
          note:
              'The person hero line (sentence + big amount), its two buttons '
              '(settle in the side colour, สรุปยอด / ทวง), a day header with '
              'the day change, statement rows (debt / repayment on a soft '
              'background, the ✓ จ่ายแล้ว pill), the earlier-cycles divider, '
              'the entry line under the amount, and a person row with its '
              'age. The share sheet opens from the button.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DebtSentenceAmount(
                sentence: 'รอจ่ายให้ลี',
                amount: const MoneyText(230),
                color: debtStateColor(context, owedToMe: false),
              ),
              const SizedBox(height: AppSpacing.sm),
              DebtPersonActions(
                color: debtStateColor(context, owedToMe: false),
                settleLabel: 'จ่ายคืน ฿230',
                onSettle: () => _note('settle'),
                shareLabel: 'สรุปยอด',
                onShare: () => showAppSheet<void>(
                  context,
                  title: 'สรุปยอดกับลี',
                  builder: (_) => DebtShareSheet(
                    variants: const [
                      (
                        label: 'รอบนี้',
                        text: 'สรุปยอดกับลี\n• 25 ก.ย. ค่าอาหาร 60',
                      ),
                      (
                        label: 'ยอดคงเหลืออย่างเดียว',
                        text: 'ยอดกับลี ตอนนี้: ฉันรอจ่ายให้ลี 230 บาท',
                      ),
                    ],
                    fieldLabel: 'ข้อความ (แก้ได้ก่อนส่ง)',
                    copyLabel: 'คัดลอก',
                    shareLabel: 'แชร์ไป LINE / แอปอื่น',
                    onCopy: (t) => _note('copy ${t.length}'),
                    onShare: (t) => _note('share ${t.length}'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DateGroupHeader(
                label: 'ศ. 10 ต.ค. 2026',
                note: 'ลดลง ฿400',
                noteColor: Theme.of(context).colorScheme.primary,
              ),
              // Statement rows: the app's AppListRow (owner 2026-10-23).
              _list([
                AppListRow(
                  leading: IconTile(
                    icon: AppIcons.cash,
                    color: Theme.of(context).colorScheme.primary,
                    size: 36,
                  ),
                  title: 'คุณจ่ายคืนลี',
                  line2: const ListRowLine(parts: ['จากกระเป๋า test2']),
                  trailing: ListRowTrailing.value(const MoneyText(400)),
                  onTap: () => _note('repayment'),
                ),
                AppListRow(
                  leading: IconTile(
                    icon: AppIcons.debt,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 36,
                  ),
                  title: 'ค่าอาหาร',
                  status: const ListRowChip('จ่ายแล้ว', icon: AppIcons.check),
                  line2: const ListRowLine(parts: ['ลีจ่ายแทน']),
                  trailing: ListRowTrailing.value(
                    const MoneyText(60, tone: MoneyTone.expense),
                  ),
                  onTap: () => _note('debt'),
                ),
              ]),
              CycleDivider(
                label: 'เคลียร์ครบ 20 ส.ค. | ดูรอบก่อน ▾',
                onTap: () => _note('earlier'),
              ),
              DebtEntryNote(
                sentence: 'รอรับจาก chalee',
                amount: const MoneyText(82),
                color: debtStateColor(context, owedToMe: true),
                paidLabel: '✓ จ่ายแล้ว',
              ),
              const SizedBox(height: AppSpacing.sm),
              // The debts list rows: AppListRow; past 30 days or overdue the
              // line is the warning colour.
              _list([
                AppListRow(
                  leading: const PersonMark(
                    name: 'ลี',
                    level: PersonLevel.linked,
                    size: 36,
                  ),
                  title: 'ลี ทดสอบ',
                  line2: const ListRowLine(parts: ['ครบกำหนด 30 ต.ค.']),
                  trailing: ListRowTrailing.value(
                    const MoneyText(1232, tone: MoneyTone.income),
                  ),
                  onTap: () => _note('person'),
                ),
                AppListRow(
                  leading: const PersonMark(
                    name: 'แบงค์',
                    level: PersonLevel.contact,
                    size: 36,
                  ),
                  title: 'แบงค์ ทดสอบ',
                  line2: ListRowLine(
                    spans: [
                      TextSpan(
                        text: 'ค้างมา 50 วันแล้ว',
                        style: TextStyle(
                          color: Tone.warning.color(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: ListRowTrailing.value(
                    const MoneyText(300, tone: MoneyTone.income),
                  ),
                  onTap: () => _note('person'),
                ),
              ]),
            ],
          ),
        ),
        // ---- Quick create · หนี้ (owner 2026-10-21) ----
        HubDemo(
          title: 'DebtModeChips + DebtResultBox — quick create หนี้',
          note:
              'No sub-tabs: two chips where the tx mode has รายจ่าย / รายรับ '
              '(record | settle): "จดหนี้" | "จ่ายหนี้", no direction words; the '
              'colour follows the direction. The '
              'arrow between the cards swaps it (tap "swap" here). '
              'DebtResultBox is the old three-line result (no longer used by '
              'quick create: a one-line caption replaced it).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DebtModeChips(
                      towardMe: _towardMe,
                      settle: _settle,
                      recordLabel: 'จดหนี้',
                      settleLabel: 'จ่ายหนี้',
                      onChanged: (s) => setState(() => _settle = s),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _towardMe = !_towardMe),
                    child: const Text('swap'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DebtResultBox(
                nowLabel: 'ลี ตอนนี้',
                afterLabel: 'หลังบันทึก',
                before: '$_iOwe ฿160.00',
                after: '$_owedToMe ฿40.00',
                beforeColor: debtStateColor(context, owedToMe: false),
                afterColor: debtStateColor(context, owedToMe: true),
                walletLabel: 'กระเป๋า test2',
                walletValue: '−฿200.00',
                warning: 'เกินยอดค้าง — หลังบันทึกจะกลายเป็น $_owedToMe ฿40.00',
              ),
              const SizedBox(height: AppSpacing.sm),
              DebtResultBox(
                nowLabel: 'ลี ตอนนี้',
                afterLabel: 'หลังบันทึก',
                before: '$_iOwe ฿230.00',
                after: '✓ เคลียร์ครบ',
                beforeColor: debtStateColor(context, owedToMe: false),
                afterColor: Theme.of(context).colorScheme.primary,
                walletLabel: 'กระเป๋า',
                walletValue: 'ไม่เปลี่ยน',
                loading: true,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        HubDemo(
          title: 'MeFlowCard + read-only ที่มา — debt hero',
          note:
              'Owner 2026-10-23. The description cell is app-made text '
              '("ที่มา": titleReadOnly, no underline, nothing to type). The '
              'pair is [กับใคร] ⇄ [ฉัน], both in the app colour: with the '
              'switch off the "ฉัน" card only says who the money goes to / '
              'comes from; with it on (settle: always) it is the usual wallet '
              'card. Under the switch, above the tag row: the summary row '
              '(DebtSummaryRow; green / red / cleared / overpay).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EntryCard(
                debt: true,
                type: _towardMe
                    ? TransactionType.expense
                    : TransactionType.income,
                typeBadge: DebtModeChips(
                  towardMe: _towardMe,
                  settle: false,
                  recordLabel: 'จดหนี้',
                  settleLabel: 'จ่ายหนี้',
                  onChanged: (_) {},
                ),
                amount: _amount,
                title: _origin,
                titleReadOnly: true,
                titleLabel: 'ที่มา',
                dateLabel: 'วันนี้',
                flowRow: FlowCards(
                  from: _towardMe ? _me() : _person(),
                  to: _towardMe ? _person() : _me(),
                  onSwap: () => setState(() => _towardMe = !_towardMe),
                  swapTooltip: 'สลับ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Expanded(child: Text('ทำรายการเงิน (tx) ด้วย')),
                  AppSwitch(
                    value: _moneyMoves,
                    onChanged: (v) => setState(() => _moneyMoves = v),
                    semanticLabel: 'ทำรายการเงิน',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DebtSummaryRow(
                label: 'หลังบันทึก',
                words: _towardMe ? 'ลี เป็นลูกหนี้' : 'ลี เป็นเจ้าหนี้',
                amount: '฿2,464',
                tone: _towardMe
                    ? DebtSummaryTone.owedToMe
                    : DebtSummaryTone.iOwe,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DebtSummaryRow(
                label: 'หลังบันทึก',
                words: 'เคลียร์ครบกับ ลี แล้ว',
                tone: DebtSummaryTone.cleared,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DebtSummaryRow(
                label: 'หลังบันทึก',
                words: 'ลี กลายเป็นเจ้าหนี้',
                amount: '฿40',
                tone: DebtSummaryTone.warn,
              ),
            ],
          ),
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
        // ---- DebtAmountLine / DebtAgeText / DebtNetLine ----
        HubDemo(
          title: 'DebtAmountLine + DebtAgeText',
          note:
              'The debt person hero\'s row C: a pill chip (รอรับ green / '
              'รอจ่าย red) + the amount on ONE line; settled = the muted '
              'word alone. DebtAgeText is the "ค้าง N วัน" fact line, amber '
              'when warn.',
          child: const HubRow(
            cells: [
              HubCell(
                caption: '+1189.67',
                child: DebtAmountLine(
                  net: 1189.67,
                  owedToMeLabel: 'รอรับ',
                  iOweLabel: 'รอจ่าย',
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '-450.5',
                child: DebtAmountLine(
                  net: -450.5,
                  owedToMeLabel: 'รอรับ',
                  iOweLabel: 'รอจ่าย',
                  settledLabel: _settled,
                ),
              ),
              HubCell(
                caption: '0',
                child: DebtAmountLine(
                  net: 0,
                  owedToMeLabel: 'รอรับ',
                  iOweLabel: 'รอจ่าย',
                  settledLabel: _settled,
                ),
              ),
              HubCell(caption: 'age', child: DebtAgeText('ค้าง 6 วัน')),
              HubCell(
                caption: 'age warn',
                child: DebtAgeText('ค้าง 45 วัน', warn: true),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'DebtNetLine',
          note: 'The list card\'s net line (only when both sides are open).',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DebtNetLine(label: 'สุทธิ', net: 1250),
              DebtNetLine(label: 'สุทธิ', net: -300),
            ],
          ),
        ),
        // ---- DebtSummaryMessageBox ----
        HubDemo(
          title: 'DebtSummaryMessageBox',
          note:
              'The hero\'s embedded tool: the BE-built message in an editable '
              'multiline field (edits are local, one-off) + two equal buttons. '
              'The callbacks get the text as it is now.',
          child: DebtSummaryMessageBox(
            text:
                'สรุปยอดกับ test\n• 10 ต.ค. ค่าไรก็ได้ +฿667.67\n'
                '• 11 ต.ค. Gaming +฿522.00\nรวม รอรับจาก test ฿1,189.67',
            label: 'ข้อความสรุปยอด | แก้ได้ก่อนส่ง',
            copyLabel: 'คัดลอก',
            shareLabel: 'แชร์',
            onCopy: (t) => _note('copy ${t.length} chars'),
            onShare: (t) => _note('share ${t.length} chars'),
          ),
        ),
      ],
    );
  }
}
