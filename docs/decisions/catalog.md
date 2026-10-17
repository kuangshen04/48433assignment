# 决策目录

本页是[完整决策日志](/decisions/log)的展示索引。完整边界条件、否决方案和 trade-off 保留在日志原页；这里提供稳定编号、状态和当前结论，供系统页引用。

状态含义：

- **Baseline**：背景直接支持或已经接受，后续设计应遵守；
- **Conditional baseline**：依赖显式业务/治理假设，报告必须写明；
- **Open**：边界已确定，但产品、参数或运营主体仍需关闭。

> 修订记录只有一份，在[完整决策日志](/decisions/log)头部的修订说明里；本页只同步状态与结论，不重复写改动说明。
>
> 2026-10-18 文档治理：决策日志回到「定位 + 原因 + 舍弃什么」。字段地板、conformance 清单、`ProtectedResource` 字段、注册表与请求绑定、`QueryPort` / `ModuleManifest` / 模块清单等**设计内容已移入系统页**（[Data & Access](/systems/data-access)、[Traceability Core](/systems/traceability-core)、[Identity & Governance](/systems/identity-governance)、[Semantic Modules](/systems/semantic-modules)）。冲突时行为以系统页为准、理由以日志为准；分权规则见[阅读方式](/architecture/reading-guide)。

## 第一层：背景充分支持的决定

<a id="a1"></a>
### A1 · 系统不是农业 ERP

**Baseline.** 系统是跨组织追溯层，负责共享 trace、消费者查询和监管调查入口，不接管库存、财务、订单、生产计划和内部质量流程。

<a id="a2"></a>
### A2 · 参与方保留自己的业务软件

**Baseline.** 小型参与方可使用 PWA/表单，大型企业通过 ERP/WMS/TMS/IoT gateway 集成；平台统一交换契约，不统一内部系统。

<a id="a3"></a>
### A3 · EPCIS 是 canonical event model

**Baseline.** 使用标准 EPCIS event types、bizStep、disposition 和 source/destination；领域中的 ShippingEvent 等名称只是便于讨论的简称。

<a id="a4"></a>
### A4 · 区块链不证明物理事实

**Baseline.** 架构保证 attribution、authorisation、content integrity、correction history 和 lineage provenance/reconstructability，不保证货物、位置或业务声明物理真实。

<a id="a5"></a>
### A5 · 完整 payload 不上链

**Baseline.** 公共链只保存 commitment/Merkle root；完整 canonical payload 进入外部归档（平台控制域之外的加密副本）；高频或私有证据使用 ProtectedResource。

<a id="a6"></a>
### A6 · 正式历史 append-only correction

**Baseline.** 已发布数据不原地覆盖，通过 correction event 或合法 EPCIS Error Declaration 保留完整更正历史。

<a id="a7"></a>
### A7 · 第一版采用模块化单体

**Baseline.** 使用 managed PostgreSQL、transactional outbox 和 targeted projections，不预先部署完整微服务、Event Sourcing、broker 和多种专用数据库。

<a id="a8"></a>
### A8 · IoT/AI 不成为 canonical write path 的必要依赖

**Baseline.** IoT 提供 source evidence；Regulatory Analytics/optional ML 提供风险分析。核心追溯在外围系统关闭时仍可工作。

## 第二层：已经接受的额外前提

<a id="b1"></a>
### B1 · 平台运营者不被完全信任

**Conditional baseline.** 参与方信任平台提供服务，但不授予其单方面静默改写、销毁密钥或垄断已接受历史的权力；当前模型仍允许获授权 runtime 读取 consortium plaintext。

**为什么是项目成立前提：** 作业明确要求 blockchain。如果完全信任平台控制 payload、唯一副本、密钥和验证结果，managed database + WORM backup 已经足够，继续使用 blockchain 就是 theatre。B1 是有意建立的场景，使公共链确实承担平台控制域之外的 existence/integrity checkpoint；最终部署若没有真实独立的 archive/KMS/recovery control，便没有兑现该决策。

