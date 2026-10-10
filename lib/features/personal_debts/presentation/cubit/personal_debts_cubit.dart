import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/clearable_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/personal_debt.dart';

enum PersonalDebtsStatus { initial, loading, loaded, error }

/// All of the user's debts (every status) in memory — the list page and
/// the per-person page both derive from it via [DebtPerson.group], so a
/// settle / edit on one screen shows up on the others without a refetch.
class PersonalDebtsState extends Equatable {
  const PersonalDebtsState({
    this.debts = const [],
    this.status = PersonalDebtsStatus.initial,
    this.error,
  });

  final List<PersonalDebt> debts;
  final PersonalDebtsStatus status;
  final ApiException? error;
  String? get errorMessage => error?.message;

  List<DebtPerson> get people => DebtPerson.group(debts);

  PersonalDebtsState copyWith({
    List<PersonalDebt>? debts,
    PersonalDebtsStatus? status,
    ApiException? error,
    bool clearError = false,
  }) {
    return PersonalDebtsState(
      debts: debts ?? this.debts,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [debts, status, error];
}

class PersonalDebtsCubit extends Cubit<PersonalDebtsState> with Clearable {
  PersonalDebtsCubit({required PersonalDebtsRepository repository})
    : _repo = repository,
      super(const PersonalDebtsState());

  final PersonalDebtsRepository _repo;

  @override
  void clear() => emit(const PersonalDebtsState());

  Future<void> load() async {
    emit(state.copyWith(status: PersonalDebtsStatus.loading, clearError: true));
    try {
      final all = await _repo.listAll();
      emit(state.copyWith(debts: all, status: PersonalDebtsStatus.loaded));
    } catch (e, st) {
      emit(
        state.copyWith(
          status: PersonalDebtsStatus.error,
          error: ApiException.from(e, st),
        ),
      );
    }
  }

  Future<void> loadIfNeeded() async {
    if (state.status == PersonalDebtsStatus.initial ||
        state.status == PersonalDebtsStatus.error) {
      await load();
    }
  }

  PersonalDebt? byId(String id) {
    for (final d in state.debts) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<PersonalDebt> create({
    required DebtDirection direction,
    required String counterpartyPersonName,
    required double amount,
    required String currency,
    String? counterpartyContactId,
    String? description,
    String? note,
  }) async {
    final created = await _repo.create(
      direction: direction,
      counterpartyPersonName: counterpartyPersonName,
      amount: amount,
      currency: currency,
      counterpartyContactId: counterpartyContactId,
      description: description,
      note: note,
    );
    emit(state.copyWith(debts: [created, ...state.debts]));
    return created;
  }

  Future<PersonalDebt> update(
    String id, {
    double? amount,
    String? description,
    String? note,
    String? counterpartyPersonName,
    String? counterpartyContactId,
    bool clearContact = false,
  }) async {
    final updated = await _repo.update(
      id,
      amount: amount,
      description: description,
      note: note,
      counterpartyPersonName: counterpartyPersonName,
      counterpartyContactId: counterpartyContactId,
      clearContact: clearContact,
    );
    _replace(updated);
    return updated;
  }

  Future<PersonalDebt> cancel(String id) async {
    final updated = await _repo.cancel(id);
    _replace(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    emit(state.copyWith(debts: state.debts.where((d) => d.id != id).toList()));
  }

  Future<PersonalDebt> settle(
    String id, {
    String? accountId,
    double? amount,
    String? date,
    String? description,
    String? note,
  }) async {
    final res = await _repo.settle(
      id,
      accountId: accountId,
      amount: amount,
      date: date,
      description: description,
      note: note,
    );
    _replace(res.debt);
    return res.debt;
  }

  void _replace(PersonalDebt d) {
    final exists = state.debts.any((e) => e.id == d.id);
    emit(
      state.copyWith(
        debts: exists
            ? [for (final e in state.debts) e.id == d.id ? d : e]
            : [d, ...state.debts],
      ),
    );
  }
}
