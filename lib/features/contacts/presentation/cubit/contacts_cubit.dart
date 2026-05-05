import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';

enum ContactsStatus { initial, loading, loaded, error }

class ContactsState extends Equatable {
  const ContactsState({
    this.contacts = const [],
    this.status = ContactsStatus.initial,
    this.errorMessage,
    this.statusFilter = 'active',
    this.linkedFilter,
    this.search,
  });

  final List<Contact> contacts;
  final ContactsStatus status;
  final String? errorMessage;
  final String statusFilter; // active | archived | all
  final bool? linkedFilter;
  final String? search;

  ContactsState copyWith({
    List<Contact>? contacts,
    ContactsStatus? status,
    String? errorMessage,
    String? statusFilter,
    bool? linkedFilter,
    String? search,
    bool clearError = false,
    bool clearLinkedFilter = false,
    bool clearSearch = false,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: statusFilter ?? this.statusFilter,
      linkedFilter: clearLinkedFilter ? null : (linkedFilter ?? this.linkedFilter),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  List<Object?> get props =>
      [contacts, status, errorMessage, statusFilter, linkedFilter, search];
}

class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit({required ContactsRepository repository})
      : _repo = repository,
        super(const ContactsState());

  final ContactsRepository _repo;

  Future<void> load({
    String? statusFilter,
    bool? linkedFilter,
    bool clearLinkedFilter = false,
    String? search,
    bool clearSearch = false,
  }) async {
    emit(state.copyWith(
      status: ContactsStatus.loading,
      statusFilter: statusFilter,
      linkedFilter: linkedFilter,
      clearLinkedFilter: clearLinkedFilter,
      search: search,
      clearSearch: clearSearch,
      clearError: true,
    ));
    try {
      final list = await _repo.list(
        status: state.statusFilter,
        linked: state.linkedFilter,
        search: state.search,
      );
      emit(state.copyWith(contacts: list, status: ContactsStatus.loaded));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ContactsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  Future<Contact> create({
    required String displayName,
    String? nickname,
    String? email,
    String? phone,
    String? notes,
    String? icon,
    List<String>? absorbNames,
  }) async {
    final res = await _repo.create(
      displayName: displayName,
      nickname: nickname,
      email: email,
      phone: phone,
      notes: notes,
      icon: icon,
      absorbNames: absorbNames,
    );
    emit(state.copyWith(contacts: [res.contact, ...state.contacts]));
    return res.contact;
  }

  Future<Contact> update(String id, {
    String? displayName,
    String? nickname,
    String? email,
    String? phone,
    String? notes,
    String? icon,
  }) async {
    final updated = await _repo.update(
      id,
      displayName: displayName,
      nickname: nickname,
      email: email,
      phone: phone,
      notes: notes,
      icon: icon,
    );
    _replace(updated);
    return updated;
  }

  Future<void> archive(String id) async {
    final updated = await _repo.archive(id);
    _replace(updated);
  }

  Future<void> restore(String id) async {
    final updated = await _repo.restore(id);
    _replace(updated);
  }

  Future<void> unlink(String id) async {
    final updated = await _repo.unlink(id);
    _replace(updated);
  }

  Future<void> requestLink(String id) async {
    await _repo.requestLink(id);
  }

  /// `GET /contacts/unlinked-names` — every (person_name, count) pair from
  /// the caller's personal_debts where contact_id is still NULL. Backs the
  /// "Wire split names" surface on contact detail.
  Future<List<UnlinkedName>> unlinkedNames() => _repo.unlinkedNames();

  /// `POST /contacts/:id/absorb` — wires every personal_debts row whose
  /// counterparty_person_name (case-insensitive exact) is in [names] to the
  /// given contact. Returns the count rewritten. Caller refreshes the
  /// contact + unlinked-names list afterwards.
  Future<int> absorb(String contactId, List<String> names) =>
      _repo.absorb(contactId, names);

  Future<void> delete(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      contacts: state.contacts.where((c) => c.id != id).toList(),
    ));
  }

  void _replace(Contact c) {
    emit(state.copyWith(
      contacts: [
        for (final existing in state.contacts)
          if (existing.id == c.id) c else existing,
      ],
    ));
  }
}
