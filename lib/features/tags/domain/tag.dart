import 'package:equatable/equatable.dart';

import 'tag_icon_preset.dart';

/// One tag — a flat, user-chosen label that can be attached to any
/// number of transactions. Mirror of the spec at
/// [`design/spec/05-categories-tags.md §3.8–3.12, §4.11`](../../../../../chubi-pocket-docs/design/spec/05-categories-tags.md)
/// trimmed to fields the UI reads.
///
/// `tags.icon` is **not** in the canonical spec yet — flagged for the
/// same P1a doc bump that picks up `accounts.note`,
/// `categories.{description, note, sort_order, include_in_report}`.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final TagColor color;
  final TagIconPreset icon;

  /// Computed at render time from `transaction_tags` once transactions
  /// ship. In the Phase 0 mock store everything sits at 0.
  final int usageCount;

  /// Reconstructs a [Tag] from the BE's `GET /v1/tags` row.
  /// `icon` defaults to `label` when null; `color` to `blue` when missing.
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: TagColor.fromHex(json['color'] as String?),
      icon: TagIconPreset.byId((json['icon'] as String?) ?? 'label'),
      usageCount: (json['usage_count'] as int?) ?? 0,
    );
  }

  /// Body for `POST /v1/tags`.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'color': color.toHex(),
      'icon': icon.id,
    };
  }

  /// Body for `PUT /v1/tags/:id`.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'color': color.toHex(),
      'icon': icon.id,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    TagColor? color,
    TagIconPreset? icon,
    int? usageCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon, usageCount];
}
