# Traceability Core

> 相关决策：[A1–A7](/decisions/catalog#a1)、[B6](/decisions/catalog#b6)、[B9–B11](/decisions/catalog#b9)、[B17–B19](/decisions/catalog#b17)

## 责任

Traceability Core 是跨组织 source assertion 的接收与查询机制，不是农业 ERP、库存系统或真实性裁判，也**不承载业务语义**（B25）。它负责：

- 接收标准 EPCIS events 和受治理的 product-profile extensions；
- canonicalisation、schema、signature、authority 和 idempotency validation；
- append-only correction 与 EPCIS Error Declaration；
- event confirmation lifecycle 与 archive/anchor 编排；
- 由 EPCIS 标准语义构建的证据图（identity、transformation、aggregation、association、correction、handover reference）；
- `QueryPort`，强制 scope 过滤、non-collapsing 返回与 watermark，并携带 per-edge provenance；
- transactional outbox 与失败后幂等续跑。

它不负责业务语义：handover 状态、召回遍历策略、合规重建、分析输入和运营洞察由同进程的语义模块承担（HandoverModule、RecallModule、ComplianceModule、ConsumerModule、AnalyticsInputModule、InsightsModule），模块只读 canonical facts、不写历史。

它也不负责企业库存、订单、支付、生产计划、设备 fleet management、物理召回执行或自动合规结论。

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

`SignatureEnvelope` 是四种 custody 模式的统一出口，字段固定：

```text
SignatureEnvelope
  signerOrganisationId / keyId / keyPurpose = SIGNING
  algorithm / payloadDigest / signature
  assertedSignedAt        (可选，本身不可信)
  signingTimeEvidence     (可选)
  custodyMode / assuranceLevel
  providerReceipt
```

**`actorId` 不在 envelope 里，也不在 canonical trace 里**（B5）：归因只由 organisation + `keyId` + `custodyMode` + `assuranceLevel` 承担；"谁操作了"留在可变 operational audit。四种模式输出同一个 envelope，但 `custodyMode` 与 `assuranceLevel` 不能省，否则统一接口会抹掉信任差异。

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

`CONFIRMED` 只能解释为“声明已签名、已进入平台控制域之外的归档并锚定”，不能显示为“平台已验证业务真实或合规”。

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
HandoverModule（B25）派生 status —— 不在 Core 内
```

状态包括 `AWAITING_RECEIPT`、`ACCEPTED`、`PARTIALLY_ACCEPTED`、`RECEIPT_REJECTED`、`DISPUTED`、`UNACKNOWLEDGED`。网络外对手方使用 `EXTERNAL_COUNTERPARTY` 单方边界声明；消费者零售不要求消费者签名。

**Core 只存两份 claim 与配对引用，不产生交接状态。** 配对键由 profile 指定，收货方必须引用发货方签发的键（候选：`bizTransaction` 的 desadv）；配不上则进入 reconciliation，不静默合并。缺数量时 HandoverModule 无法给出 `PARTIALLY_ACCEPTED`，这是能力降级而非 Core 故障。

双边确认只证明双方分别作出关联声明，不能防止双方串谋。Recall/audit 查询会保守包含争议、未确认和外部边界 edges。

## Product Profile

Versioned Product Validation Profile 可以配置：

- 标识粒度（`class-lot` / `instance`）；
- extension fields、类型、格式和枚举；
- units（UN/CEFACT code）、product vocabulary；
- required evidence-reference shape；
- consumer projection allowlist；
- 通用表单展示元数据。

**三条硬约束：**

1. **不得把 B3 的核心字段地板设为 optional 或重定义语义**（事件类型、时间、bizStep/disposition、source/destination、位置、对象标识、profile/canonicalisation 版本、签名、交接 `bizTransaction`）。
2. **粒度与数量必须一致**：`class-lot` 必须有 `quantityList` + `uom`（B9 部分收货与 B21 mass balance 的前提）；`instance` 级可用标识计数，重量退化为证据引用。
3. **发布前必须通过 conformance check**。

```text
profile conformance check（在 PUBLISH 之前执行）
- 缺少任一核心字段，或把核心字段标为 optional          -> 失败
- granularity=class-lot 但无 quantityList 或 uom     -> 失败
- TransformationEvent 缺 input/output                 -> 失败
- AggregationEvent / AssociationEvent 缺 parent 或 child -> 失败
- consumerProjectionAllowlist 引用未在 schema 中的字段  -> 失败
- 声明了 profile 不支持的 unit 或 vocabulary           -> 失败
```

地板清单由所有 ACTIVE 语义模块 manifest 的 `requiresFields` 并集编译而来（[B25](/decisions/catalog#b25)）；完整清单见 [Data & Access](/systems/data-access)。发布后地板即冻结，后续模块新增字段必须发新 profile 版本并走治理。

Profile 不配置 yield tolerance、fraud heuristic、mass balance、跨事件合理性或自动合规结论。发布后的版本不可原地修改，事件签名固定绑定所用版本。

## 内部组件边界

Core 只做机制（B25）：

```text
Capture API
  -> Canonicalisation & Profile Validator      （含 conformance check）
  -> Signature / Authority Validator
  -> Submission State Machine
  -> Archive & Anchor Orchestrator
  -> Confirmed Event Store（append-only）
  -> Evidence Graph Builder（只由 EPCIS 标准语义生成边）
  -> QueryPort（强制 scope + non-collapsing + watermark）
```

业务语义不在 Core 内，而是同一进程里的语义模块，各自通过 `QueryPort` 读事实、维护可重建投影：

```text
HandoverModule   RecallModule   ComplianceModule
ConsumerModule   AnalyticsInputModule   InsightsModule
```

模块的 `requiresFields` 并集经编译后冻结进 profile 版本（B11）；因此“某字段为什么必填”永远能回答到具体模块，没有消费者的字段（如 `readPoint`）默认 optional。

**Core 不提供 `getHandoverStatus()` / `isImpacted()` 这类方法。** 它只返回断言与边；任何结论性输出由模块产生，并且必须标注自己的 watermark 与能力边界。

第一版是模块化单体与一个 managed PostgreSQL，模块经 port 调用而不是独立部署；不为术语完整性预先部署 event store、broker、graph database 和独立 read database。

## 依赖与失败语义

- Identity/Governance 决定谁能以何种角色发布。
- Trust & Recovery 决定何时可以 receipt/confirm。
- Archive 或 KMS 故障时写入停在 `PENDING_ARCHIVE`。
- Public chain 故障时停在 `PENDING_ANCHOR`，不能自动确认。
- Projection 故障不回滚 canonical event，但查询必须显示 watermark/staleness。

完整路径见[事件接收与确认](/flows/event-acceptance)。
