import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/menu_actions.dart';
import 'package:shrimpai_pos/components/slidable_item_list.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/constants/icons.dart';
import 'package:shrimpai_pos/models/repository/menu.dart';
import 'package:shrimpai_pos/models/stock/quantity.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';

class StockQuantityList extends StatelessWidget {
  final List<Quantity> quantities;

  final Widget leading;

  const StockQuantityList({super.key, required this.quantities, required this.leading});

  @override
  Widget build(BuildContext context) {
    return SlidableItemList<Quantity, int>(
      leading: leading,
      delegate: SlidableItemDelegate(
        items: quantities,
        deleteValue: 0,
        tileBuilder: (item, _, actorBuilder) => _Tile(item, actorBuilder),
        warningContentBuilder: _warningContentBuilder,
        handleDelete: _handleDelete,
        actionBuilder: (quantity) => [
          MenuAction(
            key: const Key('btn.edit'),
            title: Text(S.menuQuantityTitleUpdate),
            leading: const Icon(KIcons.edit),
            route: Routes.quantityUpdate,
            routePathParameters: {'id': quantity.id},
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(Quantity quantity) async {
    await quantity.remove();
    return Menu.instance.removeQuantities(quantity.id);
  }

  String _warningContentBuilder(BuildContext context, Quantity quantity) {
    final count = Menu.instance.getQuantities(quantity.id).length;
    final more = S.stockQuantityDialogDeletionContent(count);

    return S.dialogDeletionContent(quantity.name, '$more\n\n');
  }
}

class _Tile extends StatelessWidget {
  final Quantity item;
  final ActorBuilder actorBuilder;

  const _Tile(this.item, this.actorBuilder);

  @override
  Widget build(BuildContext context) {
    final actor = actorBuilder(context);
    return ListTile(
      key: Key('quantities.${item.id}'),
      title: Text(item.name),
      subtitle: Text(S.stockQuantityMetaProportion(item.defaultProportion)),
      trailing: EntryMoreButton(onPressed: actor),
      onLongPress: actor,
      onTap: () => context.pushNamed(Routes.quantityUpdate, pathParameters: {'id': item.id}),
    );
  }
}
