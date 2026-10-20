import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/accounts/domain/payment_provider.dart';
import '../../../features/accounts/presentation/cubit/providers_cubit.dart';
import '../../../features/accounts/presentation/widgets/bank_picker.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// [BankPicker] as the identifier editor will open it, on the real providers
/// cache.
class BankPickerDemos extends StatelessWidget {
  const BankPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static String _label(PaymentProvider p, String lang) =>
      '${p.label(lang)} (${p.code})';

  Widget _new(
    BuildContext context,
    String label,
    Future<String> Function() run,
  ) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async {
      unawaited(context.read<ProvidersCubit>().loadIfNeeded());
      onResult(await run());
    },
  );

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final providers = context.watch<ProvidersCubit>().state.providers;
    final some = providers.where((p) => p.isBank).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'BankPicker.one — identifier bank',
          note:
              'identifier_kind_sheet: each bank with its mark, "short | code" '
              'under the name, "ไม่ระบุ" on top (picked when no bank is set); '
              'the search matches Thai, English, short name and code.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _new(
                context,
                'New',
                () async => switch (await BankPicker.one(
                  context,
                  selectedCode: some?.code,
                )) {
                  null => 'closed',
                  BankPickedNone() => 'none',
                  BankPicked(:final bank) => _label(bank, lang),
                },
              ),
              _new(
                context,
                'New, no bank set',
                () async => switch (await BankPicker.one(context)) {
                  null => 'closed',
                  BankPickedNone() => 'none',
                  BankPicked(:final bank) => _label(bank, lang),
                },
              ),
            ],
          ),
        ),
        if (providers.isEmpty)
          const HubDemo(
            title: 'No banks',
            child: AppText(
              'The providers cache is empty: a button loads it, or sign in '
              'first.',
            ),
          ),
      ],
    );
  }
}
