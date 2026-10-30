/// The kit's opacity steps: one fade for "can't use this now" everywhere.
abstract final class AppOpacity {
  /// A control that can't be used: disabled, or locked while something else
  /// saves ([BusyScope]). The value stays readable.
  static const double disabled = 0.38;

  /// An item that is still there but set aside (archived, paid); still
  /// tappable.
  static const double dimmed = 0.55;
}
