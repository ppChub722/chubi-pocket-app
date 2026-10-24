import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';

/// "จ่าย" beside a person's name in a bill: ✓ and filled on the one who paid,
/// dashed on everyone else (tap = they paid). The event bill and quick
/// create's แบ่ง card share it.
class PayChip extends StatelessWidget {
  const PayChip({
    required this.label,
    required this.paid,
    this.onTap,
    super.key,
  });

  final String label;
  final bool paid;

  /// Makes this person the payer; none once they already are.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppChip(
    label: label,
    icon: paid ? AppIcons.check : null,
    selected: paid,
    dashed: !paid,
    size: ChipSize.mini,
    onTap: paid ? null : onTap,
  );
}
