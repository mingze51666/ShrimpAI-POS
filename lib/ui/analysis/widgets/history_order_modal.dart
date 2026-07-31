import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shrimpai_pos/components/dialog/responsive_dialog.dart';
import 'package:shrimpai_pos/components/menu_actions.dart';
import 'package:shrimpai_pos/components/meta_block.dart';
import 'package:shrimpai_pos/components/style/buttons.dart';
import 'package:shrimpai_pos/components/style/hint_text.dart';
import 'package:shrimpai_pos/components/style/snackbar.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/helpers/util.dart';
import 'package:shrimpai_pos/models/objects/order_object.dart';
import 'package:shrimpai_pos/models/repository/seller.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:shrimpai_pos/ui/order/widgets/order_object_view.dart';

class HistoryOrderModal extends StatefulWidget {
  final int orderId;

  const HistoryOrderModal(this.orderId, {super.key});

  @override
  State<HistoryOrderModal> createState() => _HistoryOrderModalState();
}

class _HistoryOrderModalState extends State<HistoryOrderModal> {
  String? createdAt;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: Text(S.analysisHistoryOrderTitle),
      scrollable: false,
      content: FutureBuilder<OrderObject?>(
        future: Seller.instance.getOrder(widget.orderId),
        builder: Util.handleSnapshot((context, order) {
          if (order == null) {
            createdAt = null;
            return Center(child: Text(S.analysisHistoryOrderNotFound));
          }

          createdAt =
              S.analysisHistoryOrderListMetaNo(order.periodSeq.toString()) +
              MetaBlock.string +
              DateFormat.MMMEd(S.localeName).format(order.createdAt) +
              MetaBlock.string +
              DateFormat.Hms(S.localeName).format(order.createdAt);
          return Column(
            children: [
              Padding(
                padding: const .fromLTRB(kHorizontalSpacing, 0, kHorizontalSpacing, kInternalSpacing),
                child: Row(
                  children: [
                    Expanded(child: Center(child: HintText(createdAt!))),
                    MoreButton(key: const Key('order_modal.more'), onPressed: _showActions),
                  ],
                ),
              ),
              Expanded(child: OrderObjectView(order: order)),
            ],
          );
        }),
      ),
    );
  }

  void _showActions(BuildContext context) async {
    if (createdAt != null) {
      await MenuActionGroup.withDelete<_Action>(
        context,
        deleteValue: _Action.delete,
        popAfterDeleted: true,
        deleteCallback: () =>
            showSnackbarWhenFutureError(Seller.instance.delete(widget.orderId), 'analysis_deletion', context: context),
        warningContent: S.analysisHistoryOrderDeleteDialog(createdAt!),
      );
    }
  }
}

enum _Action { delete }
