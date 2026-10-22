import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../personal_debts/presentation/widgets/debt_entry_picker.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../domain/refs.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'pick_chip_rows.dart';

class DebtPick {
  const DebtPick({
    required this.key,
    required this.person,
    this.net,
    this.typedName,
  });

  final String key;
  final EmbeddedPerson person;
  final double? net;

  final String? typedName;

  DebtPick withNet(double? n) =>
      DebtPick(key: key, person: person, net: n, typedName: typedName);
}

/// The person card's third line: what is open with them right now, the amount
/// coloured like the debts page (green = owed to me, red = I owe).
Widget? debtNetSubtitle(BuildContext context, AppLocalizations l, double? net) {
  if (net == null) return null;
  if (net.abs() <= 0.004) return Text(l.debtSettledLabel);
  final owedToMe = net > 0;
  final palette = Theme.of(context).extension<AppColors>()!;
  final money = moneyString(
    context,
    net.abs(),
    symbol: debtCurrencySymbol(context),
  );
  return Text.rich(
    TextSpan(
      text: '${owedToMe ? l.debtsOwedToMe : l.debtsIOwe} ',
      children: [
        TextSpan(
          text: money,
          style: AppTypography.of(
            context,
            AppTextRole.money,
          )?.copyWith(color: owedToMe ? palette.income : palette.expense),
        ),
      ],
    ),
  );
}

/// Quick create's debt mode. [sub] picks the side (owner 2026-10-21):
/// record a debt (a ledger row; money in a wallet only when
/// [createTransaction]) or repay (ONE transaction tied to the person; a wallet
/// is always needed).
class DebtEntryController extends ChangeNotifier {
  DebtEntryController({
    DebtPick? person,
    DebtEntrySub sub = DebtEntrySub.record,
  }) : _person = person,
       _sub = sub {
    amount.addListener(notifyListeners);
    description.addListener(notifyListeners);
  }

  DebtEntryDirection direction = DebtEntryDirection.paid;
  final amount = TextEditingController();
  final description = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();

  /// "มีเงินเข้า/ออกกระเป๋า": off by default (owner 2026-10-21).
  bool createTransaction = false;

  DebtEntrySub _sub;
  DebtEntrySub get sub => _sub;
  bool get repaying => _sub == DebtEntrySub.repay;

  DebtRepaymentKind repayKind = DebtRepaymentKind.pay;

  /// Words for the default description of a repayment ("จ่ายคืน ลี"); set by
  /// the form, which has the localizations.
  String Function(DebtRepaymentKind kind, String name)? describeRepay;

  /// The amount / description this controller filled itself: replaced when
  /// the person or kind changes, kept once the person types their own.
  String? _autoAmount;
  String? _autoDescription;

  Account? account;
  final Set<String> tagIds = {};
  final Map<String, Tag> knownTags = {};
  final Set<String> markPaidIds = {};

  DebtPick? _person;
  DebtPick? get person => _person;

  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  /// The person's balance after saving (> 0 = they owe me); instant typing
  /// feedback only, the BE answers the real one.
  double? get netAfter {
    final n = _person?.net;
    if (n == null) return null;
    if (repaying) {
      return n +
          (repayKind == DebtRepaymentKind.pay ? amountValue : -amountValue);
    }
    return n +
        (direction == DebtEntryDirection.paid ? amountValue : -amountValue);
  }

  bool get hasKeyData => amountValue > 0 || description.text.trim().isNotEmpty;

  void setSub(DebtEntrySub s) {
    if (s == _sub) return;
    _sub = s;
    markPaidIds.clear();
    if (repaying) _repayDefaults(kindFromBalance: true);
    notifyListeners();
  }

  void setRepayKind(DebtRepaymentKind k) {
    if (k == repayKind) return;
    repayKind = k;
    _repayDefaults(kindFromBalance: false);
    notifyListeners();
  }

  void setDirection(DebtEntryDirection d) {
    if (d == direction) return;
    direction = d;
    notifyListeners();
  }

  void setPerson(DebtPick? p) {
    if (p?.key != _person?.key) markPaidIds.clear();
    _person = p;
    if (repaying) _repayDefaults(kindFromBalance: true);
    notifyListeners();
  }

  /// Applies the repay defaults now (the form calls it once its words are in).
  void syncRepayDefaults() {
    if (!repaying) return;
    _repayDefaults(kindFromBalance: true);
    notifyListeners();
  }

