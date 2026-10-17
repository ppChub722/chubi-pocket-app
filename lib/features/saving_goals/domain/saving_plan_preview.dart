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
