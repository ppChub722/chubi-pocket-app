import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
      final n = (await context.read<ContactsCubit>().absorb(contact.id, [
        widget.name,
      ])).absorbedCount;
      await debts.load();
      if (!mounted) return;
      showAppSnackBar(
        context,
        l.debtsPersonLinked(n, contact.name),
        tone: Tone.success,
      );
      context.pushReplacement(
        Uri(
          path: '/personal-debts/person',
          queryParameters: {'contact': contact.id, 'name': contact.name},
        ).toString(),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _linking = false);
      showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  void _addDebt() => context.push(
    '/personal-debts/new',
    extra: {'contactId': widget.contactId, 'name': widget.name},
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: widget.name, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<PersonalDebtsCubit, PersonalDebtsState>(
        builder: (context, state) => AsyncStateView(
          loading:
              state.status == PersonalDebtsStatus.initial ||
              state.status == PersonalDebtsStatus.loading,
          error: state.error,
          isEmpty: state.debts.isEmpty,
          onRetry: context.read<PersonalDebtsCubit>().load,
          // No debts with this person → the page's own empty sections.
          builder: (context) {
            final mine =
                state.debts.where((d) => DebtPerson.keyOf(d) == _key).toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );
            final person = DebtPerson(
              contactId: widget.contactId,
              displayName: widget.name,
              debts: mine,
              person: mine.firstOrNull?.person,
            );
            final open = mine.where((d) => d.isOpen).toList();
            final closed = mine.where((d) => !d.isOpen).toList();
            return DetailPageBody(
              onRefresh: () => context.read<PersonalDebtsCubit>().load(),
              physics: const AlwaysScrollableScrollPhysics(),
              // Top: clear the floating top bar.
              topInset: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
              hero: _Header(person: person),
              sections: [
                // ONE headless box right after the hero: add a debt (+ link
                // a typed name to a contact). Icons on every row.
                (first) => SectionCard(
                  first: first,
                  children: [
                    DetailAddRow(label: l.debtsPersonAdd, onTap: _addDebt),
                    if (widget.contactId == null)
                      DetailRow(
                        leading: _linking
                            ? const AppSpinner(size: AppSpinnerSize.medium)
                            : const AppIcon(AppIcons.link),
                        label: l.debtsPersonLinkContact,
                        helper: l.debtsPersonLinkContactHint,
                        showChevron: true,
                        onTap: _linking ? null : _linkToContact,
                      ),
                  ],
                ),
                (first) => open.isEmpty
                    ? null
                    : SectionCard(
                        first: first,
                        title: l.debtsStatusOpen,
                        children: [for (final d in open) DebtTile(debt: d)],
                      ),
                (first) => closed.isEmpty
                    ? null
                    : CollapsibleSection(
                        title: l.debtsPersonHistory(closed.length),
                        leading: const AppIcon(AppIcons.history),
                        initiallyOpen: false,
                        children: [for (final d in closed) DebtTile(debt: d)],
                      ),
              ],
            );
          },
        ),
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
    final palette = Theme.of(context).extension<AppColors>()!;
    return HeaderCard(
      accent: p.person?.iconCode.tintFor(palette, avatarName: p.displayName),
      leading: PersonMark(
        name: p.displayName,
        level: p.contactId == null ? PersonLevel.name : PersonLevel.linked,
        iconCode: p.person?.iconCode,
        size: 52,
      ),
      title: Text(p.displayName),
      subtitle: Text(
        even
            ? l.debtsEven
            : (p.net > 0
                  ? l.debtTheyOweYou(p.displayName)
                  : l.debtYouOwe(p.displayName)),
      ),
      trailing: p.contactId == null
          ? null
          : AppIconButton(
              icon: AppIcons.contact,
              tooltip: l.debtsPersonOpenContact,
              onPressed: () => openPage(context, '/contacts/${p.contactId}'),
            ),
      footer: even
          ? null
          : MoneyText(
              p.net.abs(),
              symbol: symbol,
              tone: p.net > 0 ? MoneyTone.income : MoneyTone.expense,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
    );
  }
}
