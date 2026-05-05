/// Mixin for any per-user cubit that needs to be wiped on logout.
///
/// Sign your cubit with `with Clearable` and implement [clear] to emit
/// the initial-state value. The auth listener in `app.dart` calls
/// [clear] on every cubit it knows about whenever the AuthCubit
/// transitions to AuthUnauthenticated (logout) or to a new
/// AuthAuthenticated identity (login as a different user).
///
/// Cubits that hold UI-only state (theme, locale, font) should NOT
/// mix this in — those settings outlive the session.
abstract mixin class Clearable {
  /// Drop all per-user state. Implementations typically `emit(const
  /// FooState())` and reset any timers / subscriptions / paginators.
  /// Called from the auth listener; safe to call repeatedly.
  void clear();
}
