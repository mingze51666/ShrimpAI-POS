import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/menu_actions.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/components/style/route_buttons.dart';
import 'package:shrimpai_pos/components/style/slide_to_delete.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/constants/icons.dart';
import 'package:shrimpai_pos/helpers/util.dart';
import 'package:shrimpai_pos/models/menu/product_ingredient.dart';
import 'package:shrimpai_pos/models/menu/product_quantity.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';

class ProductIngredientView extends StatelessWidget {
  final ProductIngredient ingredient;

  const ProductIngredientView(this.ingredient, {super.key});

  @override
  Widget build(BuildContext context) {
    final key = 'product_ingredient.${ingredient.id}';
    return ExpansionTile(
      key: Key(key),
      title: Text(ingredient.name),
      subtitle: Text(S.menuIngredientMetaAmount(ingredient.amount)),
      expandedCrossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: kHorizontalSpacing),
            Expanded(
              child: RouteElevatedIconButton(
                key: Key('$key.add'),
                icon: const Icon(KIcons.add),
                label: S.menuQuantityTitleCreate,
                route: Routes.menuProductUpdateIngredient,
                pathParameters: {'id': ingredient.product.id},
                queryParameters: {'iid': ingredient.id, 'qid': ''},
              ),
            ),
            EntryMoreButton(key: Key('$key.more'), onPressed: showActions),
            const SizedBox(width: kHorizontalSpacing),
          ],
        ),
        for (final item in ingredient.items) _QuantityTile(item),
      ],
    );
  }

  void showActions(BuildContext context) {
    MenuActionGroup.withDelete<int>(
      context,
      deleteValue: 0,
      actions: <MenuAction<int>>[
        MenuAction(
          title: Text(S.menuIngredientTitleUpdate),
          leading: const Icon(KIcons.modal),
          route: Routes.menuProductUpdateIngredient,
          routePathParameters: {'id': ingredient.product.id},
          routeQueryParameters: {'iid': ingredient.id},
        ),
      ],
      warningContent: S.dialogDeletionContent(ingredient.name, ''),
      deleteCallback: () => ingredient.remove(),
    );
  }
}

class _QuantityTile extends StatelessWidget {
  final ProductQuantity quantity;

  const _QuantityTile(this.quantity);

  @override
  Widget build(BuildContext context) {
    return SlideToDelete(
      item: quantity,
      deleteCallback: _remove,
      warningContent: S.dialogDeletionContent(quantity.name, ''),
      child: ListTile(
        key: Key('product_quantity.${quantity.id}'),
        title: Text(quantity.name),
        subtitle: MetaBlock.withString(context, <String>[
          S.menuQuantityMetaAmount(quantity.amount),
          S.menuQuantityMetaAdditionalPrice(quantity.additionalPrice.toCurrency()),
          S.menuQuantityMetaAdditionalCost(quantity.additionalCost.toCurrency()),
        ]),
        onLongPress: () => MenuActionGroup.withDelete<int>(
          context,
          deleteValue: 0,
          warningContent: S.dialogDeletionContent(quantity.name, ''),
          deleteCallback: _remove,
        ),
        onTap: () => context.pushNamed(
          Routes.menuProductUpdateIngredient,
          pathParameters: {'id': quantity.ingredient.product.id},
          queryParameters: {'iid': quantity.ingredient.id, 'qid': quantity.id},
        ),
      ),
    );
  }

  Future<void> _remove() => quantity.remove();
}
