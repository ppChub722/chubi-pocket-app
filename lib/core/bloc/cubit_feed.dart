import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A [ValueListenable] that follows a cubit: what a sheet shows while it is
/// open stays in step with the cache behind it. Dispose it when the sheet closes.
class CubitFeed<S, T> {
  CubitFeed(StateStreamable<S> cubit, T Function(S state) select)
    : notifier = ValueNotifier<T>(select(cubit.state)) {
    _sub = cubit.stream.listen((s) => notifier.value = select(s));
  }

  final ValueNotifier<T> notifier;
  late final StreamSubscription<S> _sub;

  ValueListenable<T> get listenable => notifier;
  T get value => notifier.value;

  Future<void> dispose() async {
    await _sub.cancel();
    notifier.dispose();
  }
}
