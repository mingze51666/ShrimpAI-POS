import 'package:flutter/foundation.dart';
import 'package:shrimpai_pos/models/analysis/chart.dart';
import 'package:shrimpai_pos/models/analysis/chart_object.dart';
import 'package:shrimpai_pos/models/repository.dart';
import 'package:shrimpai_pos/services/storage.dart';

class Analysis extends ChangeNotifier with Repository<Chart>, RepositoryStorage<Chart>, RepositoryOrderable<Chart> {
  static late Analysis instance;

  @override
  final Stores storageStore = .analysis;

  Analysis() {
    instance = this;
  }

  @override
  Chart buildItem(String id, Map<String, Object?> value) {
    return Chart.fromObject(ChartObject.build({'id': id, ...value}));
  }
}
