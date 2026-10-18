import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with the latest items while a sheet is open: the list a
/// picker was opened with is only the first value.
class LiveItems<T> extends StatelessWidget {
  const LiveItems({
    required this.initial,
    required this.builder,
    this.live,
    super.key,
  });

  final T initial;
  final ValueListenable<T>? live;
  final Widget Function(BuildContext context, T items) builder;

  @override
  Widget build(BuildContext context) {
    final source = live;
    if (source == null) return builder(context, initial);
    return ValueListenableBuilder<T>(
      valueListenable: source,
      builder: (context, items, _) => builder(context, items),
    );
  }
}

/// What a sheet's pull-to-refresh runs; read by `PickerSheet` when it has no
/// `onRefresh` of its own.
class SheetRefreshScope extends InheritedWidget {
  const SheetRefreshScope({
    required this.onRefresh,
    required super.child,
    super.key,
  });

  final Future<void> Function()? onRefresh;

  static Future<void> Function()? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SheetRefreshScope>()
      ?.onRefresh;

  @override
  bool updateShouldNotify(SheetRefreshScope old) => onRefresh != old.onRefresh;
}
