import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/scaffold/reorderable_scaffold.dart';
import 'package:shrimpai_pos/models/order/order_attribute.dart';
import 'package:shrimpai_pos/models/repository/order_attributes.dart';
import 'package:shrimpai_pos/translator.dart';

class OrderAttributeReorder extends StatelessWidget {
  const OrderAttributeReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: OrderAttributes.instance.itemList,
      title: S.orderAttributeTitleReorder,
      handleSubmit: (List<OrderAttribute> items) => OrderAttributes.instance.reorderItems(items),
    );
  }
}
