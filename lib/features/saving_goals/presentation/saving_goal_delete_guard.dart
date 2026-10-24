import '../../../core/network/api_exception.dart';
import '../domain/saving_goals_overview.dart';

bool deleteBlockedByMoney(SavingDeletePreview? preview) =>
    preview != null && !preview.canDelete;

bool deleteRefusedForMoney(ApiException e) => e.code == 'GOAL_HAS_SAVINGS';
