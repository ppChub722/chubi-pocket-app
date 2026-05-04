import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/personal_debt.dart';

enum PersonalDebtsStatus { initial, loading, loaded, error }

/// Counterparty filter set by the People-tab tap. `contactId` matches the
/// row's `counterparty_contact_id`; `personName` is the case-insensitive
/// fallback for free-text counterparties (no linked contact).
class CounterpartyFilter extends Equatable {
  const CounterpartyFilter({this.contactId, required this.displayName});

  final String? contactId;
  final String displayName;

  bool matches(PersonalDebt d) {
    if (contactId != null) {
      return d.counterpartyContactId == contactId;
    }
    // No contact_id on the filter → match free-text rows by name.
    return d.counterpartyContactId == null &&
        d.counterpartyPersonName.toLowerCase() == displayName.toLowerCase();
  }

  @override
  List<Object?> get props => [contactId, displayName];
}

class PersonalDebtsState extends Equatable {
  const PersonalDebtsState({
    this.debts = const [],
    this.people,
    this.directionFilter,
    this.statusFilter = 'open',
    this.counterpartyFilter,
    this.status = PersonalDebtsStatus.initial,
    this.errorMessage,
  });

  final List<PersonalDebt> debts;
  final PeopleResponse? people;
  final DebtDirection? directionFilter;
  final String statusFilter;
  final CounterpartyFilter? counterpartyFilter;
  final PersonalDebtsStatus status;
  final String? errorMessage;

  /// `debts` after applying the counterparty filter (if any). Items view
  /// reads this so the FE doesn't need to hit the BE for the narrowed
  /// view — full list is already in state.
  List<PersonalDebt> get filteredDebts {
    final f = counterpartyFilter;
    if (f == null) return debts;
    return debts.where(f.matches).toList();
  }

  PersonalDebtsState copyWith({
    List<PersonalDebt>? debts,
    PeopleResponse? people,
    DebtDirection? directionFilter,
    bool clearDirectionFilter = false,
    String? statusFilter,
    CounterpartyFilter? counterpartyFilter,
    bool clearCounterpartyFilter = false,
    PersonalDebtsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PersonalDebtsState(
      debts: debts ?? this.debts,
      people: people ?? this.people,
      directionFilter: clearDirectionFilter
          ? null
          : (directionFilter ?? this.directionFilter),
      statusFilter: statusFilter ?? this.statusFilter,
      counterpartyFilter: clearCounterpartyFilter
          ? null
          : (counterpartyFilter ?? this.counterpartyFilter),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        debts,
        people,
        directionFilter,
        statusFilter,
        counterpartyFilter,
        status,
        errorMessage,
      ];
}

class PersonalDebtsCubit extends Cubit<PersonalDebtsState> {
  PersonalDebtsCubit({required PersonalDebtsRepository repository})
      : _repo = repository,
        super(const PersonalDebtsState());

  final PersonalDebtsRepository _repo;

  Future<void> loadList({
    DebtDirection? directionFilter,
    bool clearDirection = false,
    String? statusFilter,
  }) async {
    emit(state.copyWith(
      status: PersonalDebtsStatus.loading,
      directionFilter: directionFilter,
      clearDirectionFilter: clearDirection,
      statusFilter: statusFilter,
      clearError: true,
    ));
    try {
      final p = await _repo.list(
        direction: state.directionFilter,
        status: state.statusFilter,
      );
      emit(state.copyWith(
        debts: p.debts,
        status: PersonalDebtsStatus.loaded,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PersonalDebtsStatus.error,
        errorMessage: e.message,
      ));
    }
  }

  /// Set or clear the counterparty filter (used by People-tap drill-down).
  void setCounterpartyFilter(CounterpartyFilter? filter) {
    if (filter == null) {
      emit(state.copyWith(clearCounterpartyFilter: true));
    } else {
      emit(state.copyWith(counterpartyFilter: filter));
    }
  }

  Future<void> loadPeople() async {
    try {
      final p = await _repo.people();
      emit(state.copyWith(people: p));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<PersonalDebt> create({
    required DebtDirection direction,
    required String counterpartyPersonName,
    required double amount,
    required String currency,
    String? counterpartyContactId,
    String? note,
  }) async {
    final created = await _repo.create(
      direction: direction,
      counterpartyPersonName: counterpartyPersonName,
      amount: amount,
      currency: currency,
      counterpartyContactId: counterpartyContactId,
      note: note,
    );
    emit(state.copyWith(debts: [created, ...state.debts]));
    return created;
  }

  Future<void> cancel(String id) async {
    final updated = await _repo.cancel(id);
    _replace(updated);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(
      debts: state.debts.where((d) => d.id != id).toList(),
    ));
  }

  Future<void> settle(String id, {
    String? accountId,
    double? amount,
    String? date,
    bool direct = false,
  }) async {
    final res = await _repo.settle(id,
        accountId: accountId, amount: amount, date: date, direct: direct);
    _replace(res.debt);
  }

  void _replace(PersonalDebt d) {
    emit(state.copyWith(
      debts: [
        for (final existing in state.debts)
          if (existing.id == d.id) d else existing,
      ],
    ));
  }
}
