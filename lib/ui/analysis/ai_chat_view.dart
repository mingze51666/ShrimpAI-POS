import 'package:flutter/material.dart';
import 'package:shrimpai_pos/services/ai_analysis_service.dart';
import 'package:shrimpai_pos/translator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 🦐 AI 对话式经营分析界面
/// 输入自然语言问题 → 显示结果（表格 / 图表）
class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  /// 快捷问题
  static const List<String> _quickQuestions = [
    '今日营业额是多少？',
    '近7天营业额趋势',
    '商品销量排行 TOP10',
    '分类销售额占比',
    '今天卖了多少单？',
    '本月利润有多少？',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final result = await AiAnalysisService.instance.analyze(question.trim());

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(result: result));
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🦐 AI 经营分析'),
        actions: [
          IconButton(
            tooltip: '清空对话',
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty
                ? null
                : () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // 快捷问题
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = _quickQuestions[index];
                return ActionChip(
                  label: Text(q),
                  onPressed: _loading ? null : () => _ask(q),
                  avatar: const Icon(Icons.bolt, size: 16),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 对话区
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          // 输入区
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        hintText: '问我任何经营问题，如"今天赚了多少？"',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'ai_send',
                    onPressed: _loading ? null : () => _ask(_controller.text),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🦐', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('AI 经营分析', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '用大白话问经营数据，AI 自动生成查询和图表\n数据全程留在本机，不出店',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '试试问：\n"今天营业额多少" "商品卖得最好的是啥" "近7天趋势"',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 聊天消息
class _ChatMessage {
  final String? text;
  final bool isUser;
  final AiAnalysisResult? result;

  _ChatMessage({this.text, this.isUser = false, this.result});
}

/// 消息气泡
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text ?? ''),
        ),
      );
    }

    final result = message.result;
    if (result == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: result.success
            ? _ResultContent(result: result)
            : _ErrorContent(result: result),
      ),
    );
  }
}

/// 结果内容（图表/表格）
class _ResultContent extends StatelessWidget {
  final AiAnalysisResult result;

  const _ResultContent({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                result.title,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (result.summary.isNotEmpty)
              Tooltip(
                message: result.summary,
                child: const Icon(Icons.info_outline, size: 16),
              ),
          ],
        ),
        if (result.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              result.summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _buildChartOrTable(context),
        if (result.sql != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'SQL: ${result.sql}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildChartOrTable(BuildContext context) {
    final rows = result.rows;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('（没有数据）'),
      );
    }

    // 单列数据：直接显示大数字
    if (result.columns.length == 1 && rows.length == 1) {
      final value = rows.first.values.first;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value?.toString() ?? '-',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            if (result.title.isNotEmpty)
              Text(
                result.title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
    }

    // 多行：按图表类型渲染
    final chart = result.chart;
    if (chart == 'line' || chart == 'bar' || chart == 'ranking') {
      return _AiChart(rows: rows, columns: result.columns, type: chart);
    }
    return _DataTable(rows: rows, columns: result.columns);
  }
}

/// AI 图表（基于 syncfusion）
class _AiChart extends StatelessWidget {
  final List<Map<String, Object?>> rows;
  final List<String> columns;
  final String type;

  const _AiChart({
    required this.rows,
    required this.columns,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // 推断 x 轴（第一列文字/日期）和 y 轴（第一列数字）
    String xField = columns.first;
    String yField = columns.lastWhere(
      (c) => rows.any((r) => r[c] is num),
      orElse: () => columns.last,
    );

    // 数值列优先选非 x 的第一列
    for (final c in columns) {
      final isNum = rows.any((r) => r[c] is num);
      if (isNum && c != xField) {
        yField = c;
        break;
      }
    }

    final chartData = rows
        .map((r) => _ChartPoint(
              label: r[xField]?.toString() ?? '-',
              value: (r[yField] as num?)?.toDouble() ?? 0,
            ))
        .toList();

    final height = (chartData.length * 36 + 60).clamp(140, 360).toDouble();

    return SizedBox(
      height: height,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: chartData.length > 6 ? 45 : 0,
          labelStyle: const TextStyle(fontSize: 10),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '{value}',
          title: AxisTitle(text: yField),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: [
          if (type == 'line')
            LineSeries<_ChartPoint, String>(
              dataSource: chartData,
              xValueMapper: (p, _) => p.label,
              yValueMapper: (p, _) => p.value,
              dataLabelSettings: const DataLabelSettings(isVisible: false),
              markerSettings: const MarkerSettings(isVisible: true),
            )
          else if (type == 'bar')
            BarSeries<_ChartPoint, String>(
              dataSource: chartData,
              xValueMapper: (p, _) => p.label,
              yValueMapper: (p, _) => p.value,
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.outer,
                textStyle: const TextStyle(fontSize: 10),
              ),
            )
          else
            ColumnSeries<_ChartPoint, String>(
              dataSource: chartData,
              xValueMapper: (p, _) => p.label,
              yValueMapper: (p, _) => p.value,
              dataLabelSettings: DataLabelSettings(
                isVisible: chartData.length <= 12,
                labelAlignment: ChartDataLabelAlignment.outer,
                textStyle: const TextStyle(fontSize: 10),
              ),
              width: 0.6,
            ),
        ],
      ),
    );
  }
}

/// 数据表格
class _DataTable extends StatelessWidget {
  final List<Map<String, Object?>> rows;
  final List<String> columns;

  const _DataTable({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columns: [
            for (final c in columns)
              DataColumn(
                label: Text(
                  c,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  for (final c in columns)
                    DataCell(Text(r[c]?.toString() ?? '-')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 错误内容
class _ErrorContent extends StatelessWidget {
  final AiAnalysisResult result;

  const _ErrorContent({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            result.error ?? '出错了，请换个问法试试',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

/// 加载气泡
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'AI 思考中...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 图表数据点
class _ChartPoint {
  final String label;
  final double value;

  _ChartPoint({required this.label, required this.value});
}