**两种表述（不是两个决定）：** 日志保留内部表述（"参与方不完全信任运营者"，便于向组内解释为什么每条约束是 load-bearing）；**报告用对外表述**——跨组织共享历史本身就要求没有单一所有者，因此任何一方包括运营方都不能单方静默改写、且第三方可独立验证。机制完全相同，对外表述不增加任何能力声明。

<a id="b2"></a>
### B2 · 平台失效后恢复最小完整 trace

**Conditional baseline.** 恢复范围包括 canonical EPCIS、signatures、profiles、identity/key/governance history 和 chain/archive metadata，不强制恢复所有 raw telemetry 与业务附件。按 B3 的划分，各成员恢复自己的 scope，完整联盟历史由全 scope 方（监管方、审计者、受托恢复方）恢复；`logical RPO=0` 衡量"存在且可恢复"，不要求每个成员都能恢复全部。

<a id="b3"></a>
### B3 · PUBLIC / CONSORTIUM / PRIVATE 三层数据模型

**Conditional baseline.** Active consortium participants 共享 canonical trace core；消费者只读 allowlisted public projection；敏感证据不上平台，只在 canonical event 留加盐承诺（B23）。联盟内广泛共享是假设，需利益相关方验证。

**保证范围（验证 ≠ 重建）：** 任一成员可独立验证"历史是一条 append-only 日志、自己的记录已被纳入"（inclusion + consistency proof），并可重建自己 scope 内的历史；完整历史的重建与语义验证由全 scope 方执行。这是对**能力声明**的收窄，不影响 B1 的完整性保证——完整性验证不需要明文。

**Epoch 与历史访问：** 新成员默认只获得当前及之后的 KEK epoch，不自动取得加入前的明文访问权；历史访问是显式治理授予。v1 的 scope = 全体 active 成员（扁平）；按 trace 收窄是治理参数，因为 `keyId/keyEpoch` 只是 envelope 元数据，变更不影响 canonicalisation、签名与 anchor 格式。

**核心字段地板：** 事件类型、时间、`bizStep`/`disposition`、`source`/`destination`、位置、对象标识、profile/canonicalisation 版本、`captureRecordId`/`epcisEventId`、签名与交接 `bizTransaction` 一律必须在 canonical event 内，profile 不得把它们设为 optional。**数量与粒度绑定**：`class-lot` 级事件必须带 `quantityList` + UN/CEFACT `uom`（B9 部分收货、B21 mass balance 的前提）；`instance` 级（SSCC 整车/整托）可用标识计数，重量等退化为证据引用。

<a id="b4"></a>
### B4 · 保证限制在可归责与确认后完整性

**Baseline.** 公共链降低平台单方事后改写风险，但不防业务方串谋提交虚假声明，也不解决上链前入口 censorship；不同签名 custody 模式具有不同 non-impersonation assurance。

<a id="b5"></a>
### B5 · 统一 SignatureEnvelope，保留 custody 差异

**Baseline.** 支持 enterprise self-custody、**device-bound self-custody**、assisted external custody 和 delegated platform custody。签名真实性、acceptance-time authority 与 trusted signing-time evidence 分开验证；客户端时间不能绕过撤销。

**Device-bound 档位的边界：** 它是**组织的设备密钥**（私钥不可导出、绑定一条 delegation），不引入自然人身份，因此只证明"哪个组织"、不证明"哪个自然人"；设备丢失或共享会削弱 assurance。**载体是硬边界**——iOS 上可靠的密钥持久化不可得，该档位只在支持的载体上提供，其余退回 draft + 联网补签。不要对外承诺"所有小农场都能离线签名"。

**`actorId` 已移出：** canonical trace 与 `SignatureEnvelope` 都不再带自然人标识，归属只由 `signerOrganisationId` + `keyId` + `custodyMode` + `assuranceLevel` 承担（EPCIS 本无 who 维度）。"谁操作了"留在可变 operational audit。代价：immutable 层不再能回答"哪个员工签的"，内部追责需组织自证。

