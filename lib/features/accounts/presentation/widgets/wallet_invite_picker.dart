import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';

Future<Contact?> showWalletInvitePicker(
  BuildContext context, {
  required Set<String> excludeUserIds,
}) => showAppSheetCustom<Contact>(
  context,
  builder: (_) => _WalletInvitePicker(excludeUserIds: excludeUserIds),
);

class _WalletInvitePicker extends StatefulWidget {
  const _WalletInvitePicker({required this.excludeUserIds});
  final Set<String> excludeUserIds;

  @override
  State<_WalletInvitePicker> createState() => _WalletInvitePickerState();
}

class _WalletInvitePickerState extends State<_WalletInvitePicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<ContactsCubit>().state;
    final invitable = [
      for (final c in state.contacts)
        if (c.isLinked &&
            !c.isArchived &&
            !widget.excludeUserIds.contains(c.linkedUser?.id))
          c,
    ];
    final loading =
        invitable.isEmpty &&
        (state.status == ContactsStatus.initial ||
            state.status == ContactsStatus.loading);
    return WalletInviteSheet(
      candidates: [
        for (final c in invitable)
          WalletInviteCandidate(
            id: c.id,
            name: c.name,
            email: c.email,
            iconCode: c.iconCode,
          ),
      ],
      strings: WalletInviteStrings(
        title: l.walletInvitePickTitle,
        searchHint: l.contactsSearchHint,
        hint: l.walletInvitePickHint,
        empty: l.walletInvitePickEmpty,
      ),
      loading: loading,
      error: invitable.isEmpty && state.status == ContactsStatus.error
          ? state.error
          : null,
      onRetry: context.read<ContactsCubit>().load,
      onPick: (picked) => Navigator.of(
        context,
      ).pop(invitable.firstWhere((c) => c.id == picked.id)),
    );
  }
}
