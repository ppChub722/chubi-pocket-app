import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../projects/presentation/cubit/project_directory_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../domain/form_options.dart';
import 'form_defaults_cubit.dart';

enum TxFormOptionsStatus { initial, loading, loaded, error }

class TxFormOptionsState extends Equatable {
  const TxFormOptionsState({
    this.status = TxFormOptionsStatus.initial,
    this.options,
    this.error,
  });

  final TxFormOptionsStatus status;
  final TxFormOptions? options;
  final ApiException? error;

  bool get isLoading =>
      options == null &&
      (status == TxFormOptionsStatus.initial ||
          status == TxFormOptionsStatus.loading);

  @override
  List<Object?> get props => [status, options, error];
}

/// The form's wallets, categories, tags and events, read from the caches the
/// app already holds. It makes no request of its own; `options` stays null
/// until every cache has its data.
class TxFormOptionsCubit extends Cubit<TxFormOptionsState> {
  TxFormOptionsCubit({
    required AccountsCubit accounts,
    required CategoriesCubit categories,
    required TagsCubit tags,
    required ProjectDirectoryCubit projects,
    required FormDefaultsCubit defaults,
  }) : _accounts = accounts,
       _categories = categories,
       _tags = tags,
       _projects = projects,
       _defaults = defaults,
       super(const TxFormOptionsState()) {
    _subs = [
      accounts.stream.listen((_) => _recompute()),
      categories.stream.listen((_) => _recompute()),
      tags.stream.listen((_) => _recompute()),
      projects.stream.listen((_) => _recompute()),
      defaults.stream.listen((_) => _recompute()),
    ];
    _recompute();
  }

  final AccountsCubit _accounts;
  final CategoriesCubit _categories;
  final TagsCubit _tags;
  final ProjectDirectoryCubit _projects;
  final FormDefaultsCubit _defaults;
  late final List<StreamSubscription<Object?>> _subs;

  void _recompute() {
    if (isClosed) return;
    final a = _accounts.state;
    final c = _categories.state;
    final t = _tags.state;
    final p = _projects.state;
    final d = _defaults.state;
    final loaded =
        a.status == AccountsStatus.loaded &&
        c.status == CategoriesStatus.loaded &&
        t.status == TagsStatus.loaded &&
        p.status == ProjectDirectoryStatus.loaded &&
        d.status == FormDefaultsStatus.loaded;
    if (loaded) {
      emit(
        TxFormOptionsState(
          status: TxFormOptionsStatus.loaded,
          options: TxFormOptions.fromCaches(
            accounts: a.accounts,
            categories: c.categories,
            tags: t.tags,
            events: p.formEvents,
            defaultAccountId: d.defaultAccountId,
            feeCategoryId: d.feeCategoryId,
          ),
        ),
      );
      return;
    }
    final error = a.error ?? c.error ?? t.error ?? p.error ?? d.error;
    final failed =
        a.status == AccountsStatus.error ||
        c.status == CategoriesStatus.error ||
        t.status == TagsStatus.error ||
        p.status == ProjectDirectoryStatus.error ||
        d.status == FormDefaultsStatus.error;
    emit(
      TxFormOptionsState(
        status: failed
            ? TxFormOptionsStatus.error
            : TxFormOptionsStatus.loading,
        options: state.options,
        error: failed ? error : null,
      ),
    );
  }

  Future<void> load() => Future.wait([
    _accounts.load(),
    _categories.load(),
    _tags.load(),
    _projects.load(),
    _defaults.loadIfNeeded(),
  ]);

  Future<void> loadIfNeeded() => Future.wait([
    _accounts.loadIfNeeded(),
    _categories.loadIfNeeded(),
    _tags.loadIfNeeded(),
    _projects.loadIfNeeded(),
    _defaults.loadIfNeeded(),
  ]);

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

TxFormOptionsCubit? maybeTxFormOptions(
  BuildContext context, {
  bool watch = true,
}) {
  try {
    return watch
        ? context.watch<TxFormOptionsCubit>()
        : context.read<TxFormOptionsCubit>();
  } catch (_) {
    // Not provided (flutter_bloc / provider throw when the type is absent).
    return null;
  }
}
