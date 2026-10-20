import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../../../features/accounts/presentation/widgets/account_picker.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [AccountPicker] as each page will open it, on the real wallets cache.
class AccountPickerDemos extends StatelessWidget {
  const AccountPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static String _one(AccountPickOutcome? r) => switch (r) {
    null => 'closed',
    AccountPickedNone() => 'none',
    AccountPicked(:final account) => account.name,
  };

  static String _many(AccountPicks? r) {
    if (r == null) return 'closed';
    final unknown = r.ids.length - r.accounts.length;
    final s = [
      if (r.none) 'none',
      for (final a in r.accounts) a.name,
      if (unknown > 0) '$unknown unknown',
    ].join(', ');
    return s.isEmpty ? 'nothing' : s;
  }

  Widget _new(String label, Future<String> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => onResult(await run()),
  );

  Widget _demo(String title, String note, List<Widget> buttons) => HubDemo(
    title: title,
    note: note,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AccountsCubit>().state;
    final active = state.accounts;
    final first = active.firstOrNull;
    final second = active.skip(1).firstOrNull;
    final archived = state.archivedAccounts.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'AccountPicker.one — transaction forms',
          'draft_form (not a transfer), saving_entry_form, debt_entry_form: '
              '"ไม่ระบุกระเป๋า" and add a wallet; the wallet set is the '
              'picked card.',
          [
            _new(
              'New',
              () async => _one(
                await AccountPicker.one(
                  context,
                  selectedId: first?.id,
                  allowNone: true,
                  allowCreate: true,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'AccountPicker.one — transfer from / to (draft form)',
          'Each side leaves out the wallet on the other side; no none; add a '
              'wallet. "To" has its own title.',
          [
            _new(
              'New, from',
              () async => _one(
                await AccountPicker.one(
                  context,
                  selectedId: first?.id,
                  excludeIds: {?second?.id},
                  allowCreate: true,
                ),
              ),
            ),
            _new(
              'New, to',
              () async => _one(
                await AccountPicker.one(
                  context,
                  selectedId: second?.id,
                  excludeIds: {?first?.id},
                  title: l.quickTo,
                  allowCreate: true,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'AccountPicker.one — recurring from / to',
          'recurring_detail_page: leaves out the other side; no none, no add.',
          [
            _new(
              'New, from',
              () async => _one(
                await AccountPicker.one(
                  context,
                  selectedId: first?.id,
                  excludeIds: {?second?.id},
                ),
              ),
            ),
            _new(
              'New, to',
              () async => _one(
                await AccountPicker.one(
                  context,
                  selectedId: second?.id,
                  excludeIds: {?first?.id},
                  title: l.recurringFieldToWallet,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'AccountPicker.one — none, no add',
          'debt_entry_detail_page (default title), settings main wallet, '
              'notification receiving wallet, saving goal auto-save source: '
              'each its own title and "ไม่ระบุกระเป๋า". Nothing set yet = the '
              'none card is the picked one.',
          [
            _new(
              'New',
              () async => _one(
                await AccountPicker.one(
                  context,
                  allowNone: true,
                  title: l.settingsMainWallet,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'AccountPicker.one — resolve (event)',
          'resolve_sheet: a wallet only; no none, no add.',
          [
            _new(
              'New',
              () async =>
                  _one(await AccountPicker.one(context, selectedId: first?.id)),
            ),
          ],
        ),
        _demo(
          'AccountPicker.many — transaction filter',
          'tx_filter_sheet "more": wallet cards with their balance; '
              '"ไม่ระบุกระเป๋า" is a tick of its own.',
          [
            _new(
              'New',
              () async => _many(
                await AccountPicker.many(
                  context,
                  selected: {?first?.id},
                  allowNone: true,
                  title: l.transactionsFilterAccount,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'AccountPicker.many — budget wallets',
          'budget_detail_page: wallet cards; no none. '
              'An archived wallet shows only when it is already ticked; '
              '${archived == null ? 'there is no archived wallet to try.' : 'this demo ticks "${archived.name}".'}',
          [
            _new(
              'New',
              () async => _many(
                await AccountPicker.many(
                  context,
                  selected: {?first?.id, ?archived?.id},
                ),
              ),
            ),
          ],
        ),
        if (active.isEmpty)
          const HubDemo(
            title: 'No wallets',
            child: AppText('The wallets cache is empty: sign in first.'),
          ),
      ],
    );
  }
}
