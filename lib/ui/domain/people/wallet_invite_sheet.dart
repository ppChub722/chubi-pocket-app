import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui.dart';

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

  final String hint;

  final String empty;
}

Future<WalletInviteCandidate?> showWalletInviteSelectSheet(
  BuildContext context, {
  required List<WalletInviteCandidate> candidates,
  required WalletInviteStrings strings,
  ValueListenable<List<WalletInviteCandidate>>? live,
  Future<void> Function()? onRefresh,
}) {
  return showAppSheetCustom<WalletInviteCandidate>(
    context,
    builder: (ctx) => SheetRefreshScope(
      onRefresh: onRefresh,
      child: LiveItems<List<WalletInviteCandidate>>(
        initial: candidates,
        live: live,
        builder: (_, items) => WalletInviteSheet(
          candidates: items,
          strings: strings,
          onPick: (c) => Navigator.of(ctx).pop(c),
        ),
      ),
    ),
  );
}

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

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PickerSheet(
      title: strings.title,
      searchable: candidates.length > 8,
      searchToggle: true,
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
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppText(
            candidates.isEmpty ? strings.empty : strings.hint,
            role: AppTextRole.caption,
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
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
