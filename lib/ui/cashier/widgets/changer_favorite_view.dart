import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/components/slidable_item_list.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/components/style/empty_body.dart';
import 'package:shrimpai_pos/components/style/hint_text.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/helpers/util.dart';
import 'package:shrimpai_pos/models/objects/cashier_object.dart';
import 'package:shrimpai_pos/models/repository/cashier.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:provider/provider.dart';

class ChangerFavoriteView extends StatelessWidget {
  final VoidCallback emptyAction;
  final ValueNotifier<FavoriteItem?> selectedItem;

  const ChangerFavoriteView({super.key, required this.emptyAction, required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    context.watch<Cashier>();

    if (Cashier.instance.favoriteIsEmpty) {
      return EmptyBody(content: S.cashierChangerFavoriteEmptyBody, onPressed: emptyAction);
    }

    final delegate = SlidableItemDelegate<FavoriteItem, int>(
      items: Cashier.instance.favoriteItems.toList(),
      deleteValue: 0,
      handleDelete: (item) => handleDeletion(item.index),
      tileBuilder: (item, index, actorBuilder) => _Tile(item, actorBuilder, selectedItem),
    );

    return ValueListenableBuilder(
      valueListenable: selectedItem,
      builder: (context, value, child) {
        // return RadioGroup<FavoriteItem?>(
        //   groupValue: value,
        //   onChanged: (selected) => selectedItem.value = selected,
        //   child: Column(children: [
        return Column(
          children: [
            const SizedBox(height: kTopSpacing),
            HintText(S.cashierChangerFavoriteHint),
            const SizedBox(height: kInternalSpacing),
            for (final item in delegate.items) delegate.build(item, item.index),
            const SizedBox(height: kFABSpacing),
          ],
        );
        //   ]),
        // );
      },
    );
  }

  Future<void> handleDeletion(int index) async {
    await Cashier.instance.deleteFavorite(index);

    selectedItem.value = null;
  }
}

class _Tile extends StatelessWidget {
  final FavoriteItem item;
  final ActorBuilder actorBuilder;
  final ValueNotifier<FavoriteItem?> selectedItem;

  const _Tile(this.item, this.actorBuilder, this.selectedItem);

  @override
  Widget build(BuildContext context) {
    final actor = actorBuilder(context);
    return InkWell(
      onLongPress: actor,
      child: RadioListTile<FavoriteItem?>(
        key: Key('changer.favorite.${item.index}'),
        value: item,
        // TODO: change to RadioGroup when it is stable, see
        // https://github.com/flutter/flutter/issues/175258
        // ignore: deprecated_member_use
        groupValue: selectedItem.value,
        // ignore: deprecated_member_use
        onChanged: (value) => selectedItem.value = value,
        title: Text(S.cashierChangerFavoriteItemFrom(item.source.count!, item.source.unit!.toCurrency())),
        subtitle: MetaBlock.withString(
          context,
          item.targets.map<String>((e) => S.cashierChangerFavoriteItemTo(e.count!, e.unit!.toCurrency())),
          textOverflow: .visible,
        ),
        secondary: EntryMoreButton(onPressed: actor),
      ),
    );
  }
}
