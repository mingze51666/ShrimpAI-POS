import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/style/snackbar.dart';
import 'package:shrimpai_pos/models/xfile.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/transit/exporter/excel_exporter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/field_formatter.dart';
import 'package:shrimpai_pos/ui/transit/formatter/formatter.dart';
import 'package:shrimpai_pos/ui/transit/previews/preview_page.dart';
import 'package:shrimpai_pos/ui/transit/widgets.dart';

class ImportBasicHeader extends ImportBasicBaseHeader {
  final ExcelExporter exporter;

  const ImportBasicHeader({
    super.key,
    required super.selected,
    required super.stateNotifier,
    required super.formatter,
    super.icon = const Icon(Icons.file_present_sharp),
    super.allowAll = true,
    super.logName = 'csv',
    this.exporter = const ExcelExporter(),
  });

  @override
  String get label => S.transitImportBtnExcel;

  @override
  Future<PreviewFormatter?> onImport(BuildContext context) async {
    final input = await XFile.pick();
    if (input == null) {
      // ignore: use_build_context_synchronously
      showSnackBar(S.transitImportErrorExcelPickFile, context: context);
      return null;
    }

    final excel = exporter.decode(input);
    return (FormattableModel able) {
      final data = exporter.import(excel, able.l10nName);

      if (data == null) {
        return null;
      }

      return findFieldFormatter(able).format(data);
    };
  }
}
