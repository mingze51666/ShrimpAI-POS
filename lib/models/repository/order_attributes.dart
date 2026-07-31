import 'package:flutter/foundation.dart';
import 'package:shrimpai_pos/models/objects/order_attribute_object.dart';
import 'package:shrimpai_pos/models/order/order_attribute.dart';
import 'package:shrimpai_pos/services/storage.dart';

import '../repository.dart';

class OrderAttributes extends ChangeNotifier
    with Repository<OrderAttribute>, RepositoryOrderable<OrderAttribute>, RepositoryStorage<OrderAttribute> {
  static late OrderAttributes instance;

  @override
  final Stores storageStore = .orderAttributes;

  OrderAttributes() {
    instance = this;
  }

  List<OrderAttribute> get notEmptyItems => itemList.where((item) => item.isNotEmpty).toList();

  @override
  OrderAttribute buildItem(String id, Map<String, Object?> value) {
    return OrderAttribute.fromObject(OrderAttributeObject.build({'id': id, ...value}));
  }
}
