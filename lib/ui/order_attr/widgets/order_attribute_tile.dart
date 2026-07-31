import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shrimpai_pos/components/menu_actions.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/components/models/order_attribute_value_widget.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/components/style/outlined_text.dart';
import 'package:shrimpai_pos/components/style/slide_to_delete.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/constants/icons.dart';
import 'package:shrimpai_pos/models/order/order_attribute.dart';
import 'package:shrimpai_pos/models/order/order_attribute_option.dart';
import 'package:shrimpai_pos/routes.dart';
import 'package:shrimpai_pos/translator.dart';

class OrderAttributeTile extends StatelessWidget {
  final OrderAttribute attr;

  const OrderAttributeTile({super.key, required this.attr});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: attr, builder: (context, child) => _buildTile(context));
  }

  Widget _buildTile(BuildContext context) {
    final key = 'order_attributes.${attr.id}';
    final theme = Theme.of(context);
    final subtitle = RichText(
      overflow: .ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: S.orderAttributeMetaMode(S.orderAttributeModeName(attr.mode.name))),
          MetaBlock.span(),
          attr.defaultOption?.name != null
              ? TextSpan(text: S.orderAttributeMetaDefault(attr.defaultOption!.name))
              : TextSpan(
                  text: S.orderAttributeMetaDefault(''),
                  children: [
                    TextSpan(
                      text: S.orderAttributeMetaNoDefault,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
        ],
        // disable parent text style
        style: theme.textTheme.bodyMedium,
      ),
    );

    return ExpansionTile(
      key: Key(key),
      title: Text(attr.name),
      subtitle: subtitle,
      expandedCrossAxisAlignment: .stretch,
      children: <Widget>[
        _buildActions(context),
        const SizedBox(height: kInternalLargeSpacing),
        for (final item in attr.itemList) _OptionTile(item),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: kHorizontalSpacing),
        Expanded(
          child: ElevatedButton.icon(
            key: Key('order_attributes.${attr.id}.add'),
            onPressed: () => context.pushNamed(Routes.orderAttrCreate, queryParameters: {'id': attr.id}),
            label: Text(S.orderAttributeOptionTitleCreate),
            icon: const Icon(KIcons.add),
          ),
        ),
        EntryMoreButton(key: Key('order_attributes.${attr.id}.more'), onPressed: _showActions),
        const SizedBox(width: kHorizontalSpacing),
      ],
    );
  }

  void _showActions(BuildContext context) async {
    await MenuActionGroup.withDelete<int>(
      context,
      deleteValue: 0,
      actions: <MenuAction<int>>[
        MenuAction(
          title: Text(S.orderAttributeTitleUpdate),
          leading: const Icon(KIcons.modal),
          route: Routes.orderAttrUpdate,
          routePathParameters: {'id': attr.id},
        ),
        MenuAction(
          title: Text(S.orderAttributeOptionTitleReorder),
          leading: const Icon(KIcons.reorder),
          route: Routes.orderAttrReorderOption,
          routePathParameters: {'id': attr.id},
        ),
      ],
      warningContent: S.dialogDeletionContent(attr.name, ''),
      deleteCallback: () => attr.remove(),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final OrderAttributeOption option;

  const _OptionTile(this.option);

  @override
  Widget build(BuildContext context) {
    return SlideToDelete(
      item: option,
      deleteCallback: _remove,
      warningContent: S.dialogDeletionContent(option.name, ''),
      child: ListTile(
        key: Key('order_attributes.${option.repository.id}.${option.id}'),
        title: Text(option.name),
        subtitle: OrderAttributeValueWidget.build(option.mode, option.modeValue),
        trailing: option.isDefault ? OutlinedText(S.orderAttributeOptionMetaDefault) : null,
        onLongPress: () => MenuActionGroup.withDelete<int>(
          context,
          deleteValue: 0,
          warningContent: S.dialogDeletionContent(option.name, ''),
          deleteCallback: _remove,
        ),
        onTap: () => context.pushNamed(
          Routes.orderAttrUpdate,
          pathParameters: {'id': option.attribute.id},
          queryParameters: {'oid': option.id},
        ),
      ),
    );
  }

  Future<void> _remove() => option.remove();
}
