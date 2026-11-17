import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/institution.dart';

/// The user's institutions (0.4.3): banks, card issuers, finance companies,
/// stores. A debt counterparty (`i:` key) and a wallet's owner.
class InstitutionsRepository {
  InstitutionsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static InstitutionsRepository of(BuildContext context) =>
      context.read<InstitutionsRepository>();

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<List<Institution>> list({bool archived = false}) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/institutions',
      queryParameters: {'status': archived ? 'archived' : 'active'},
    );
    return [
      for (final i in (res.data?['data'] as List?) ?? const [])
        if (i is Map<String, dynamic>) Institution.fromJson(i),
    ];
  });

  Future<InstitutionDetail> get(String id) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>('/institutions/$id');
    return InstitutionDetail.fromJson(res.data!);
  });

  /// With a provider the user already has: that row back (no duplicate).
  Future<Institution> create(InstitutionWrite write) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/institutions',
      data: write.toJson(),
    );
    return Institution.fromJson(res.data!);
  });

  Future<Institution> update(String id, InstitutionWrite write) =>
      _call((dio) async {
        final res = await dio.put<Map<String, dynamic>>(
          '/institutions/$id',
          data: write.toJson(),
        );
        return Institution.fromJson(res.data!);
      });

  Future<Institution> archive(String id, {bool restore = false}) =>
      _call((dio) async {
        final res = await dio.post<Map<String, dynamic>>(
          '/institutions/$id/${restore ? 'restore' : 'archive'}',
        );
        return Institution.fromJson(res.data!);
      });

  /// 409 INSTITUTION_IN_USE while debts / items / wallets point at it.
  Future<void> delete(String id) =>
      _call((dio) => dio.delete<Map<String, dynamic>>('/institutions/$id'));
}
