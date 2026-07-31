# 🦐 ShrimpAI POS — 小虾米AI收银系统

> AI-powered open source Point of Sale system for small restaurants and businesses.
> 给小商户的「AI原生」开源收银系统 — 开源省年费，AI真智能，本地数据自主。

[![Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

## 📌 项目简介

ShrimpAI POS 是「小六AI团队」基于开源项目 [flutter-pos-system](https://github.com/evan361425/flutter-pos-system)（Apache 2.0）二次开发的 AI 收银系统。

**核心卖点：开源（省年费）+ AI（真智能）+ 本地（数据自主）**

- 🌏 跨平台：Flutter 一套代码 → Android / iOS / Web / Windows / macOS / Linux
- 🔌 离线优先：无网络也能收银，数据只存本机
- 🔒 隐私优先：不上传云端，商户数据自己做主
- 🤖 AI 增强（规划中）：
  - 🎤 AI 语音点单
  - 📷 AI 视觉识别结算
  - 📊 AI 对话式经营分析（自然语言→图表）
  - 📦 AI 库存预测（历史+天气+节假日→采购建议）
  - 🛡️ AI 防损风控

## ✨ 已有功能（继承上游）

- **库存系统**：原料/商品库存管理与监控
- **顾客信息**：顾客画像采集与分析
- **收银机**：日常结算、找零计算
- **数据流转**：CSV / Excel / Google Sheets 导入导出
- **经营分析**：自定义折线图、饼图
- **打印**：蓝牙小票打印（ESC/POS）
- **订单属性**：自定义口味/备注选项
- **补货管理**：原料消耗追踪 + 补货提醒
- **多语言**：中文 / English

## 🚀 快速开始

```bash
# 环境要求: Flutter ≥3.41 / Dart ≥3.11
flutter pub get
flutter run
```

## 🛠️ 技术栈

| 类别 | 技术 |
|:-----|:-----|
| 框架 | Flutter 3.41+ / Dart 3.11+ |
| 路由 | go_router |
| 状态管理 | provider |
| 本地数据库 | sqflite + sembast（本地优先） |
| 图表 | syncfusion_flutter_charts |
| 测试 | flutter_test + mockito |

## 🗺️ 路线图

- [x] Fork 品牌化（2026-08-01）
- [ ] AI 对话式经营分析（MVP）
- [ ] AI 语音点单
- [ ] AI 库存预测
- [ ] AI 视觉结算 + 防损风控
- [ ] 支付对接（聚合支付）
- [ ] 多门店版（大龙虾一体机适配）

## 📄 License

Apache 2.0 — 可商用、可修改、可二次分发。

## 👥 团队

小六AI团队 🎨 — 小虾米AI收银系统（ShrimpAI-POS）项目组

---
*本仓库由 flutter-pos-system (evan361425) fork 而来，保留 Apache 2.0 许可。*
