import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/scaffold/reorderable_scaffold.dart';
import 'package:shrimpai_pos/models/menu/product.dart';
import 'package:shrimpai_pos/models/menu/product_ingredient.dart';
import 'package:shrimpai_pos/translator.dart';

class ProductIngredientReorder extends StatelessWidget {
  final Product product;

  const ProductIngredientReorder(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: product.itemList,
      title: S.menuIngredientTitleReorder,
      handleSubmit: (List<ProductIngredient> items) => product.reorderItems(items),
    );
  }
}
