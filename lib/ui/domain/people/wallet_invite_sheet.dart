import 'package:flutter/material.dart';

import '../../ui.dart';

/// A person who can be invited to a wallet, as plain values: a contact
/// linked to an app account. [id] is the caller's own key; [iconCode] is the
/// linked user's effective icon.
@immutable
class WalletInviteCandidate {
  const WalletInviteCandidate({
    required this.id,
    required this.name,
    this.email,
    this.iconCode,
  });

  final String id;
  final String name;
  final String? email;
  final IconCode? iconCode;
}

/// The words of [WalletInviteSheet] (the kit never reads the app's l10n).
class WalletInviteStrings {
  const WalletInviteStrings({
    required this.title,
    required this.searchHint,
    required this.hint,
    required this.empty,
  });

  final String title;
  final String searchHint;

  /// The caption over the list.
  final String hint;

  /// The caption when there is nobody to invite.
  final String empty;
}

/// "Invite to this wallet": pick one of [candidates] (a list the caller has
/// already filtered). Resolves the picked candidate, or null when dismissed.
Future<WalletInviteCandidate?> showWalletInviteSelectSheet(
  BuildContext context, {
  required List<WalletInviteCandidate> candidates,
  required WalletInviteStrings strings,
}) {
  return showPpForgeSheetCustom<WalletInviteCandidate>(
    context,
    builder: (ctx) => WalletInviteSheet(
      candidates: candidates,
      strings: strings,
      onPick: (c) => Navigator.of(ctx).pop(c),
    ),
  );
}

/// The sheet body on the kit [PickerSheet], searchable by name / email once
/// there are more than 8. Stateless: a live caller (cubit-backed) rebuilds it
/// with new [candidates] / [loading] / [error] and handles [onPick] itself.
class WalletInviteSheet extends StatelessWidget {
  const WalletInviteSheet({
    required this.candidates,
    required this.strings,
    required this.onPick,
    this.loading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final List<WalletInviteCandidate> candidates;
  final WalletInviteStrings strings;
  final ValueChanged<WalletInviteCandidate> onPick;

  /// Still fetching and nothing to show yet.
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PickerSheet(
      title: strings.title,
      searchable: candidates.length > 8,
      searchHint: strings.searchHint,
      loading: loading,
      error: error,
      onRetry: onRetry,
      builder: (context, query) {
        final shown = query.isEmpty
            ? candidates
            : candidates
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(query) ||
                        (c.email?.toLowerCase().contains(query) ?? false),
                  )
                  .toList();
        final hint = Padding(
          padding: const EdgeInsets.fromLTRB(
            PpForgeSpacing.lg,
            0,
            PpForgeSpacing.lg,
            PpForgeSpacing.sm,
          ),
          child: PpForgeText(
            candidates.isEmpty ? strings.empty : strings.hint,
            role: PpForgeTextRole.caption,
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
                      // Every one here is linked: "(avatar)link name".
                      leading: PersonMark(
                        name: c.name,
                        level: PersonLevel.linked,
                        iconCode: c.iconCode,
                        size: 40,
                        reserveLinkSlot: true,
                      ),
                      title: c.name,
                      subtitle: c.email,
                      onTap: () => onPick(c),
                    ),
                ],
              ),
            const SizedBox(height: PpForgeSpacing.md),
          ],
        );
      },
    );
  }
}
