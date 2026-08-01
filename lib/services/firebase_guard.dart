/// 🔧 Firebase 就绪标志（2026-08-01）
///
/// 项目没有真实 Firebase 配置（google-services.json 是占位符），
/// 初始化失败后任何 Firebase.instance 访问都会崩溃。
/// 所有 Firebase 调用点必须检查 [ready]。
class FirebaseGuard {
  /// 是否已成功初始化 Firebase
  static bool ready = false;

  /// Firebase 是否可用（Web 端永远不可用；移动端需初始化成功）
  static bool get enabled => !isWeb && ready;

  /// 是否为 Web 平台
  static bool get isWeb {
    // 避免直接依赖 flutter/foundation，保持轻量
    // ignore: avoid_dynamic_calls
    return const bool.fromEnvironment('dart.vm.product') == false &&
        // 通过 kIsWeb 判断（在 main.dart 初始化时设置）
        _isWeb;
  }

  static bool _isWeb = false;

  /// 由 main.dart 在启动时设置平台信息
  static void init({required bool isWeb}) {
    _isWeb = isWeb;
  }

  /// 标记 Firebase 初始化成功
  static void markReady() {
    ready = true;
  }
}
