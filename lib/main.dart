import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/models/analysis/analysis.dart';
import 'package:shrimpai_pos/models/printer.dart';
import 'package:shrimpai_pos/models/repository/cart.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_compatible_options.dart';
import 'helpers/logger.dart';
import 'models/repository/cashier.dart';
import 'models/repository/menu.dart';
import 'models/repository/order_attributes.dart';
import 'models/repository/quantities.dart';
import 'models/repository/replenisher.dart';
import 'models/repository/seller.dart';
import 'models/repository/stock.dart';
import 'services/cache.dart';
import 'services/database.dart';
import 'services/firebase_guard.dart';
import 'services/storage.dart';
import 'settings/collect_events_setting.dart';
import 'settings/settings_provider.dart';

void main() async {
  // Not all errors are caught by Flutter. Sometimes, errors are instead caught by Zones.
  await runZonedGuarded<Future<void>>(() async {
    // https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    // 🔧 平台标志（2026-08-01）
    FirebaseGuard.init(isWeb: kIsWeb);

    // 🔧 真机容错：Firebase 占位配置可能导致初始化崩溃，失败时优雅跳过
    // （Web 端无 Firebase；移动端占位配置初始化失败也不拖垮启动）
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        Log.out('start with firebase: ${DefaultFirebaseOptions.currentPlatform.appId}', 'init');
        // 🔧 标记 Firebase 就绪（2026-08-01）
        FirebaseGuard.markReady();

        // https://firebase.google.com/docs/crashlytics/get-started?platform=flutter&authuser=0&hl=zh-tw#configure-crash-handlers
        // Pass all uncaught errors from the framework to Crashlytics.
        if (FirebaseGuard.ready) {
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        }
        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        if (FirebaseGuard.ready) {
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }

        if (kDebugMode && FirebaseGuard.ready) {
          await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
          await FirebaseInAppMessaging.instance.setMessagesSuppressed(true);
        }
      } catch (e) {
        // 无真实 Firebase 配置时：降级运行，不崩溃
        Log.out('firebase init skipped: $e', 'init');
      }
    }

    // 🔧 初始化链每步防御：任一步失败都不崩溃，保证页面能打开（2026-08-01）
    Future<void> safeInit(String name, Future<void> Function() fn) async {
      try {
        await fn();
        Log.out('init ok: $name', 'init');
      } catch (e) {
        Log.out('init failed: $name → $e', 'init');
        // Web 端把错误显示在页面上方便排查
        if (kIsWeb) {
          // ignore: avoid_print
          print('⚠️ init failed: $name → $e');
        }
      }
    }

    await safeInit('Database', () => Database.instance.initialize(logWhenQuery: isLocalTest));
    await safeInit('Storage', Storage.instance.initialize);
    await safeInit('Cache', Cache.instance.initialize);

    safeInit('Settings', () async => SettingsProvider.instance.initialize());
    safeInit('Log', () async => Log.allowSendEvents = CollectEventsSetting.instance.value);

    await safeInit('Stock', Stock().initialize);
    await safeInit('Quantities', Quantities().initialize);
    await safeInit('OrderAttributes', OrderAttributes().initialize);
    await safeInit('Replenisher', Replenisher().initialize);
    await safeInit('Cashier', Cashier().reset);
    await safeInit('Analysis', Analysis().initialize);
    await safeInit('Printers', Printers().initialize);
    // Last for setup ingredient and quantity
    await safeInit('Menu', Menu().initialize);

    /// Why use provider?
    /// https://stackoverflow.com/questions/57157823/provider-vs-inheritedwidget
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SettingsProvider.instance),
          ChangeNotifierProvider.value(value: Menu.instance),
          ChangeNotifierProvider.value(value: Stock.instance),
          ChangeNotifierProvider.value(value: Quantities.instance),
          ChangeNotifierProvider.value(value: Replenisher.instance),
          ChangeNotifierProvider.value(value: OrderAttributes.instance),
          ChangeNotifierProvider.value(value: Seller.instance),
          ChangeNotifierProvider.value(value: Cashier.instance),
          ChangeNotifierProvider.value(value: Cart.instance),
          ChangeNotifierProvider.value(value: Printers.instance),
        ],
        child: const App(),
      ),
    );
  }, (error, stack) {
    // 🔧 Firebase 未就绪时不访问 Crashlytics，避免二次崩溃（2026-08-01）
    if (FirebaseGuard.ready) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      // ignore: avoid_print
      print('uncaught: $error');
    }
  });
}
