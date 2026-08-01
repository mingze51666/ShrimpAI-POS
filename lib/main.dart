import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shrimpai_pos/constants/constant.dart';
import 'package:shrimpai_pos/models/analysis/analysis.dart';
import 'package:shrimpai_pos/models/printer.dart';
import 'package:shrimpai_pos/models/repository/cart.dart';
import 'package:provider/provider.dart';

import 'app.dart';
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
    // 🔧 Firebase 已移除，直接打印避免崩溃（2026-08-01）
    // ignore: avoid_print
    print('uncaught: $error');
  });
}
