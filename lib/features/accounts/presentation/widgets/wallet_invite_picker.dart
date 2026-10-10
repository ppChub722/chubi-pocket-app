import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../contacts/presentation/widgets/contact_linked_mark.dart';

/// "เชิญเข้ากระเป๋านี้" (owner 2026-10-11) — the wallet invite picks a
/// CONTACT, never an email: only active contacts linked to an app account
/// (`linked_user_id` set), minus the people already in the wallet or
/// invited ([excludeUserIds]). On the kit [PickerSheet], searchable by
/// name / email. Null when dismissed.
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
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<ContactsCubit>().state;
    final invitable = [
      for (final c in state.contacts)
        if (c.isLinked &&
            !c.isArchived &&
            !widget.excludeUserIds.contains(c.linkedUserId))
          c,
    ];
    final loading =
        invitable.isEmpty &&
        (state.status == ContactsStatus.initial ||
            state.status == ContactsStatus.loading);
    return PickerSheet(
      title: l.walletInvitePickTitle,
      searchable: invitable.length > 8,
      searchHint: l.contactsSearchHint,
      loading: loading,
      error: invitable.isEmpty && state.status == ContactsStatus.error
          ? state.error
          : null,
      onRetry: context.read<ContactsCubit>().load,
      builder: (context, query) {
        final shown = query.isEmpty
            ? invitable
            : invitable
                  .where(
                    (c) =>
                        c.effectiveName.toLowerCase().contains(query) ||
                        (c.effectiveEmail?.toLowerCase().contains(query) ??
                            false),
                  )
                  .toList();
        final hint = Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            invitable.isEmpty
                ? l.walletInvitePickEmpty
                : l.walletInvitePickHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hint,
            if (shown.isNotEmpty)
              SectionCard(
                first: true,
                children: [
                  for (final c in shown)
                    PickerRow(
                      // Every one here is linked: "(ม)🔗 name".
                      leading: ContactAvatar(contact: c),
                      title: c.effectiveName,
                      subtitle: c.effectiveEmail,
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
