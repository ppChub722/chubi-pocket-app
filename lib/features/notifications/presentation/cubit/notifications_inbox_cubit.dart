import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show ValueChanged;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';

enum InboxStatus { initial, loading, loaded, error }

enum InboxFilter {
  all,
  needsAnswer,
  unread,
  hidden;

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
  });

  final List<AppNotification> notifications;
  final int unreadCount;

  final InboxSummary summary;
  final InboxStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final int page;
  final int totalPages;
  final InboxFilter filter;

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
  ];
}

class NotificationsInboxCubit extends Cubit<InboxState> {
  NotificationsInboxCubit({
    required NotificationsRepository repository,
    this.onUnreadChanged,
  }) : _repo = repository,
       super(const InboxState());

  final NotificationsRepository _repo;

  final ValueChanged<int>? onUnreadChanged;

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

  Future<bool> hide(String id) async {
    final at = state.notifications.indexWhere((n) => n.id == id);
    final row = at < 0 ? null : state.notifications[at];
    emit(
      state.copyWith(
        notifications: state.notifications.where((n) => n.id != id).toList(),
      ),
    );
    try {
      final r = await _repo.markDismissed(id);
      _apply(r.badges, r.summary);
      return true;
    } on ApiException catch (e) {
      final rows = [...state.notifications];
      if (row != null && !rows.any((n) => n.id == id)) {
        rows.insert(at.clamp(0, rows.length), row);
      }
      emit(state.copyWith(notifications: rows, error: e));
      return false;
    }
  }

  Future<bool> restore(String id) async {
    try {
      final r = await _repo.restore(id);
      final rows = state.notifications.where((n) => n.id != id).toList();
      if (state.filter != InboxFilter.hidden) {
        final i = rows.indexWhere(
          (n) => n.createdAt.isBefore(r.notification.createdAt),
        );
        rows.insert(i < 0 ? rows.length : i, r.notification);
      }
      emit(state.copyWith(notifications: rows));
      _apply(r.badges, r.summary);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
      return false;
    }
  }

  Future<void> markDismissed(String id) => hide(id);

  Future<void> markReadAll() async {
    try {
      final r = await _repo.markReadAll();
      final now = DateTime.now().toUtc();
      emit(
        state.copyWith(
          notifications: [
            for (final n in state.notifications) n.isUnread ? n.asRead(now) : n,
          ],
        ),
      );
      _apply(r.badges, r.summary);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  Future<void> delete(String id) async {
    try {
      final r = await _repo.delete(id);
      emit(
        state.copyWith(
          notifications: state.notifications.where((n) => n.id != id).toList(),
        ),
      );
      _apply(r.badges, r.summary);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  void applyAnswer(NotificationActionResult r) {
    final keep =
        !r.notification.isDismissed || state.filter == InboxFilter.hidden;
    emit(
      state.copyWith(
        notifications: [
          for (final n in state.notifications)
            if (n.id != r.notification.id) n else if (keep) r.notification,
        ],
      ),
    );
    _apply(r.badges, r.summary);
  }

  void applyInboxSummary(String id, InboxSummary summary) {
    final now = DateTime.now().toUtc();
    emit(
      state.copyWith(
        notifications: [
          for (final n in state.notifications)
            if (n.id == id) n.asActioned(now) else n,
        ],
        unreadCount: summary.unread,
        summary: summary,
      ),
    );
    onUnreadChanged?.call(summary.unread);
  }

  Future<void> _write(Future<NotificationActionResult> Function() call) async {
    try {
      final r = await call();
      emit(
        state.copyWith(
          notifications: [
            for (final n in state.notifications)
              if (n.id == r.notification.id) r.notification else n,
          ],
        ),
      );
      _apply(r.badges, r.summary);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  void _apply(Badges badges, InboxSummary summary) {
    emit(
      state.copyWith(unreadCount: badges.unreadNotifications, summary: summary),
    );
    onUnreadChanged?.call(badges.unreadNotifications);
  }
}
