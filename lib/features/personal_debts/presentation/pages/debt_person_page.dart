import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_picker_sheet.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';
import '../widgets/debt_widgets.dart';

/// `/personal-debts/person?contact=…&name=…` — everything with one person
/// (§11): net, what's outstanding, collapsed history, "+ บันทึกหนี้กับคนนี้".
/// A typed-name person can be merged into a contact (absorb).
class DebtPersonPage extends StatefulWidget {
  const DebtPersonPage({required this.name, this.contactId, super.key});

  final String? contactId;
  final String name;

  @override
  State<DebtPersonPage> createState() => _DebtPersonPageState();
}

class _DebtPersonPageState extends State<DebtPersonPage> {
  bool _linking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PersonalDebtsCubit>().loadIfNeeded();
    });
  }

  String get _key => widget.contactId != null
      ? 'c:${widget.contactId}'
      : 'n:${widget.name.trim().toLowerCase()}';

  Future<void> _linkToContact() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showContactPickerSheet(context, allowFreeText: false);
    if (picked is! ContactPicked || !mounted) return;
    final contact = picked.contact;
    final debts = context.read<PersonalDebtsCubit>();
    setState(() => _linking = true);
    try {
      final n = await context
          .read<ContactsCubit>()
          .absorb(contact.id, [widget.name]);
      await debts.load();
      if (!mounted) return;
      showAppSnackBar(context, l.debtsPersonLinked(n, contact.effectiveName),
          tone: Tone.success);
      context.pushReplacement(Uri(
        path: '/personal-debts/person',
        queryParameters: {'contact': contact.id, 'name': contact.effectiveName},
      ).toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _linking = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  void _addDebt() => context.push('/personal-debts/new', extra: {
        'contactId': widget.contactId,
        'name': widget.name,
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: widget.name, showBack: true),
      body: BlocBuilder<PersonalDebtsCubit, PersonalDebtsState>(
        builder: (context, state) {
          if (state.status == PersonalDebtsStatus.loading &&
              state.debts.isEmpty) {
            return const LoadingView();
          }
          final mine =
              state.debts.where((d) => DebtPerson.keyOf(d) == _key).toList()
                ..sort((a, b) => (b.createdAt ?? DateTime(0))
                    .compareTo(a.createdAt ?? DateTime(0)));
          final person = DebtPerson(
            contactId: widget.contactId,
            displayName: widget.name,
            debts: mine,
          );
          final open = mine.where((d) => d.isOpen).toList();
          final closed = mine.where((d) => !d.isOpen).toList();
          return PullToRefresh(
            onRefresh: () => context.read<PersonalDebtsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
              children: [
                _Header(person: person),
                const SizedBox(height: AppSpacing.lg),
                if (open.isNotEmpty)
                  SectionCard(
                    title: l.debtsStatusOpen,
                    children: [
                      for (final (i, d) in open.indexed) ...[
                        if (i > 0) const RowDivider(),
                        DebtTile(debt: d),
                      ],
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
                AddTile(
                  label: l.debtsPersonAdd,
                  variant: AddTileVariant.row,
                  onTap: _addDebt,
                ),
                if (widget.contactId == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  DetailRow(
                    leading: _linking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(AppIcons.link),
                    label: l.debtsPersonLinkContact,
                    helper: l.debtsPersonLinkContactHint,
                    showChevron: true,
                    onTap: _linking ? null : _linkToContact,
                  ),
                ],
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Theme(
                    // No divider lines from ExpansionTile.
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      leading: const Icon(AppIcons.history),
                      title: Text(l.debtsPersonHistory(closed.length)),
                      children: [
                        for (final (i, d) in closed.indexed) ...[
                          if (i > 0) const RowDivider(),
                          DebtTile(debt: d),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person});

  final DebtPerson person;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = person;
    final symbol = Currencies.symbolOf(p.currency);
    final even = p.net.abs() < 0.005;
    return HeaderCard(
      leading: DebtAvatar(contactId: p.contactId, name: p.displayName, size: 52),
      title: Text(p.displayName),
      subtitle: Text(even
          ? l.debtsEven
          : (p.net > 0 ? l.debtTheyOweYou(p.displayName) : l.debtYouOwe(p.displayName))),
      trailing: p.contactId == null
          ? null
          : AppIconButton(
              icon: AppIcons.contact,
              tooltip: l.debtsPersonOpenContact,
              onPressed: () => context.push('/contacts/${p.contactId}'),
            ),
      footer: even
          ? null
          : MoneyText(
              p.net.abs(),
              symbol: symbol,
              tone: p.net > 0 ? MoneyTone.income : MoneyTone.expense,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
    );
  }
}
