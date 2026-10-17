import 'package:flutter/material.dart';

abstract final class BankBrand {
  static const Map<String, Color> _brand = {
    '002': Color(0xFF1E4598), // BBL
    '004': Color(0xFF138F2D), // KBANK
    '006': Color(0xFF1BA5E1), // KTB
    '011': Color(0xFF0050F0), // TTB
    '014': Color(0xFF4E2E7F), // SCB
    '022': Color(0xFF7E2F36), // CIMB
    '024': Color(0xFF0B3979), // UOB
    '025': Color(0xFFFEC43B), // BAY
    '030': Color(0xFFEB198D), // GSB
    '033': Color(0xFFF57D23), // GHB
    '034': Color(0xFF4B9B2E), // BAAC
    '067': Color(0xFF12549F), // TISCO
    '069': Color(0xFF199CC5), // KKP
    '073': Color(0xFF6D6E71), // LH Bank
  };

  static const List<Color> _fallback = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFF00897B),
  ];

  static Color of(String code) =>
      _brand[code] ??
      _fallback[code.codeUnits.fold(0, (a, b) => a + b) % _fallback.length];
}
