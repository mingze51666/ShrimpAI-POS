import 'package:flutter/material.dart';
import 'package:shrimpai_pos/models/objects/stock_object.dart';
import 'package:shrimpai_pos/models/repository.dart';
import 'package:shrimpai_pos/models/repository/stock.dart';
import 'package:shrimpai_pos/models/stock/replenishment.dart';
import 'package:shrimpai_pos/services/storage.dart';

class Replenisher extends ChangeNotifier with Repository<Replenishment>, RepositoryStorage<Replenishment> {
  static late Replenisher instance;

  @override
  final Stores storageStore = .replenisher;

  Replenisher() {
    instance = this;
  }

  @override
  void abortStaged() {
    super.abortStaged();
    Stock.instance.abortStaged();
  }

  @override
  Replenishment buildItem(String id, Map<String, Object?> value) {
    return Replenishment.fromObject(ReplenishmentObject.build({'id': id, ...value}));
  }

  @override
  Future<void> commitStaged({bool save = true, bool reset = true}) async {
    await Stock.instance.commitStaged(reset: false);
    await super.commitStaged();
  }
}

enum ReplenishBy { quantity, price }
