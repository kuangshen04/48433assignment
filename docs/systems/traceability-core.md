# Traceability Core

> 主要决策：[A1–A7](/decisions/catalog#a1)、[B6](/decisions/catalog#b6)、[B9–B11](/decisions/catalog#b9)、[B17–B19](/decisions/catalog#b17)

## 责任

Traceability Core 是跨组织 source assertion 的接收和查询系统，不是农业 ERP、库存系统或真实性裁判。它负责：

- 接收标准 EPCIS events 和受治理的 product-profile extensions；
- canonicalisation、schema、signature、authority 和 idempotency validation；
- append-only correction 与 EPCIS Error Declaration；
- event confirmation lifecycle；
- Shipping/Receiving claim correlation；
- lineage、recall、consumer 和 investigation projections；
- transactional outbox 与失败后幂等续跑。

它不负责企业库存、订单、支付、生产计划、设备 fleet management、物理召回执行或自动合规结论。

## 核心写入契约

一次 submission 至少包含：

```text
captureRecordId              platform idempotency identity
epcisEventId                 EPCIS business event identity; nullable
profileId/profileVersion     validation and interpretation context
canonicalisationVersion      deterministic digest contract
canonical EPCIS payload      organisation source assertion
SignatureEnvelope            attribution and custody assurance
optional evidence references protected resources, not embedded files
```

相同 `captureRecordId` 重试必须具有相同 digest，否则拒绝。相同非空 `epcisEventId` 通常也拒绝重复，唯一标准例外是合法的 EPCIS Error Declaration。

## 验证边界

Core 只做 admission/protocol validation，不是因为领域校验不重要，而是因为平台既不知道也无权决定跨产品、地区和监管制度的权威业务规则。这些规则必须由 [Regulatory Analytics](/systems/regulatory-analytics) 的监管主体管理。

| Core 验证 | Core 不判断 |
|---|---|
| EPCIS/schema/profile 结构 | 数量或 yield 是否合理 |
| canonical digest 与签名 | 货物是否真实存在 |
| organisation authority/delegation | 传感器是否真的安装在声明位置 |
| key、profile 和 governance 状态 | transformation 是否构成欺诈 |
| idempotency 和合法状态转换 | 某一冲突声明哪一方真实 |
| correction relationship | 是否违反具体食品法规 |

`CONFIRMED` 只能解释为“声明已签名、独立归档并锚定”，不能显示为“平台已验证业务真实或合规”。

将规则放入 Regulatory Analytics 不会把它降为外围系统：deterministic heuristics 是平台整体的核心领域能力，只有 ML 算法本身是可选的。Core 与 Analytics 使用异步 peer integration，是为了隔离规则故障并保留原始冲突证据，而不是让平台忽略领域风险。

## 不可变历史与纠错

正式事件不原地更新或删除。纠错采用：

- 新 correction event 引用原事件；或
- 符合 EPCIS 2.0 Error Declaration 约束的同 eventID 声明。

Core 保留原声明、纠错声明、发布方、时间、profile 和签名。查询可以给出当前解释，但审计和恢复必须能重建完整更正历史。

## Handover 模型

联盟内注册组织之间的 B2B 交接由两份独立声明组成：

```text
sender-signed shipping claim
receiver-signed receiving claim
              |
              v
derived handover status
```

状态包括 `AWAITING_RECEIPT`、`ACCEPTED`、`PARTIALLY_ACCEPTED`、`REJECTED`、`DISPUTED`、`UNACKNOWLEDGED`。网络外对手方使用 `EXTERNAL_COUNTERPARTY` 单方边界声明；消费者零售不要求消费者签名。

双边确认只证明双方分别作出关联声明，不能防止双方串谋。Recall/audit 查询会保守包含争议、未确认和外部边界 edges。

## Product Profile

Versioned Product Validation Profile 可以配置：

- extension fields、类型、格式和枚举；
- units、product vocabulary；
- required evidence-reference shape；
- consumer projection allowlist；
- 通用表单展示元数据。

Profile 不配置 yield tolerance、fraud heuristic、mass balance、跨事件合理性或自动合规结论。发布后的版本不可原地修改，事件签名固定绑定所用版本。

## 内部组件边界

```text
Capture API
  -> Canonicalisation & Profile Validator
  -> Signature / Authority Validator
  -> Submission State Machine
  -> Archive & Anchor Orchestrator
  -> Confirmed Event Index
  -> Handover / Lineage / Consumer Projections
  -> Query, Export and Recall Services
```

第一版是模块化单体与一个 managed PostgreSQL，不为术语完整性预先部署 event store、broker、graph database 和独立 read database。

## 依赖与失败语义

- Identity/Governance 决定谁能以何种角色发布。
- Trust & Recovery 决定何时可以 receipt/confirm。
- Archive 或 KMS 故障时写入停在 `PENDING_ARCHIVE`。
- Public chain 故障时停在 `PENDING_ANCHOR`，不能自动确认。
- Projection 故障不回滚 canonical event，但查询必须显示 watermark/staleness。

完整路径见[事件接收与确认](/flows/event-acceptance)。
