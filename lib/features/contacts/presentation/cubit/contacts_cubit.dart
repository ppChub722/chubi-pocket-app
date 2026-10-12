import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../../../../ui/ui.dart';

enum ContactsStatus { initial, loading, loaded, error }

class ContactsState extends Equatable {
  const ContactsState({
    this.contacts = const [],
    this.status = ContactsStatus.initial,
    this.error,
    this.statusFilter = 'active',
  });

  final List<Contact> contacts;
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
      contacts: contacts ?? this.contacts,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [contacts, status, error, statusFilter];
}

class ContactsCubit extends Cubit<ContactsState> with Clearable {
  ContactsCubit({required ContactsRepository repository})
    : _repo = repository,
      super(const ContactsState());

  final ContactsRepository _repo;

  @override
  void clear() => emit(const ContactsState());

  Future<void> load({String? statusFilter}) async {
    emit(
      state.copyWith(
        status: ContactsStatus.loading,
        statusFilter: statusFilter,
        clearError: true,
      ),
    );
    try {
      final list = await _repo.list(status: state.statusFilter);
      emit(state.copyWith(contacts: list, status: ContactsStatus.loaded));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: ContactsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  /// Loads once (or again after a failure) — pickers call it. A list left
  /// on archived only (the contacts page's filter) widens to all, so the
  /// active ones are there to pick.
  ///
  /// [keepFilter]: the contacts page itself — leave its status filter alone.
  Future<void> loadIfNeeded({bool keepFilter = false}) async {
    if (!keepFilter && state.statusFilter == 'archived') {
      return load(statusFilter: 'all');
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
    // Only into a list whose status filter takes it (a new one is active).
    if (_fits(res.contact)) {
      emit(state.copyWith(contacts: [res.contact, ...state.contacts]));
    }
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

  // Every write returns the contact from the response (the page patches its
  // own copy from it) and patches the list — no re-GET.

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

  /// `GET /contacts/unlinked-names` — create-sheet suggestions only.
  Future<List<UnlinkedName>> unlinkedNames() => _repo.unlinkedNames();

  /// `POST /contacts/:id/absorb` — wires every personal_debts row whose
  /// typed name (case-insensitive exact) is in [names] to the contact.
  /// Returns the contact + the count wired.
  Future<AbsorbResult> absorb(String contactId, List<String> names) async {
    final res = await _repo.absorb(contactId, names);
    _replace(res.contact);
    return res;
  }

  /// Post-accept "create a contact for the sender" — patches the list.
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

  /// Post-accept "link my existing contact" — patches the list.
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
        contacts: state.contacts.where((c) => c.id != id).toList(),
      ),
    );
    return res;
  }

  /// Does [c] belong in the list under its status filter?
  bool _fits(Contact c) => switch (state.statusFilter) {
    'archived' => c.isArchived,
    'all' => true,
    _ => !c.isArchived,
  };

  /// [c] in place — or out, when it no longer fits the status filter
  /// (archived under ใช้งาน, restored under เก็บถาวร) — or in at the top
  /// when it now fits a list it wasn't in (restored under ใช้งาน).
  void _replace(Contact c) {
    final known = state.contacts.any((e) => e.id == c.id);
    emit(
      state.copyWith(
        contacts: [
          if (!known && _fits(c)) c,
          for (final existing in state.contacts)
            if (existing.id != c.id) existing else if (_fits(c)) c,
        ],
      ),
    );
  }
}