  /// Repay: the kind from the balance, the full open amount, "จ่ายคืน ลี";
  /// whatever the person typed themselves stays.
  void _repayDefaults({required bool kindFromBalance}) {
    final p = _person;
    if (p == null) return;
    final net = p.net ?? 0;
    if (kindFromBalance && net.abs() > 0.004) {
      repayKind = DebtRepaymentKind.forNet(net);
    }
    if (amount.text.isEmpty || amount.text == _autoAmount) {
      final open = net.abs();
      _autoAmount = open <= 0.004
          ? ''
          : (open == open.roundToDouble()
                ? open.toStringAsFixed(0)
                : open.toStringAsFixed(2));
      amount.text = _autoAmount!;
    }
    final describe = describeRepay;
    if (describe != null &&
        (description.text.isEmpty || description.text == _autoDescription)) {
      _autoDescription = describe(repayKind, p.person.name);
      description.text = _autoDescription!;
    }
  }

  void setAccount(Account? a) {
    account = a;
    notifyListeners();
  }

  void setCreateTransaction(bool v) {
    if (v == createTransaction) return;
    createTransaction = v;
    notifyListeners();
  }

  void clearMarkPaid() {
    markPaidIds.clear();
    notifyListeners();
  }

  void setMarkPaidIds(Set<String> ids) {
    markPaidIds
      ..clear()
      ..addAll(ids);
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

  void toggleMarkPaid(String id) {
    if (!markPaidIds.remove(id)) markPaidIds.add(id);
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    note.dispose();
    super.dispose();
  }
}

class DebtEntryForm extends StatefulWidget {
  const DebtEntryForm({
    required this.controller,
    this.heroKey,
    this.autofocus = false,
    super.key,
  });

  final DebtEntryController controller;
  final GlobalKey? heroKey;
  final bool autofocus;

