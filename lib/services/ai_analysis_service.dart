import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shrimpai_pos/services/database.dart';

/// 🦐 ShrimpAI POS — AI 经营分析服务 (Dart 正式版)
///
/// 自然语言 → LLM 生成 SQL → 本地 SQLite 查询 → 结构化结果
/// 数据不出本机（仅发送 schema 描述 + 问题给 LLM）
///
/// 双后端: DeepSeek API / 本地 Ollama
class AiAnalysisService {
  AiAnalysisService._();

  static final AiAnalysisService instance = AiAnalysisService._();

  /// LLM 提供方: "deepseek" | "ollama"（默认 ollama 本地优先）
  String provider = 'ollama';

  /// DeepSeek 配置
  String deepseekApiKey = '';
  String deepseekModel = 'deepseek-chat';

  /// Ollama 配置
  String ollamaUrl = 'http://localhost:11434';
  String ollamaModel = 'qwen2.5:14b';

  static const String _systemPrompt = '''
你是餐饮/零售 POS 系统的数据分析师。根据给定的 SQLite schema 和用户问题，生成一条可直接执行的 SQL 查询。

要求:
1. 只输出 JSON，格式: {"sql": "SELECT ...", "chart": "line|bar|ranking|pie|table", "title": "图表标题", "summary": "一句话解读"}
2. chart 类型判断:
   - 时间趋势(按天/周/月) → line
   - 分类对比(少量类别) → bar
   - 排行(TOP N) → ranking
   - 占比(百分比) → pie
   - 其他/明细 → table
3. 查询金额用 order_records.price（总额）或 paid（实收）
4. 时间过滤用 createdAt（毫秒时间戳），示例: WHERE createdAt >= strftime('%s','now','-7 days')*1000
5. 商品名/productName、分类名/catalogName 在 order_products 表，不在 order_records 表！
6. 如果问题无法用 SQL 回答，输出: {"sql": "ERROR", "chart": "table", "title": "", "summary": "无法回答该问题"}
7. 聚合查询用 ORDER BY 排序，LIMIT 合理限制行数（排行类 LIMIT 10，趋势类 LIMIT 30）
8. 只允许 SELECT 查询，禁止 INSERT/UPDATE/DELETE/DROP

常用示例:
- 今日营业额: SELECT SUM(price) AS 营业额 FROM order_records WHERE createdAt >= strftime('%s','now','start of day')*1000
- 商品销量排行: SELECT productName AS 商品, SUM(count) AS 销量 FROM order_products GROUP BY productName ORDER BY 销量 DESC LIMIT 10
- 分类销售额: SELECT catalogName AS 分类, SUM(singlePrice*count) AS 销售额 FROM order_products GROUP BY catalogName ORDER BY 销售额 DESC
- 近7天每日营业额: SELECT date(createdAt/1000,'unixepoch','localtime') AS 日期, SUM(price) AS 营业额 FROM order_records WHERE createdAt >= strftime('%s','now','-7 days')*1000 GROUP BY 日期 ORDER BY 日期
''';

  /// 从 SQLite 提取真实 schema 描述
  Future<String> getSchema() async {
    final db = Database.instance.db;
    final tables = <String>[];
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    for (final row in result) {
      final name = row['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info($name)');
      final colStrs = cols
          .map((c) => '  ${c['name']} ${c['type']}${c['pk'] == 1 ? ' PK' : ''}')
          .join('\n');
      tables.add('表 $name:\n$colStrs');
    }
    return tables.join('\n\n');
  }

  /// 调用 LLM 获取 JSON 结果
  Future<String> _askLlm(String prompt) async {
    if (provider == 'deepseek' && deepseekApiKey.isNotEmpty) {
      return _askDeepseek(prompt);
    }
    return _askOllama(prompt);
  }

