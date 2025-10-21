import 'package:possystem/models/model.dart';
import 'package:possystem/models/objects/receipt_template_object.dart';
import 'package:possystem/models/receipt_component.dart';
import 'package:possystem/models/repository/receipt_templates.dart';
import 'package:possystem/services/storage.dart';
import 'package:possystem/translator.dart';

class ReceiptTemplate extends Model<ReceiptTemplateObject> with ModelStorage<ReceiptTemplateObject> {
  List<ReceiptComponent> components;

  @override
  final Stores storageStore = .receiptTemplates;

  @override
  ReceiptTemplates get repository => .instance;

  @override
  String get prefix => 'template.$id';

  bool get isSelected => ReceiptTemplates.instance.selected.id == id;
  bool get isDefault => id == '__default';

  ReceiptTemplate({
    super.id,
    super.status = ModelStatus.normal,
    super.name = 'receipt template',
    List<ReceiptComponent>? components,
  }) : components = components ?? const [];

  factory ReceiptTemplate.fromObject(ReceiptTemplateObject object) =>
      ReceiptTemplate(id: object.id, name: object.name!, components: object.components);

  /// Get default receipt components matching the current hardcoded layout
  static List<ReceiptComponent> getDefaultComponents() {
    return [
      TextFieldComponent(
        texts: [
          StyledPlaceholderObject.fromType(.title, fontSize: 28),
          StyledTextObject.fromText('\n', fontSize: 8),
          StyledPlaceholderObject.fromType(.orderedAt, meta: ''),
        ],
        textAlign: .center,
        padding: const .only(bottom: 1),
      ),
      OrderTableComponent(padding: const .only(bottom: 0)),
      DiscountTableComponent(padding: const .only(bottom: 0)),
      AttributeTableComponent(),
      PriceTableComponent(padding: const .only(bottom: 0)),
    ];
  }

  String get displayName => name == '' ? S.printerReceiptTemplateDefaultName : name;

  @override
  ReceiptTemplateObject toObject() {
    return ReceiptTemplateObject(id: id, name: name, components: components);
  }

  @override
  Future<void> update(ReceiptTemplateObject object, {String event = 'update'}) async {
    // although default template is not editable in UI, but prevent updating by routing
    if (!isDefault) {
      await super.update(object, event: event);
    }
  }
}
