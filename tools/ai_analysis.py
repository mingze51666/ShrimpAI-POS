#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🦐 ShrimpAI POS — AI 对话式经营分析原型
自然语言 → SQL → 本地 SQLite 查询 → 结果/图表

用法:
  python3 ai_analysis.py "上周哪个产品卖得最好?"
  python3 ai_analysis.py --db /path/to/pos.db "今天营业额多少?"

架构:
  1. 收集 SQLite schema 信息
  2. 自然语言问题 + schema → LLM (DeepSeek/Ollama) → 生成 SQL
  3. 本地执行 SQL（数据不出本机）
  4. 输出结果 + 可选图表

依赖:
  pip install openai (DeepSeek 兼容 OpenAI SDK)
  或本地 Ollama: curl http://localhost:11434 (qwen2.5)
"""
import argparse
import json
import os
import sqlite3
import sys
import urllib.request
from datetime import datetime

# ── 配置 ──────────────────────────────────────────────
# LLM 提供方: "deepseek" | "ollama"
LLM_PROVIDER = os.getenv("AI_LLM_PROVIDER", "deepseek")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "DEEPSEEK_API_KEY_FROM_ENV")
DEEPSEEK_MODEL = os.getenv("AI_MODEL", "deepseek-chat")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://192.168.1.29:11434")
OLLAMA_MODEL = os.getenv("AI_MODEL", "qwen2.5:14b")

# ── Schema 描述 ───────────────────────────────────────
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
"""

SYSTEM_PROMPT = """你是餐饮/零售 POS 系统的数据分析师。根据给定的 SQLite schema 和用户问题，生成一条可直接执行的 SQL 查询。

要求:
1. 只输出 SQL 语句本身，不要任何解释、注释或 markdown 代码块标记
2. 查询金额用 order_records.price（总额）或 paid（实收）
3. 时间过滤用 createdAt（毫秒时间戳），示例: WHERE createdAt >= strftime('%s','now','-7 days')*1000
4. 商品名/productName、分类名/catalogName 在 order_products 表，不在 order_records 表！
5. 如果问题无法用 SQL 回答，输出: ERROR: 无法回答
6. 聚合查询用 ORDER BY 排序，LIMIT 合理限制行数
7. 用 WHERE 1=1 开头拼接条件，避免语法错误

常用示例:
- 今日营业额: SELECT SUM(price) FROM order_records WHERE createdAt >= strftime('%s','now','start of day')*1000
- 商品销量排行: SELECT productName, SUM(count) AS total_count FROM order_products GROUP BY productName ORDER BY total_count DESC LIMIT 10
- 分类销售额: SELECT catalogName, SUM(singlePrice*count) AS sales FROM order_products GROUP BY catalogName ORDER BY sales DESC
- 近7天每日营业额: SELECT date(createdAt/1000,'unixepoch','localtime') AS day, SUM(price) FROM order_records WHERE createdAt >= strftime('%s','now','-7 days')*1000 GROUP BY day ORDER BY day
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
    """调用 LLM 生成 SQL"""
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
            "max_tokens": 500,
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
        }).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())
    return data["message"]["content"].strip()


def clean_sql(sql: str) -> str:
    """清理 LLM 输出，提取纯 SQL"""
    sql = sql.strip()
    if sql.startswith("```"):
        lines = sql.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        sql = "\n".join(lines).strip()
    if sql.upper().startswith("ERROR"):
        return None
    return sql


def main():
    parser = argparse.ArgumentParser(description="ShrimpAI AI 经营分析原型")
    parser.add_argument("question", help="自然语言问题，如: 上周哪个产品卖得最好?")
    parser.add_argument("--db", default=None, help="SQLite 数据库路径（默认自动查找）")
    args = parser.parse_args()

    # 查找数据库
    db_path = args.db
    if not db_path:
        candidates = [
            "/root/.openclaw/workspace/ShrimpAI-POS/build/app/outputs/flutter-apk/",
            "./pos.db",
            "/tmp/pos.db",
        ]
        # 检查常见路径
        for c in candidates:
            if os.path.exists(c) and os.path.isfile(c):
                db_path = c
                break
    if not db_path or not os.path.exists(db_path):
        print(f"❌ 找不到数据库文件: {db_path}")
        print("   可用 --db 指定路径")
        sys.exit(1)

    print(f"📊 数据库: {db_path}")
    print(f"🤖 LLM: {LLM_PROVIDER} ({DEEPSEEK_MODEL if LLM_PROVIDER=='deepseek' else OLLAMA_MODEL})")
    print(f"💬 问题: {args.question}")
    print("-" * 50)

    # 1. 提取 schema
    schema = get_schema(db_path)

    # 2. LLM 生成 SQL
    prompt = f"Schema:\n{schema}\n\n用户问题: {args.question}\n\n生成的 SQL:"
    sql = clean_sql(ask_llm(prompt))
    if not sql:
        print("❌ LLM 无法生成 SQL")
        sys.exit(1)
    print(f"📝 生成的 SQL:\n{sql}\n")

    # 3. 本地执行
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        cur = conn.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print(f"✅ 查询成功: {len(rows)} 行")
        print("-" * 50)
        if not rows:
            print("（无数据）")
        else:
            print(" | ".join(cols))
            print("-" * 50)
            for r in rows[:20]:
                print(" | ".join(str(v) for v in r))
            if len(rows) > 20:
                print(f"... 还有 {len(rows)-20} 行")
    except Exception as e:
        print(f"❌ SQL 执行失败: {e}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