<a id="b6"></a>
### B6 · ArchiveAck + public finality 后才 CONFIRMED

**Baseline.** 普通 event 必须先进入**平台控制域之外**的 immutable archive（副本持有者见 B8），再完成公共链 finality。门禁比较的是"是否已离开平台控制域"，不是"是否由某类专职机构保管"。Official Recall/Safety Notice 可在签名与 ArchiveAck 后以 `VERIFIED_PENDING_ANCHOR` 紧急发布。

<a id="b7"></a>
### B7 · 固定窗口 deterministic Merkle batching

**Baseline.** 平台 relayer 提交 versioned Merkle root；leaf 绑定 event identity、canonical digest、signature digest 和 ArchiveAck digest。首版不要求 secondary relayer。**批次序列本身必须可验证**：root 承诺前序 root（running hash chain）或采用支持 consistency proof 的 log 结构——只有独立 root 时无法证明"没有批次被跳过或重排"，而这是 B3 中成员可独立验证的那一半。

<a id="b8"></a>
### B8 · 一个平台控制域外的强制副本 + 联盟控制 KMS

**Conditional baseline.** 至少一个位于平台控制域之外的持久副本；**持有者可以是成员或监管方 mirror，也可以是独立账户的商用 WORM，不要求专职 archive 服务商**——首版把"签约独立操作方"作为演进目标而非上线前置条件（理由见日志 B8）。额外 mirrors 可选。Consortium KEK 使用由联盟/受托方控制账户和 recovery authority 的专业 KMS。

**演进触发条件：** 监管或成员治理要求第三方持久化证明、mirror 覆盖不足、或审计要求 retention commitment 具合同效力时，引入签约操作方作为第二个强制副本。

<a id="b9"></a>
### B9 · 联盟内 B2B handover 使用两份独立 claims

**Baseline.** Sender 与 receiver 分别签署；Core 只存两份 claim 与配对引用，**handover status 由 HandoverModule 派生**（B25）。网络外交易方标为 `EXTERNAL_COUNTERPARTY`，消费者零售不要求消费者签名。

**配对键用 `bizTransaction`（desadv），不自造标识：** 发货方 shipping claim 引用自己签发的 desadv，**收货方 receiving claim 必须引用同一个 desadv**，HandoverModule 按它配对。理由是 EPCIS 本就把物理流（`quantityList`）与商业单据（`bizTransactionList`）分开，而 desadv 是唯一"双方在看同一个东西"的单据。`EXTERNAL_COUNTERPARTY` 可以没有配对键。收货方不复用发货方的键，`ACCEPTED` 就会退化成启发式匹配、`PARTIALLY_ACCEPTED` 不可靠。

<a id="b10"></a>
### B10 · Append-only trace core，不采用全应用 Event Sourcing

**Baseline.** Canonical records append-only；普通应用状态使用事务模型；outbox 驱动 archive、anchor 和 projections。数据库是运营索引而不是唯一历史。

<a id="b11"></a>
### B11 · 不可变版本化 Product Validation Profiles

**Baseline.** Profile 配置字段、单位、vocabulary、evidence reference、consumer allowlist 和 UI metadata，不成为通用规则引擎或合规判断来源。

**三条硬约束：** ① 不得把 B3 的核心字段地板降级为 optional 或重定义语义；② 必须声明标识粒度（`class-lot` / `instance`）且与数量规则一致；③ 发布前必须通过 conformance check（缺核心字段、粒度与 quantityList 不一致、Transformation 缺 input/output、allowlist 引用未定义字段等一律失败）。扩展字段按「监管筛查需要 → 进 event / 仅举证 → 证据引用 / 否则不收集」三问判定，见日志 B11。

<a id="b12"></a>
### B12 · 三类 workload planes

**Baseline.** Participant ingestion、regulator investigation/export 与 public consumer delivery 分离资源和读取策略；农村连接通过 offline queue 处理。

