import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/scaffold/reorderable_scaffold.dart';
import 'package:shrimpai_pos/models/menu/catalog.dart';
import 'package:shrimpai_pos/models/repository/menu.dart';
import 'package:shrimpai_pos/translator.dart';

class CatalogReorder extends StatelessWidget {
  const CatalogReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: Menu.instance.itemList,
      title: S.menuCatalogTitleReorder,
      handleSubmit: (List<Catalog> items) => Menu.instance.reorderItems(items),
    );
  }
}
