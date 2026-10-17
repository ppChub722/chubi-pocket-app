import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/refs.dart';
import '../../domain/transaction_type.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'account_picker_sheet.dart';
import 'debt_close_picker_sheet.dart';
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

class DebtEntryController extends ChangeNotifier {
  DebtEntryController({DebtPick? person}) : _person = person {
    amount.addListener(notifyListeners);
    description.addListener(notifyListeners);
  }

  DebtEntryDirection direction = DebtEntryDirection.paid;
  final amount = TextEditingController();
  final description = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();

  bool createTransaction = true;

  Account? account;
  final Set<String> tagIds = {};
  final Map<String, Tag> knownTags = {};
  final Set<String> markPaidIds = {};

  DebtPick? _person;
  DebtPick? get person => _person;

  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  double? get netAfter {
    final n = _person?.net;
    if (n == null) return null;
    return n +
        (direction == DebtEntryDirection.paid ? amountValue : -amountValue);
  }

  bool get hasKeyData => amountValue > 0 || description.text.trim().isNotEmpty;

  void setDirection(DebtEntryDirection d) {
    if (d == direction) return;
    direction = d;
    notifyListeners();
  }

  void setPerson(DebtPick? p) {
    if (p?.key != _person?.key) markPaidIds.clear();
    _person = p;
    notifyListeners();
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

  Future<void> _loadPeople() async {
    try {
      final page = await context.read<PersonalDebtsRepository>().listPeople();
      if (!mounted) return;
      final p = _c.person;
      if (p != null && p.net == null) {
        final known = page.items.where((x) => x.key == p.key).firstOrNull;
        _c.setPerson(p.withNet(known?.net ?? 0));
      }
    } catch (_) {
    }
  }

  Future<void> _pickPerson() async {
    final picked = await showDebtPersonPicker(context, selected: _c.person);
    if (picked != null && mounted) _c.setPerson(picked);
  }

  Future<void> _pickAccount() async {
    final l = AppLocalizations.of(context)!;
    final accounts =
        maybeTxFormOptions(context, watch: false)?.state.options?.accountList ??
        context.read<AccountsCubit>().state.accounts;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selected: _c.account,
      title: l.transactionFormAccountLabel,
      allowNone: true,
      allowCreate: true,
    );
    if (!mounted || r == null) return;
    _c.setAccount(r is AccountPickerSelected ? r.account : null);
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
    final next = await showTagPickerSheet(context, selected: _c.tagIds);
    if (next != null && mounted) _c.setTagIds(next);
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
      label: l.debtPersonPickerTitle,
      value: p?.person.name,
      placeholder: l.debtPickPerson,
      dense: true,
      editable: true,
      leading: p == null
          ? const PickCardEmptyIcon(AppIcons.contact, size: 32)
          : PersonMark(
              name: p.person.name,
              level: debtPersonLevel(p.person),
              iconCode: p.person.iconCode,
              size: 32,
            ),
      onTap: _pickPerson,
    );
  }

  Widget _walletCard(AppLocalizations l) => WalletPickCard(
    account: _c.account,
    label: l.transactionFormAccountLabel,
    placeholder: l.quickPickWallet,
    dense: true,
    twoLine: true,
    editable: true,
    onTap: _pickAccount,
  );

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
    final ids = await showDebtClosePickerSheet(
      context,
      person: person,
      selected: _c.markPaidIds,
    );
    if (ids != null && mounted) _c.setMarkPaidIds(ids);
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
                    l.debtCreateTxLabel,
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
              semanticLabel: l.debtCreateTxLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeRow(AppLocalizations l) {
    final n = _c.markPaidIds.length;
    return DraftFieldRow(
      label: l.debtCloseLabel,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EntryCard(
              key: widget.heroKey,
              debt: true,
              type: _c.direction == DebtEntryDirection.paid
                  ? TransactionType.expense
                  : TransactionType.income,
              onTypeChanged: (t) => _c.setDirection(
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
              titleHint: _c.direction == DebtEntryDirection.paid
                  ? l.debtTitleHintPaid
                  : l.debtTitleHintReceived,
              flowRow: _flow(l),
            ),
            const SizedBox(height: HeroSpacing.after),
            if (_c.createTransaction) ...[
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
                hint: l.txNoteAddHint,
              ),
            ),
            gap,
            _createTxRow(l),
            if (_c.person != null) ...[gap, _closeRow(l)],
          ],
        );
      },
    );
  }
}

