import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';

class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    this.iconCode,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final IconCode? iconCode;
  final int usageCount;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      usageCount: (json['usage_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'icon_code': iconCode?.toJson(),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    IconCode? iconCode,
    int? usageCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [id, name, iconCode, usageCount];
}
