import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/scaffold/item_modal.dart';
import 'package:possystem/components/scaffold/reorderable_scaffold.dart';
import 'package:possystem/components/style/hint_text.dart';
import 'package:possystem/components/style/slide_to_delete.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/validator.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/objects/receipt_template_object.dart';
import 'package:possystem/models/receipt_component.dart';
import 'package:possystem/models/repository/receipt_templates.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/printer/widgets/printer_receipt_view.dart';
import 'package:possystem/ui/printer/widgets/receipt_component_modal.dart';

class ReceiptTemplateModal extends StatefulWidget {
  final ReceiptTemplate? template;

  final bool isNew;

  const ReceiptTemplateModal({super.key, this.template}) : isNew = template == null;

  @override
  State<ReceiptTemplateModal> createState() => _ReceiptTemplateModalState();
}

class _ReceiptTemplateModalState extends State<ReceiptTemplateModal> with ItemModal<ReceiptTemplateModal> {
  late TextEditingController _nameController;
  late List<ReceiptComponent> _components;
  late ValueNotifier<bool> _rebuildComponents;
  late FocusNode _nameFocusNode;
  late final OrderObject _order;

  @override
  String get title => widget.isNew ? S.printerSettingsTitleTemplateCreate : S.printerSettingsTitleTemplateUpdate;

  @override
  bool get scrollable => false;

  @override
  bool get readonly => widget.template?.isDefault ?? false;

  @override
  List<Widget> buildFormFields() {
    return [
      if (!readonly)
        p(
          TextFormField(
            key: const Key('receipt_tpl.name'),
            controller: _nameController,
            textInputAction: .done,
            textCapitalization: .words,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(
              labelText: S.printerReceiptTemplateNameLabel,
              hintText: widget.template?.name,
              filled: false,
            ),
            maxLength: 30,
            validator: Validator.textLimit(
              S.printerReceiptTemplateNameLabel,
              30,
              focusNode: _nameFocusNode,
              validator: (name) {
                return widget.template?.name != name && ReceiptTemplates.instance.hasName(name)
                    ? S.printerReceiptTemplateNameErrorRepeat
                    : null;
              },
            ),
            onFieldSubmitted: handleFieldSubmit,
          ),
        ),
      Expanded(
        child: ValueListenableBuilder<bool>(
          valueListenable: _rebuildComponents,
          builder: (context, value, child) {
            if (_components.isEmpty) {
              return Center(child: Text(S.printerReceiptComponentTitleEmpty));
            }

            return _buildTemplateWidget();
          },
        ),
      ),
    ];
  }

  @override
  Widget? buildFloatingActionButton() {
    return FloatingActionButton.extended(
      key: const Key('receipt_tpl.add_component'),
      icon: const Icon(Icons.add),
      label: Text(S.printerReceiptComponentTitleAdd),
      onPressed: _onAddComponent,
    );
  }

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.template?.name);
    _nameFocusNode = FocusNode();
    _components = widget.template?.components.toList() ?? [];
    _rebuildComponents = ValueNotifier<bool>(true);
    _order = OrderObject.example();

    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Widget _buildTemplateWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewWidget = Card(
          child: SingleChildScrollView(
            child: Padding(
              padding: const .fromLTRB(24.0, 16, 24.0, 24.0),
              child: PrinterReceiptView(order: _order, customComponents: _components),
            ),
          ),
        );
        final editorWidget = Column(
          children: [
            Center(child: HintText(S.printerReceiptComponentTitleDragToReorder)),
            const SizedBox(height: kInternalSpacing),
            Expanded(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: MyReorderableList(
                  padding: const .only(bottom: kFABSpacing),
                  items: _components,
                  itemBuilder: _buildComponentTile,
                  onReorder: () => _rebuildComponents.value = !_rebuildComponents.value,
                  itemWhenDraggingBuilder: _buildComponentListTile,
                ),
              ),
            ),
          ],
        );
        final isHorizon = constraints.maxWidth > Breakpoint.medium.max;

        if (isHorizon) {
          return Row(
            children: [
              Expanded(child: previewWidget),
              const VerticalDivider(),
              Expanded(child: editorWidget),
            ],
          );
        }

        final maxHeight = math.min(360.0, constraints.maxHeight * 0.5);
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: previewWidget,
            ),
            p(const Divider()),
            Expanded(child: editorWidget),
          ],
        );
      },
    );
  }

  Widget _buildComponentTile(BuildContext context, ReceiptComponent item, Widget toggler) {
    return SlideToDelete(
      item: item,
      deleteCallback: () async {
        _components.remove(item);
        _rebuildComponents.value = !_rebuildComponents.value;
      },
      child: _buildComponentListTile(
        context,
        item,
        toggler,
        onTap: () async {
          final saved = await _routeToComponentEditor(item);
          if (saved != null && mounted) {
            _components[_components.indexOf(item)] = saved;
            _rebuildComponents.value = !_rebuildComponents.value;
          }
        },
      ),
    );
  }

  Widget _buildComponentListTile(BuildContext context, ReceiptComponent item, Widget toggler, {VoidCallback? onTap}) {
    final subtitle = item.buildDescription(context);
    return ListTile(
      title: Text(S.printerReceiptComponentType(item.type.name)),
      titleAlignment: .center,
      subtitle: subtitle,
      isThreeLine: subtitle != null,
      leading: item.buildLeading(context),
      trailing: toggler,
      onTap: onTap,
    );
  }

  void _onAddComponent() async {
    final wanted = await showPositionedMenu<ReceiptComponentType>(
      context,
      actions: [
        for (final type in ReceiptComponentType.values)
          MenuAction(
            title: Text(S.printerReceiptComponentType(type.name)),
            leading: ReceiptComponent.fromType(type).leading,
            returnValue: type,
          ),
      ],
    );

    if (wanted != null && mounted) {
      final saved = await _routeToComponentEditor(ReceiptComponent.fromType(wanted));
      if (saved != null && mounted) {
        _components.add(saved);
        _rebuildComponents.value = !_rebuildComponents.value;
      }
    }
  }

  Future<ReceiptComponent?> _routeToComponentEditor(ReceiptComponent component) {
    return showDialog(
      context: context,
      builder: (context) => ReceiptComponentModal(component: component),
    );
  }

  @override
  Future<void> updateItem() async {
    final object = ReceiptTemplateObject(name: _nameController.text, components: _components);

    if (widget.isNew) {
      await ReceiptTemplates.instance.addItem(ReceiptTemplate(name: object.name!, components: object.components));
    } else {
      await widget.template!.update(object);
    }

    if (mounted && context.canPop()) {
      context.pop();
    }
  }
}
