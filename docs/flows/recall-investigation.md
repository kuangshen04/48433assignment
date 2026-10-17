# 召回与监管调查

## 召回开始于外部决定

```text
Regulator/responsible organisation decides externally
  -> signs official Recall/Safety Notice
  -> platform verifies authority and archives notice
  -> notice may publish as VERIFIED_PENDING_ANCHOR
  -> Traceability Core runs conservative lineage traversal
  -> participants receive impact information
  -> ERP/WMS/POS/staff execute physical withdrawal
  -> optional EPCIS claims record subsequent actions
```

平台负责查找和传播可验证的影响范围，不执行 POS 禁售、仓库封存、门店下架、运输、退款或销毁。

## Conservative traversal

Recall 在固定 confirmed-data watermark `W` 上遍历：

```text
Transformation input -> all claimed outputs
Aggregation child <-> time-applicable parent/container
Shipping/Receiving object -> all claimed destinations/custodians
```

查询保留 edge provenance，并包含 `AWAITING_RECEIPT`、`PARTIALLY_ACCEPTED`、`DISPUTED`、`UNACKNOWLEDGED` 和 `EXTERNAL_COUNTERPARTY`。平台不选择哪条冲突路径真实，也不推断某种加工是否消除污染。

结果按 B17 的 non-collapsing 规则呈现：竞争边并存显示，不排序、不打分、不选代表路径。任何 impact 结论都必须能追溯回它依赖的断言集合与 watermark。

结果还要标注**遍历范围**：成员自行运行得到的是 `scope-limited` 结果（B3），只能说明“在我的可见范围内可能受影响”；权威影响范围由全 scope 方（监管方、审计者或受托恢复方）执行同一遍历得到。超出 scope 的节点必须显示为“存在但不可见”，不能静默视为不存在。

输出语义始终是：

> possibly affected based on available claims at watermark W

## Confirmed 与 recent pending 分离

| 集合 | 内容 | 表达方式 |
|---|---|---|
| `confirmedImpact` | watermark W 之前的 confirmed assertions | 可复现的主要结果 |
| `recentPendingClaims` | receipted/pending-anchor claims | 单独显示，不混入 confirmed result |
| private evidence | raw IoT、报告、合同等 | 具体调查中单独授权 |

超过 10,000 edges 或接近响应限制时转为异步 export。Export 固定 watermark、记录 dataset version、purpose、recipient、expiry 和审计 ID。

## Analytics 辅助路径

```text
Confirmed trace projection
  -> Regulatory Analytics rule/ML
  -> regulator-private RiskAlert
  -> officer review
  -> optional case-specific evidence request
  -> formal signed assessment/notice
```

Analytics 不直接读取任意 private evidence，也不自动发布 recall。Analytics 故障时，Core 的 conservative traversal 和监管人员手工调查仍可工作，但 UI 必须标记 risk assessment delayed/unavailable。

## 物理行动的后续记录

参与方可以提交 `recalled`、`quarantined`、`returned`、`destroying/decommissioning` 等 EPCIS claims，记录其声称采取的行动。平台不会把通知送达或 EPCIS claim 自动解释为物理行动已完成。

## 关联系统

- [Query & Experience](/systems/query-experience)
- [Regulatory Analytics](/systems/regulatory-analytics)
- [Traceability Core](/systems/traceability-core)
