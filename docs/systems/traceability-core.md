# Traceability Core

> 主要决策：[A1–A7](/decisions/catalog#a1)、[B6](/decisions/catalog#b6)、[B9–B11](/decisions/catalog#b9)、[B17–B19](/decisions/catalog#b17)

## 责任

Traceability Core 是跨组织 source assertion 的接收和查询系统，不是农业 ERP、库存系统或真实性裁判。它负责：

- 接收标准 EPCIS events 和受治理的 product-profile extensions；
- canonicalisation、schema、signature、authority 和 idempotency validation；
- append-only correction 与 EPCIS Error Declaration；
- event confirmation lifecycle；
- Shipping/Receiving claim correlation；
- lineage、recall、consumer 和 investigation projections，且必须 non-collapsing 地并存呈现竞争断言；
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

证据引用一律是**平台侧记录**：reference、owner、加盐 `plaintextCommitment`、可选密文位置（B23）。平台不接收、不解析、不解密私有内容；需要按字段查询的内容必须进 `CONSORTIUM`，没有中间地带。

相同 `captureRecordId` 重试必须具有相同 digest，否则拒绝。相同非空 `epcisEventId` 通常也拒绝重复，唯一标准例外是合法的 EPCIS Error Declaration。

## 记录断言，不裁决真伪

Core 只做 admission/protocol validation，有两条独立理由：平台既不知道也无权决定跨产品、地区和监管制度的权威业务规则；平台也无法观察现实，因此不能判断两条冲突声明中哪一条为真（同一序列化对象被两项 transformation 分别声称消耗即属此类）。

由此得到本系统的判定规则：

> 平台记录断言；判定只能由有权主体以签署声明的方式进入历史。

判定进入历史的通道只有三条：EPCIS `ErrorDeclaration`、signed Recall/Safety Notice、regulator-signed Assessment/Inspection。平台推断得出的“错误”或“违规”结论不得写入历史。

### 两类校验必须分开

| 类别 | 典型内容 | 是否阻断写入 |
|---|---|---|
| Admission validation | EPCIS/schema/profile 结构、canonical digest、签名、organisation authority/delegation、key/profile/governance 状态、idempotency、合法状态转换、correction relationship | 是 |
| In-domain structural representability | 同一对象被多项 transformation 声称消耗、存在竞争 parent、引用网络内未知标识、lineage 关系在时间上成环 | 否，只决定投影如何呈现 |

第二类不是业务合理性判断，而是关于已提交断言集合的、无需领域知识的事实：可计算、可复现、不含价值判断。它不阻塞归档与锚定，也不生成 verdict 状态，但必须被如实呈现。

| Core 不判断的问题 | 归属 |
|---|---|
| 数量、yield、损耗是否合理 | [Regulatory Analytics](/systems/regulatory-analytics) |
| 传感器是否真的安装在声明位置 | Regulatory Analytics 与现场调查 |
| transformation 是否构成欺诈 | Regulatory Analytics |
| 某一冲突声明哪一方真实 | 只能以签署声明表达 |
| 是否违反具体食品法规 | Regulatory Analytics 与官方结论 |

`CONFIRMED` 只能解释为“声明已签名、独立归档并锚定”，不能显示为“平台已验证业务真实或合规”。

将规则放入 Regulatory Analytics 不会把它降为外围系统：它与 Core 同属系统边界内，只是处在监管方的独立运行时域（见[系统地图](/architecture/system-map)）。deterministic heuristics 是平台整体的核心领域能力，只有 ML 算法本身是可选的。Core 与 Analytics 使用异步 peer integration，是为了隔离规则故障并保留原始冲突证据，而不是让平台忽略领域风险。

## 不可变历史与纠错

正式事件不原地更新或删除。纠错采用：

- 新 correction event 引用原事件；或
- 符合 EPCIS 2.0 Error Declaration 约束的同 eventID 声明。

Core 保留原声明、纠错声明、发布方、时间、profile 和签名。查询可以给出当前解释，但审计和恢复必须能重建完整更正历史。

## 竞争断言的表示义务（non-collapsing）

保留冲突断言只有在视图里也保留才有意义：

- lineage、recall impact、handover 和 audit 的**默认视图不得折叠为一条路径**；
- 对同一对象的所有已确认断言必须多边并存，每条边保留 `fromObjectId`、`toObjectId`、`edgeType`、`sourceEventId`、publisher、event time、effective interval、confirmation status 和 handover status；
- 平台不排序、不打分、不选“代表路径”，也不产生置信度；
- recall/food-safety 结论必须能追溯回它所依赖的断言集合与 watermark；依赖集合含竞争边时必须显示该竞争关系，而不是取其一。

`UNRESOLVED_INPUT`、`MASS_BALANCE_WARNING` 这类 platform verdict 是禁止的；“该对象存在两条由不同组织发布、无法相互衔接的已确认断言”属于 provenance fact，必须可见。两类的区别是：前者是平台对现实的判断，后者是对已提交断言的陈述。

Consumer projection 受 `PUBLIC` allowlist 约束，但同样不得在存在竞争断言时呈现为单一路径；具体措辞可与消费者视图的合规审查一并确定。

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
