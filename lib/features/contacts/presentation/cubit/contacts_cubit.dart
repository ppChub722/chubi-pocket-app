import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/data/sync_backed.dart';
import '../../../../core/data/sync_coordinator.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../../../../ui/ui.dart';

enum ContactsStatus { initial, loading, loaded, error }

class ContactsState extends Equatable {
  const ContactsState({
    List<Contact> contacts = const [],
    this.status = ContactsStatus.initial,
    this.error,
    this.statusFilter = 'active',
  }) : allContacts = contacts;

  /// Every contact, whatever its status, in the server's order.
  final List<Contact> allContacts;

  /// The contacts the status filter lets through.
  List<Contact> get contacts => [
    for (final c in allContacts)
      if (switch (statusFilter) {
        'archived' => c.isArchived,
        'all' => true,
        _ => !c.isArchived,
      })
        c,
  ];

  final ContactsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final String statusFilter; // active | archived | all

  ContactsState copyWith({
    List<Contact>? contacts,
    ContactsStatus? status,
    ApiException? error,
    String? statusFilter,
    bool clearError = false,
  }) {
    return ContactsState(
      contacts: contacts ?? allContacts,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [allContacts, status, error, statusFilter];
}

class ContactsCubit extends Cubit<ContactsState>
    with Clearable, SyncBacked<ContactsState> {
  ContactsCubit({
    required ContactsRepository repository,
    required SyncCoordinator coordinator,
  }) : _repo = repository,
       syncCoordinator = coordinator,
       super(const ContactsState()) {
    bindSync();
  }

  final ContactsRepository _repo;

  @override
  final SyncCoordinator syncCoordinator;

  @override
  SyncSet get syncSet => SyncSet.contacts;

  @override
  bool get syncLoading => state.status == ContactsStatus.loading;

  @override
  void markSyncLoading() =>
      emit(state.copyWith(status: ContactsStatus.loading, clearError: true));

  @override
  void syncFailed(ApiException error) =>
      emit(state.copyWith(status: ContactsStatus.error, error: error));

  @override
  void applySync(Map<String, dynamic> body) {
    emit(
      state.copyWith(
        contacts: [
          for (final c in (body['data'] as List? ?? const []))
            Contact.fromJson(c as Map<String, dynamic>),
        ],
        status: ContactsStatus.loaded,
        clearError: true,
      ),
    );
  }

  @override
  void clear() => emit(const ContactsState());

  /// The filter works on the contacts the device holds; nothing is fetched.
  void setStatusFilter(String statusFilter) =>
      emit(state.copyWith(statusFilter: statusFilter));

  Future<void> load() => loadSynced();

  Future<void> loadIfNeeded({bool keepFilter = false}) async {
    if (!keepFilter && state.statusFilter == 'archived') {
      setStatusFilter('all');
    }
    if (state.status == ContactsStatus.initial ||
        state.status == ContactsStatus.error) {
      return load();
    }
  }

  Future<Contact> create({
    required String displayName,
    String? nickname,
    bool? showNickname,
    String? email,
    String? phone,
    String? description,
    String? note,
    IconCode? iconCode,
  }) async {
    final res = await _repo.create(
      displayName: displayName,
      nickname: nickname,
      showNickname: showNickname,
      email: email,
      phone: phone,
      description: description,
      note: note,
      iconCode: iconCode,
    );
    emit(state.copyWith(contacts: [res.contact, ...state.allContacts]));
    return res.contact;
  }

  Future<Contact> update(
    String id, {
    String? displayName,
    String? nickname,
    bool? showNickname,
    String? email,
    String? phone,
    String? description,
    String? note,
    IconCode? iconCode,
  }) async {
    final updated = await _repo.update(
      id,
      displayName: displayName,
      nickname: nickname,
      showNickname: showNickname,
      email: email,
      phone: phone,
      description: description,
      note: note,
      iconCode: iconCode,
    );
    _replace(updated);
    return updated;
  }

  Future<Contact> archive(String id) async {
    final updated = await _repo.archive(id);
    _replace(updated);
    return updated;
  }

  Future<Contact> restore(String id) async {
    final updated = await _repo.restore(id);
    _replace(updated);
    return updated;
  }

  Future<Contact> unlink(String id) async {
    final updated = await _repo.unlink(id);
    _replace(updated);
    return updated;
  }

  Future<Contact> requestLink(String id) async {
    final updated = await _repo.requestLink(id);
    _replace(updated);
    return updated;
  }

  Future<List<UnlinkedName>> unlinkedNames() => _repo.unlinkedNames();

  Future<AbsorbResult> absorb(String contactId, List<String> names) async {
    final res = await _repo.absorb(contactId, names);
    _replace(res.contact);
    return res;
  }

  Future<LinkRequestResult> createLinkedFromRequest(
    String notificationId, {
    String? phone,
    String? description,
    String? note,
  }) async {
    final res = await _repo.createLinkedContactFromLinkRequest(
      notificationId,
      phone: phone,
      description: description,
      note: note,
    );
    if (res.contact != null) _replace(res.contact!);
    return res;
  }

  Future<LinkRequestResult> linkExistingFromRequest(
    String notificationId,
    String contactId, {
    String? phone,
    String? description,
    String? note,
  }) async {
    final res = await _repo.linkExistingContactFromLinkRequest(
      notificationId,
      contactId,
      phone: phone,
      description: description,
      note: note,
    );
    if (res.contact != null) _replace(res.contact!);
    return res;
  }

  Future<DeleteContactResult> delete(String id) async {
    final res = await _repo.delete(id);
    emit(
      state.copyWith(
        contacts: state.allContacts.where((c) => c.id != id).toList(),
      ),
    );
    return res;
  }

  void _replace(Contact c) {
    final known = state.allContacts.any((e) => e.id == c.id);
    emit(
      state.copyWith(
        contacts: [
          if (!known) c,
          for (final existing in state.allContacts)
            if (existing.id == c.id) c else existing,
        ],
      ),
    );
  }
}
