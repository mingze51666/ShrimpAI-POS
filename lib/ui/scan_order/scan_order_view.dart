import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shrimpai_pos/services/scan_order_service.dart';

/// 🦐 扫码订单页（POS端接单）
/// 显示顾客扫码点餐的新订单，支持接单/完成/取消
class ScanOrderView extends StatefulWidget {
  const ScanOrderView({super.key});

  @override
  State<ScanOrderView> createState() => _ScanOrderViewState();
}

class _ScanOrderViewState extends State<ScanOrderView> {
  @override
  void initState() {
    super.initState();
    // 进入页面即启动轮询
    ScanOrderService.instance.start();
  }

  @override
  void dispose() {
    ScanOrderService.instance.stop();
    super.dispose();
  }

  Future<void> _updateStatus(ScanOrder order, String status, String action) async {
    final ok = await ScanOrderService.instance.updateStatus(order.id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ 订单#${order.id} $action' : '❌ 操作失败，请重试'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🦐 扫码订单'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: ScanOrderService.instance.newOrderCount,
            builder: (context, count, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    avatar: const Icon(Icons.notifications_active, size: 18),
                    label: Text('$count 个新订单'),
                    backgroundColor: count > 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: ScanOrderService.instance.newOrderCount,
        builder: (context, _, __) {
          final orders = ScanOrderService.instance.newOrders;
          if (orders.isEmpty) {
            return _buildEmpty(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              // 触发一次手动拉取
              await Future.delayed(const Duration(seconds: 1));
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _OrderCard(
                  order: orders[index],
                  onConfirm: () => _updateStatus(orders[index], 'confirmed', '已接单'),
                  onComplete: () => _updateStatus(orders[index], 'completed', '已完成'),
                  onCancel: () => _updateStatus(orders[index], 'cancelled', '已取消'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('等待扫码点餐订单...', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '顾客扫码下单后，订单会实时显示在这里\n每5秒自动刷新',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('手动刷新'),
          ),
        ],
      ),
    );
  }
}

/// 订单卡片
class _OrderCard extends StatelessWidget {
  final ScanOrder order;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('HH:mm').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '订单 #${order.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.table_restaurant, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(order.tableNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
            const Divider(height: 16),
            // 商品列表
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} ×${item.count}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Text(
                      '¥${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const Divider(height: 16),
            Row(
              children: [
                if (order.note.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.note,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  '合计 ¥${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('取消'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('接单'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