<a id="b13"></a>
### B13 · 写 fail-closed/resumable，读显式降级

**Baseline.** 必要依赖在哪一步失败就停在哪一步，使用稳定 identity 幂等续跑。既有 confirmed 数据尽量继续读取，并显示 watermark、staleness 和 dependency health。

<a id="b14"></a>
### B14 · Raw IoT 是 participant-controlled PRIVATE evidence

**Baseline.** Core 保存 profile-required summary、source-reported exception、reference、provenance 和 commitment。Evidence status 是客观状态，是否构成风险由 Analytics/监管人员判断。平台托管 raw telemetry 时按 B23 采用零知识托管，平台没有解密能力。

<a id="b15"></a>
### B15 · Regulator 与 Analytics 使用不同身份权限

**Baseline.** Analytics 只读 purpose-minimised confirmed projection，无任意 archive/KMS/private-evidence 权限，不能继承监管人员法定能力。该子系统位于系统边界内但属监管方运行时域（B21）：边界内不代表平台可获得它的规则、模型或 finding 数据。**唯一例外**是 B23 的窄通道——所有者提交时已把内容加密给监管 scope，Analytics 可用自有密钥解密并对照 commitment 校验；授权来自所有者，不是权限扩张。

**Evidence request 只是审计记录：** 平台无法代理解密，因此取用私有证据必须落成一次请求。它是一条 `AuditRecord(type=EVIDENCE_REQUEST)`（caseId、requester、owner、resourceRefs、legalBasis、有效期、`outcome`），`outcome` 由参与方行动**推导**、超时为 `NO_RESPONSE`；**不建工作流引擎、portal、催办或 SLA**；请求记录属 regulator-private、不进 canonical trace，可信性靠最终签署的 assessment 引用 `requestId`。

<a id="b16"></a>
### B16 · Human/Device IAM 在外围，Organisation Governance 在核心

**Baseline.** 企业/IoT vendor 管理账号与设备 fleet；核心保存 organisation membership、public keys、delegations 和 signed GovernanceRecords。扩权变更在 archive/anchor finality 后生效，紧急撤销可先 fail closed。**组织是唯一身份与租户单元，每请求显式绑定 acting organisation，不建组织层级**（见 B24）。

<a id="b17"></a>
### B17 · Core 记录断言，不裁决真伪

**Baseline.** Core 只做 admission/protocol validation，并原样保留相互冲突的 signed assertions；它不判定哪一条冲突声明为真（例如同一序列化对象被两项 transformation 分别声称消耗时，核心无从观察现实），也不产生 anomaly、mass balance、fraud 或 compliance verdict。判定只能由有权主体以签署声明进入历史：EPCIS Error Declaration、signed Recall/Safety Notice，或 regulator-signed Assessment/Inspection。

**必须配对的表示义务（non-collapsing）：** lineage、recall、handover 和 audit 的默认视图不得把竞争断言折叠成一条路径，必须多边并存并保留 provenance，不排序、不打分、不选代表路径。**该义务相对 scope**：可读范围内的竞争必须并存；超出 scope 的内容显示为“存在但不在你的可见范围内”，不得静默丢弃或合并。平台不得创建 `UNRESOLVED_INPUT` 这类 verdict；但“该对象存在两条由不同组织发布、无法相互衔接的已确认断言”属于 provenance fact，必须可见。

**为什么是项目成立前提：** 平台不知道不同产品、地区和监管制度下的权威领域规则，无权自行发明；它同时无法观察现实，因此连“哪条冲突声明为真”都不能判断。普通 deterministic heuristics 与高级 statistics/optional ML 因而统一放在 Regulatory Analytics 中，由监管方配置、版本化、审计并承担规则责任。Optional 的是 ML 技术，不是该核心业务子系统。

<a id="b18"></a>
### B18 · Recall 是保守 lineage query，不是物理下架

