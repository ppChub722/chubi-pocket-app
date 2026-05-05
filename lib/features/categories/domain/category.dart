import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'category_type.dart';

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
    String? note,
    bool? includeInReport,
    bool? isSystem,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      includeInReport: includeInReport ?? this.includeInReport,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
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
      ];
}
