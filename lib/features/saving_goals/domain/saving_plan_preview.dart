/// The edit form's live line "ออมแล้ว ฿X · เหลือ ฿Y → ต้องออม ฿Z/เดือน".
///
/// Instant feedback while typing only (like the split remainder): the BE
/// recomputes every figure on save and the view mode shows ITS numbers. Same
/// rule as the BE: months = days to the deadline / 30.44 (at least 1), rounded
/// up to the baht; null without a deadline, past it, or when nothing is left.
class SavingPlanPreview {
  const SavingPlanPreview({required this.remaining, this.neededMonthly});

  final double remaining;
  final double? neededMonthly;

  factory SavingPlanPreview.of({
    required double target,
    required double saved,
    DateTime? deadline,
    DateTime? today,
  }) {
    final left = target - saved;
    final remaining = left > 0 ? left : 0.0;
    if (deadline == null || remaining == 0) {
      return SavingPlanPreview(remaining: remaining);
    }
    final now = today ?? DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(deadline.year, deadline.month, deadline.day);
    final days = to.difference(from).inDays;
    if (days < 0) return SavingPlanPreview(remaining: remaining);
    final months = (days / 30.44).ceil().clamp(1, 100000);
    return SavingPlanPreview(
      remaining: remaining,
      neededMonthly: (remaining / months).ceilToDouble(),
    );
  }
}
