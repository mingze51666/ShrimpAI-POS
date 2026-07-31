import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shrimpai_pos/models/objects/stock_object.dart';
import 'package:shrimpai_pos/models/repository.dart';
import 'package:shrimpai_pos/models/stock/quantity.dart';
import 'package:shrimpai_pos/services/storage.dart';

class Quantities extends ChangeNotifier
    with Repository<Quantity>, RepositoryStorage<Quantity>, RepositorySearchable<Quantity> {
  static late Quantities instance;

  @override
  final Stores storageStore = .quantities;

  Quantities() {
    instance = this;
  }

  @override
  Quantity buildItem(String id, Map<String, Object?> value) {
    return Quantity.fromObject(QuantityObject.build({'id': id, ...value}));
  }

  @override
  void addStaged(Quantity item) {
    if (stagedItems.firstWhereOrNull((e) => e.name == item.name) == null) {
      super.addStaged(item);
    }
  }

  @override
  Future<void> commitStaged({bool save = true, bool reset = true}) {
    // Avoid reset since it will effect Menu
    return super.commitStaged(save: save, reset: false);
  }
}
