import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🦐 扫码点餐订单服务（POS端）
/// 轮询服务器拉取顾客扫码下单的新订单
class ScanOrderService {
  ScanOrderService._();

  static final ScanOrderService instance = ScanOrderService._();

  /// 服务器地址（可配置）
  String serverUrl = 'http://118.31.72.24/order';

  /// 轮询间隔（秒）
  static const pollInterval = Duration(seconds: 5);

  Timer? _timer;
  final List<ScanOrder> _newOrders = [];
  final ValueNotifier<int> newOrderCount = ValueNotifier(0);

  /// 是否已启动轮询
  bool _running = false;

  /// 启动轮询
  void start() {
    if (_running) return;
    _running = true;
    _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
    debugPrint('🦐 扫码订单轮询已启动: $serverUrl');
  }

  /// 停止轮询
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 拉取新订单
  Future<void> _poll() async {
    try {
      final resp = await http
          .get(Uri.parse('$serverUrl/api/orders?status=new'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['success'] != true) return;
      final orders = (json['data'] as List)
          .map((e) => ScanOrder.fromJson(e as Map<String, dynamic>))
          .toList();

      // 只保留新出现的订单
      final existingIds = _newOrders.map((o) => o.id).toSet();
      final fresh = orders.where((o) => !existingIds.contains(o.id)).toList();
      if (fresh.isNotEmpty) {
        _newOrders.insertAll(0, fresh);
        newOrderCount.value = _newOrders.length;
        debugPrint('🦐 收到 ${fresh.length} 个新扫码订单');
      }
    } catch (e) {
      // 网络失败静默，下轮重试
      debugPrint('扫码订单轮询失败: $e');
    }
  }

  /// 获取新订单列表
  List<ScanOrder> get newOrders => List.unmodifiable(_newOrders);

  /// 接单/完成/取消订单
  Future<bool> updateStatus(int orderId, String status) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$serverUrl/api/orders/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': orderId, 'status': status}),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return false;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['success'] == true) {
        // 从新订单列表移除
        _newOrders.removeWhere((o) => o.id == orderId);
        newOrderCount.value = _newOrders.length;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('更新订单状态失败: $e');
      return false;
    }
  }
}

/// 扫码订单模型
class ScanOrder {
  final int id;
  final String tableNo;
  final String note;
  final List<ScanOrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  ScanOrder({
    required this.id,
    required this.tableNo,
    required this.note,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory ScanOrder.fromJson(Map<String, dynamic> json) {
    return ScanOrder(
      id: json['id'] as int,
      tableNo: json['table_no'] as String? ?? '',
      note: json['note'] as String? ?? '',
      items: ((json['items'] as List?) ?? [])
          .map((e) => ScanOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'new',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

/// 扫码订单商品项
class ScanOrderItem {
  final int id;
  final String name;
  final double price;
  final int count;

  ScanOrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.count,
  });

  factory ScanOrderItem.fromJson(Map<String, dynamic> json) {
    return ScanOrderItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }

  double get subtotal => price * count;
}
