import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/style/snackbar.dart';
import 'package:shrimpai_pos/models/objects/order_object.dart';
import 'package:shrimpai_pos/models/repository/seller.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/exporter/csv_exporter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/formatter.dart';
import 'package:shrimpai_pos/ui/transit/order_widgets.dart';

class ExportOrderHeader extends TransitOrderHeader {
  final CSVExporter exporter;

  const ExportOrderHeader({
    super.key,
    required super.stateNotifier,
    required super.ranger,
    super.settings,
    this.exporter = const CSVExporter(),
  });

  @override
  String get title => S.transitExportOrderTitleCsv;

  @override
  Future<void> onExport(BuildContext context, List<OrderObject> orders) async {
    final headers = FormattableOrder.values.map((e) => e.formatHeader()).toList();
    final data = FormattableOrder.values
        .map(
          (formatter) => orders.expand((o) {
            return formatter.formatRows(o).map((r) => r.map((v) => v.toString()));
          }),
        )
        .toList();

    final ok = await exporter.export(name: S.transitExportOrderFileName, data: data, headers: headers);
    if (context.mounted && ok) {
      showSnackBar(S.transitExportOrderSuccessCsv, context: context);
    }
  }
}

class ExportOrderView extends TransitOrderList {
  const ExportOrderView({super.key, required super.ranger});

  @override
  String get helpMessage => S.transitExportOrderSubtitleCsv;

  @override
  int memoryPredictor(OrderMetrics metrics) => _memoryPredictor(metrics);

  /// Offset are headers
  static int _memoryPredictor(OrderMetrics m) {
    const offset = 60 + 15 + 40 + 20; // headers
    return (offset + m.count * 40 + m.attrCount! * 20 + m.productCount! * 30 + m.ingredientCount! * 20).toInt();
  }
}
