import 'package:flutter/material.dart';

import '../molecules/detail_rows.dart';
import '../tokens/app_spacing.dart';

class ChartSection extends StatelessWidget {
  const ChartSection({
    required this.title,
    required this.chart,
    this.description,
    this.first = false,
    super.key,
  });

  final String title;
  final String? description;
  final Widget chart;
  final bool first;

  @override
  Widget build(BuildContext context) => SectionCard(
    first: first,
    title: title,
    description: description,
    children: [
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: chart),
    ],
  );
}