  @override
  State<DebtEntryForm> createState() => _DebtEntryFormState();
}

class _DebtEntryFormState extends State<DebtEntryForm> {
  DebtEntryController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  bool _wordsSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppLocalizations.of(context)!;
    _c.describeRepay = (kind, name) => kind == DebtRepaymentKind.pay
        ? l.debtRepayDescPay(name)
        : l.debtRepayDescReceive(name);
    if (!_wordsSet) {
      _wordsSet = true;
      // Opened on the repay side (a preset): fill its defaults once.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.syncRepayDefaults();
      });
    }
  }

  /// Repay: only people with something open, each with their balance.
  Future<void> _pickOpenPerson() async {
    final l = AppLocalizations.of(context)!;
    final directory = context.read<DebtDirectoryCubit>();
    final symbol = debtCurrencySymbol(context);
    final open = [
      for (final p in directory.state.people)
        if (p.net.abs() > 0.004) p,
    ];
    final r = await showItemPicker(
      context,
      ItemPickerSheet(
        title: l.debtRepayPickTitle,
        selected: {?_c.person?.key},
        emptyText: l.debtRepayNoOpen,
        items: [
          for (final p in open)
            PickerItem(
              id: p.key,
              title: p.person.name,
              subtitle:
                  '${p.net > 0 ? l.debtsOwedToMe : l.debtsIOwe} '
                  '${moneyString(context, p.net.abs(), symbol: symbol)}',
              leading: PersonMark(
                name: p.person.name,
                level: debtPersonLevel(p.person),
                iconCode: p.person.iconCode,
                size: 32,
              ),
            ),
        ],
      ),
    );
    final id = r?.id;
    if (id == null || !mounted) return;
    final p = open.firstWhere((p) => p.key == id);
    _c.setPerson(DebtPick(key: p.key, person: p.person, net: p.net));
  }

  Future<void> _loadPeople() async {
    final directory = context.read<DebtDirectoryCubit>();
    try {
      await directory.loadIfNeeded();
    } catch (_) {}
    if (!mounted) return;
    final p = _c.person;
    if (p != null && p.net == null) {
      _c.setPerson(p.withNet(directory.byKey(p.key)?.net ?? 0));
    }
  }

  Future<void> _pickPerson() async {
    final picked = await showDebtPersonPicker(context, selected: _c.person);
    if (picked != null && mounted) _c.setPerson(picked);
  }

  Future<void> _pickAccount() async {
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await AccountPicker.one(
      context,
      accounts: accounts,
      selectedId: _c.account?.id,
      // A repayment is a real transaction: it always has a wallet.
      allowNone: !_c.repaying,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _c.setAccount(r is AccountPicked ? r.account : null);
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

  Future<void> _moreTags() async {
    final next = await TagPicker.many(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next.ids);
  }

  String _dayLabel(AppLocalizations l, DateTime d) => DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );

  Widget? _resultLine(AppLocalizations l, String symbol) {
    final p = _c.person;
    final after = _c.netAfter;
    if (p == null || after == null || _c.amountValue <= 0) return null;
    final name = p.person.name;
    final money = moneyString(context, after.abs(), symbol: symbol);
    final before = p.net ?? 0;
    // Repay: "หลังบันทึก เหลือ ฿230" / "เคลียร์ครบ" while it still settles the
    // same way; past zero it says who owes whom, like recording a debt.
    if (_c.repaying && (after.abs() <= 0.004 || after.sign == before.sign)) {
      return AppText(
        after.abs() <= 0.004 ? l.debtRepayCleared : l.debtRepayLeft(money),
        role: AppTextRole.caption,
      );
    }
    final result = after > 0.004
        ? '${l.debtTheyOweYou(name)} $money'
        : after < -0.004
        ? '${l.debtYouOwe(name)} $money'
        : l.debtSettledLabel;
    return AppText(l.debtResultAfter(result), role: AppTextRole.caption);
  }

  Widget _personCard(AppLocalizations l) {
    final p = _c.person;
    return PickCard(
      label: !_c.repaying
          ? l.debtPersonPickerTitle
          : _c.repayKind == DebtRepaymentKind.pay
          ? l.debtRepayTo
          : l.debtRepayFrom,
      value: p?.person.name,
      placeholder: l.debtPickPerson,
      dense: true,
      editable: true,
      reserveSubtitle: true,
      subtitle: debtNetSubtitle(context, l, p?.net),
      leading: p == null
          ? const PickCardEmptyIcon(AppIcons.contact, size: 32)
          : PersonMark(
              name: p.person.name,
              level: debtPersonLevel(p.person),
              iconCode: p.person.iconCode,
              size: 32,
            ),
      onTap: _c.repaying ? _pickOpenPerson : _pickPerson,
    );
  }

  Widget _walletCard(AppLocalizations l) => WalletPickCard(
    account: _c.account,
    label: l.transactionFormAccountLabel,
    placeholder: l.quickPickWallet,
    dense: true,
    editable: true,
    onTap: _pickAccount,
  );

  /// Repay: always wallet ↔ person (pay = wallet → person).
  Widget _repayFlow(AppLocalizations l) {
    final pay = _c.repayKind == DebtRepaymentKind.pay;
    final wallet = _walletCard(l);
    final person = _personCard(l);
    return FlowCards(
      from: pay ? wallet : person,
      to: pay ? person : wallet,
      swapTooltip: l.quickSwap,
      onSwap: () => _c.setRepayKind(
        pay ? DebtRepaymentKind.receive : DebtRepaymentKind.pay,
      ),
    );
  }

  Widget _flow(AppLocalizations l) {
    final paid = _c.direction == DebtEntryDirection.paid;
    if (!_c.createTransaction) return FlowCards(from: _personCard(l));
    final wallet = _walletCard(l);
    final person = _personCard(l);
    return FlowCards(
      from: paid ? wallet : person,
      to: paid ? person : wallet,
      swapTooltip: l.quickSwap,
      onSwap: () => _c.setDirection(
        paid ? DebtEntryDirection.received : DebtEntryDirection.paid,
      ),
    );
  }

  Future<void> _pickClose() async {
    final person = _c.person;
    if (person == null) return;
    final r = await DebtEntryPicker.many(
      context,
      personKey: person.key,
      selected: _c.markPaidIds,
      entries: person.typedName != null && person.key.startsWith('n:')
          ? const []
          : null,
    );
    if (r != null && mounted) _c.setMarkPaidIds(r.ids);
  }

  Widget _createTxRow(AppLocalizations l) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _c.setCreateTransaction(!_c.createTransaction),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.debtMoneyMovedLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l.debtCreateTxHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSwitch(
              value: _c.createTransaction,
              onChanged: _c.setCreateTransaction,
              semanticLabel: l.debtMoneyMovedLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeRow(AppLocalizations l) {
    final n = _c.markPaidIds.length;
    return DraftFieldRow(
      label: l.debtMarkPaidLabel,
      dense: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: n == 0
            ? AppChip(
                label: l.debtClosePick,
                icon: AppIcons.add,
                tone: AppChipTone.primary,
                selected: true,
                dashed: true,
                onTap: _pickClose,
              )
            : AppChip(
                label: l.debtCloseChosen(n),
                selected: true,
                dashed: true,
                inset: true,
                trailing: AppChipTrailing.remove,
                onRemove: _c.clearMarkPaid,
                onTap: _pickClose,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        const gap = SizedBox(height: AppSpacing.sm);
        final repay = _c.repaying;
        final paid = _c.direction == DebtEntryDirection.paid;
        final payBack = _c.repayKind == DebtRepaymentKind.pay;
        // Money in a wallet: always on the repay side, on request otherwise.
        final moneyMoves = repay || _c.createTransaction;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // A value picker, not tabs: which kind of debt entry this is.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegmentedChoice<DebtEntrySub>(
                key: const ValueKey('debtSub'),
                segments: [
                  ChoiceSegment(DebtEntrySub.record, l.debtSubRecord),
                  ChoiceSegment(DebtEntrySub.repay, l.debtSubRepay),
                ],
                selected: _c.sub,
                onChanged: _c.setSub,
              ),
            ),
            gap,
            EntryCard(
              key: widget.heroKey,
              debt: true,
              repay: repay,
              type: (repay ? payBack : paid)
                  ? TransactionType.expense
                  : TransactionType.income,
              onTypeChanged: repay
                  ? (t) => _c.setRepayKind(
                      t == TransactionType.income
                          ? DebtRepaymentKind.receive
                          : DebtRepaymentKind.pay,
                    )
                  : (t) => _c.setDirection(
                      t == TransactionType.income
                          ? DebtEntryDirection.received
                          : DebtEntryDirection.paid,
                    ),
              amount: _c.amount,
              title: _c.description,
              dateLabel: _dayLabel(l, _c.date),
              onPickDate: _pickDate,
              autofocus: widget.autofocus,
              symbol: symbol,
              amountNote: _resultLine(l, symbol),
              titleHint: repay
                  ? l.debtRepayTitleHint
                  : paid
                  ? l.debtTitleHintOwedToMe
                  : l.debtTitleHintIOwe,
              flowRow: repay ? _repayFlow(l) : _flow(l),
            ),
            SizedBox(height: HeroMetrics.of(context).after),
            if (moneyMoves) ...[
              TagChipRow(
                selected: _c.tagIds,
                onRemove: _c.toggleTag,
                onMore: _moreTags,
                known: _c.knownTags,
              ),
              gap,
            ],
            DraftFieldRow(
              label: l.commonNote,
              child: AppInput.inline(
                editing: true,
                controller: _c.note,
                maxLines: 5,
                maxLength: TextLimits.note,
                hint: l.debtNoteHint,
              ),
            ),
            gap,
            if (!repay) _createTxRow(l),
            // "ติดป้ายจ่ายแล้ว": only on the repay side (owner 2026-10-21).
            if (repay && _c.person != null) _closeRow(l),
          ],
        );
      },
    );
  }
}

