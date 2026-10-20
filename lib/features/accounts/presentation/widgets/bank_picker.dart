import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/payment_provider.dart';
import '../cubit/providers_cubit.dart';

sealed class BankPickOutcome {
  const BankPickOutcome();
}

class BankPicked extends BankPickOutcome {
  const BankPicked(this.bank);
  final PaymentProvider bank;
}

/// "ไม่ระบุ" was picked.
class BankPickedNone extends BankPickOutcome {
  const BankPickedNone();
}

/// The bank picker: the banks of the providers cache, the big five first and
/// the rest by name. [providers] = the list to start from; without it the
/// cache.
abstract final class BankPicker {
  static const _majorCodes = ['004', '014', '002', '006', '025'];

  static Future<BankPickOutcome?> one(
    BuildContext context, {
    String? selectedCode,
    bool allowNone = true,
    String? noneLabel,
    String? title,
    List<PaymentProvider>? providers,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    ProvidersCubit? cache;
    try {
      cache = context.read<ProvidersCubit>();
    } catch (_) {
      cache = null;
    }
    var latest =
        providers ?? cache?.state.providers ?? const <PaymentProvider>[];
    final start = latest;
    final feed = cache == null
        ? null
        : CubitFeed<ProvidersState, PickerData>(cache, (s) {
            latest = s.providers;
            return PickerData(
              _items(latest, lang),
              loading: s.status == ProvidersStatus.loading,
              error: s.error,
            );
          });
    try {
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: title ?? l.identifierBankLabel,
          items: _items(latest, lang),
          live: feed?.listenable,
          onRefresh: cache == null
              ? null
              : syncRefreshOf(context, const {SyncSet.providers}),
          selected: {?selectedCode},
          noneSelected: allowNone && selectedCode == null,
          none: allowNone
              ? PickerNone(
                  label: noneLabel ?? l.identifierBankNone,
                  leading: const AppIcon(AppIcons.bank),
                )
              : null,
          searchable: true,
          emptyText: l.multiPickEmpty,
          noMatchText: l.multiPickNoMatch,
        ),
      );
      if (result == null) return null;
      if (result.none) return const BankPickedNone();
      final code = result.id;
      final hit =
          latest.where((p) => p.code == code).firstOrNull ??
          start.where((p) => p.code == code).firstOrNull;
      return hit == null ? null : BankPicked(hit);
    } finally {
      unawaited(feed?.dispose());
    }
  }

  static List<PickerItem> _items(List<PaymentProvider> all, String lang) {
    int rank(PaymentProvider p) {
      final i = _majorCodes.indexOf(p.code);
      return i < 0 ? _majorCodes.length : i;
    }

    final banks = all.where((p) => p.isBank).toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name(lang).compareTo(b.name(lang));
      });
    return [
      for (final b in banks)
        PickerItem(
          id: b.code,
          title: b.name(lang),
          subtitle: [?b.shortName, b.code].join(' | '),
          leading: BankBrandMark(
            code: b.code,
            shortName: b.shortName,
            nameEn: b.nameEn,
          ),
          keywords: [b.nameTh, b.nameEn],
        ),
    ];
  }
}
