import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_input.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../atoms/busy_scope.dart';

/// The debt person hero's main line (owner 2026-10-22, mock DebtPerson):
/// "รอจ่ายให้ลี" at the start, the big amount at the end, in [color].
class DebtSentenceAmount extends StatelessWidget {
  const DebtSentenceAmount({
    required this.sentence,
    required this.amount,
    this.color,
    super.key,
  });

  final String sentence;
  final Widget amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            sentence,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: DefaultTextStyle.merge(
              style: text.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              child: amount,
            ),
          ),
        ),
      ],
    );
  }
}

/// The line under a debt entry's amount (mock DebtEntry): "รอรับจาก chalee
/// ฿82" (the amount bold, in [color]) and the "✓ จ่ายแล้ว" pill.
class DebtEntryNote extends StatelessWidget {
  const DebtEntryNote({
    required this.sentence,
    required this.amount,
    this.color,
    this.paidLabel,
    super.key,
  });

  final String sentence;
  final Widget amount;
  final Color? color;
  final String? paidLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodySmall;
    final paid = paidLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            sentence,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        DefaultTextStyle.merge(
          style: text?.copyWith(color: color, fontWeight: FontWeight.w700),
          child: amount,
        ),
        if (paid != null) ...[
          const SizedBox(width: AppSpacing.xs),
          AppChip(
            key: const ValueKey('debtEntryPaid'),
            label: paid,
            size: ChipSize.mini,
          ),
        ],
      ],
    );
  }
}

/// The debt person hero's two buttons (mock): settle ("จ่ายคืน ฿230",
/// filled, in the side's [color]) and the summary ("สรุปยอด" / "ทวง",
/// outlined). [onSettle] null hides settle (nothing open).
class DebtPersonActions extends StatelessWidget {
  const DebtPersonActions({
    required this.shareLabel,
    required this.onShare,
    this.settleLabel,
    this.onSettle,
    this.color,
    super.key,
  });

  final String? settleLabel;
  final VoidCallback? onSettle;
  final String shareLabel;
  final VoidCallback onShare;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    final tinted = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: c,
        onPrimary: Colors.white,
      ),
    );
    final settle = settleLabel;
    return Theme(
      data: tinted,
      child: Row(
        children: [
          if (settle != null && onSettle != null) ...[
            Expanded(
              flex: 16,
              child: AppButton(
                key: const ValueKey('debtSettle'),
                label: settle,
                icon: AppIcons.cash,
                size: AppButtonSize.control,
                expand: true,
                onPressed: onSettle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: 10,
            child: AppButton(
              key: const ValueKey('debtShare'),
              label: shareLabel,
              icon: AppIcons.share,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.control,
              expand: true,
              onPressed: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

/// "เคลียร์ครบ 20 ส.ค. | ดูรอบก่อน ▾": a line, the words, a line — the
/// earlier cycles open behind it (mock DebtPerson).
class CycleDivider extends StatelessWidget {
  const CycleDivider({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Container(height: 1, color: scheme.outlineVariant),
    );
    return BusyLock(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          // The words keep at least a short line each side; a long label
          // wraps (narrow phones, big text).
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                line,
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (box.maxWidth - 2 * AppSpacing.lg).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      label,
                      key: const ValueKey('cycleDivider'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                line,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// สรุปยอด / ทวง (mock DebtPerson): pick a [variants] text (รอบนี้ /
/// ยอดคงเหลืออย่างเดียว), edit it, then copy or share it.
class DebtShareSheet extends StatefulWidget {
  const DebtShareSheet({
    required this.variants,
    required this.fieldLabel,
    required this.copyLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
    super.key,
  });

  final List<({String label, String text})> variants;
  final String fieldLabel;
  final String copyLabel;
  final String shareLabel;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onShare;

  @override
  State<DebtShareSheet> createState() => _DebtShareSheetState();
}

class _DebtShareSheetState extends State<DebtShareSheet> {
  int _picked = 0;
  late final _text = TextEditingController(
    text: widget.variants.firstOrNull?.text ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _pick(int i) => setState(() {
    _picked = i;
    _text.text = widget.variants[i].text;
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final (i, v) in widget.variants.indexed)
                AppChip(
                  key: ValueKey('shareVariant$i'),
                  label: v.label,
                  selected: i == _picked,
                  size: ChipSize.chip,
                  onTap: () => _pick(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
            key: const ValueKey('shareText'),
            controller: _text,
            label: widget.fieldLabel,
            minLines: 5,
            maxLines: 10,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: widget.copyLabel,
                  icon: AppIcons.copy,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: () => widget.onCopy(_text.text),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: widget.shareLabel,
                  icon: AppIcons.share,
                  expand: true,
                  onPressed: () => widget.onShare(_text.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
