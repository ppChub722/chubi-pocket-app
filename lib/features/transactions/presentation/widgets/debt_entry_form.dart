import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
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
import 'pick_chip_rows.dart';

/// Who a debt entry is with: the person's key (`c:<contact>` / `n:<name>`),
/// how they show, and their balance before this entry (null = not known
/// yet; a new person = 0).
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

  /// A new typed name: its spelling as typed (`person_name`).
  final String? typedName;

  DebtPick withNet(double? n) =>
      DebtPick(key: key, person: person, net: n, typedName: typedName);
}

/// The fields of quick create's DEBT MODE (owner 2026-10-12): Paid /
/// Received, amount, description, date, the person, a wallet or none (no
/// wallet = ledger only), tags (only with a wallet), note, entries to label
/// paid in the same call.
class DebtEntryController extends ChangeNotifier {
  DebtEntryController({DebtPick? person}) : _person = person {
    // Typing changes the result line and the close guard.
    amount.addListener(notifyListeners);
    description.addListener(notifyListeners);
  }

  DebtEntryDirection direction = DebtEntryDirection.paid;
  final amount = TextEditingController();
  final description = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();

  /// Null = "ไม่ผูก" (ledger only).
  Account? account;
  final Set<String> tagIds = {};
  final Map<String, Tag> knownTags = {};
  final Set<String> markPaidIds = {};

  DebtPick? _person;
  DebtPick? get person => _person;

  double get amountValue => AmountInput.parse(amount.text) ?? 0;

  /// The person's balance after this entry: paid = they owe me more.
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
    // Tags ride on the wallet transaction: none without a wallet.
    if (a == null) tagIds.clear();
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

/// Quick create's debt-mode body: the SAME EntryCard (Paid / Received in
/// place of the type, the PERSON chip row in place of the category, the
/// wallet row with "ไม่ผูก"), the result line under the amount, tags only
/// with a wallet, the compact note and the collapsible "mark entries paid".
/// Calls: the people list once (the chip row; the picker loads everyone
/// once more when opened), and the person's open entries only when the
/// mark-paid section opens.
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

  final _walletOrder = ChipOrder();
  final _tagOrder = ChipOrder();

  /// People with something open (the chip row), null while loading.
  List<PersonBalance>? _people;

