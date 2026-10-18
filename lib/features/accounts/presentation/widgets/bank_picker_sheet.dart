import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../cubit/providers_cubit.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/payment_provider.dart';

class BankPick {
  const BankPick(this.bank);
  final PaymentProvider? bank;
}

const _majorBankCodes = ['004', '014', '002', '006', '025'];

BankPickerItem bankPickerItemOf(PaymentProvider p, String lang) =>
    BankPickerItem(
      code: p.code,
      name: p.name(lang),
      nameTh: p.nameTh,
      nameEn: p.nameEn,
      shortName: p.shortName,
    );

List<BankPickerItem> rankedBankItems(
  List<PaymentProvider> providers,
  String lang,
) {
  int rank(PaymentProvider p) {
    final i = _majorBankCodes.indexOf(p.code);
    return i < 0 ? _majorBankCodes.length : i;
  }

  final banks = providers.where((p) => p.isBank).toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name(lang).compareTo(b.name(lang));
    });
  return [for (final b in banks) bankPickerItemOf(b, lang)];
}

Future<BankPick?> showBankPicker(
  BuildContext context, {
  required List<PaymentProvider> providers,
  String? selectedCode,
  bool allowNone = true,
  String? title,
}) async {
  final l = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  ProvidersCubit? cache;
  try {
    cache = context.read<ProvidersCubit>();
  } catch (_) {
    cache = null; // no cache here (a test, the hub): the list as given
  }
  var latest = providers;
  final feed = cache == null
      ? null
      : CubitFeed<ProvidersState, List<BankPickerItem>>(cache, (s) {
          latest = s.providers;
          return rankedBankItems(latest, lang);
        });
  try {
    final choice = await showBankSelectSheet(
      context,
      banks: rankedBankItems(providers, lang),
      live: feed?.listenable,
      onRefresh: cache == null
          ? null
          : syncRefreshOf(context, const {SyncSet.providers}),
      selectedCode: selectedCode,
      allowNone: allowNone,
      strings: BankPickerStrings(
        title: title ?? l.identifierBankLabel,
        noneLabel: l.identifierBankNone,
      ),
    );
    if (choice == null) return null;
    return BankPick(
      choice.code == null
          ? null
          : latest.firstWhere(
              (p) => p.code == choice.code,
              orElse: () => providers.firstWhere((p) => p.code == choice.code),
            ),
    );
  } finally {
    await feed?.dispose();
  }
}

class BankMark extends StatelessWidget {
  const BankMark({required this.provider, this.size = 36, super.key});

  final PaymentProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) => BankBrandMark(
    code: provider.code,
    shortName: provider.shortName,
    nameEn: provider.nameEn,
    size: size,
  );
}
