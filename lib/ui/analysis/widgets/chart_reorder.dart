import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/scaffold/reorderable_scaffold.dart';
import 'package:shrimpai_pos/models/analysis/analysis.dart';
import 'package:shrimpai_pos/models/analysis/chart.dart';
import 'package:shrimpai_pos/translator.dart';

class ChartReorder extends StatelessWidget {
  const ChartReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: Analysis.instance.itemList,
      title: S.analysisChartTitleReorder,
      handleSubmit: (List<Chart> items) => Analysis.instance.reorderItems(items),
    );
  }
}