/// "กับใคร": the contact picker in debt mode — every contact and every name
/// from the debts at once, each with its balance; a new name can be typed.
Future<DebtPick?> showDebtPersonPicker(
  BuildContext context, {
  DebtPick? selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final directory = context.read<DebtDirectoryCubit>();
  final key = selected?.key;
  final r = await ContactPicker.one(
    context,
    mode: ContactPickerMode.debts,
    allowFreeText: true,
    allowCreate: true,
    title: l.debtPersonPickerTitle,
    selectedId: key == null
        ? null
        : (key.startsWith('c:') ? key.substring(2) : key),
  );
  PersonBalance? known(String key) => directory.byKey(key);

  switch (r) {
    case null:
      return null;
    case ContactPicked(:final contact):
      final key = debtPersonKey(contactId: contact.id);
      return DebtPick(
        key: key,
        person: EmbeddedPerson(
          name: contact.name,
          contactId: contact.id,
          iconCode: contact.iconCode,
          linked: contact.isLinked,
          linkedUserId: contact.linkedUser?.id,
        ),
        net: known(key)?.net ?? 0,
      );
    case ContactNamePicked(:final name):
      final key = debtPersonKey(name: name);
      final p = known(key);
      return DebtPick(
        key: key,
        person: p?.person ?? EmbeddedPerson(name: name),
        net: p?.net ?? 0,
      );
    case ContactNameTyped(:final name):
      final key = debtPersonKey(name: name);
      final p = known(key);
      return DebtPick(
        key: key,
        person: p?.person ?? EmbeddedPerson(name: name),
        net: p?.net ?? 0,
        typedName: name,
      );
  }
}
