import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/institutions_repository.dart';
import '../../domain/institution.dart';

/// Picks one of the user's institutions (a debt counterparty, a wallet's
/// owner). Selection = highlight; "+ เพิ่ม …" creates one by the typed name
/// and returns it. Institutions never show in person pickers.
abstract final class InstitutionPicker {
  static Future<InstitutionRef?> one(
    BuildContext context, {
    String? selectedId,
    String? title,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final repo = InstitutionsRepository.of(context);
    final byId = <String, InstitutionRef>{};

    List<PickerItem> items(List<Institution> all) {
      byId
        ..clear()
        ..addAll({for (final i in all) i.id: i.ref});
      return [
        for (final i in all)
          PickerItem(
            id: i.id,
            title: i.name,
            subtitle: institutionKindLabel(l, i.kind),
            leading: InstitutionMark(
              name: i.name,
              iconCode: i.iconCode,
              shortName: i.provider?.shortName,
              color: InstitutionMark.parseHex(i.provider?.color),
              size: 36,
            ),
            keywords: [?i.provider?.name, ?i.provider?.shortName],
          ),
      ];
    }

    final r = await showItemPicker(
      context,
      useRootNavigator: useRootNavigator,
      ItemPickerSheet(
        title: title ?? l.institutionPickTitle,
        items: const [],
        load: () async {
          try {
            return items(await repo.list());
          } catch (e, st) {
            throw ApiException.from(e, st);
          }
        },
        selected: {?selectedId},
        searchable: true,
        emptyText: l.institutionEmpty,
        noMatchText: l.multiPickNoMatch,
        create: PickerCreate(
          fromSearch: true,
          label: (typed) => typed.trim().isEmpty
              ? l.institutionAdd
              : l.institutionAddNamed(typed.trim()),
          onCreate: (typed) async {
            final name = typed.trim();
            if (name.isEmpty) return null;
            final made = await repo.create(
              InstitutionWrite(name: name, kind: InstitutionKind.other),
            );
            byId[made.id] = made.ref;
            return made.id;
          },
        ),
      ),
    );
    final id = r?.id;
    return id == null ? null : byId[id];
  }
}

String institutionKindLabel(AppLocalizations l, InstitutionKind k) =>
    switch (k) {
      InstitutionKind.bank => l.institutionKindBank,
      InstitutionKind.card => l.institutionKindCard,
      InstitutionKind.finance => l.institutionKindFinance,
      InstitutionKind.store => l.institutionKindStore,
      InstitutionKind.other => l.institutionKindOther,
    };
