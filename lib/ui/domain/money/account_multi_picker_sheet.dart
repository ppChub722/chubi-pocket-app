import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../molecules/detail_rows.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../organisms/picker_sheet.dart';
import '../../tokens/app_spacing.dart';

/// One wallet of [showAccountMultiPicker], as plain display data.
@immutable
class AccountMultiPickItem {
  const AccountMultiPickItem({
    required this.id,
    required this.name,
    required this.icon,
    this.balance,
  });

  final String id;
  final String name;
  final IconData icon;

  /// The balance, already formatted. null = none shown (an untracked wallet).
  final String? balance;
}

/// The words of the multi wallet picker (the caller's localised strings).
class AccountMultiPickerLabels {
  const AccountMultiPickerLabels({
    required this.title,
    required this.searchHint,
    required this.confirm,
    required this.empty,
    required this.noMatch,
  });

  final String title;
  final String searchHint;

  /// The confirm button, built from the picked count.
  final String Function(int count) confirm;
  final String empty;
  final String noMatch;
}

/// Pick several wallets - a PRESENTATIONAL organism on [PickerSheet]: rows
/// with a square check and the highlight tint (no tick mark). Resolves the
/// picked ids (in pick order, empty allowed) on confirm, null when
/// dismissed. Search shows with more than 8 wallets.
Future<List<String>?> showAccountMultiPicker(
  BuildContext context, {
  required List<AccountMultiPickItem> wallets,
  required AccountMultiPickerLabels labels,
  List<String> initial = const [],
}) {
  return showAppSheetCustom<List<String>>(
    context,
    builder: (_) => AccountMultiPickerSheet(
      wallets: wallets,
      labels: labels,
      initial: initial,
    ),
  );
}

/// The sheet body of [showAccountMultiPicker]; pops the picked ids.
class AccountMultiPickerSheet extends StatefulWidget {
  const AccountMultiPickerSheet({
    required this.wallets,
    required this.labels,
    this.initial = const [],
    super.key,
  });

  final List<AccountMultiPickItem> wallets;
  final AccountMultiPickerLabels labels;
  final List<String> initial;

  @override
  State<AccountMultiPickerSheet> createState() =>
      _AccountMultiPickerSheetState();
}

class _AccountMultiPickerSheetState extends State<AccountMultiPickerSheet> {
  late final List<String> _picked = [...widget.initial];

  void _toggle(String id) => setState(() {
    if (!_picked.remove(id)) _picked.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return PickerSheet(
      title: l.title,
      searchable: widget.wallets.length > 8,
      searchHint: l.searchHint,
      footer: PickerConfirmBar(
        label: l.confirm(_picked.length),
        onPressed: () => Navigator.of(context).pop([..._picked]),
      ),
      builder: (context, q) {
        final visible = q.isEmpty
            ? widget.wallets
            : widget.wallets
                  .where((w) => w.name.toLowerCase().contains(q))
                  .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (visible.isNotEmpty)
              SectionCard(
                first: true,
                children: [
                  for (final w in visible)
                    PickerRow(
                      key: ValueKey('wallet-${w.id}'),
                      leading: AppIcon(w.icon),
                      title: w.name,
                      subtitle: w.balance,
                      checked: _picked.contains(w.id),
                      onTap: () => _toggle(w.id),
                    ),
                ],
              )
            else
              EmptyView.compact(message: q.isEmpty ? l.empty : l.noMatch),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }
}
