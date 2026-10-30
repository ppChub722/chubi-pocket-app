import 'package:flutter/widgets.dart';

import '../tokens/app_durations.dart';
import '../tokens/app_opacity.dart';
import 'app_spinner.dart';

/// What the kit's interactive pieces under a [BusyScope] do (owner
/// 2026-10-28: no scrims — only the pressed control shows loading).
enum BusyLevel {
  /// Normal.
  idle,

  /// Something else is running: every interactive piece below is faded
  /// ([AppOpacity.disabled]) and ignores input; inputs keep their value
  /// readable and turn read-only. No spinner.
  locked,

  /// The control below IS the one that was pressed: it shows a spinner in
  /// place (same size, same position) and ignores presses. A row here is
  /// inert; its own control (switch, ▾ button, ›) spins.
  active,
}

/// Locks a region while a call runs, with no per-field wiring: every
/// interactive kit piece below reads it.
///
///     BusyScope(busy: saving, child: form)       // the form fades + locks
///     AppButton(label: 'Save', loading: saving)  // the pressed one spins
///
/// Explicit flags still win: a piece's own `loading: true` spins even inside a
/// locked scope, and a disabled piece (`onPressed: null`, `enabled: false`)
/// keeps its own disabled look. A control that must stay usable inside a
/// locked region goes under [BusyScope.free].
class BusyScope extends StatelessWidget {
  /// [busy] locks everything below; not busy = whatever the scope above says.
  const BusyScope({required bool busy, required this.child, super.key})
    : _level = busy ? BusyLevel.locked : null;

  /// The control below is the pressed one: it spins (a live setting's row
  /// while its save runs). Not [active] = whatever the scope above says.
  const BusyScope.active({required this.child, bool active = true, super.key})
    : _level = active ? BusyLevel.active : null;

  /// Normal below, whatever the scopes above say (an unrelated control inside
  /// a locked form).
  const BusyScope.free({required this.child, super.key})
    : _level = BusyLevel.idle;

  final BusyLevel? _level;
  final Widget child;

  static BusyLevel of(BuildContext context) =>
      _BusyData.maybeOf(context)?.level ?? BusyLevel.idle;

  static bool isLocked(BuildContext context) => of(context) == BusyLevel.locked;

  static bool isActive(BuildContext context) => of(context) == BusyLevel.active;

  /// How a control with its own [loading] flag shows here: it [spinning]s
  /// (its own flag or an active scope), or it is [locked] (a locked scope,
  /// unless it is disabled anyway: [enabled] false keeps its own look).
  static ({bool spinning, bool locked}) control(
    BuildContext context, {
    bool loading = false,
    bool enabled = true,
  }) {
    final level = of(context);
    final spinning = loading || level == BusyLevel.active;
    return (
      spinning: spinning,
      locked: !spinning && enabled && level == BusyLevel.locked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parent = _BusyData.maybeOf(context);
    return _BusyData(
      level: _level ?? parent?.level ?? BusyLevel.idle,
      faded: parent?.faded ?? false,
      child: child,
    );
  }
}

class _BusyData extends InheritedWidget {
  const _BusyData({
    required this.level,
    required this.faded,
    required super.child,
  });

  final BusyLevel level;

  /// An ancestor already faded this subtree: don't fade it twice.
  final bool faded;

  static _BusyData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BusyData>();

  @override
  bool updateShouldNotify(_BusyData old) =>
      level != old.level || faded != old.faded;
}

/// The one "locked" look of the kit: faded to [AppOpacity.disabled] and inert,
/// size and position unchanged. [locked] null = the [BusyScope]'s; true / false
/// = this piece's own say (false: it doesn't fade, the pieces inside still read
/// the scope). Never fades twice: a lock inside a faded lock only stops input.
/// [inert] stops input without fading (the pressed control while it spins).
class BusyLock extends StatelessWidget {
  const BusyLock({
    required this.child,
    this.locked,
    this.inert = false,
    super.key,
  });

  final bool? locked;
  final bool inert;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = _BusyData.maybeOf(context);
    final level = data?.level ?? BusyLevel.idle;
    final alreadyFaded = data?.faded ?? false;
    final on = locked ?? level == BusyLevel.locked;
    final fade = on && !alreadyFaded;
    // The same tree whatever the state, so an input inside keeps its focus
    // and text when the lock comes and goes.
    return IgnorePointer(
      ignoring: on || inert,
      child: AnimatedOpacity(
        opacity: fade ? AppOpacity.disabled : 1,
        duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
            ? Duration.zero
            : AppDurations.fast,
        child: _BusyData(
          level: on ? BusyLevel.locked : level,
          faded: alreadyFaded || fade,
          child: child,
        ),
      ),
    );
  }
}

/// A control's content swapped for the kit's [AppSpinner] while [loading]: the
/// content stays laid out (invisible), so the control keeps its exact size
/// and position; the spinner is centred on it.
class BusySwap extends StatelessWidget {
  const BusySwap({
    required this.loading,
    required this.child,
    this.color,
    this.spinnerSize,
    super.key,
  });

  final bool loading;
  final Widget child;

  /// Null = the theme's primary.
  final Color? color;

  /// The spinner's side; null = [AppSpinnerSize.small] (16).
  final double? spinnerSize;

  @override
  Widget build(BuildContext context) {
    final side = spinnerSize ?? AppSpinnerSize.small.dimension;
    // passthrough: the content gets exactly the constraints it would get
    // without this wrapper, so it lays out the same, loading or not.
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Visibility(
          visible: !loading,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: child,
        ),
        if (loading)
          Positioned.fill(
            child: Center(
              child: SizedBox.square(
                dimension: side,
                child: AppSpinner(size: AppSpinnerSize.small, color: color),
              ),
            ),
          ),
      ],
    );
  }
}
