# Regulatory Analytics

> 主要决策：[B15](/decisions/catalog#b15)、[B17](/decisions/catalog#b17)、[B21](/decisions/catalog#b21)

## 系统定位

Regulatory Analytics 与 Traceability Core 是本系统的两个 peer core subsystems，**都在系统边界之内**。Core 保留可归责的 source assertions；Analytics 在监管方的独立运行时域中执行普通领域启发式规则、统计分析和 optional ML，并把结果用于风险筛查、平台基础提醒和监管调查。

它不是只供监管人员“查东西”的附加报表工具，也不是 Traceability Core 的内部规则引擎。平台运营者不知道不同产品、地区和监管制度下的权威领域规则，因此 deterministic heuristics 与高级分析统一由监管方配置、版本化和审计。这里 optional 的是 ML 技术，而不是 Regulatory Analytics 这一核心业务能力。

它也不是边界外的第三方黑盒：平台自身的基础审查能力（缺证据、跨断言冲突、handover 异常、recall 辅助范围）由它提供，否则合规只能靠“平台不判”来回答。因此 C4 的 container / component / code 三层都必须覆盖它。它的运行时、数据边界和治理权属于监管方；平台只实现并运维 runtime、registry 接口、export 入口和 advisory 接收端。

它也不是平台用来自动决定违法、召回或事件有效性的组件：规则执行结果必须保留来源、版本、watermark 和保证等级，正式监管结论仍需 authorised officer 签署；它同样不判断哪条冲突声明为真。

## 控制域与 C4 分解责任

```text
System boundary
├── Platform control domain   -> Traceability Core
└── Regulator control domain  -> Regulatory Analytics
        ^  minimised projection
        |  signed AdvisoryFinding
        `-- 这条线即主要 trust boundary
```

| C4 层 | 最少需要出现 |
|---|---|
| Container | Analytics Input/Export Gate、Rule & Model Registry、Screening Scheduler + Runner pool、Finding & Advisory Store、Disclosure & Advisory Publisher；ML 侧 Training Snapshot、Model Evaluation/Registry、Human Review Queue |
| Component | 每 container 2–3 个：Watermark Verifier、Dataset Packager、Rule Version Loader、Rule Validator、Finding Evaluator、Dedup/Expiry、Audience Resolver、Advisory Signer |
| Code | `Rule`、`RuleVersion`、`ScreeningRun`、`DatasetSnapshot`、`Finding`、`AdvisoryFinding`、`DisclosurePolicy`、`ModelVersion`、`ReviewDecision` |

规模控制在这个量级：再细会与“避免 feature concentration / dense structure”冲突，再粗则无法说明 rule 版本、watermark 和披露控制究竟落在哪个组件上。

## 规则所有权

`RuleVersion` 由监管方密钥签署后进入 Registry；平台只提供 runtime 与 registry，不 author、不改规则、不扩大适用范围。这与“平台跑账本、但由组织签交易”是同一个模式，用来回答“平台团队实现了规则引擎，是否等于平台在定义规则”。

关闭 Analytics 属于**系统内**降级，而不是外部依赖故障：ingestion、trace query、consumer view 和监管人员手工调查继续运行，但 risk assessment 必须显示 `DELAYED/UNAVAILABLE`，过期 finding 停止当前态展示。这同时是可用性战术的正面例证——异步解耦、可选依赖、advisory 不参与写入路径。

## 合规能力的三层分工

| 层 | 机制 | 权威来源 | 是否阻断写入 |
|---|---|---|---|
| 准入层 | regulation profile 的 mandatory evidence requirements、EPCIS 结构与 vocabulary | 联盟治理发布的 profile | 是 |
| 筛查层 | deterministic rules / statistics / optional ML → `AdvisoryFinding` | 监管方持有并签署的 `RuleVersion` | 否 |
| 结论层 | Assessment/Inspection、Recall/Safety Notice | 监管方或责任组织的组织密钥 | 否（追加记录） |

三层共同的前提是 Traceability Core 提供可核验、不可静默改写的证据链。判定权始终留在第二层（规则 owner）和第三层（签署者），平台不自行添加业务门槛。

## 身份与权限分离

| 能力 | Regulator officer | Analytics service |
|---|---|---|
| 读取 confirmed consortium trace | 通过 regulator role | 只读 purpose-minimised projection |
| 读取完整 archive | 必要时经授权路径 | 无直接 KMS/archive 权限 |
| 访问 private evidence | 具体案件和记录的法律/治理依据 | 日常筛查不允许 |
| 发出 evidence request/行使权力 | 可以 | 不可以 |
| 产生风险提示 | 可以 | 可以，默认 regulator-private |
| 签署正式 Assessment/Inspection | authorised officer | 不可以 |
| 自动改变 event/handover/recall | 不可以原地修改 | 不可以 |

## 输入投影

```text
CONFIRMED consortium assertions at watermark W
  -> field- and purpose-minimised dataset
  -> dataset/schema version + recipient + expiry + audit ID
  -> Regulatory Analytics
```

可包含 event relationships、handover claims、sensor summaries、evidence status、correction history 和必要 organisation/location identifiers。不得包含 raw telemetry、完整文件、credentials 或 signing material，也不能根据 reference 自动追取 ProtectedResource。

第一版不分析 pending assertions；其 freshness SLO 明确包含普通事件等待 public-chain finality 的时间。

### 私有证据的唯一取用通道

Analytics **不能任意追取** ProtectedResource。唯一例外来自 B23：所有者提交时已把内容加密给监管 scope，Analytics 用自有密钥解密并对照 `plaintextCommitment` 校验。

这条通道的性质要写清：

- 授权来自**所有者**，不是平台或 Analytics 的权限扩张；
- 平台全程无法解密，因此也无法审计"谁真的解开了"，只能审计"谁被授权持有 key"；
- 没有被加密授予的证据只能按案件向所有者索取，平台负责转达，不负责取证。

## 输出与披露

```text
private RiskAlert
  -> regulator review
  -> optional evidence request / investigation
  -> formal human-signed Assessment, Recall or Safety Notice

approved rule/finding
  -> signed AdvisoryFinding
  -> Platform Advisory Ingestion
  -> permitted participant reminder
```

## 跨租户接口

本子系统跑在监管方租户里，所以和平台之间只有三条流，且都是签名消息：

```text
平台 → 监管方    DatasetSnapshot（最小化 + purpose + expiry + watermark）
监管方 → 平台    RegulationRequirement / RuleVersionManifest（归档并锚定）
监管方 → 平台    signed AdvisoryFinding（含撤回）
```

**传输认证不是授权**：mTLS/token 只证明调用方身份，权威性来自监管方签名，平台用 `EventSignatureVerifier` + Organisation Key Registry 验。

| 契约项 | 约定 |
|---|---|
| 幂等 | 按 `findingId` 去重，重复推送不产生多条 |
| watermark 回显 | finding 携带 `dataWatermark`，平台不能用当前 watermark 替代 |
| 过期 | `expiresAt` 到期停止当前态展示，历史保留 |
| 撤回 | 同一 `findingId` 重新签名并带 `status: ACTIVE \| RETRACTED`，追加不覆盖 |
| 通道活性 | 平台自观测，与监管方自报的 `analysisHealth` 分开显示 |

### 什么才上链：由法律效力决定

| 产出 | 法律效力 | 上链 | 机制 |
|---|---|---|---|
| 日常 advisory / ML 提示 | 无，仅供参照 | **否** | 签名消息 + 平台 advisory store，按 `expiresAt` 过期 |
| 实质调查材料（evidence request、调查笔记） | 过程材料 | **否** | regulator-private audit，不进 canonical trace |
| 正式 Assessment / Inspection / Recall Notice | 有 | **是** | 本身就是 signed canonical event，走正常 capture → archive → anchor |

第三行不需要额外机制——**正式声明上链是它作为 canonical event 的自然结果**，不是额外的"锚定动作"。

**不新增 advisory 的 Merkle leaf。** 代价是 prelim advisory 没有链上痕迹，平台理论上可事后否认曾展示某条提示；缓解靠两点，都不上链：发行方（监管方）自己留底、平台 advisory store 保留原始 signed payload 与接收时间且不原地修改。因为 prelim advisory 没有法律效力，这个强度与后果是匹配的。

### 两个健康信号不能混

平台看不到 Analytics 的运行状态，只能看通道：

```text
analysisHealth            监管方自报
advisoryChannelLiveness   平台自观测：最后一次成功接收时间
```

任一为 stale，UI 必须显示"提示可能不完整"，不能因为"最近没收到 advisory"就暗示"没有风险"。

`AdvisoryFinding` 至少绑定 issuer、rule/version、affected references、severity/reason codes、data watermark、generated/expiry time、disclosure scope 和 regulator signature。它不进入 canonical trace，不改变 event validity，也不自动成为 recall。

### 基础规则如何授权给平台

监管方可以把部分基础 `ruleId/ruleVersion` 的输出标为 `SUBJECT_ORGANISATION` 或 `CONSORTIUM_ADVISORY`。第一版仍由规则在监管方运行时域（系统边界内、监管方控制）中运行，再向平台返回 signed `AdvisoryFinding`；平台据此生成基础提醒，但不能修改规则、重新解释 severity 或扩大 audience。

这实现了“监管方把基础规则能力授权给平台使用”，同时避免平台维护一套未经授权的领域规则副本。未来若低延迟确实要求平台本地执行，可以单独设计 signed declarative rule package 与 sandbox；它不能悄悄进入 Core write validation。

## 披露范围

- `REGULATOR_ONLY`：监管人员内部使用；
- `SUBJECT_ORGANISATION`：只通知涉及组织；
- `CONSORTIUM_ADVISORY`：只面向明确获准的联盟 audience；
- `PUBLIC`：自动 analytics output 不允许，必须独立人工签署发布。

行业协会当前不是 Regulatory Advisory issuer。它可以通过联盟治理提出 Product Profile、vocabulary 或行业指导；若未来允许其直接发出提示，需要与监管 advisory 分开的 authority type、适用范围和 UI 语义。

## Freshness 与故障

Analytics 对外发布：

```text
analysisInputWatermark
lastSuccessfulEvaluationAt
activeRuleSetVersion
analysisHealth = CURRENT | DELAYED | UNAVAILABLE
```

Analytics 故障时，trace ingestion/query、recall traversal 和人工调查继续运行。UI 必须显示 `Risk assessment delayed/unavailable`；“没有当前 finding”只能表示对已成功评估到的 watermark 未产生提示，不能解释为没有食品安全风险。

## C4 最小覆盖范围（首版）

按 [B21](/decisions/catalog#b21)，本子系统必须出现在 container / component / code 三层；但首版只覆盖到**边界自洽**所需的粒度，不追求内部完备。

### Containers

| Container | 职责 |
|---|---|
| Analytics Workspace | 接收数据集、在固定 watermark 上执行规则、产出 finding、发布 advisory |
| Rule & Model Registry | 保存监管方签署的 `RuleVersion`（以及将来的 `ModelVersion`） |
| Finding & Advisory Store | 保存 private finding 与已授权 advisory，携带 watermark 与 expiry |

### Components（Analytics Workspace 内）

| Component | 职责 |
|---|---|
| Dataset Intake | 校验 dataset schema/version、调用方 service identity、watermark、purpose 与 expiry |
| Rule Loader & Validator | 从 registry 装载 `RuleVersion`，校验监管方签名与适用范围 |
| Screening Runner | 在固定 watermark 上执行 deterministic rules（首版不含 ML） |
| Advisory Publisher | 套用 disclosure policy、签名、路由回平台的 Advisory Ingestion |

### Code（对应 3.8）

`Rule`、`RuleVersion`、`RuleVersionManifest`、`DatasetSnapshot`、`ScreeningRun`、`Finding`、`AdvisoryFinding`、`DisclosurePolicy`

### RuleVersion 的两处存放

```text
监管域：规则正文（Rule）+ 签署后的 RuleVersion
平台侧：RuleVersionManifest（ruleId/version、issuer、effective、scope、
        ruleBodyDigest、disclosuresAllowed、regulatorSignature）
        → 进 archive + Merkle 锚定
```

正文不进 `CONSORTIUM`：把筛查规则公开等于告诉参与方"哪里会被查"，会同时伤害筛查效果和监管调查利益。平台验证时只比对 digest；需要复核时由监管方向审计方出示正文。

撤回 = 发新 `RuleVersion`（`supersedes`），不回溯已签发的 `AdvisoryFinding`；finding 的有效性由自身 `ruleVersion`、`expiresAt` 和 `dataWatermark` 决定。

### 首版明确不做

- 模型训练管线、drift 监控、human review 队列 UI（属 ML 深度，见扩展条件）；
- 多个监管域的多租户隔离（首版一个 NSW 监管域）；
- 流式或低延迟执行（B21 已定不做 provisional analytics path）。

### 什么时候才扩到完整设计

满足任一条件才扩，否则维持最小覆盖：

1. 4.B 需要 ML 深度（模型版本、训练快照、评估、HITL）才够分；
2. 真出现第二个监管域或第二个监管机构；
3. 首版 deterministic rules 的容量或时延被实测证明不足。

当前判断：4.B 的加分可以用已有的 IoT 叙事获得（判分表措辞是 AI/ML **and/or** IoT），因此完整设计的投入产出比很低。
