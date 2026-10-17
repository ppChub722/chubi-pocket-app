import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show ValueChanged;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';

enum InboxStatus { initial, loading, loaded, error }

/// The inbox's filter tiles (ทั้งหมด / ต้องตอบ / ยังไม่อ่าน / ซ่อนไว้). Each
/// maps to the list call's own query parameters.
enum InboxFilter {
  all,
  needsAnswer,
  unread,
  hidden;

  /// Query for `GET /notifications` (one call per filter).
  ({String? read, String? dismissed, String? awaitsAnswer}) get query =>
      switch (this) {
        InboxFilter.all => (read: null, dismissed: null, awaitsAnswer: null),
        InboxFilter.needsAnswer => (
          read: null,
          dismissed: null,
          awaitsAnswer: 'true',
        ),
        InboxFilter.unread => (
          read: 'false',
          dismissed: null,
          awaitsAnswer: null,
        ),
        InboxFilter.hidden => (
          read: null,
          dismissed: 'true',
          awaitsAnswer: null,
        ),
      };
}

class InboxState extends Equatable {
  const InboxState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.summary = const InboxSummary(),
    this.status = InboxStatus.initial,
    this.error,
    this.page = 0,
    this.totalPages = 0,
    this.filter = InboxFilter.all,
    this.allTotal,
  });

  final List<AppNotification> notifications;
  final int unreadCount;

  /// The card's numbers over all rows, as the last load returned them.
  final InboxSummary summary;
  final InboxStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final int page;
  final int totalPages;
  final InboxFilter filter;

  /// Rows of the unfiltered list (null until the first unfiltered load).
  final int? allTotal;

  bool get hasMore => page > 0 && page < totalPages;

  InboxState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    InboxSummary? summary,
    InboxStatus? status,
    ApiException? error,
    int? page,
    int? totalPages,
    InboxFilter? filter,
    int? allTotal,
    bool clearError = false,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      filter: filter ?? this.filter,
      allTotal: allTotal ?? this.allTotal,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    unreadCount,
    summary,
    status,
    error,
    page,
    totalPages,
    filter,
    allTotal,
  ];
}

/// Inbox cubit. Owns the page-1-loaded list. Row writes patch the row from
/// the write's reply; the ones that move the card's numbers (hide, restore,
/// read-all) re-fetch the page's one `GET /notifications`.
class NotificationsInboxCubit extends Cubit<InboxState> {
  NotificationsInboxCubit({
    required NotificationsRepository repository,
    this.onUnreadChanged,
  }) : _repo = repository,
       super(const InboxState());

  final NotificationsRepository _repo;

  /// Called with the fresh unread count whenever a load or a write returns
  /// one — lets the owner patch the app-wide bell badge without a poll.
  final ValueChanged<int>? onUnreadChanged;

  /// Every await here can outlive the page that owns this cubit (the home
  /// tab, the inbox) — a reply landing after close is dropped, not thrown
  /// ("Cannot emit new states after calling close", QA S1 2026-10-11).
  @override
  void emit(InboxState state) {
    if (!isClosed) super.emit(state);
  }

  /// Takes page-1 rows a page already received (the dashboard's attention
  /// block) instead of loading them: no call.
  void seed(List<AppNotification> items, {required int unreadCount}) {
    emit(
      state.copyWith(
        notifications: items,
        unreadCount: unreadCount,
        status: InboxStatus.loaded,
        clearError: true,
      ),
    );
  }

  /// The page's one `GET /notifications`. Rows already on screen stay while
  /// it runs and when it fails (the error rides in [InboxState.error]).
  Future<void> load({InboxFilter? filter}) async {
    final f = filter ?? state.filter;
    emit(
      state.copyWith(status: InboxStatus.loading, filter: f, clearError: true),
    );
    try {
      final q = f.query;
      final p = await _repo.list(
        read: q.read,
        dismissed: q.dismissed,
        awaitsAnswer: q.awaitsAnswer,
      );
      onUnreadChanged?.call(p.unreadCount);
      emit(
        state.copyWith(
          notifications: p.notifications,
          unreadCount: p.unreadCount,
          summary: p.summary,
          allTotal: f == InboxFilter.all ? p.total : null,
          status: InboxStatus.loaded,
          page: p.page,
          totalPages: p.totalPages,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: InboxStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// Re-fetch keeping the current filter.
  Future<void> reload() => load();

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == InboxStatus.loading) return;
    try {
      final q = state.filter.query;
      final p = await _repo.list(
        read: q.read,
        dismissed: q.dismissed,
        awaitsAnswer: q.awaitsAnswer,
        page: state.page + 1,
      );
      emit(
        state.copyWith(
          notifications: [...state.notifications, ...p.notifications],
          page: p.page,
          totalPages: p.totalPages,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: InboxStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> markRead(String id) => _write(() => _repo.markRead(id));

  Future<void> markActioned(String id) => _write(() => _repo.markActioned(id));

  /// Hides a row (swipe). The row leaves the list at once; the call is
  /// followed by the page's re-fetch so the card's numbers follow. A failed
  /// call brings the row back through the re-fetch.
  Future<bool> hide(String id) async {
    emit(
      state.copyWith(
        notifications: state.notifications.where((n) => n.id != id).toList(),
      ),
    );
    try {
      final r = await _repo.markDismissed(id);
      onUnreadChanged?.call(r.badges.unreadNotifications);
      await reload();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
      await reload();
      return false;
    }
  }

  /// Un-hides a row (the snackbar's undo, the ซ่อนไว้ tile's กู้คืน).
  Future<bool> restore(String id) async {
    try {
      final r = await _repo.restore(id);
      onUnreadChanged?.call(r.badges.unreadNotifications);
      await reload();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
      return false;
    }
  }

  /// The one-tap rows' "skip" just hides the row.
  Future<void> markDismissed(String id) => hide(id);

  Future<void> markReadAll() async {
    try {
      final badges = await _repo.markReadAll();
      onUnreadChanged?.call(badges.unreadNotifications);
      await reload();
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  Future<void> delete(String id) async {
    try {
      final badges = await _repo.delete(id);
      emit(
        state.copyWith(
          notifications: state.notifications.where((n) => n.id != id).toList(),
          unreadCount: badges.unreadNotifications,
        ),
      );
      onUnreadChanged?.call(badges.unreadNotifications);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  /// One write: the reply carries the row in its new state + fresh badges.
  Future<void> _write(Future<NotificationActionResult> Function() call) async {
    try {
      final r = await call();
      emit(
        state.copyWith(
          notifications: [
            for (final n in state.notifications)
              if (n.id == r.notification.id) r.notification else n,
          ],
          unreadCount: r.badges.unreadNotifications,
          summary: InboxSummary(
            needsAnswer: state.summary.needsAnswer,
            unread: r.badges.unreadNotifications,
            dismissed: state.summary.dismissed,
          ),
        ),
      );
      onUnreadChanged?.call(r.badges.unreadNotifications);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }
}
