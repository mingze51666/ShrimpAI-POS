import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/dialog/responsive_dialog.dart';
import 'package:shrimpai_pos/components/style/card_info_text.dart';
import 'package:shrimpai_pos/models/stock/replenishment.dart';
import 'package:shrimpai_pos/translator.dart';

class ReplenishmentPreviewPage extends StatelessWidget {
  final Replenishment item;

  const ReplenishmentPreviewPage(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: Text(item.name),
      action: TextButton(
        key: const Key('repl.apply'),
        onPressed: () async {
          await item.apply();
          if (context.mounted && context.canPop()) {
            context.pop(true);
          }
        },
        child: Text(S.stockReplenishmentApplyConfirmButton),
      ),
      content: Column(
        children: [
          CardInfoText(child: Text(S.stockReplenishmentApplyConfirmHint)),
          DataTable(
            columns: [
              DataColumn(label: Text(S.stockReplenishmentApplyConfirmColumn('name'))),
              DataColumn(numeric: true, label: Text(S.stockReplenishmentApplyConfirmColumn('amount'))),
            ],
            rows: <DataRow>[
              for (final entry in item.ingredientData.entries)
                DataRow(cells: [DataCell(Text(entry.key.name)), DataCell(Text(entry.value.toString()))]),
            ],
          ),
        ],
      ),
    );
  }
}
