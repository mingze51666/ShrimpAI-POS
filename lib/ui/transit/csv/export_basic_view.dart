import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/style/snackbar.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/exporter/csv_exporter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/field_formatter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/formatter.dart';
import 'package:shrimpai_pos/ui/transit/widgets.dart';

class ExportBasicHeader extends BasicModelPicker {
  final CSVExporter exporter;

  const ExportBasicHeader({
    super.key,
    required super.selected,
    required super.stateNotifier,
    this.exporter = const CSVExporter(),
    super.icon = const Icon(Icons.share_outlined),
    super.allowAll = true,
  });

  @override
  String get label => S.transitExportBasicBtnCsv;

  @override
  Future<void> onExport(BuildContext context, FormattableModel? able) async {
    final name = able?.l10nName;
    final headers = getAllFormattedFieldHeaders(able).map((e) => e.map((v) => v.toString())).toList();
    final data = getAllFormattedFieldData(able).map((e) => e.map((r) => r.map((c) => c.toString()))).toList();

    final ok = await exporter.export(name: name ?? S.transitExportBasicFileName, data: data, headers: headers);
    if (context.mounted && ok) {
      showSnackBar(S.transitExportBasicSuccessCsv, context: context);
    }
  }
}

class ExportBasicView extends ExportView {
  const ExportBasicView({super.key, required super.selected, required super.stateNotifier});

  @override
  ModelData getSourceAndHeaders(FormattableModel able) {
    final formatter = findFieldFormatter(able);
    final headers = formatter.getHeader();
    return ModelData(headers, formatter.getRows());
  }
}
