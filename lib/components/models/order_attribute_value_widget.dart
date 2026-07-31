import 'package:flutter/material.dart';
import 'package:shrimpai_pos/components/style/hint_text.dart';
import 'package:shrimpai_pos/helpers/util.dart';
import 'package:shrimpai_pos/models/objects/order_attribute_object.dart';
import 'package:shrimpai_pos/translator.dart';

class OrderAttributeValueWidget {
  static Widget? build(OrderAttributeMode? mode, num? value) {
    if (value == null || mode == null || mode == .statOnly) {
      return null;
    }

    final name = string(mode, value);
    return name == '' ? HintText(S.orderAttributeValueEmpty) : Text(name);
  }

  static String string(OrderAttributeMode mode, num value) {
    final modeValue = value;
    if (mode == .changeDiscount) {
      final value = modeValue.toInt();
      return value == 0 ? S.orderAttributeValueFree : 'x $value%';
    } else {
      final value = modeValue.toCurrency();
      return modeValue == 0
          ? ''
          : modeValue > 0
          ? '+ \$$value'
          : '- \$$value';
    }
  }
}
