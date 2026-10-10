import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';

class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    this.iconCode,
    this.description,
    this.note,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final IconCode? iconCode;
  final String? description;
  final String? note;
  final int usageCount;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      usageCount: (json['usage_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      if (description != null) 'description': description,
      if (note != null) 'note': note,
    };
  }

  /// Full replace — null clears.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'icon_code': iconCode?.toJson(),
      'description': description,
      'note': note,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    IconCode? iconCode,
    String? description,
    String? note,
    int? usageCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    description,
    note,
    usageCount,
  ];
}
