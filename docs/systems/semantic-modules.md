# Semantic Modules

> 主要决策：[B25](/decisions/catalog#b25)、[B17](/decisions/catalog#b17)、[B18](/decisions/catalog#b18)、[B21](/decisions/catalog#b21)

## 定位

Core 只做机制，业务语义由本页描述的模块承担（决定与理由见 [B25](/decisions/catalog#b25)）。一句话分界：

> **Core 保证"这条事实是什么、你能否看见、你是否看全"；Module 决定"它意味着什么"。**

模块是**同进程内的模块**：同一 PostgreSQL、经 port 调用，不独立部署、不引入 broker。只有在出现独立发布或扩缩容需求时才拆分（A7、B10）。

## Core 提供的唯一读取入口

模块读不到 canonical 表，只能通过 `QueryPort`：

```text
edges(subjectRef, edgeTypes[], timeWindow, watermark?)
  -> EdgeGroup[]        // 同一 (from, to, edgeType) 的全部竞争断言成组返回
  + per-edge provenance
  + dataCompleteThrough / completeness status

不存在 getHandoverStatus() / isImpacted() / getComplianceStatus()
这类方法。Core 只返回断言与边，不返回业务状态。
```

设计理由：如果让六个模块各自实现"不许折叠"和"按 scope 过滤"，一定有人漏掉。把 [B17](/decisions/catalog#b17) 的 non-collapsing 与 [B3](/decisions/catalog#b3) 的 scope 强制放在**唯一查询入口**，保证才不会被某个模块出卖。

`EdgeGroup` 是对同一 `(from, to, edgeType)` 的全部竞争断言；它不能被模块拆成"选一条"，只能整组呈现或整体标注为不可见。

## ModuleManifest

每个模块以声明式 manifest 表达自己的依赖：

```text
ModuleManifest
- moduleId / version / status: DRAFT | ACTIVE | RETIRED
- requiresFields: [...]        影响 profile 地板
- requiresEdges:  [...]        要求 Core 提供哪些边类型
- requiresPairingKey: bizTransaction(type) | objectIdentity
- produces: projectionId / reportId
- invariant: 本模块自己对外承诺什么
- watermarkSource
```

三条硬规则（决定见 B25）：

1. **模块只读 canonical facts。** 任何"结论"——召回通知、监管评估、纠错声明——仍然作为签署事件走**同一条 capture 路径**。整个系统只有一个写路径。
2. **模块能力可以降级，但不能影响 Core 的确认、归档与锚定。** 降级必须可显示（见下表），不能静默丢掉。
3. **`requiresFields` 的并集是编译产物，不是运行时 union。** 编译进 profile 版本后冻结，因为 [B2](/decisions/catalog#b2) 的恢复要求还原当时的 schema 与验证规则。

## 第一版模块

| 模块 | 读什么 | 产出 | 缺依赖时失去什么 |
|---|---|---|---|
| **HandoverModule** | shipping/receiving claims + `requiresPairingKey` | handover projection（`AWAITING_RECEIPT` / `ACCEPTED` / `PARTIALLY_ACCEPTED` / `DISPUTED` / `UNACKNOWLEDGED`） | 缺数量 → 失去 `PARTIALLY_ACCEPTED`；缺 pairing key → 退化为启发式匹配并进入 reconciliation |
| **RecallModule** | transformation / aggregation / handover 边 + 时间范围 | 保守 impact 报告，带 watermark 与 `scope-limited` 标注 | 缺标识 → 无法遍历 |
| **ComplianceModule** | `source`/`destination` + `bizTransaction` + profile 字段 | 一上一下重建、义务映射证据 | 缺 source/destination → 该辖区的一上一下不成立 |
| **ConsumerModule** | allowlist 字段 | 版本化 `PUBLIC` 快照 | 缺字段 → 该字段不出现（fail-closed allowlist） |
| **AnalyticsInputModule** | 最小化 confirmed projection | 交给 [Regulatory Analytics](/systems/regulatory-analytics) 的数据集 | 缺字段 → 对应 rule 类不可用于该产品线 |
| **InsightsModule** | confirmed projection | warehouse / mart + dashboard serving | 缺字段 → 对应统计维度不可用 |

## 模块之间必须对齐 watermark

模块各自持有可重建投影，因此**跨模块比较必须用同一 watermark**。否则会出现"召回说批次已到仓库，handover 说还在途"这类不一致。

```text
正确：recall(watermark=W) + handover(watermark=W)
错误：recall(watermark=W) + handover(当前)
```

需要同时看多个模块结论的界面（召回工作台、监管调查视图）必须在一次查询里固定 watermark，而不是分别取最新值。

## 与 Core 的边界

| 归属 | 例子 | 判定依据 |
|---|---|---|
| Core | 签名验证、幂等、lifecycle、archive/anchor、证据图、`QueryPort` | 缺失会让 `CONFIRMED` 记录不可验证或不可恢复 |
| Module | handover 状态、召回遍历策略、合规重建、公开投影、分析输入、洞察 | 可从 canonical events 重建，失败只影响自身能力 |

反例需要拒绝的两种做法：

- 模块向证据图注入自定义边（例如"疑似同一批次"）——图只能来自 EPCIS 标准语义；
- 模块维护自己的"业务状态表"并对外承诺可以恢复历史——只有 canonical trace 是权威历史。
