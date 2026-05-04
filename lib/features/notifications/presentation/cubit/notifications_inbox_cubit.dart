import 'package:equatable/equatable.dart';
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
    this.errorMessage,
    this.page = 0,
    this.totalPages = 0,
    this.filterUnreadOnly = false,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final InboxStatus status;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final bool filterUnreadOnly;

  bool get hasMore => page > 0 && page < totalPages;

  InboxState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    InboxStatus? status,
    String? errorMessage,
    int? page,
    int? totalPages,
    bool? filterUnreadOnly,
    bool clearError = false,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
        errorMessage,
        page,
        totalPages,
        filterUnreadOnly,
      ];
}

/// Inbox cubit. Owns the page-1-loaded list. Surgical updates on
/// mark-read/actioned/dismissed/delete.
class NotificationsInboxCubit extends Cubit<InboxState> {
  NotificationsInboxCubit({required NotificationsRepository repository})
      : _repo = repository,
        super(const InboxState());

  final NotificationsRepository _repo;

  Future<void> load({bool unreadOnly = false}) async {
    emit(state.copyWith(
      status: InboxStatus.loading,
      filterUnreadOnly: unreadOnly,
      clearError: true,
    ));
    try {
      final p = await _repo.list(read: unreadOnly ? 'false' : null);
      emit(state.copyWith(
        notifications: p.notifications,
        unreadCount: p.unreadCount,
        status: InboxStatus.loaded,
        page: p.page,
        totalPages: p.totalPages,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: InboxStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == InboxStatus.loading) return;
    try {
      final p = await _repo.list(
        read: state.filterUnreadOnly ? 'false' : null,
        page: state.page + 1,
      );
      emit(state.copyWith(
        notifications: [...state.notifications, ...p.notifications],
        page: p.page,
        totalPages: p.totalPages,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: InboxStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> markRead(String id) async {
    try {
      final updated = await _repo.markRead(id);
      _replace(updated);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> markActioned(String id) async {
    try {
      final updated = await _repo.markActioned(id);
      _replace(updated);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> markDismissed(String id) async {
    try {
      final updated = await _repo.markDismissed(id);
      _replace(updated);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> markReadAll() async {
    try {
      await _repo.markReadAll();
      // Reload — easier than patching every row.
      await load(unreadOnly: state.filterUnreadOnly);
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
      final remaining =
          state.notifications.where((n) => n.id != id).toList();
      final wasUnread = state.notifications.any((n) => n.id == id && n.isUnread);
      emit(state.copyWith(
        notifications: remaining,
        unreadCount:
            wasUnread ? (state.unreadCount - 1).clamp(0, 1 << 31) : state.unreadCount,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _replace(AppNotification updated) {
    final next = [
      for (final n in state.notifications)
        if (n.id == updated.id) updated else n,
    ];
    final unread = next.where((n) => n.isUnread).length;
    emit(state.copyWith(notifications: next, unreadCount: unread));
  }
}
