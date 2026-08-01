#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🦐 ShrimpAI POS — AI 经营分析引擎 (正式版 v2)
自然语言 → SQL → 本地 SQLite → 结构化结果 (支持图表 JSON)

相比原型 v1 的升级:
  1. ✅ 结构化 JSON 输出 (表格 + 图表数据, 前端直接渲染)
  2. ✅ SQL 安全检查 (只允许 SELECT, 禁写禁删)
  3. ✅ 图表类型识别 (趋势线/柱状/排行/占比)
  4. ✅ 健壮错误处理 + 自愈 (SQL 失败自动重试)
  5. ✅ 结果摘要生成 (自然语言解读)

用法:
  python3 -c "from ai_analysis_lib import analyze; print(analyze('今日营业额', '/tmp/pos_test.db'))"
  python3 ai_analysis_lib.py "近7天营业额趋势" --db /tmp/pos_test.db
"""
import argparse
import json
import os
import re
import sqlite3
import sys
import urllib.request
from datetime import datetime

# ── 配置 ──────────────────────────────────────────────
LLM_PROVIDER = os.getenv("AI_LLM_PROVIDER", "ollama")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
DEEPSEEK_MODEL = os.getenv("AI_MODEL", "deepseek-chat")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("AI_MODEL", "qwen2.5:14b")

# ── Schema 描述 (与原型一致, 增强字段说明) ────────────
SCHEMA_DESC = """
数据库 schema (SQLite):

表 order_records (订单记录):
  id INTEGER PK
  paid REAL      - 实收金额
  price REAL     - 订单总额
  cost REAL      - 成本
  revenue REAL   - 利润 (price - cost)
  productsPrice REAL - 商品金额
  productsCount INTEGER - 商品总件数
  attributesPrice REAL - 附加属性金额
  createdAt INTEGER - 创建时间 (毫秒时间戳)
  note TEXT      - 备注

表 order_products (订单商品明细):
  id INTEGER PK
  orderId INTEGER - 关联 order_records.id
  productName BLOB - 商品名
  catalogName BLOB - 分类名
  count INTEGER - 数量
  singleCost REAL - 单品成本
  singlePrice REAL - 单品售价
  originalPrice REAL - 原价
  isDiscount INTEGER - 是否折扣
  createdAt INTEGER - 毫秒时间戳

表 order_ingredients (订单配料):
  id INTEGER PK
  orderId INTEGER
  orderProductId INTEGER
  ingredientName BLOB - 配料名
  quantityName BLOB
  additionalPrice REAL - 加价
  additionalCost REAL
  amount REAL
  createdAt INTEGER

表 order_attributes (订单附加属性):
  id INTEGER PK
  orderId INTEGER
  name BLOB - 属性名(如口味)
  optionName BLOB - 选项名(如微辣)
  mode INTEGER
  modeValue REAL
  createdAt INTEGER

