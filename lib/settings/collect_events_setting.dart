import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shrimpai_pos/helpers/logger.dart';
import 'package:shrimpai_pos/settings/setting.dart';

class CollectEventsSetting extends Setting<bool> {
  static final CollectEventsSetting instance = ._();

  static const defaultValue = true;

  CollectEventsSetting._() {
    value = defaultValue;
  }

  @override
  String get key => 'feat.collectEvents';

  @override
  void initialize() {
    value = service.get<bool>(key) ?? defaultValue;
  }

  @override
  Future<void> updateRemotely(bool data) async {
    Log.allowSendEvents = data;

    // Do it first to make testing easier, because the rest future will not
    // complete.
    await service.set<bool>(key, data);
    // 🔧 Web 端无 Firebase 时跳过，避免崩溃（2026-08-01）
    if (!kIsWeb) {
      await Future.wait([
        FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(data),
        FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(data),
      ]);
    }
  }
}