**Baseline.** 平台查询可能受影响对象、展示授权 notice 和记录后续 claims；ERP/WMS/POS 与人员执行封存、下架、退货和销毁。**遍历策略（跟哪些边、时间范围、哪些 handover 状态必须保守纳入）归 RecallModule（B25），Core 只提供带 scope / non-collapsing / watermark 的边查询。** 结果按 B17 的规则呈现：竞争边并存，不选代表路径、不打分；`confirmedImpact` 与 `recentPendingClaims` 分开展示，不静默混入。**成员自行运行的遍历只覆盖其 scope，必须标注 `scope-limited`，不能作为权威影响范围**；权威遍历由全 scope 方在同一 watermark 与同一遍历规则下执行。

<a id="b19"></a>
### B19 · 标识符由参与方分配，QR 不是防伪证明

**Baseline.** 优先使用 GTIN/GLN/SSCC 等标准标识，缺少外部 scheme 时使用 network-scoped fallback。QR 解析 public projection，不证明标签物理真实性。

<a id="b20"></a>
### B20 · NSW/Australian residency 与按类别 retention

**Conditional baseline.** 非公开数据、archive 和 KMS 默认位于 Australian regions。Canonical trace 默认按七年 capacity/retention assumption 设计，可由 product/jurisdiction/legal hold 调整；到期后删除 payload/DEK 并保留最小删除审计和非个人 commitment。

<a id="b21"></a>
### B21 · Regulatory Analytics 是边界内的 peer subsystem

**Baseline.** 它与 Traceability Core 同属系统边界内的两个 peer core subsystems，但拥有独立运行时域、独立 service identity，以及由监管方持有的规则和模型所有权。**它整体运行在监管方账户内**：平台构建并交付制品与接口，但不持运行时凭据、不能远程推送。Findings 默认 regulator-private；监管方可把指定基础 `ruleId/ruleVersion` 的输出授权为受限 signed AdvisoryFinding，由平台用于基础提醒。`RuleVersion` 由监管方密钥签署，平台不取得修改或扩大规则的权力。Analytics 有独立 watermark/health，规则未运行不能展示为“无风险”。行业协会当前不是 Regulatory Advisory issuer。

**为什么不当成外部黑盒：** 平台自身的基础审查能力（缺证据、跨断言冲突、handover 异常、recall 辅助范围）由该子系统提供；若画在系统边界之外，合规只能靠“平台不判”回答，AI/ML 的模型版本、训练数据快照、评估与 human-in-the-loop 也没有可描述的架构位置。

**由此产生的义务：** C4 3.2–3.10 必须覆盖该子系统（container / component / code 三层都要有），并把 Traceability Core ↔ Regulatory Analytics 标注为主要信任边界。关闭 Analytics 属于**系统内**降级：追溯、查询与人工调查照常，但 risk assessment 必须显示 `DELAYED/UNAVAILABLE`。首版只做**最小覆盖**（3 container / 4 component / 8 类），扩展条件写在 [Regulatory Analytics](/systems/regulatory-analytics)。

**租户归属由控制平面决定：** 判据不是"能不能登录数据库"，而是"谁掌握控制平面"——掌握者至少能通过 dump 进程内存、读宿主存储或替换镜像拿到明文，所以"同集群、只是没有 DB key"不构成隔离。因此 Analytics 整体搬进监管方账户，**runner 与 registry 不能拆**（runner 执行规则必须读规则正文，拆开就毁掉"只锚定 digest、正文不外泄"）。代价是平台失去远程运维能力：出问题只能出制品、由监管方上线。

**`RuleVersion` 的锚定：** 规则正文留在监管域，只把 `RuleVersionManifest`（ruleId/version、issuer、effective、scope、`ruleBodyDigest`、disclosures、签名）放进 platform archive 与 Merkle 锚定——这样"当时依据哪条规则"可事后验证，又不会把筛查规则正文暴露给全体成员。撤回通过发布新版本实现，不回溯已签发的 finding。

