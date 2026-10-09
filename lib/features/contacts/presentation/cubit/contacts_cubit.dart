import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/contacts_repository.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../domain/contact.dart';

enum ContactsStatus { initial, loading, loaded, error }

class ContactsState extends Equatable {
  const ContactsState({
    this.contacts = const [],
    this.status = ContactsStatus.initial,
    this.error,
    this.statusFilter = 'active',
    this.linkedFilter,
    this.search,
  });

  final List<Contact> contacts;
  final ContactsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;
  final String statusFilter; // active | archived | all
  final bool? linkedFilter;
  final String? search;

  ContactsState copyWith({
    List<Contact>? contacts,
    ContactsStatus? status,
    ApiException? error,
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
      error: clearError ? null : (error ?? this.error),
      statusFilter: statusFilter ?? this.statusFilter,
      linkedFilter: clearLinkedFilter
          ? null
          : (linkedFilter ?? this.linkedFilter),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  List<Object?> get props => [
    contacts,
    status,
    error,
    statusFilter,
    linkedFilter,
    search,
  ];
}

class ContactsCubit extends Cubit<ContactsState> with Clearable {
  ContactsCubit({required ContactsRepository repository})
    : _repo = repository,
      super(const ContactsState());

  final ContactsRepository _repo;

  @override
  void clear() => emit(const ContactsState());

  Future<void> load({
    String? statusFilter,
    bool? linkedFilter,
    bool clearLinkedFilter = false,
    String? search,
    bool clearSearch = false,
  }) async {
    emit(
      state.copyWith(
        status: ContactsStatus.loading,
        statusFilter: statusFilter,
        linkedFilter: linkedFilter,
        clearLinkedFilter: clearLinkedFilter,
        search: search,
        clearSearch: clearSearch,
        clearError: true,
      ),
    );
    try {
      final list = await _repo.list(
        status: state.statusFilter,
        linked: state.linkedFilter,
        search: state.search,
      );
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

  Future<Contact> create({
    required String displayName,
    String? email,
    String? phone,
    String? notes,
    IconCode? iconCode,
    List<String>? absorbNames,
  }) async {
    final res = await _repo.create(
      displayName: displayName,
      email: email,
      phone: phone,
      notes: notes,
      iconCode: iconCode,
      absorbNames: absorbNames,
    );
    emit(state.copyWith(contacts: [res.contact, ...state.contacts]));
    return res.contact;
  }

  Future<Contact> update(
    String id, {
    String? displayName,
    String? email,
    String? phone,
    String? notes,
    IconCode? iconCode,
  }) async {
    final updated = await _repo.update(
      id,
      displayName: displayName,
      email: email,
      phone: phone,
      notes: notes,
      iconCode: iconCode,
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
    emit(
      state.copyWith(
        contacts: state.contacts.where((c) => c.id != id).toList(),
      ),
    );
  }

  void _replace(Contact c) {
    emit(
      state.copyWith(
        contacts: [
          for (final existing in state.contacts)
            if (existing.id == c.id) c else existing,
        ],
      ),
    );
  }
}
