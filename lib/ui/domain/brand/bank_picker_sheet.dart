import 'package:flutter/material.dart';

import '../../ui.dart';

@immutable
class BankPickerItem {
  const BankPickerItem({
    required this.code,
    required this.name,
    this.nameTh = '',
    this.nameEn = '',
    this.shortName,
  });

  final String code;
  final String name;
  final String nameTh;
  final String nameEn;
  final String? shortName;
}

@immutable
class BankPickerChoice {
  const BankPickerChoice(this.code);
  final String? code;
}

class BankBrandMark extends StatelessWidget {
  const BankBrandMark({
    required this.code,
    this.shortName,
    this.nameEn = '',
    this.size = 36,
    super.key,
  });

  final String code;
  final String? shortName;
  final String nameEn;
  final double size;

  String get _letters {
    final s = shortName?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final initials = nameEn
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
    return initials.isEmpty ? code : initials;
  }

  @override
  Widget build(BuildContext context) =>
      AppAvatar.brand(name: _letters, color: BankBrand.of(code), size: size);
}