**跨租户接口（三条流）：** 平台 → 监管方送 `DatasetSnapshot`；监管方 → 平台送 `RegulationRequirement` / `RuleVersionManifest`（归档并锚定）与 signed `AdvisoryFinding`。**传输认证不是授权**——权威性来自监管方签名。finding 按 `findingId` 幂等、回显 `dataWatermark`、`expiresAt` 到期即停展示；撤回用同一 `findingId` 重签并带 `status: ACTIVE | RETRACTED`（追加不覆盖）。

**`RegulationRequirement` 不是 profile 的别名：** 它是监管方签署、可独立定位的 artifact，只允许做两件事——绑定 profile 里已存在的字段，或用**同一套 primitive 类型系统**新声明字段。它不能引入平台不认识的类型，也不能改已冻结的 profile 版本。核心字段地板因此由「模块 manifest 的 `requiresFields` ∪ 适用辖区要求」编译而成：**加一个辖区是加约束，不是加架构**。

**上链由法律效力决定：** 日常 advisory / ML 提示**不上链**（只供参照、无法律效力）；实质调查材料留在 regulator-private audit；正式 Assessment / Inspection / Recall Notice 上链——因为它们**本来就是 signed canonical event**，不是额外锚定。因此不新增 advisory 的 Merkle leaf；代价是 prelim advisory 无链上痕迹，靠发行方留底 + 平台 advisory store 不可覆盖缓解。`analysisHealth`（监管方自报）与 `advisoryChannelLiveness`（平台自观测）必须分开显示。

<a id="b22"></a>
### B22 · 使用显式、可测试的 NSW pilot 数量假设

**Conditional baseline.** 200 初始组织、10k events/day、50 events/s offline burst、5k consumer RPS、logical RPO=0 target、PostgreSQL RPO 5m、core RTO 4h、regional rebuild 24h；均需测试验证。

<a id="b23"></a>
### B23 · PRIVATE 不上平台，只留加盐承诺；分享由所有者授予

**Baseline.** `PRIVATE` 内容默认保存在参与方一侧，平台只保存 `plaintextCommitment`（加盐摘要）与资源引用。可选的平台托管是**零知识**的：平台只有密文，无解密能力、无 key escrow。分享通过**所有者**把内容加密给指定接收方（含监管 scope）实现，不使用平台计算的 `accessScope`，也不引入事件级受众。

**收益而非限制：** commitment 随事件锚定后，参与方事后无法替换证据而不被发现；加盐使低熵内容不可被字典穷举；retention 到期后 commitment 仍在但无 nonce 无法反推内容。平台在提交时无法验证 commitment 对应真实材料——这正是“举证义务在参与方”的准确含义。

**明确不承诺：** 密钥恢复、平台侧取证、PRIVATE 内容的可用性进入 core RPO/RTO、删除的全局证明、元数据保密。详见日志 B23 的不承诺清单。

**`availabilityStatus` 是两个独立事实的并集：** `OBJECT_PRESENT`（平台确实存着密文，**不代表能解密**）、`OWNER_ASSERTED`（所有者声明持有，平台无法核实）、`UNKNOWN`（两者都无）。两条使用规则：`OBJECT_PRESENT ≠ 可读`、`UNKNOWN ≠ 不存在`——调查不能把"平台查不到"写成"对方没提供"。它不影响任何 canonical event 的有效性。

**`ENCRYPTION` 密钥生命周期与签名密钥相反：** 撤销只阻止"再加密给它"，已加密的密文仍可解；**旧私钥必须保留到最后一份用它加密的密文被删除**，否则历史证据永久不可读；丢失即永久不可解（无 escrow）。因此 `recipientKeyRefs` 必须带 `keyId`，且旧私钥销毁要与 B20 的 retention 终态联动。

**设计：** `ProtectedResource` 字段与 `availabilityStatus` 语义见 [Data & Access](/systems/data-access)。

<a id="b24"></a>
### B24 · 平台以组织为身份、访问与租户单元

