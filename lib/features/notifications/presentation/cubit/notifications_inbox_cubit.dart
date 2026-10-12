import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show ValueChanged;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';

enum InboxStatus { initial, loading, loaded, error }

class InboxState extends Equatable {
  const InboxState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.status = InboxStatus.initial,
    this.error,
    this.page = 0,
    this.totalPages = 0,
    this.filterUnreadOnly = false,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final InboxStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final int page;
  final int totalPages;
  final bool filterUnreadOnly;

  bool get hasMore => page > 0 && page < totalPages;

  InboxState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    InboxStatus? status,
    ApiException? error,
    int? page,
    int? totalPages,
    bool? filterUnreadOnly,
    bool clearError = false,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      filterUnreadOnly: filterUnreadOnly ?? this.filterUnreadOnly,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    unreadCount,
    status,
    error,
    page,
    totalPages,
    filterUnreadOnly,
  ];
}

/// Inbox cubit. Owns the page-1-loaded list. Surgical updates on
/// mark-read/actioned/dismissed/delete/read-all, patched from the write's
/// reply (no reload).
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

  Future<void> load({bool unreadOnly = false}) async {
    emit(
      state.copyWith(
        status: InboxStatus.loading,
        filterUnreadOnly: unreadOnly,
        clearError: true,
      ),
    );
    try {
      final p = await _repo.list(read: unreadOnly ? 'false' : null);
      onUnreadChanged?.call(p.unreadCount);
      emit(
        state.copyWith(
          notifications: p.notifications,
          unreadCount: p.unreadCount,
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

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == InboxStatus.loading) return;
    try {
      final p = await _repo.list(
        read: state.filterUnreadOnly ? 'false' : null,
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

  Future<void> markDismissed(String id) =>
      _write(() => _repo.markDismissed(id));

  Future<void> markReadAll() async {
    try {
      final badges = await _repo.markReadAll();
      final unreadOnly = state.filterUnreadOnly;
      final now = DateTime.now().toUtc();
      // Unread rows are read now: gone from the Unread tab, flipped on All.
      final next = [
        for (final n in state.notifications)
          if (!n.isUnread) n else if (!unreadOnly) n.asRead(now),
      ];
      emit(
        state.copyWith(
          notifications: next,
          unreadCount: badges.unreadNotifications,
          totalPages: unreadOnly ? state.page : state.totalPages,
        ),
      );
      onUnreadChanged?.call(badges.unreadNotifications);
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
        ),
      );
      onUnreadChanged?.call(r.badges.unreadNotifications);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }
}
