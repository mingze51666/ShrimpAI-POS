import 'package:flutter/material.dart';
import 'package:possystem/helpers/logger.dart';
import 'package:possystem/models/objects/receipt_template_object.dart';
import 'package:possystem/models/repository.dart';
import 'package:possystem/models/repository/receipt_template.dart';
import 'package:possystem/services/storage.dart';

const _defaultId = '__default';

class ReceiptTemplates extends ChangeNotifier with Repository<ReceiptTemplate>, RepositoryStorage<ReceiptTemplate> {
  static late ReceiptTemplates instance;

  @override
  final Stores storageStore = .receiptTemplates;

  @override
  RepositoryStorageType get repoType => .repoModel;

  String? selectedId;

  ReceiptTemplates() {
    instance = this;
  }

  @visibleForTesting
  static reset() {
    ReceiptTemplates()._prepareDefault();
  }

  @override
  Future<void> initialize({String? record}) async {
    await super.initialize(record: record);

    final data = await Storage.instance.get(storageStore, 'setting');
    selectedId = data['selectedId'] as String?;

    _prepareDefault();
  }

  /// Get the current enabled template
  ReceiptTemplate get selected => getItem(selectedId ?? _defaultId)!;

  @override
  ReceiptTemplate buildItem(String id, Map<String, Object?> value) {
    return ReceiptTemplate.fromObject(ReceiptTemplateObject.build({'id': id, ...value}));
  }

  Future<void> changeSelected(String id) async {
    selectedId = id;
    await _saveProperties();
  }

  void _prepareDefault() async {
    await addItem(
      ReceiptTemplate(id: _defaultId, name: '', components: ReceiptTemplate.getDefaultComponents()),
      save: false,
    );
  }

  Future<void> _saveProperties() async {
    Log.ger('update_repo', {'type': storageStore.name});

    await Storage.instance.set(storageStore, {
      'setting': {'selectedId': selectedId},
    });

    notifyListeners();
  }
}
