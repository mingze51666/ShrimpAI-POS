import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/scaffold/item_modal.dart';
import 'package:shrimpai_pos/components/style/hint_text.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/models/printer.dart';
import 'package:shrimpai_pos/services/bluetooth.dart';
import 'package:shrimpai_pos/translator.dart';

class PrinterSettingsModal extends StatefulWidget {
  const PrinterSettingsModal({super.key});

  @override
  State<PrinterSettingsModal> createState() => _PrinterSettingsModalState();
}

class _PrinterSettingsModalState extends State<PrinterSettingsModal> with ItemModal<PrinterSettingsModal> {
  late PrinterDensity density;

  @override
  String get title => S.printerSettingsTitle;

  @override
  List<Widget> buildFormFields() {
    return [
      SwitchListTile(
        title: Text(S.printerSettingsPaddingLabel),
        subtitle: Text(S.printerSettingsPaddingHelper),
        value: density == PrinterDensity.tight,
        onChanged: (value) => setState(() => density = value ? PrinterDensity.tight : PrinterDensity.normal),
      ),
      const SizedBox(height: kInternalLargeSpacing),
      Center(child: HintText(S.printerSettingsMore)),
    ];
  }

  @override
  initState() {
    density = Printers.instance.density;
    super.initState();
  }

  @override
  Future<void> updateItem() async {
    Printers.instance.density = density;
    await Printers.instance.saveProperties();

    if (mounted && context.canPop()) {
      context.pop();
    }
  }
}
