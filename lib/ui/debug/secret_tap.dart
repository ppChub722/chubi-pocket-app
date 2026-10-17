import 'package:flutter/widgets.dart';

class TapUnlockCounter {
  TapUnlockCounter({this.taps = 5, this.window = const Duration(seconds: 2)});

  final int taps;

  /// All taps must land within this window of the first one.
  final Duration window;

  int _count = 0;
  DateTime? _first;

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