  /// The mark-paid list of the person it was loaded for.
  String? _entriesKey;
  List<DebtEntry>? _entries;
  bool _entriesOpen = false;
  Object? _entriesError;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    try {
      final page = await context.read<PersonalDebtsRepository>().listPeople();
      if (!mounted) return;
      setState(() => _people = page.items);
      // A preset person: their balance for the result line.
      final p = _c.person;
      if (p != null && p.net == null) {
        final known = page.items.where((x) => x.key == p.key).firstOrNull;
        _c.setPerson(p.withNet(known?.net ?? 0));
      }
    } catch (_) {
      // The picker still works (it loads its own list); no chips.
      if (mounted) setState(() => _people = const []);
    }
  }

  Future<void> _loadEntries() async {
    final key = _c.person?.key;
    if (key == null || key.startsWith('n:') && _c.person?.typedName != null) {
      setState(() {
        _entriesKey = key;
        _entries = const [];
      });
      return;
    }
    setState(() {
      _entriesKey = key;
      _entries = null;
      _entriesError = null;
    });
    try {
      final page = await context.read<PersonalDebtsRepository>().entries(
        key,
        query: const DebtEntryQuery(paid: false),
        perPage: 50,
      );
      if (mounted && _entriesKey == key) {
        setState(() => _entries = page.items);
      }
    } catch (e, st) {
      if (mounted && _entriesKey == key) {
        setState(() => _entriesError = ApiException.from(e, st));
      }
    }
  }

  DebtPick _pickOf(PersonBalance p) =>
      DebtPick(key: p.key, person: p.person, net: p.net);

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

  /// "หลังบันทึก: แม่ติดคุณ ฿200" — instant feedback while typing (the BE
  /// returns the real balance on save).
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

  Widget _personChip(
    DebtPick p, {
    required bool selected,
    VoidCallback? onTap,
  }) => AppChip(
    label: p.person.name,
    leading: PersonMark(
      name: p.person.name,
      level: debtPersonLevel(p.person),
      iconCode: p.person.iconCode,
    ),
    selected: selected,
    onTap: onTap,
  );

  Widget _personRow(AppLocalizations l) {
    final sel = _c.person;
    final others = [
      for (final p in _people ?? const <PersonBalance>[])
        if (p.key != sel?.key) p,
    ].take(4);
    return ChipRow(
      icon: AppIcons.contact,
      chips: [
        if (sel != null)
          _personChip(sel, selected: true, onTap: _pickPerson)
        else
          AppChip(
            label: l.debtPickPerson,
            icon: AppIcons.add,
            dashed: true,
            onTap: _pickPerson,
          ),
        if (_people == null)
          for (var i = 0; i < 2; i++)
            const SkeletonBox(width: 72, height: 28, borderRadius: 14),
        for (final p in others)
          _personChip(
            _pickOf(p),
            selected: false,
            onTap: () => _c.setPerson(_pickOf(p)),
          ),
      ],
    );
  }

  Widget _walletRow(AppLocalizations l) => WalletChipRow(
    selectedId: _c.account?.id,
    // Tapping the picked wallet again = no wallet.
    onPick: (a) => _c.setAccount(_c.account?.id == a.id ? null : a),
    onMore: _pickAccount,
    order: _walletOrder,
    pickLabel: l.quickPickWallet,
    leading: [
      AppChip(
        label: l.debtNoWallet,
        selected: _c.account == null,
        onTap: () => _c.setAccount(null),
      ),
    ],
  );

  List<Widget> _markPaid(AppLocalizations l, String symbol) {
    final entries = _entries;
    if (_entriesError != null) {
      return [ErrorView(error: _entriesError!, onRetry: _loadEntries)];
    }
    if (entries == null) {
      return [for (var i = 0; i < 2; i++) const SkeletonListTile()];
    }
    if (entries.isEmpty) {
      return [EmptyView.compact(message: l.debtMarkPaidNone)];
    }
    return [
      for (final e in entries)
        PickerRow(
          title: (e.description ?? '').trim().isNotEmpty
              ? e.description!.trim()
              : (e.direction == DebtEntryDirection.paid
                    ? l.debtsDirPaid
                    : l.debtsDirReceived),
          subtitle: e.date == null ? null : _dayLabel(l, e.date!),
          trailing: MoneyText(
            e.amount,
            symbol: symbol,
            tone: e.direction == DebtEntryDirection.paid
                ? MoneyTone.expense
                : MoneyTone.income,
          ),
          checked: _c.markPaidIds.contains(e.id),
          onTap: () => _c.toggleMarkPaid(e.id),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        // The person changed while the section is open: their entries.
        if (_entriesOpen && _entriesKey != _c.person?.key) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadEntries();
          });
        }
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
              walletRow: _walletRow(l),
              categoryRow: _personRow(l),
            ),
            const SizedBox(height: HeroSpacing.after),
            // Tags belong to the wallet transaction: only with a wallet.
            if (_c.account != null) ...[
              TagChipRow(
                selected: _c.tagIds,
                onToggle: _c.toggleTag,
                onMore: _moreTags,
                known: _c.knownTags,
                order: _tagOrder,
              ),
              const SizedBox(height: AppSpacing.sm),
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
            if (_c.person != null) ...[
              const SizedBox(height: AppSpacing.sm),
              CollapsibleSection(
                title: l.debtMarkPaidTitle,
                initiallyOpen: false,
                onToggle: (open) {
                  _entriesOpen = open;
                  if (open && _entriesKey != _c.person?.key) _loadEntries();
                },
                children: _markPaid(l, symbol),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// "กับใคร" — the debt person picker: everyone with a debt (open first,
/// search), "+ เพิ่มชื่อ “…”" for a new typed name, and "เลือกจากผู้ติดต่อ".
/// Loads the people once when it opens.
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
