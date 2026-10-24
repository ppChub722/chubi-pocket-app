import '../../../core/network/api_exception.dart';

bool isCategoryNameDuplicate(ApiException e) =>
    e.code == 'CATEGORY_NAME_DUPLICATE' || e.code == 'DUPLICATE_NAME';
