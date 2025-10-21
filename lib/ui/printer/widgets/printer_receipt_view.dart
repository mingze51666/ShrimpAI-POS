import 'package:flutter/material.dart';
import 'package:possystem/components/imageable_container.dart';
import 'package:possystem/helpers/logger.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/receipt_component.dart';
import 'package:possystem/models/repository/receipt_templates.dart';
import 'package:possystem/models/xfile.dart';
import 'package:possystem/translator.dart';

const _defaultTextColor = Color(0xFF424242);

class PrinterReceiptView extends StatelessWidget {
  final OrderObject order;
  final ImageableController? controller;
  final List<ReceiptComponent>? customComponents;

  const PrinterReceiptView({super.key, required this.order, this.controller, this.customComponents});

  @override
  Widget build(BuildContext context) {
    // Use custom components if provided, otherwise use default from repository
    final components = customComponents ?? ReceiptTemplates.instance.selected.components;

    final children = components
        .map((component) => Padding(padding: component.padding, child: _buildComponent(component, context)))
        .whereType<Widget>()
        .toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: .noScaling),
      child: SizedBox(
        // wider width can result low density of receipt, since the paper
        // is fixed width (58mm or 80mm).
        width: 320, // fixed width can provide same density of receipt
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(height: 1.8, overflow: .clip, color: _defaultTextColor),
          child: controller == null
              ? Column(mainAxisSize: .min, children: children)
              : ImageableContainer(controller: controller!, children: children),
        ),
      ),
    );
  }

  Widget? _buildComponent(ReceiptComponent component, BuildContext context) {
    final theme = Theme.of(context);
    final attributes = order.effectiveAttributes.toList();

    switch (component.type) {
      case .textField:
        final c = component as TextFieldComponent;
        return Text.rich(
          TextSpan(children: c.texts.map((e) => e.buildSpan(order: order)).toList()),
          textAlign: c.textAlign,
          style: const TextStyle(height: 1.2),
        );
      case .divider:
        final c = component as DividerComponent;
        return Divider(height: c.height);
      case .image:
        final c = component as ImageComponent;
        return AspectRatio(
          aspectRatio: c.widthRatio,
          child: Image(
            fit: .cover,
            errorBuilder: (context, error, stackTrace) {
              Log.out('reading image failed', 'image_error', error: error, stackTrace: stackTrace);
              return Container(
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_outlined, color: Colors.grey[500], size: 40),
              );
            },
            image: FileImage(XFile(c.imagePath).file),
          ),
        );
      case .orderTable:
        final c = component as OrderTableComponent;
        return PrinterReceiptView.buildOrderTable(c, order, theme.colorScheme);
      case .discountTable:
        if (order.discounted.isNotEmpty) {
          final c = component as DiscountTableComponent;
          return PrinterReceiptView.buildDiscountTable(c, order.discounted.toList());
        }
        return null;
      case .attributeTable:
        if (attributes.isNotEmpty) {
          final c = component as AttributeTableComponent;
          return PrinterReceiptView.buildAttributesTable(c, attributes);
        }
        return null;
      case .priceTable:
        final c = component as PriceTableComponent;
        return PrinterReceiptView.buildPriceTable(c, order);
    }
  }

  static String getProductName(
    OrderProductObject product, {
    bool showProductName = false,
    bool showCatalogName = false,
  }) {
    if (!showProductName) {
      return product.catalogName;
    }

    if (!showCatalogName) {
      return product.productName;
    }

    return '${product.productName}(${product.catalogName})';
  }

  static Widget buildOrderTable(OrderTableComponent config, OrderObject order, ColorScheme color) {
    final columns = <int, TableColumnWidth>{};
    final headers = <Widget>[];
    int colIndex = 0;

    if (config.showProductName || config.showCatalogName) {
      columns[colIndex++] = const FlexColumnWidth();
      headers.add(TableCell(child: Text(S.printerReceiptProductTableName)));
    }
    if (config.showQuantity) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.1), IntrinsicColumnWidth());
      headers.add(TableCell(child: Text(S.printerReceiptProductTableCount, textAlign: .end)));
    }
    if (config.showSinglePrice) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.1), IntrinsicColumnWidth());
      headers.add(TableCell(child: Text(S.printerReceiptProductTablePrice, textAlign: .end)));
    }
    if (config.showTotalPrice) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.2), IntrinsicColumnWidth());
      headers.add(TableCell(child: Text(S.printerReceiptProductTableTotal, textAlign: .end)));
    }

    return Table(
      defaultVerticalAlignment: .middle,
      columnWidths: columns,
      border: TableBorder(
        horizontalInside: BorderSide(color: color.outlineVariant),
        top: BorderSide(color: color.outline),
        bottom: BorderSide(color: color.outline),
      ),
      children: [
        TableRow(children: headers),
        for (final product in order.products)
          TableRow(
            children: [
              if (config.showProductName || config.showCatalogName)
                TableCell(
                  child: Text(
                    PrinterReceiptView.getProductName(
                      product,
                      showProductName: config.showProductName,
                      showCatalogName: config.showCatalogName,
                    ),
                  ),
                ),
              if (config.showQuantity) TableCell(child: Text(product.count.toString(), textAlign: .end)),
              if (config.showSinglePrice)
                TableCell(child: Text('\$${product.singlePrice.toCurrency()}', textAlign: .end)),
              if (config.showTotalPrice)
                TableCell(child: Text('\$${product.totalPrice.toCurrency()}', textAlign: .end)),
            ],
          ),
      ],
    );
  }

  static Widget buildDiscountTable(DiscountTableComponent config, List<OrderProductObject> discounted) {
    final columns = <int, TableColumnWidth>{0: const FlexColumnWidth()};
    final headers = <Widget>[TableCell(child: Text(S.printerReceiptDiscountTableTitle))];
    int colIndex = 1;
    const numberStyle = TextStyle(fontSize: 12);

    if (config.showQuantity) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.1), IntrinsicColumnWidth());
      headers.add(
        TableCell(
          child: Padding(
            padding: const .only(left: 4.0),
            child: Text(S.printerReceiptDiscountTableCount, textAlign: .end),
          ),
        ),
      );
    }
    if (config.showOriginPrice) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.1), IntrinsicColumnWidth());
      headers.add(
        TableCell(
          child: Padding(
            padding: const .only(left: 4.0),
            child: Text(S.printerReceiptDiscountTableOrigin, textAlign: .end),
          ),
        ),
      );
    }
    if (config.showSinglePrice) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.1), IntrinsicColumnWidth());
      headers.add(
        TableCell(
          child: Padding(
            padding: const .only(left: 4.0),
            child: Text(S.printerReceiptDiscountTablePrice, textAlign: .end),
          ),
        ),
      );
    }
    if (config.showTotalPrice) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.2), IntrinsicColumnWidth());
      headers.add(TableCell(child: Text(S.printerReceiptDiscountTableTotal, textAlign: .end)));
    }

    return Table(
      defaultVerticalAlignment: .middle,
      columnWidths: columns,
      border: TableBorder.all(width: 0, color: Colors.transparent),
      children: [
        TableRow(children: headers),
        for (final product in discounted)
          TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const .only(left: 8),
                  child: Text(
                    config.showProductName || config.showCatalogName
                        ? PrinterReceiptView.getProductName(
                            product,
                            showProductName: config.showProductName,
                            showCatalogName: config.showCatalogName,
                          )
                        : '',
                  ),
                ),
              ),
              if (config.showQuantity)
                TableCell(
                  child: Padding(
                    padding: const .only(left: 4.0),
                    child: Text(product.count.toString(), style: numberStyle, textAlign: .end),
                  ),
                ),
              if (config.showOriginPrice)
                TableCell(
                  child: Padding(
                    padding: const .only(left: 4.0),
                    child: Text('\$${product.originalPrice.toCurrency()}', style: numberStyle, textAlign: .end),
                  ),
                ),
              if (config.showSinglePrice)
                TableCell(
                  child: Padding(
                    padding: const .only(left: 4.0),
                    child: Text('\$${product.singlePrice.toCurrency()}', style: numberStyle, textAlign: .end),
                  ),
                ),
              if (config.showTotalPrice)
                TableCell(
                  child: Text('\$${product.totalPrice.toCurrency()}', style: numberStyle, textAlign: .end),
                ),
            ],
          ),
      ],
    );
  }

  static Widget buildAttributesTable(AttributeTableComponent config, List<OrderEffectiveAttribute> attributes) {
    final columns = <int, TableColumnWidth>{0: const FlexColumnWidth()};
    final headers = <Widget>[TableCell(child: Text(S.printerReceiptAttributeTableTitle))];
    int colIndex = 1;
    const numberStyle = TextStyle(fontSize: 12);

    if (config.showAdjustment) {
      columns[colIndex++] = const MaxColumnWidth(FractionColumnWidth(0.2), IntrinsicColumnWidth());
      headers.add(TableCell(child: Text(S.printerReceiptAttributeTableAdjustment, textAlign: .end)));
    }

    return Table(
      defaultVerticalAlignment: .middle,
      columnWidths: columns,
      border: TableBorder.all(width: 0, color: Colors.transparent),
      children: [
        TableRow(children: headers),
        for (final attribute in attributes)
          TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const .only(left: 8),
                  child: Text(
                    config.showName || config.showOptionName
                        ? [
                            if (config.showName) attribute.name,
                            if (config.showOptionName) attribute.optionName,
                          ].join(' - ')
                        : '',
                  ),
                ),
              ),
              if (config.showAdjustment)
                TableCell(
                  child: Text(attribute.priceChanged, style: numberStyle, textAlign: .end),
                ),
            ],
          ),
      ],
    );
  }

  static Widget buildPriceTable(PriceTableComponent config, OrderObject order) {
    const subtitle = TextStyle(fontSize: 12, height: 1.2);
    final subtitles = <List<String>>[
      if (config.showProductsQuantity) [S.printerReceiptPriceTableProductsQuantity, order.productsCount.toString()],
      if (config.showProductsPrice) [S.printerReceiptPriceTableProductsPrice, '\$${order.productsPrice.toCurrency()}'],
      if (config.showPrice) [S.printerReceiptPriceTablePrice, '\$${order.price.toCurrency()}'],
      if (config.showChange) [S.printerReceiptPriceTableChange, '\$${order.change.toCurrency()}'],
    ];

    return Column(
      mainAxisSize: .min,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(S.printerReceiptPriceTableTotal),
            Text('\$${order.price.toCurrency()}', style: const TextStyle(fontSize: 22, height: 1.2)),
          ],
        ),
        if (subtitles.isNotEmpty || config.showPaid) ...[
          const Divider(height: 4),
          if (config.showPaid)
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(S.printerReceiptPriceTablePaid, style: subtitle),
                Text('\$${order.paid.toCurrency()}', style: subtitle),
              ],
            ),
          if (subtitles.isNotEmpty)
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Padding(
                  padding: const .only(left: 8),
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: subtitles.map((e) => Text(e[0], style: subtitle)).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .end,
                  children: subtitles.map((e) => Text(e[1], style: subtitle)).toList(),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
