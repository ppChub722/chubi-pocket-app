import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../personal_debts/presentation/debt_wiring.dart';
import 'debt_entry_form.dart';

/// "ปิดหนี้" picker (owner 2026-10-17): the person's open debt entries, any
/// number ticked. It only MARKS them paid — nothing is checked against the
/// amount of the entry being written, and nothing is sent until the form's
/// บันทึก. Resolves the ticked ids (null = dismissed, nothing changes).
Future<Set<String>?> showDebtClosePickerSheet(
  BuildContext context, {
  required DebtPick person,
  required Set<String> selected,
}) {
  return showAppSheetCustom<Set<String>>(
    context,
    builder: (_) => _DebtClosePickerSheet(person: person, selected: selected),
  );
}

class _DebtClosePickerSheet extends StatefulWidget {
  const _DebtClosePickerSheet({required this.person, required this.selected});

  final DebtPick person;
  final Set<String> selected;

  @override
  State<_DebtClosePickerSheet> createState() => _DebtClosePickerSheetState();
}

class _DebtClosePickerSheetState extends State<_DebtClosePickerSheet> {
  late final Set<String> _ids = {...widget.selected};
  List<DebtEntry>? _entries;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = widget.person.key;
    // A person typed just now has no entries yet.
    if (key.startsWith('n:') && widget.person.typedName != null) {
      setState(() => _entries = const []);
      return;
    }
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final page = await context.read<PersonalDebtsRepository>().entries(
        key,
        query: const DebtEntryQuery(paid: false),
        perPage: 50,
      );
      if (mounted) setState(() => _entries = page.items);
    } catch (e, st) {
      if (mounted) setState(() => _error = ApiException.from(e, st));
    }
  }

  String _dayLabel(AppLocalizations l, DateTime d) => DateFormatter.friendly(
    d,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = debtCurrencySymbol(context);
    final entries = _entries;
    final Widget body;
    if (_error != null) {
      body = ErrorView(error: _error!, onRetry: _load);
    } else if (entries == null) {
      body = Column(
        children: [for (var i = 0; i < 3; i++) const SkeletonListTile()],
      );
    } else if (entries.isEmpty) {
      body = EmptyView.compact(message: l.debtMarkPaidNone);
    } else {
      body = Column(
        children: [
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
              checked: _ids.contains(e.id),
              onTap: () => setState(() {
                if (!_ids.remove(e.id)) _ids.add(e.id);
              }),
            ),
        ],
      );
    }
    return AppSheetScaffold(
      title: l.debtMarkPaidTitle,
      footer: AppButton(
        label: l.debtCloseConfirm(_ids.length),
        expand: true,
        onPressed: () => Navigator.of(context).pop(_ids),
      ),
      child: body,
    );
  }
}
