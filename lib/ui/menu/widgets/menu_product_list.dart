import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/menu_actions.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/components/slidable_item_list.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/components/style/route_buttons.dart';
import 'package:shrimpai_pos/constants/icons.dart';
import 'package:shrimpai_pos/models/menu/catalog.dart';
import 'package:shrimpai_pos/models/menu/product.dart';
import 'package:shrimpai_pos/models/repository/menu.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';

class MenuProductList extends StatelessWidget {
  final Catalog? catalog;

  final Widget? leading;

  const MenuProductList({super.key, required this.catalog, this.leading});

  @override
  Widget build(BuildContext context) {
    return SlidableItemList(
      leading: leading,
      action: RouteIconButton(
        label: S.menuProductTitleReorder,
        icon: const Icon(KIcons.reorder),
        route: Routes.menuProductReorder,
        pathParameters: {'id': catalog?.id ?? ''},
        hideLabel: true,
      ),
      delegate: SlidableItemDelegate<Product, int>(
        items: catalog?.itemList ?? Menu.instance.products.toList(),
        deleteValue: 0,
        actionBuilder: _actionBuilder,
        tileBuilder: (product, _, actorBuilder) => _Tile(product, actorBuilder),
        warningContentBuilder: (context, product) => S.dialogDeletionContent(product.name, ''),
        handleDelete: (item) => item.remove(),
      ),
    );
  }

  Iterable<MenuAction<int>> _actionBuilder(Product product) {
    return <MenuAction<int>>[
      MenuAction(
        title: Text(S.menuProductTitleUpdate),
        leading: const Icon(KIcons.modal),
        route: Routes.menuProductUpdate,
        routePathParameters: {'id': product.id},
      ),
      MenuAction(
        title: Text(S.menuIngredientTitleReorder),
        leading: const Icon(KIcons.reorder),
        route: Routes.menuProductReorderIngredient,
        routePathParameters: {'id': product.id},
      ),
    ];
  }
}

class _Tile extends StatelessWidget {
  final Product product;
  final ActorBuilder actorBuilder;

  const _Tile(this.product, this.actorBuilder);

  @override
  Widget build(BuildContext context) {
    final actor = actorBuilder(context);
    return ListTile(
      key: Key('product.${product.id}'),
      leading: product.avator,
      title: Text(product.name),
      trailing: EntryMoreButton(onPressed: actor),
      subtitle: MetaBlock.withString(
        context,
        product.items.map((e) => e.name),
        emptyText: S.menuProductEmptyIngredients,
      ),
      onLongPress: actor,
      onTap: () => context.pushNamed(Routes.menuProduct, pathParameters: {'id': product.id}),
    );
  }
}
