import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/helpers/util.dart';
import 'package:shrimpai_pos/models/repository/cart.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/order/cart/cart_actions.dart';
import 'package:provider/provider.dart';

class CartMetadataView extends StatelessWidget {
  const CartMetadataView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();

    return Row(
      children: <Widget>[
        const SizedBox(width: 16.0),
        const CartActions(),
        const SizedBox(width: 16.0),
        Expanded(
          key: const Key('cart.metadata'),
          child: MetaBlock.withString(context, <String>[
            S.orderCartMetaTotalCount(cart.productCount),
            S.orderCartMetaTotalPrice(cart.productsPrice.toCurrency()),
          ])!,
        ),
        const SizedBox(width: 16.0),
      ],
    );
  }
}
