import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks whether the device has network connectivity. Emits a single boolean:
/// `true` = online, `false` = offline.
///
/// `connectivity_plus` reports the link layer (wifi/ethernet/mobile/none), not
/// reachability — but for the OfflineBanner's purpose ("nothing will work
/// right now") this is good enough. Reachability checks are Phase 2+ polish.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(true) {
    _bootstrap();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _bootstrap() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      emit(_isOnline(initial));
    } catch (_) {
      // Some web browsers throw before user interaction; assume online.
      emit(true);
    }
    _sub = _connectivity.onConnectivityChanged.listen(
      (result) => emit(_isOnline(result)),
    );
  }

  bool _isOnline(List<ConnectivityResult> result) {
    return result.isNotEmpty && !result.every((r) => r == ConnectivityResult.none);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
