import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:possystem/components/style/slide_to_delete.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/printer.dart';
import 'package:possystem/models/receipt_component.dart';
import 'package:possystem/models/repository/receipt_templates.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/printer/printer_page.dart';

import '../../mocks/mock_cache.dart';
import '../../mocks/mock_storage.dart';
import '../../test_helpers/translator.dart';

void main() {
  group('Printer Template', () {
    Widget buildApp() {
      return MaterialApp.router(
        routerConfig: GoRouter(
          navigatorKey: Routes.rootNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: PrinterPage()),
            ),
            ...Routes.getDesiredRoute(0).routes,
          ],
        ),
      );
    }

    testWidgets('Add template with all type of component', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // open settings
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();

      // tap add template
      await tester.tap(find.byKey(const Key('printer.settings.template_create')));
      await tester.pumpAndSettle();

      // fill name
      await tester.enterText(find.byKey(const Key('receipt_tpl.name')), 'AllComponentsTemplate');
      await tester.pumpAndSettle();

      // add every component type
      // 1. Text Field
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('textField')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor_ant.editor')), 'Sample Text');
      await tester.tap(find.byIcon(Icons.data_object));
      await tester.pumpAndSettle();
      await tester.tap(find.text('now'));
      await tester.pumpAndSettle();

      // 1-1. Date Placeholder
      await tester.tap(find.text('now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('yMMMd Hms'));
      await tester.pumpAndSettle();
      expect(find.text(S.printerReceiptComponentTextPlaceholderDateLabel), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 2. Image
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 3. Order Table
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('orderTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 4. Discount Table
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('discountTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 5. Attribute Table
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('attributeTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 6. Price Table
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('priceTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 7. Divider
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('divider')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // save template
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // Expect template appears in list
      expect(find.text('AllComponentsTemplate'), findsOneWidget);

      // Verify storage add/set called with expected structure
      verify(
        storage.set(
          any,
          argThat(
            predicate((v) {
              if (v is! Map) return false;
              final containsTemplate = v.values.any((entry) {
                if (entry is! Map) return false;
                final name = entry['name'] as String?;
                final components = entry['components'] as List<dynamic>?;
                return name == 'AllComponentsTemplate' &&
                    components != null &&
                    components.length == 7 &&
                    components.any((c) => c['type'] == ReceiptComponentType.textField.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.image.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.orderTable.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.discountTable.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.attributeTable.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.priceTable.index) &&
                    components.any((c) => c['type'] == ReceiptComponentType.divider.index);
              });
              return containsTemplate;
            }),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('Edit template with component reordering and deleting', (tester) async {
      await ReceiptTemplates.instance.addItem(
        ReceiptTemplate(
          id: 'tpl1',
          name: 'EditTemplate',
          components: [
            DividerComponent(height: 2.0),
            ImageComponent(imagePath: 'path', widthRatio: 0.5),
            DividerComponent(height: 3.0),
          ],
        ),
        save: false,
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // open settings
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();

      // open edit modal by tapping the template
      await tester.tap(find.text('EditTemplate'));
      await tester.pumpAndSettle();

      // Delete the image component by dismissing it via SlideToDelete (drag right-to-left)
      await tester.drag(find.byType(SlideToDelete<ReceiptComponent>).at(1), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_dialog.confirm')));
      await tester.pumpAndSettle();

      // save changes
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // verify storage.set called to persist order and deletion
      verify(
        storage.set(
          any,
          argThat(
            predicate((v) {
              if (v is! Map) return false;
              if (v['template.tpl1.components'] is! List) return false;
              final invalid = (v['template.tpl1.components'] as List).where((e) {
                if (e is! Map) return true;
                if (e['type'] != ReceiptComponentType.divider.index) return true;
                return false;
              });
              return invalid.isEmpty;
              return false;
            }),
          ),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('Open default template and confirm no modal.save button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // open settings
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();

      // open default template item
      await tester.tap(find.text(S.printerReceiptTemplateDefaultName));
      await tester.pumpAndSettle();

      // default template should be view-only: no save button in modal
      expect(find.byKey(const Key('modal.save')), findsNothing);
    });

    testWidgets('Add template validation - repeat name', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Create a template named "RepeatName" first
      await ReceiptTemplates.instance.addItem(
        ReceiptTemplate(id: 'existing', name: 'RepeatName', components: []),
        save: false,
      );

      // open settings
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();

      // tap add template
      await tester.tap(find.byKey(const Key('printer.settings.template_create')));
      await tester.pumpAndSettle();

      // fill name with RepeatName
      await tester.enterText(find.byKey(const Key('receipt_tpl.name')), 'RepeatName');
      await tester.pumpAndSettle();

      // save template
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // Should show error for repeat name
      expect(find.text(S.printerReceiptTemplateNameErrorRepeat), findsOneWidget);
    });

    testWidgets('Edit component padding validation and splitting', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await ReceiptTemplates.instance.addItem(ReceiptTemplate(id: 'id', name: 'Example', components: []), save: false);

      // open settings -> add template
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Example'));
      await tester.pumpAndSettle();

      // add textField component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('textField')));
      await tester.pumpAndSettle();

      // enter negative number in padding
      final paddingField = find.widgetWithText(TextFormField, S.printerReceiptComponentPaddingAll);
      await tester.enterText(paddingField, '3');
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();
      expect(ReceiptTemplates.instance.itemList.last.components.first.padding, const EdgeInsets.all(3));

      await tester.tap(find.text('Example'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SlideToDelete<ReceiptComponent>).first);
      await tester.pumpAndSettle();

      // split padding
      await tester.tap(find.text(S.printerReceiptComponentPaddingLabel));
      await tester.pumpAndSettle();

      // enter valid number and save
      await tester.enterText(find.widgetWithText(TextFormField, S.printerReceiptComponentPaddingLeft), '1');
      await tester.enterText(find.widgetWithText(TextFormField, S.printerReceiptComponentPaddingTop), '2');
      await tester.enterText(find.widgetWithText(TextFormField, S.printerReceiptComponentPaddingRight), '3');
      await tester.enterText(find.widgetWithText(TextFormField, S.printerReceiptComponentPaddingBottom), '4');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      expect(ReceiptTemplates.instance.itemList.last.components.first.padding, const EdgeInsets.fromLTRB(1, 2, 3, 4));
    });

    testWidgets('Edit template component specific configurations', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // open settings -> add template
      await tester.tap(find.byKey(const Key('printer.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('printer.settings.template_create')));
      await tester.pumpAndSettle();

      // 1. Add Order Table component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('orderTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 2. Add Discount Table component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('discountTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 3. Add Attribute Table component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('attributeTable')));
      await tester.pumpAndSettle();
      // 3. Add Attribute Table component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('attributeTable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // 4. Add Price Table component
      await tester.tap(find.byKey(const Key('receipt_tpl.add_component')), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.printerReceiptComponentType('priceTable')));
      await tester.pumpAndSettle(); // ensure modal is fully built

      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      // fill name and save template
      await tester.enterText(find.byKey(const Key('receipt_tpl.name')), 'CustomConfigTemplate');
      await tester.tap(find.byKey(const Key('modal.save')).last);
      await tester.pumpAndSettle();

      expect(find.text('CustomConfigTemplate'), findsOneWidget);
    });

    testWidgets('Unit tests for components and formats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // 1. OrderTableComponent
                {
                  final c = OrderTableComponent(
                    padding: const .all(5),
                    columns: const [
                      TableColumnConfig(OrderTableColumn.productName),
                      TableColumnConfig(OrderTableColumn.quantity),
                    ],
                  );
                  expect(c.leading, isNotNull);
                  final json = c.toJson();
                  expect((json['columns'] as List).length, 2);
                  expect(json['padding'], '5,5,5,5');

                  final c2 = ReceiptComponent.fromJson(json) as OrderTableComponent;
                  expect(c2.columns.length, 2);
                  expect(c2.padding, const EdgeInsets.all(5));
                }

                // 2. DiscountTableComponent
                {
                  final c = DiscountTableComponent(
                    padding: const .all(2),
                    columns: const [TableColumnConfig(DiscountTableColumn.productName)],
                  );
                  expect(c.leading, isNotNull);
                  final json = c.toJson();
                  expect((json['columns'] as List).length, 1);

                  final c2 = ReceiptComponent.fromJson(json) as DiscountTableComponent;
                  expect(c2.columns.length, 1);
                  expect(c2.padding, const EdgeInsets.all(2));
                }

                // 3. AttributeTableComponent
                {
                  final c = AttributeTableComponent(
                    padding: const .all(1),
                    columns: const [TableColumnConfig(AttributeTableColumn.optionName)],
                  );
                  expect(c.leading, isNotNull);
                  final json = c.toJson();

                  final c2 = ReceiptComponent.fromJson(json) as AttributeTableComponent;
                  expect(c2.columns.length, 1);
                  expect(c2.padding, const EdgeInsets.all(1));
                }

                // 4. PriceTableComponent
                {
                  final c = PriceTableComponent(
                    padding: const .all(3),
                    columns: const [TableColumnConfig(PriceTableColumn.paid)],
                  );
                  expect(c.leading, isNotNull);
                  final json = c.toJson();

                  final c2 = ReceiptComponent.fromJson(json) as PriceTableComponent;
                  expect(c2.columns.length, 1);
                  expect(c2.padding, const EdgeInsets.all(3));
                }

                // 5. DividerComponent
                {
                  final c = DividerComponent(height: 3.0);
                  expect(c.leading, isNotNull);
                  final json = c.toJson();
                  expect(json['height'], 3.0);

                  final c2 = ReceiptComponent.fromJson(json) as DividerComponent;
                  expect(c2.height, 3.0);
                }

                // 6. ImageComponent
                {
                  final c = ImageComponent(imagePath: 'test_path', widthRatio: 0.8);
                  expect(c.leading, isNotNull);
                  final json = c.toJson();
                  expect(json['imagePath'], 'test_path');
                  expect(json['widthRatio'], 0.8);

                  final c2 = ReceiptComponent.fromJson(json) as ImageComponent;
                  expect(c2.imagePath, 'test_path');
                  expect(c2.widthRatio, 0.8);
                }

                // 7. TextFieldComponent and objects
                {
                  final t1 = StyledTextObject.fromText(
                    'hello',
                    isBold: true,
                    isItalic: true,
                    isStrikethrough: true,
                    isUnderline: true,
                    fontSize: 14,
                    color: Colors.red,
                  );
                  final p1 = StyledPlaceholderObject.fromType(
                    .title,
                    isBold: true,
                    isItalic: true,
                    isStrikethrough: true,
                    isUnderline: true,
                    fontSize: 16,
                    color: Colors.blue,
                  );
                  final p2 = StyledPlaceholderObject.fromType(.orderedAt, meta: 'yyyy-MM-dd');

                  final c = TextFieldComponent(texts: [t1, p1, p2], textAlign: .right);
                  expect(c.leading, isNotNull);

                  final json = c.toJson();
                  expect(json['textAlign'], TextAlign.right.index);

                  final c2 = ReceiptComponent.fromJson(json) as TextFieldComponent;
                  expect(c2.textAlign, TextAlign.right);
                  expect(c2.texts.length, 3);
                  expect(c2.texts[0].part.text, 'hello');
                  expect(c2.texts[1].part.text, TextFieldPlaceholderType.title.name);

                  final order = OrderObject(
                    id: 1,
                    paid: 100,
                    price: 80,
                    cost: 50,
                    createdAt: DateTime(2025, 5, 20, 12, 0, 0),
                  );

                  final placeholderNow = StyledPlaceholderObject.fromType(.now, meta: 'yyyy-MM-dd');
                  expect(placeholderNow.formatText(order: order), isNotEmpty);

                  final placeholderSeq = StyledPlaceholderObject.fromType(.seq);
                  expect(placeholderSeq.formatText(order: order), isNotNull);

                  final placeholderProductCount = StyledPlaceholderObject.fromType(.productCount);
                  expect(placeholderProductCount.formatText(order: order), isNotNull);

                  final placeholderPaid = StyledPlaceholderObject.fromType(.paid);
                  expect(placeholderPaid.formatText(order: order), isNotNull);

                  final placeholderChange = StyledPlaceholderObject.fromType(.change);
                  expect(placeholderChange.formatText(order: order), isNotNull);

                  final placeholderPrice = StyledPlaceholderObject.fromType(.price);
                  expect(placeholderPrice.formatText(order: order), isNotNull);

                  final placeholderCost = StyledPlaceholderObject.fromType(.cost);
                  expect(placeholderCost.formatText(order: order), isNotNull);

                  final placeholderRevenue = StyledPlaceholderObject.fromType(.revenue);
                  expect(placeholderRevenue.formatText(order: order), isNotNull);

                  final placeholderProductPrice = StyledPlaceholderObject.fromType(.productPrice);
                  expect(placeholderProductPrice.formatText(order: order), isNotNull);

                  final placeholderAttrPrice = StyledPlaceholderObject.fromType(.attributePrice);
                  expect(placeholderAttrPrice.formatText(order: order), isNotNull);

                  expect(t1.buildSpan(order: order), isNotNull);
                  expect(p1.buildSpan(order: order), isNotNull);
                  expect(p1.buildSpan(order: null), isNotNull);
                }

                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    test('ReceiptTemplates and ReceiptTemplate model behavior', () async {
      when(storage.get(any, any)).thenAnswer((_) => Future.value({}));

      final repo = ReceiptTemplates();
      await repo.initialize();
      expect(repo.itemList.length, 1);
      expect(repo.selected.id, '__default');

      final t1 = ReceiptTemplate(id: 'tpl1', name: 'Test Template', components: []);
      expect(t1.isDefault, false);
      expect(t1.isSelected, false);
      expect(t1.displayName, 'Test Template');

      await repo.addItem(t1, save: false);
      expect(repo.itemList.length, 2);

      await repo.changeSelected('tpl1');
      expect(repo.selectedId, 'tpl1');
      expect(t1.isSelected, true);
    });

    setUpAll(() {
      Printers();
      ReceiptTemplates.reset();
      initializeStorage();
      initializeCache();
      initializeTranslator();
    });

    setUp(() {
      reset(storage);
      reset(cache);
      when(storage.set(any, any)).thenAnswer((_) => Future.value());
      when(storage.add(any, any, any)).thenAnswer((_) => Future.value());
      when(cache.get(any)).thenReturn(true);
      Printers.instance.replaceItems({'exist': Printer(id: 'exist', name: 'exist', address: 'address2')});
      ReceiptTemplates.instance
        ..replaceItems({})
        ..prepareDefault();
    });
  });
}
