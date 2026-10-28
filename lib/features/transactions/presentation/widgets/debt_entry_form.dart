import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../projects/presentation/event_claim.dart' show showClaimSheet;
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
import '../../domain/refs.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../quick_create_bodies.dart';
import 'event_pick.dart';
import 'event_picker.dart';
import 'pick_chip_rows.dart';
import 'transaction_picker.dart';
import 'transaction_tile.dart';

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
/// coloured like the debts page (green = owed to me, red = I owe). The words
/// default to the debts pages' ones; quick create passes ลูกหนี้ / เจ้าหนี้.
Widget? debtNetSubtitle(
  BuildContext context,
  AppLocalizations l,
  double? net, {
  String? owedToMeLabel,
  String? iOweLabel,
}) {
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
      text:
          '${owedToMe ? (owedToMeLabel ?? l.debtsOwedToMe) : (iOweLabel ?? l.debtsIOwe)} ',
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

/// Quick create's debt mode, one form for the four kinds (0.4.1-1 D10): [sub]
/// picks record (ให้ยืม / ยืม) or repay (จ่ายคืน / รับคืน), the arrow the
/// direction. Every kind is a person-book row; a transaction comes with it
/// only when [createTransaction] ("บันทึกในรายการ": a new one, wallet
/// optional, or [linkedTx] connected).
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

  /// "บันทึกในรายการ" (money in / out of a wallet), every kind: on by default
  /// (owner 2026-10-26; it was off 2026-10-21).
  bool createTransaction = true;

  /// "กำหนดจ่าย": recording only, never before [date].
  DateTime? dueDate;

  DebtEntrySub _sub;
  DebtEntrySub get sub => _sub;
  bool get repaying => _sub == DebtEntrySub.repay;

  DebtRepaymentKind repayKind = DebtRepaymentKind.pay;

  /// The amount this controller filled itself (a repayment's open balance):
  /// replaced when the person or kind changes, kept once the person types
  /// their own.
  String? _autoAmount;

  bool get amountIsAuto => _autoAmount != null && amount.text == _autoAmount;

  /// The money goes from me to them: lend, or pay back.
  bool get moneyOut => repaying
      ? repayKind == DebtRepaymentKind.pay
      : direction == DebtEntryDirection.paid;

  void _clearAutoAmount() {
    if (!amountIsAuto) return;
    amount.text = '';
    _autoAmount = null;
  }

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

  bool get hasKeyData =>
      amountValue > 0 ||
      note.text.trim().isNotEmpty ||
      description.text.trim().isNotEmpty;

  /// The direction both chips share (owner 2026-10-21, the arrow): them → me
  /// (รอรับ / รับคืน) or me → them (รอจ่าย / จ่ายคืน).
  bool get towardMe => repaying
      ? repayKind == DebtRepaymentKind.receive
      : direction == DebtEntryDirection.paid;

  void _syncDirection(bool toMe) {
    direction = toMe ? DebtEntryDirection.paid : DebtEntryDirection.received;
    repayKind = toMe ? DebtRepaymentKind.receive : DebtRepaymentKind.pay;
  }

  /// The arrow between กับใคร and กระเป๋า.
  void swapDirection() {
    _syncDirection(!towardMe);
    if (repaying) _repayDefaults(kindFromBalance: false);
    notifyListeners();
  }

  // ── the BE preview (?preview=true) behind the result box ───────────────
  /// What a preview is for; null = nothing to preview yet.
  String? get previewKey {
    final p = _person;
    if (p == null || amountValue <= 0) return null;
    return [
      p.key,
      repaying,
      towardMe,
      amountValue,
      createTransaction,
      linkedTx?.id,
      createTransaction ? account?.id : null,
    ].join('|');
  }

  DebtPreview? _preview;
  String? _previewFor;

  /// The BE's answer for what's on screen now; null = none (yet).
  DebtPreview? get preview => _previewFor == previewKey ? _preview : null;

  void setPreview(String key, DebtPreview? p) {
    _previewFor = key;
    _preview = p;
  }

  /// Settling more than what's open flips the side (the save warns once).
  bool get overpays {
    final p = _person;
    if (!repaying || p == null) return false;
    final pv = preview;
    if (pv != null) return pv.flipped;
    final before = p.net ?? 0;
    final after = netAfter ?? before;
    return before.abs() > 0.004 &&
        after.abs() > 0.004 &&
        before.sign != after.sign;
  }

  /// The wallet's change, as the app reckons it (money out < 0); null = no
  /// wallet moves. The BE preview has the last word.
  double? get walletDelta {
    if (!createTransaction || linkedTx != null || account == null) return null;
    return moneyOut ? -amountValue : amountValue;
  }

  /// The chip picked: record (รอรับ / รอจ่าย) or settle (รับคืน / จ่ายคืน);
  /// the direction stays.
  void setSub(DebtEntrySub s) {
    if (s == _sub) return;
    final toMe = towardMe;
    _sub = s;
    _syncDirection(toMe);
    markPaidIds.clear();
    if (repaying) {
      dueDate = null;
      _repayDefaults(kindFromBalance: false);
    } else {
      // Back to recording: the open balance the repay side filled in is not
      // an amount the person typed.
      _clearAutoAmount();
    }
    notifyListeners();
  }

  void setRepayKind(DebtRepaymentKind k) {
    if (k == repayKind) return;
    _syncDirection(k == DebtRepaymentKind.receive);
    _repayDefaults(kindFromBalance: false);
    notifyListeners();
  }

  void setDirection(DebtEntryDirection d) {
    if (d == direction) return;
    _syncDirection(d == DebtEntryDirection.paid);
    notifyListeners();
  }

  void setPerson(DebtPick? p) {
    if (p?.key != _person?.key) markPaidIds.clear();
    _person = p;
    if (p == null) _clearAutoAmount();
    if (repaying) _repayDefaults(kindFromBalance: true);
    notifyListeners();
  }

  /// Applies the repay defaults now (the form calls it after its first frame).
  void syncRepayDefaults() {
    if (repaying) _repayDefaults(kindFromBalance: true);
    notifyListeners();
  }

  /// Repay: the kind from the balance and the full open amount; an amount
  /// the person typed themselves stays.
  void _repayDefaults({required bool kindFromBalance}) {
    final p = _person;
    if (p == null) return;
    final net = p.net ?? 0;
    if (kindFromBalance && net.abs() > 0.004) {
      _syncDirection(
        DebtRepaymentKind.forNet(net) == DebtRepaymentKind.receive,
      );
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
  }

  /// "ไม่ระบุกระเป๋า" was picked (else no wallet = not picked yet).
  bool noWalletPicked = false;

  /// "ผูกกับรายการที่มีอยู่" (0.4.1-1 D10): one of my transactions connected
  /// in the save call instead of a new one; its amount and date are the
  /// entry's.
  Transaction? linkedTx;

  /// "ปิดหนี้" (repaying only): label every open debt on the side this
  /// repayment pays down paid (label only).
  bool closeDebt = false;

  /// Picking a wallet means the money moved: "บันทึกในรายการ" turns on (every
  /// kind). [picked]: the person chose it in the picker.
  void setAccount(Account? a, {bool picked = false}) {
    account = a;
    noWalletPicked = picked && a == null;
    linkedTx = null;
    createTransaction = true;
    notifyListeners();
  }

  /// An existing transaction instead of a new one: the amount and date follow
  /// it (the BE uses its values).
  void setLinkedTx(Transaction tx) {
    linkedTx = tx;
    account = null;
    noWalletPicked = false;
    createTransaction = true;
    _autoAmount = null;
    amount.text = AmountInput.format(tx.amount);
    final d = DateTime.tryParse(tx.date);
    if (d != null) date = d;
    notifyListeners();
  }

  /// Back to a new transaction (the amount and date stay as they are).
  void clearLinkedTx() {
    if (linkedTx == null) return;
    linkedTx = null;
    notifyListeners();
  }

  void setCreateTransaction(bool v) {
    if (v == createTransaction) return;
    createTransaction = v;
    if (!v) linkedTx = null;
    notifyListeners();
  }

  void setCloseDebt(bool v) {
    if (v == closeDebt) return;
    closeDebt = v;
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
    final due = dueDate;
    if (due != null && due.isBefore(DateTime(d.year, d.month, d.day))) {
      dueDate = null;
    }
    notifyListeners();
  }

  void setDueDate(DateTime? d) {
    dueDate = d;
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
    _c.addListener(_onChanged);
    // A repay preset's defaults, after the frame: the controller notifies,
    // which must not happen mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.syncRepayDefaults();
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _c.removeListener(_onChanged);
    super.dispose();
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
                  '${p.net > 0 ? l.debtRoleDebtor : l.debtRoleCreditor} '
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
      // "ไม่ระบุกระเป๋า" on both sides: a repayment with no wallet moves no
      // balance (owner 2026-10-23).
      allowNone: true,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _c.setAccount(r is AccountPicked ? r.account : null, picked: true);
  }

  Future<void> _pickDate() async {
    final r = await AppDatePicker.show(
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

  // ── the result box: before → after + the wallet (BE preview) ───────────
  String? _asked;
  bool _previewLoading = false;
  Timer? _previewTimer;

  void _onChanged() {
    final want = _c.previewKey;
    if (want == _asked) return;
    _asked = want;
    _previewTimer?.cancel();
    if (want == null) {
      if (_previewLoading) setState(() => _previewLoading = false);
      return;
    }
    if (!_previewLoading) setState(() => _previewLoading = true);
    _previewTimer = Timer(
      const Duration(milliseconds: 350),
      () => _loadPreview(want),
    );
  }

  Future<void> _loadPreview(String want) async {
    final p = _c.person;
    PersonalDebtsRepository? repo;
    try {
      repo = context.read<PersonalDebtsRepository>();
    } catch (_) {}
    if (p == null || repo == null) {
      if (mounted) setState(() => _previewLoading = false);
      return;
    }
    try {
      final body = debtPreviewBody(_c, p);
      final r = await repo.preview(
        body.key,
        direction: body.direction,
        kind: body.kind,
        amount: body.amount,
        accountId: body.accountId,
        createTransaction: body.createTransaction,
        personName: body.personName,
      );
      if (!mounted || _c.previewKey != want) return;
      _c.setPreview(want, r);
      setState(() => _previewLoading = false);
    } catch (_) {
      // The app's own numbers stay.
      if (!mounted || _c.previewKey != want) return;
      _c.setPreview(want, null);
      setState(() => _previewLoading = false);
    }
  }

  /// The summary row, outside the card above the tag row (owner 2026-10-23):
  /// where the balance with this person ends up, with what it was; null until
  /// a person and an amount are in.
  Widget? _summaryRow(AppLocalizations l, String symbol) {
    final p = _c.person;
    if (p == null || _c.amountValue <= 0) return null;
    final preview = _c.preview;
    final before = preview?.before ?? p.net ?? 0;
    final after = preview?.after ?? _c.netAfter ?? before;
    final name = p.person.name;
    String money(double v) => moneyString(context, v.abs(), symbol: symbol);
    if (after.abs() <= 0.004) {
      return DebtSummaryRow(
        label: l.debtResultAfterSave,
        words: l.debtSummaryCleared(name),
        tone: DebtSummaryTone.cleared,
      );
    }
    // ลูกหนี้ = they owe me, เจ้าหนี้ = I owe (owner 2026-10-23); a settle
    // past what was open turns them into the other one.
    final owedToMe = after > 0;
    final flipped = _c.overpays;
    final words = flipped
        ? (owedToMe
              ? l.debtSummaryBecomesDebtor(name)
              : l.debtSummaryBecomesCreditor(name))
        : (owedToMe ? l.debtSummaryDebtor(name) : l.debtSummaryCreditor(name));
    return DebtSummaryRow(
      label: l.debtResultAfterSave,
      words: words,
      amount: money(after),
      tone: flipped
          ? DebtSummaryTone.warn
          : owedToMe
          ? DebtSummaryTone.owedToMe
          : DebtSummaryTone.iOwe,
    );
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
      accent: Theme.of(context).colorScheme.primary,
      subtitle: debtNetSubtitle(
        context,
        l,
        p?.net,
        owedToMeLabel: l.debtRoleDebtor,
        iOweLabel: l.debtRoleCreditor,
      ),
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

  /// My end of the flow (owner 2026-10-23): the wallet card when money moves
  /// ("บันทึกในรายการ" on, every kind), else "ฉัน" — my avatar + name — so
  /// the arrow still points at someone. A connected transaction shows its
  /// own wallet, not changed here.
  Widget _meCard(AppLocalizations l) {
    final linked = _c.linkedTx;
    if (_c.createTransaction && linked != null) {
      return WalletPickCard(
        account: linked.account?.toAccount(),
        label: l.transactionFormAccountLabel,
        placeholder: l.debtNoWallet,
        dense: true,
        editable: false,
        onTap: _pickLinkTx,
      );
    }
    if (_c.createTransaction) {
      // No wallet is a choice here, as in the tx mode: "ไม่ระบุกระเป๋า"
      // once picked, "เลือกกระเป๋า" before.
      return WalletPickCard(
        account: _c.account,
        label: l.transactionFormAccountLabel,
        placeholder: _c.noWalletPicked
            ? l.transactionFormAccountNone
            : l.quickPickWallet,
        dense: true,
        editable: true,
        onTap: _pickAccount,
      );
    }
    final auth = context.read<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    return MeFlowCard(
      label: l.txLinkCardMe,
      name: user?.displayName ?? l.txLinkCardMe,
      iconCode: user?.iconCode,
    );
  }

  /// กับใคร ⇄ ฉัน / กระเป๋า in the MONEY's direction: recording a loan I
  /// made (they owe me) / settling a payment I make = me → person; recording
  /// a loan I took / settling a payment I receive = person → me. The arrow
  /// swaps the direction.
  Widget _flowCards(AppLocalizations l) {
    final me = _meCard(l);
    final person = _personCard(l);
    final moneyIn = _c.repaying ? _c.towardMe : !_c.towardMe;
    return FlowCards(
      key: const ValueKey('debtFlow'),
      from: moneyIn ? person : me,
      to: moneyIn ? me : person,
      swapTooltip: l.quickSwap,
      onSwap: _c.swapDirection,
    );
  }

  /// "บันทึกในรายการ" (0.4.1-1 D10, every kind): off = the person book only,
  /// on = a transaction too (a new one, or one of mine connected).
  Widget _createTxRow(AppLocalizations l) => _switchRow(
    key: const ValueKey('debtCreateTx'),
    label: l.occurrenceRecordInTx,
    hint: !_c.createTransaction
        ? l.debtTxHintOff
        : _c.moneyOut
        ? l.debtTxHintLend
        : l.debtTxHintBorrow,
    value: _c.createTransaction,
    onChanged: _c.setCreateTransaction,
  );

  /// "ปิดหนี้" (repaying): every open debt on the side this pays down gets the
  /// "จ่ายแล้ว" label (label only, numbers never change).
  Widget _closeRow(AppLocalizations l) => _switchRow(
    key: const ValueKey('debtCloseAll'),
    label: l.debtMarkPaidLabel,
    hint: l.debtCloseAllHint,
    value: _c.closeDebt,
    onChanged: _c.setCloseDebt,
  );

  Widget _switchRow({
    required Key key,
    required String label,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
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
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSwitch(
              key: key,
              value: value,
              onChanged: onChanged,
              semanticLabel: label,
            ),
          ],
        ),
      ),
    );
  }

  /// "ผูกกับรายการที่มีอยู่": one of my plain transactions of the money's way
  /// (out = expense), connected in the save call.
  Future<void> _pickLinkTx() async {
    final l = AppLocalizations.of(context)!;
    final tx = await TransactionPicker.one(
      context,
      type: _c.moneyOut ? TransactionType.expense : TransactionType.income,
      near: _c.date,
      amount: _c.amountValue > 0 ? _c.amountValue : null,
      title: l.debtLinkExistingLabel,
    );
    if (tx != null && mounted) _c.setLinkedTx(tx);
  }

  /// The connected transaction as its list row (tap = pick again, ✕ = back
  /// to a new one), or a dashed "ผูกรายการ".
  Widget _linkRow(AppLocalizations l) {
    final tx = _c.linkedTx;
    if (tx == null) {
      return DraftFieldRow(
        key: const ValueKey('debtLinkRow'),
        label: l.debtLinkExistingLabel,
        dense: true,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: l.occurrenceLinkPick,
            icon: AppIcons.link,
            tone: AppChipTone.primary,
            selected: true,
            dashed: true,
            onTap: _pickLinkTx,
          ),
        ),
      );
    }
    return PickedRowFrame(
      key: const ValueKey('debtLinkRow'),
      onTap: _pickLinkTx,
      onRemove: _c.clearLinkedTx,
      removeTooltip: l.commonRemove,
      child: TransactionTile(transaction: tx, showDate: true),
    );
  }

  Future<void> _pickDue() async {
    final from = DateTime(_c.date.year, _c.date.month, _c.date.day);
    final r = await AppDatePicker.show(
      context,
      initial: _c.dueDate ?? from,
      first: from,
      last: from.add(const Duration(days: 365 * 5)),
    );
    if (r is AppDatePicked && mounted) _c.setDueDate(r.date);
  }

  /// 0.4.1-2 V10 — "จากบิลอีเวนต์" (record side, a person picked): pick an
  /// event, then that person's bills there; the claim (ONE call) books them
  /// as one debt and the sheet closes.
  Widget _fromEventRow(AppLocalizations l) => DraftFieldRow(
    key: const ValueKey('debtFromEventRow'),
    label: l.debtFromEventLabel,
    dense: true,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppChip(
        label: l.debtFromEventPick,
        icon: AppIcons.project,
        tone: AppChipTone.primary,
        selected: true,
        dashed: true,
        onTap: _claimFromEvent,
      ),
    ),
  );

  Future<void> _claimFromEvent() async {
    final p = _c.person;
    if (p == null) return;
    final navigator = Navigator.of(context);
    final event = await EventPicker.one(context, allowCreate: false);
    if (event is! ExistingEventTarget || !mounted) return;
    final contactId = p.person.contactId;
    final claimed = await showClaimSheet(
      context,
      projectId: event.project.id,
      contactId: contactId,
      personName: contactId == null ? p.person.name : null,
      memberName: p.person.name,
    );
    if (claimed && mounted) navigator.pop(true);
  }

  /// "กำหนดจ่าย" (owner 2026-10-23): like the รายการประจำ row, under โน้ต.
  Widget _dueRow(AppLocalizations l) {
    final due = _c.dueDate;
    return DraftFieldRow(
      key: const ValueKey('debtDueRow'),
      label: l.debtDueLabel,
      dense: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DatePickChip(
          date: due,
          emptyLabel: l.debtDuePick,
          format: (d) => _dayLabel(l, d),
          onPick: _pickDue,
          onClear: () => _c.setDueDate(null),
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
        final toMe = _c.towardMe;
        // A transaction too ("บันทึกในรายการ", every kind); tags only on a
        // new one (a connected one keeps its own).
        final withTx = _c.createTransaction;
        final linked = withTx && _c.linkedTx != null;
        final summary = _summaryRow(l, symbol);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EntryCard(
              key: widget.heroKey,
              debt: true,
              repay: repay,
              accentColor: QuickCreateModeColors.of(
                context,
                QuickCreateMode.debt,
              ),
              type: (repay ? payBack : paid)
                  ? TransactionType.expense
                  : TransactionType.income,
              // No sub-tabs (owner 2026-10-21): record | settle where the tx
              // mode has รายจ่าย / รายรับ. Record is one chip (the cards say
              // the direction); settle keeps its direction word.
              typeBadge: DebtModeChips(
                towardMe: toMe,
                settle: repay,
                recordLabel: l.debtRecordChip,
                settleLabel: l.debtSettleChip,
                onChanged: (settle) => _c.setSub(
                  settle ? DebtEntrySub.repay : DebtEntrySub.record,
                ),
              ),
              amount: _c.amount,
              title: _c.description,
              dateLabel: _dayLabel(l, _c.date),
              onPickDate: _pickDate,
              autofocus: widget.autofocus,
              symbol: symbol,
              // Typed freely on every kind; blank saves none and shows the
              // kind's category name, the hint (owner 2026-10-26).
              titleHint: debtKindName(l, out: _c.moneyOut, repayment: repay),
              amountNote: linked ? Text(l.debtLinkedAmountNote) : null,
              flowRow: _flowCards(l),
            ),
            SizedBox(height: HeroMetrics.of(context).after),
            if (withTx && !linked) ...[
              TagChipRow(
                selected: _c.tagIds,
                onRemove: _c.toggleTag,
                onMore: _moreTags,
                known: _c.knownTags,
              ),
              gap,
            ],
            _createTxRow(l),
            gap,
            if (withTx) ...[_linkRow(l), gap],
            if (summary != null) ...[summary, gap],
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
            if (!repay && _c.person != null) ...[_fromEventRow(l), gap],
            if (!repay) _dueRow(l),
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
