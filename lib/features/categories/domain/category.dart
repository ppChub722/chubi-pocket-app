import 'package:equatable/equatable.dart';

import 'category_type.dart';
import '../../../ui/ui.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.iconCode,
    this.parentId,
    this.description,
    this.note,
    this.includeInReport = true,
    this.isSystem = false,
    this.sortOrder = 0,
    this.systemKind,
    this.status = 'active',
    this.depth = 1,
    this.path = const [],
    this.createdAt,
    this.updatedAt,
    this.monthSpent = 0,
    this.monthCount = 0,
  });

  final String id;
  final String name;
  final String? parentId;
  final CategoryType type;
  final IconCode? iconCode;
  final String? description;
  final String? note;
  final bool includeInReport;
  final bool isSystem;
  final int sortOrder;

  final String? systemKind;

  final String status;

  final int depth;

  final List<CategoryPathItem> path;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final num monthSpent;
  final int monthCount;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CategoryType.values.byName(json['type'] as String),
      parentId: json['parent_id'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      includeInReport: (json['include_in_report'] as bool?) ?? true,
      isSystem: (json['is_system'] as bool?) ?? false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      systemKind: json['system_kind'] as String?,
      status: (json['status'] as String?) ?? 'active',
      depth: (json['depth'] as num?)?.toInt() ?? 1,
      path: [
        for (final p in (json['path'] as List?) ?? const [])
          CategoryPathItem.fromJson(p as Map<String, dynamic>),
      ],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      monthSpent: (json['month_spent'] as num?) ?? 0,
      monthCount: (json['month_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.name,
      'parent_id': parentId,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      'include_in_report': includeInReport,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'parent_id': parentId,
      'icon_code': iconCode?.toJson(),
      'include_in_report': includeInReport,
      'description': description,
      'note': note,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    bool clearParent = false,
    CategoryType? type,
    IconCode? iconCode,
    String? description,
    bool clearDescription = false,
    String? note,
    bool clearNote = false,
    bool? includeInReport,
    bool? isSystem,
    int? sortOrder,
    String? systemKind,
    String? status,
    int? depth,
    List<CategoryPathItem>? path,
    DateTime? createdAt,
    DateTime? updatedAt,
    num? monthSpent,
    int? monthCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      description: clearDescription ? null : (description ?? this.description),
      note: clearNote ? null : (note ?? this.note),
      includeInReport: includeInReport ?? this.includeInReport,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      systemKind: systemKind ?? this.systemKind,
      status: status ?? this.status,
      depth: depth ?? this.depth,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      monthSpent: monthSpent ?? this.monthSpent,
      monthCount: monthCount ?? this.monthCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    parentId,
    type,
    iconCode,
    description,
    note,
    includeInReport,
    isSystem,
    sortOrder,
    systemKind,
    status,
    depth,
    path,
    createdAt,
    updatedAt,
    monthSpent,
    monthCount,
  ];
}

class CategoryPathItem extends Equatable {
  const CategoryPathItem({required this.id, required this.name, this.iconCode});

  factory CategoryPathItem.fromJson(Map<String, dynamic> json) =>
      CategoryPathItem(
        id: json['id'] as String,
        name: json['name'] as String,
        iconCode: json['icon_code'] is Map<String, dynamic>
            ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
            : null,
      );

  final String id;
  final String name;

  final IconCode? iconCode;

  @override
  List<Object?> get props => [id, name, iconCode];
}

class CategoryDetail extends Category {
  const CategoryDetail({
    required super.id,
    required super.name,
    required super.type,
    super.iconCode,
    super.parentId,
    super.description,
    super.note,
    super.includeInReport,
    super.isSystem,
    super.sortOrder,
    super.systemKind,
    super.status,
    super.depth,
    super.path,
    super.createdAt,
    super.updatedAt,
    super.monthSpent,
    super.monthCount,
    this.parentName,
    this.childCount = 0,
    this.transactionCount = 0,
    this.budgetCount = 0,
    this.isFeeCategory = false,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    final c = Category.fromJson(json);
    return CategoryDetail.fromCategory(
      c,
      parentName: json['parent_name'] as String?,
      childCount: (json['child_count'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      budgetCount: (json['budget_count'] as num?)?.toInt() ?? 0,
      isFeeCategory: (json['is_fee_category'] as bool?) ?? false,
    );
  }

  factory CategoryDetail.fromCategory(
    Category c, {
    String? parentName,
    int childCount = 0,
    int transactionCount = 0,
    int budgetCount = 0,
    bool isFeeCategory = false,
  }) => CategoryDetail(
    id: c.id,
    name: c.name,
    type: c.type,
    iconCode: c.iconCode,
    parentId: c.parentId,
    description: c.description,
    note: c.note,
    includeInReport: c.includeInReport,
    isSystem: c.isSystem,
    sortOrder: c.sortOrder,
    systemKind: c.systemKind,
    status: c.status,
    depth: c.depth,
    path: c.path,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    monthSpent: c.monthSpent,
    monthCount: c.monthCount,
    parentName: parentName,
    childCount: childCount,
    transactionCount: transactionCount,
    budgetCount: budgetCount,
    isFeeCategory: isFeeCategory,
  );

  final String? parentName;
  final int childCount;
  final int transactionCount;

  final int budgetCount;
  final bool isFeeCategory;

  CategoryDetail withFee(bool value) => CategoryDetail.fromCategory(
    this,
    parentName: parentName,
    childCount: childCount,
    transactionCount: transactionCount,
    budgetCount: budgetCount,
    isFeeCategory: value,
  );

  @override
  List<Object?> get props => [
    ...super.props,
    parentName,
    childCount,
    transactionCount,
    budgetCount,
    isFeeCategory,
  ];
}

class CategoryRef extends Equatable {
  const CategoryRef({
    required this.id,
    required this.name,
    required this.type,
    this.iconCode,
    this.isSystem = false,
    this.systemKind,
    this.parentId,
  });

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
    id: json['id'] as String,
    name: json['name'] as String,
    type: CategoryType.values.byName(json['type'] as String),
    iconCode: json['icon_code'] != null
        ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
        : null,
    isSystem: (json['is_system'] as bool?) ?? false,
    systemKind: json['system_kind'] as String?,
    parentId: json['parent_id'] as String?,
  );

  final String id;
  final String name;
  final CategoryType type;
  final IconCode? iconCode;
  final bool isSystem;
  final String? systemKind;
  final String? parentId;

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    iconCode,
    isSystem,
    systemKind,
    parentId,
  ];
}