注意:
- createdAt 是毫秒时间戳, SQL 中可用 datetime(createdAt/1000, 'unixepoch', 'localtime') 转日期
- 查询销售额/营业额用 order_records.price 或 paid
- 查询商品销量用 order_products 聚合
- 利润 = revenue = price - cost
"""

SYSTEM_PROMPT = """你是餐饮/零售 POS 系统的数据分析师。根据给定的 SQLite schema 和用户问题，生成一条可直接执行的 SQL 查询。

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
"""


def get_schema(db_path: str) -> str:
    """从数据库提取真实 schema"""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    tables = []
    for (name,) in cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    ):
        cols = cur.execute(f"PRAGMA table_info({name})").fetchall()
        col_strs = [f"  {c[1]} {c[2]}" + (" PK" if c[5] else "") for c in cols]
        tables.append(f"表 {name}:\n" + "\n".join(col_strs))
    conn.close()
    return "\n\n".join(tables)


def ask_llm(prompt: str) -> str:
    """调用 LLM 生成 JSON"""
    if LLM_PROVIDER == "deepseek":
        return ask_deepseek(prompt)
    return ask_ollama(prompt)


def ask_deepseek(prompt: str) -> str:
    req = urllib.request.Request(
        "https://api.deepseek.com/chat/completions",
        data=json.dumps({
            "model": DEEPSEEK_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.1,
            "max_tokens": 800,
            "response_format": {"type": "json_object"},
        }).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
    return data["choices"][0]["message"]["content"].strip()


def ask_ollama(prompt: str) -> str:
    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/chat",
        data=json.dumps({
            "model": OLLAMA_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            "stream": False,
            "options": {"temperature": 0.1},
        }).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.loads(resp.read())
    return data["message"]["content"].strip()


def extract_json(text: str) -> dict:
    """从 LLM 输出提取 JSON（容忍 markdown 包裹/前后杂文本）"""
    text = text.strip()
    # 去掉 ```json ... ``` 包裹
    fence = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    if fence:
        text = fence.group(1)
    # 找第一个 { 到最后一个 }
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end == -1:
        return {"sql": "ERROR", "chart": "table", "title": "", "summary": "LLM 输出无法解析"}
    try:
        return json.loads(text[start:end + 1])
    except json.JSONDecodeError:
        return {"sql": "ERROR", "chart": "table", "title": "", "summary": "LLM 输出无法解析"}


def validate_sql(sql: str) -> bool:
    """SQL 安全检查：只允许 SELECT"""
    if not sql:
        return False
    s = sql.strip().lstrip("(").upper()
    if not s.startswith("SELECT"):
        return False
    # 禁止危险关键词
    danger = ["INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE", "ATTACH",
              "PRAGMA", "EXEC", "SHELL", "LOAD", "VACUUM", "REPLACE INTO"]
    for d in danger:
        if re.search(r"\b" + d + r"\b", s):
            return False
    return True


def run_query(db_path: str, sql: str) -> list:
    """执行查询，返回 [{col: value}, ...]"""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        cur = conn.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = [dict(zip(cols, r)) for r in cur.fetchall()]
        return rows
    finally:
        conn.close()


def analyze(question: str, db_path: str, max_retries: int = 2) -> dict:
    """
    核心入口：自然语言 → 结构化分析结果
    返回: {question, sql, chart, title, summary, columns, rows, success, error}
    """
    schema = get_schema(db_path)
    prompt = f"Schema:\n{schema}\n\n用户问题: {question}\n\n输出 JSON:"

    result = {
        "question": question,
        "sql": None,
        "chart": "table",
        "title": question,
        "summary": "",
        "columns": [],
        "rows": [],
        "success": False,
        "error": None,
        "provider": LLM_PROVIDER,
        "ts": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }

    for attempt in range(max_retries + 1):
        try:
            raw = ask_llm(prompt)
            parsed = extract_json(raw)
            sql = parsed.get("sql", "").strip()
            if sql.upper() == "ERROR" or not validate_sql(sql):
                result["error"] = f"无法生成有效SQL: {parsed.get('summary', '')}"
                return result
            result["sql"] = sql
            result["chart"] = parsed.get("chart", "table")
            result["title"] = parsed.get("title", question)
            result["summary"] = parsed.get("summary", "")
            try:
                rows = run_query(db_path, sql)
            except Exception as e:
                if attempt < max_retries:
                    # SQL 报错时把错误喂回 LLM 重试
                    prompt = f"Schema:\n{schema}\n\n用户问题: {question}\n\n之前生成的 SQL 执行失败: {e}\n请重新生成一条正确的 SQL，输出 JSON:"
                    continue
                result["error"] = f"SQL执行失败: {e}"
                return result
            result["rows"] = rows
            result["columns"] = list(rows[0].keys()) if rows else []
            result["success"] = True
            return result
        except Exception as e:
            if attempt < max_retries:
                continue
            result["error"] = f"LLM调用失败: {e}"
            return result
    return result


def main():
    parser = argparse.ArgumentParser(description="ShrimpAI AI 经营分析引擎 v2")
    parser.add_argument("question", help="自然语言问题")
    parser.add_argument("--db", default=None, help="SQLite 数据库路径（默认自动查找）")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    args = parser.parse_args()

    db_path = args.db
    if not db_path:
        candidates = ["/tmp/pos_test.db", "./pos.db", "/tmp/pos.db"]
        for c in candidates:
            if os.path.exists(c):
                db_path = c
                break
    if not db_path or not os.path.exists(db_path):
        print(json.dumps({"error": f"找不到数据库: {db_path}"}, ensure_ascii=False))
        sys.exit(1)

    result = analyze(args.question, db_path)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"📊 问题: {result['question']}")
        print(f"🤖 LLM: {result['provider']} | 图表: {result['chart']} | 标题: {result['title']}")
        print(f"📝 SQL: {result['sql']}")
        if result.get("summary"):
            print(f"💡 解读: {result['summary']}")
        if result["success"]:
            print(f"✅ 查询成功: {len(result['rows'])} 行")
            cols = result["columns"]
            print(" | ".join(cols))
            print("-" * 40)
            for r in result["rows"][:20]:
                print(" | ".join(str(r.get(c, "")) for c in cols))
        else:
            print(f"❌ 失败: {result['error']}")


if __name__ == "__main__":
    main()