**Baseline.** 不建设用户目录、岗位、审批流程或人员生命周期；组织内部授权由组织自己决定并声明为 delegation 断言。角色只保留少量固定值（OrgAdmin、EventPublisher、EvidenceManager、Viewer）。**每个请求必须显式携带 acting organisation**——因为一个 subject 可代表多个组织，不能从 token 推断，缺失时拒绝而不是取默认值。

**组织层级 out of scope：** 不建 `parentOrganisationId`。合作社、集团、多站点企业一律注册为多个 `organisationId`，用 delegation 表达代理关系；层级会污染 scope 计算、KMS epoch、签名归因与召回范围。触发条件：出现“父组织代为提交”的需求时先看 delegation 是否够用，不够再作为新架构前提评估。

**设计：** 四个注册表与请求绑定流程见 [Identity & Governance](/systems/identity-governance)。

<a id="b25"></a>
### B25 · Core 只做机制，业务语义放在语义模块里

**Baseline.** Core 收缩为机制：接收、验证、追加、确认、归档/锚定，以及**只由 EPCIS 标准语义生成**的边。handover 状态、召回遍历策略、合规重建、分析输入、运营洞察都是**同进程内的语义模块**，通过唯一的 `QueryPort` 读取事实，各自维护可重建投影。Core 不认识任何模块；这是分层，不是微服务。

**不可下沉的七条不变量：** 身份与幂等；完整性管道（签名/authority/archive ack/finality 门禁）；append-only 与 correction 结构；**scope 强制**；**non-collapsing 强制**；watermark 暴露；图的语义下限（边只能来自 EPCIS 标准语义）。第 4、5 条放在唯一查询入口，避免每个模块各自实现而漏掉。

**模块 manifest 驱动地板：** 每个模块声明 `requiresFields` / `requiresEdges` / `requiresPairingKey` / `produces` / `invariant`。所有 ACTIVE manifest 的字段并集**编译**进 profile 版本后冻结（B11），因此“没有消费者的字段不进地板”，新增模块等于收紧地板，属治理变更。

**核心分界：** Core 保证“这条事实是什么、你能否看见、你是否看全”；模块决定“它意味着什么”。模块能力可以降级，但不能影响确认、归档与锚定；任何结论仍作为签署事件走同一条 capture 路径。

**设计：** `QueryPort` 契约、`ModuleManifest` 定义与六个模块的读写/降级表见 [Semantic Modules](/systems/semantic-modules)。

## 第三层：仍需关闭的决定

<a id="c1"></a>
### C1 · Public network、anchor window 与迁移方案

**Open.** Payload/leaf/manifest 逻辑已定；仍需选择具体网络、15–60 分钟内的窗口/finality、contract mutability、gas/relayer 和 chain migration continuity。

<a id="c2"></a>
### C2 · PostgreSQL 产品级部署与恢复配置

**Open.** Australian primary region、单一 managed PostgreSQL 起步和 RPO/RTO target 已定；仍需给出具体 service、PITR/backup、成本和 load/recovery evidence。

<a id="c3"></a>
### C3 · 外部归档与 KMS 的运营主体与产品级恢复

**Open.** 独立控制域和跨 Australian failure domain 已定；仍需选定副本的持有者与账户归属（成员/监管方 mirror 或商用 WORM）、产品、recovery identity、key deletion protection、restore runbook、relayer wallet 和 Participant Gateway 首版范围。

## 已舍弃但保留的替代方案

Permissioned Consortium Ledger 仍是技术上可行的替代方案，但当前缺少足够、愿意承担成本且真正独立的 validator operators。项目因此采用 public-chain commitment + external archive + consortium-controlled KMS；不是因为 BFT 本身无效。

> 日志里的 D1–D7 是**原方案的产品 / 数据 / 签名 / 共识 / 生命周期分析与舍弃理由**，属背景材料而不是决策，因此不在本页编号，也没有锚点；需要引用时用[完整决策日志的 D 段](/decisions/log#layer-d)。
