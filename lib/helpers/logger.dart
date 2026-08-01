import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shrimpai_pos/constants/constant.dart';

const _isDebug = kDebugMode || isLocalTest;

class Log {
  static Future<void>? current;

  static void out(String msg, String code, {Object? error, StackTrace? stackTrace}) {
    developer.log(msg, name: code, error: error, stackTrace: stackTrace);
  }

  static void ger(String event, [Map<String, Object?>? parameters, @visibleForTesting bool forceSend = false]) async {
    assert(!event.contains('.'), 'should not contain "."');
    final message = parameters?.entries.map((e) => '${e.key}=${e.value}').join(' ');
    Log.out(message ?? '', event);
  }

  static void err(Object error, String code, [StackTrace? stackTrace, @visibleForTesting bool forceSend = false]) {
    assert(() {
      errorCount++;
      return !code.contains('.');
    }());
    out(error.toString(), code, error: error, stackTrace: stackTrace);
  }

  // no need send event in debug mode
  static bool _allowSendEvents = !_isDebug;
  static bool get allowSendEvents => _allowSendEvents;
  static set allowSendEvents(bool value) => _allowSendEvents = _isDebug ? false : value;

  @visibleForTesting
  static int errorCount = 0;
}