  Future<String> _askDeepseek(String prompt) async {
    final resp = await http
        .post(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $deepseekApiKey',
          },
          body: jsonEncode({
            'model': deepseekModel,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.1,
            'max_tokens': 800,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw Exception('DeepSeek API 错误: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    return (data['choices'][0]['message']['content'] as String).trim();
  }

  Future<String> _askOllama(String prompt) async {
    final resp = await http
        .post(
          Uri.parse('$ollamaUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': ollamaModel,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': prompt},
            ],
            'stream': false,
            'options': {'temperature': 0.1},
          }),
        )
        .timeout(const Duration(seconds: 120));
    if (resp.statusCode != 200) {
      throw Exception('Ollama 错误: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    return (data['message']['content'] as String).trim();
  }

  /// 提取 JSON（容忍 markdown 包裹）
  Map<String, dynamic> _extractJson(String text) {
    final trimmed = text.trim();
    // 去 ```json ... ``` 包裹
    final fence = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true).firstMatch(trimmed);
    final body = fence != null ? fence.group(1)! : trimmed;
    final start = body.indexOf('{');
    final end = body.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return {'sql': 'ERROR', 'chart': 'table', 'title': '', 'summary': 'LLM 输出无法解析'};
    }
    try {
      return jsonDecode(body.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return {'sql': 'ERROR', 'chart': 'table', 'title': '', 'summary': 'LLM 输出无法解析'};
    }
  }

  /// SQL 安全检查：只允许 SELECT
  bool _validateSql(String sql) {
    if (sql.isEmpty) return false;
    final s = sql.trimLeft().toUpperCase();
    if (!s.startsWith('SELECT')) return false;
    const danger = [
      'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER', 'CREATE',
      'ATTACH', 'PRAGMA', 'EXEC', 'VACUUM', 'REPLACE INTO',
    ];
    for (final d in danger) {
      if (RegExp('\\b$d\\b').hasMatch(s)) return false;
    }
    return true;
  }

  /// 核心分析入口
  Future<AiAnalysisResult> analyze(String question) async {
    final schema = await getSchema();
    var prompt = 'Schema:\n$schema\n\n用户问题: $question\n\n输出 JSON:';

    for (var attempt = 0; attempt <= 2; attempt++) {
      try {
        final raw = await _askLlm(prompt);
        final parsed = _extractJson(raw);
        final sql = (parsed['sql'] as String? ?? '').trim();

        if (sql.toUpperCase() == 'ERROR' || !_validateSql(sql)) {
          return AiAnalysisResult(
            question: question,
            success: false,
            error: parsed['summary'] as String? ?? '无法生成有效 SQL',
            provider: provider,
          );
        }

        try {
          // 本地 SQLite 执行（数据不出本机）
          final rows = await Database.instance.db.rawQuery(sql);
          return AiAnalysisResult(
            question: question,
            sql: sql,
            chart: parsed['chart'] as String? ?? 'table',
            title: parsed['title'] as String? ?? question,
            summary: parsed['summary'] as String? ?? '',
            columns: rows.isEmpty ? const <String>[] : rows.first.keys.toList(),
            rows: rows,
            success: true,
            provider: provider,
          );
        } catch (e) {
          if (attempt < 2) {
            // SQL 报错时把错误喂回 LLM 重试
            prompt = 'Schema:\n$schema\n\n用户问题: $question\n\n之前生成的 SQL 执行失败: $e\n请重新生成一条正确的 SQL，输出 JSON:';
            continue;
          }
          return AiAnalysisResult(
            question: question,
            success: false,
            error: 'SQL 执行失败: $e',
            provider: provider,
          );
        }
      } catch (e) {
        if (attempt < 2) continue;
        return AiAnalysisResult(
          question: question,
          success: false,
          error: 'LLM 调用失败: $e',
          provider: provider,
        );
      }
    }
    return AiAnalysisResult(
      question: question,
      success: false,
      error: '未知错误',
      provider: provider,
    );
  }
}

/// AI 分析结果
class AiAnalysisResult {
  final String question;
  final String? sql;
  final String chart; // line | bar | ranking | pie | table
  final String title;
  final String summary;
  final List<String> columns;
  final List<Map<String, Object?>> rows;
  final bool success;
  final String? error;
  final String provider;

  AiAnalysisResult({
    required this.question,
    this.sql,
    this.chart = 'table',
    this.title = '',
    this.summary = '',
    this.columns = const [],
    this.rows = const [],
    required this.success,
    this.error,
    required this.provider,
  });
}