Future<DebtPick?> showDebtPersonPicker(
  BuildContext context, {
  DebtPick? selected,
}) async {
  final repo = context.read<PersonalDebtsRepository>();
  final l = AppLocalizations.of(context)!;
  final symbol = debtCurrencySymbol(context);
  final search = TextEditingController();
  final people = repo.listPeople(all: true, perPage: 100);
  try {
    final r = await showAppSheetCustom<Object>(
      context,
      builder: (ctx) => FutureBuilder<DebtPeoplePage>(
        future: people,
        builder: (ctx, snap) => PickerSheet(
          title: l.debtPersonPickerTitle,
          searchable: true,
          searchHint: l.debtsSearchHint,
          searchController: search,
          searchAutofocus: true,
          loading: snap.connectionState != ConnectionState.done,
          error: snap.error,
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListenableBuilder(
                listenable: search,
                builder: (ctx, _) {
                  final typed = search.text.trim();
                  final all = snap.data?.items ?? const <PersonBalance>[];
                  final exists = all.any(
                    (p) => p.person.name.toLowerCase() == typed.toLowerCase(),
                  );
                  if (typed.isEmpty || exists) return const SizedBox.shrink();
                  return PickerCreateRow(
                    label: l.debtPersonAddTyped(typed),
                    onTap: () => Navigator.of(ctx).pop(
                      DebtPick(
                        key: debtPersonKey(name: typed),
                        person: EmbeddedPerson(name: typed),
                        net:
                            all
                                .where(
                                  (p) => p.key == debtPersonKey(name: typed),
                                )
                                .firstOrNull
                                ?.net ??
                            0,
                        typedName: typed,
                      ),
                    ),
                  );
                },
              ),
              PickerCreateRow(
                label: l.debtPersonFromContacts,
                onTap: () => Navigator.of(ctx).pop(const _FromContacts()),
              ),
            ],
          ),
          builder: (ctx, query) {
            final all = snap.data?.items ?? const <PersonBalance>[];
            final rows = query.isEmpty
                ? all
                : all
                      .where((p) => p.person.name.toLowerCase().contains(query))
                      .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in rows)
                  PersonBalanceRow(
                    name: p.person.name,
                    level: debtPersonLevel(p.person),
                    iconCode: p.person.iconCode,
                    net: p.net,
                    subtitle: l.debtsOpenCount(p.openCount),
                    owedToMeLabel: l.debtsOwedToMe,
                    iOweLabel: l.debtsIOwe,
                    settledLabel: l.debtSettledLabel,
                    currencySymbol: symbol,
                    selected: p.key == selected?.key,
                    onTap: () => Navigator.of(
                      ctx,
                    ).pop(DebtPick(key: p.key, person: p.person, net: p.net)),
                  ),
              ],
            );
          },
        ),
      ),
    );
    if (r is DebtPick) return r;
    if (r is _FromContacts && context.mounted) {
      final c = await showContactPickerSheet(context, allowFreeText: false);
      if (c is! ContactPicked) return null;
      final key = debtPersonKey(contactId: c.contact.id);
      PersonBalance? known;
      try {
        known = (await people).items.where((p) => p.key == key).firstOrNull;
      } catch (_) {
        known = null; // no list: a new person (balance 0)
      }
      return DebtPick(
        key: key,
        person: EmbeddedPerson(
          name: c.contact.name,
          contactId: c.contact.id,
          iconCode: c.contact.iconCode,
          linked: c.contact.isLinked,
          linkedUserId: c.contact.linkedUser?.id,
        ),
        net: known?.net ?? 0,
      );
    }
    return null;
  } finally {
    search.dispose();
  }
}

class _FromContacts {
  const _FromContacts();
}
