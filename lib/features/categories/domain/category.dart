import 'package:equatable/equatable.dart';

import 'category_icon_preset.dart';
import 'category_type.dart';

/// One category — an income or expense bucket transactions group under.
///
/// Mirrors the spec at
/// [`design/spec/05-categories-tags.md`](../../../../../chubi-pocket-docs/design/spec/05-categories-tags.md)
/// trimmed to fields the UI actually reads. Two fields are **not** in the
/// current spec and need a P1a schema bump:
/// - [includeInReport] — `categories.include_in_report BOOLEAN NOT NULL
///   DEFAULT true`. When false, transactions in this category are excluded
///   from totals / charts (e.g. "Adjustment", "Lending", "Reimbursements").
/// - [sortOrder] — `categories.sort_order INTEGER NOT NULL DEFAULT 0`.
///   Persists drag-and-drop ordering chosen in the categories management
///   page.
///
/// [description] and [note] are also new — kept as two separate fields so
/// the seed taxonomy's "what this is for" guidance lives separately from
/// the user's personal scratch notes. Pending P1a schema bump (`description
/// TEXT NULLABLE`, `note TEXT NULLABLE`).
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentId,
    this.description,
    this.note,
    this.includeInReport = true,
    this.isSystem = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// Null for top-level categories. Maximum nesting is 3 (parent →
  /// child → grandchild) per spec §4.4.
  final String? parentId;

  final CategoryType type;
  final CategoryIconPreset icon;
  final CategoryColor color;

  /// Free-text "what this category is for" — auto-filled from the seed
  /// taxonomy for system / starter categories. User can edit. ~200-char
  /// advisory, no DB CHECK.
  final String? description;

  /// User's personal scratch note — always blank for seeded categories.
  /// ~200-char advisory.
  final String? note;

  /// When false, transactions in this category are excluded from report
  /// totals. Default true for user-created categories; default false in
  /// seed for `Adjustments`, `Lending / Pay for Others`, `Reimbursements /
  /// Payback`, and the income-side `Adjustment`.
  final bool includeInReport;

  /// Spec §2.1 — system categories are seeded at registration, never
  /// editable beyond renaming, never visible in the management page,
  /// auto-assigned by the backend on transfer / opening / adjustment
  /// transactions. The categories management page filters these out.
  final bool isSystem;

  /// User-defined ordering inside the parent's siblings. Updated by the
  /// drag-and-drop reorder flow.
  final int sortOrder;

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    bool clearParent = false,
    CategoryType? type,
    CategoryIconPreset? icon,
    CategoryColor? color,
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
      icon: icon ?? this.icon,
      color: color ?? this.color,
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
        icon,
        color,
        description,
        note,
        includeInReport,
        isSystem,
        sortOrder,
      ];
}
