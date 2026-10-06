import 'package:flutter/widgets.dart';

/// Counts quick taps for a hidden gesture ("tap 5× to unlock"). Use it
/// directly when the target already has its own `onTap` (e.g. a ListTile);
/// otherwise wrap the target in [SecretTapDetector].
class TapUnlockCounter {
  TapUnlockCounter({this.taps = 5, this.window = const Duration(seconds: 2)});

  /// Taps needed to unlock.
  final int taps;

  /// All taps must land within this window of the first one.
  final Duration window;

  int _count = 0;
  DateTime? _first;

  /// Registers one tap; returns true on the tap that completes the
  /// sequence (then resets).
  bool register() {
    final now = DateTime.now();
    if (_first == null || now.difference(_first!) > window) {
      _first = now;
      _count = 0;
    }
    _count++;
    if (_count < taps) return false;
    _count = 0;
    _first = null;
    return true;
  }
}

/// Wraps [child] with an invisible tap counter; fires [onUnlock] after
/// [taps] quick taps. The app's dev-hub entrance (login title, settings
/// version row).
class SecretTapDetector extends StatefulWidget {
  const SecretTapDetector({
    required this.onUnlock,
    required this.child,
    this.taps = 5,
    super.key,
  });

  final VoidCallback onUnlock;
  final Widget child;
  final int taps;

  @override
  State<SecretTapDetector> createState() => _SecretTapDetectorState();
}

class _SecretTapDetectorState extends State<SecretTapDetector> {
  late final _counter = TapUnlockCounter(taps: widget.taps);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_counter.register()) widget.onUnlock();
      },
      child: widget.child,
    );
  }
}
