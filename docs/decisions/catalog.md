# 决策目录

本页是[完整决策日志](/decisions/log)的**索引**：给每个决定一个稳定编号、状态和一句话结论，供系统页引用。完整边界条件、否决方案和 trade-off 在日志里；字段、接口、状态机等设计细节在系统页里。权威划分见[阅读方式](/architecture/reading-guide)。

状态含义：

- **Baseline**：背景直接支持或已经接受，后续设计应遵守；
- **Conditional baseline**：依赖显式业务/治理假设，报告必须写明；
- **Open**：边界已确定，但产品、参数或运营主体仍需关闭。

> 修订记录只有一份，在[完整决策日志](/decisions/log)的头部；本页只同步状态与结论。

## 第一层：背景充分支持的决定

<a id="a1"></a>
### A1 · 系统不是农业 ERP
**Baseline.** 跨组织追溯层：共享 trace、消费者查询、监管调查入口。不接管库存、财务、订单、生产计划或内部质量流程。

<a id="a2"></a>
### A2 · 参与方保留自己的业务软件
**Baseline.** 小参与方用 PWA/表单，大企业经 ERP/WMS/TMS/IoT gateway 集成；平台统一交换契约，不统一内部系统。

<a id="a3"></a>
### A3 · EPCIS 是 canonical event model
**Baseline.** 用标准 event types 与 `bizStep` / `disposition` / source / destination；领域名（如 ShippingEvent）只是便于讨论的简称。

<a id="a4"></a>
### A4 · 区块链不证明物理事实
**Baseline.** 保证 attribution、authorisation、内容完整性、纠错历史与 lineage 可重建；不保证货物、位置或声明在物理上真实。

<a id="a5"></a>
### A5 · 完整 payload 不上链
**Baseline.** 链上只存 commitment / Merkle root；完整 payload 进平台控制域之外的加密归档；高频或私有证据用 `ProtectedResource`。

<a id="a6"></a>
### A6 · 正式历史 append-only correction
**Baseline.** 已发布数据不原地覆盖；用 correction event 或合法的 EPCIS Error Declaration 保留完整更正历史。

<a id="a7"></a>
### A7 · 第一版采用模块化单体
**Baseline.** managed PostgreSQL + transactional outbox + targeted projections；不预先部署微服务、Event Sourcing、broker 和多种专用数据库。

<a id="a8"></a>
### A8 · IoT/AI 不成为 canonical write path 的必要依赖
**Baseline.** IoT 提供 source evidence，Analytics 与 optional ML 提供风险分析；外围系统关闭时核心追溯仍可工作。

## 第二层：已经接受的额外前提

<a id="b1"></a>
### B1 · 平台运营者不被完全信任
**Conditional baseline.** 参与方信任平台提供服务，但不授予其单方面静默改写、销毁密钥或垄断已接受历史的权力；获授权 runtime 仍可读 consortium plaintext。

报告用**对外表述**（多主体共享历史要求没有单一所有者、第三方可独立验证），日志保留内部表述；两套说法对应完全相同的机制，不增加任何能力声明。

<a id="b2"></a>
### B2 · 平台失效后恢复最小完整 trace
**Conditional baseline.** 恢复 canonical EPCIS、签名、profiles、identity/key/governance history 与 chain/archive metadata，不强制恢复 raw telemetry。成员恢复自己的 scope，完整联盟历史由全 scope 方执行；`logical RPO=0` 衡量"存在且可恢复"，不要求每个成员都能重建全部。

<a id="b3"></a>
### B3 · PUBLIC / CONSORTIUM / PRIVATE 三层数据模型
**Conditional baseline.** Active 成员共享 canonical trace core；消费者只读 allowlisted public projection；敏感证据不上平台，只在 canonical event 留加盐承诺（B23）。广泛共享是待验证的商业假设。

**保证范围（验证 ≠ 重建）：** 任一成员可验证"历史是 append-only、自己的记录已被纳入"（inclusion + consistency proof），重建受 scope 限制；完整重建由全 scope 方执行。KEK epoch 构成时间边界，v1 scope = 全体 active 成员。**收窄不是改参数**——它同时改动 scope 计算、epoch 授予与遍历可见范围。成员默认不持 KEK，读取走 `QueryPort`；需要自行重建时由治理授予某一 epoch 的 unwrap 权限，这就是成员侧的解锁通道。

**核心字段地板：** 事件类型、时间、`bizStep`/`disposition`、source/destination、位置、对象标识、profile/canonicalisation 版本、`captureRecordId`/`epcisEventId`、签名、交接 `bizTransaction` 必须在 canonical event 内，profile 不得设为 optional；**数量与粒度绑定**——`class-lot` 级必须带 `quantityList` + UN/CEFACT `uom`，`instance` 级可用标识计数。设计见 [Data & Access](/systems/data-access)。

<a id="b4"></a>
### B4 · 保证限制在可归责与确认后完整性
**Baseline.** 降低平台单方事后改写风险，但不防业务方串谋造假，也不解决上链前 censorship；不同 custody 档位的 non-impersonation assurance 不同。

<a id="b5"></a>
### B5 · 统一 SignatureEnvelope，保留 custody 差异
**Baseline.** 四档 custody——enterprise self-custody、device-bound self-custody、assisted external custody、delegated platform custody——输出同一个 envelope，但必须保留 `custodyMode` 与 `assuranceLevel`。签名真实性、acceptance-time authority、trusted signing time 分开验证。

**`actorId` 已移出**（EPCIS 本无 who 维度）：归因由 organisation + `keyId` + custody 档位承担，"谁操作了"只在可变 audit。**Device-bound 是组织的设备密钥**，不是个人密钥；载体是硬边界，不承诺"所有小农场都能离线签名"。

<a id="b6"></a>
### B6 · ArchiveAck + public finality 后才 CONFIRMED
**Baseline.** 门禁是"已离开平台控制域"且"达到所选 finality"，比较的不是"由哪类专职机构保管"。Official Recall/Safety Notice 可在签名与 ArchiveAck 后以 `VERIFIED_PENDING_ANCHOR` 紧急发布。**投影发布同样等到 finality**：receipt 是对参与方的持久性承诺，投影是对消费者与监管方的"不会被我改写"承诺；代价是最近一窗不可见，由 B18 的 `provisionalImpact` 处理。

<a id="b7"></a>
### B7 · 固定窗口 deterministic Merkle batching
**Baseline.** 平台 relayer 提交 versioned root；leaf 绑 event identity、canonical digest、signature digest、ArchiveAck digest；首版不要 secondary relayer。**批次序列本身必须可验证**（running hash chain 或 consistency proof），否则无法证明"没有批次被跳过"。

<a id="b8"></a>
### B8 · 一个平台控制域外的强制副本 + 联盟控制 KMS
**Conditional baseline.** 至少一个位于平台控制域之外的持久副本；**持有者可以是成员/监管方 mirror，也可以是独立账户的商用 WORM，不要求专职 archive 服务商**——签约操作方是演进目标而非上线前置条件。Consortium KEK 由联盟/受托方控制的专业 KMS 保护。

**持有强制副本有资格条件：必须能对实际保存的字节签发 `ArchiveAck`。** 只能存、不能签的普通对象存储桶只能当附加 mirror。**"独立"另有三条可执行验收测试**：平台无 delete/admin/billing 权限；删除需持有方与第三方共同批准；catalogue 可被非平台方独立枚举。

**演进触发条件：** 监管或成员治理要求第三方持久化证明、mirror 覆盖不足、或审计要求 retention commitment 具合同效力时，引入签约操作方作为第二个强制副本。

<a id="b9"></a>
### B9 · 联盟内 B2B handover 使用两份独立 claims
**Baseline.** Sender 与 receiver 分别签署；Core 只存两份 claim 与配对引用，**handover status 由 HandoverModule 派生**（B25）。配对键是 `bizTransaction(type=desadv)`：发货方签发、收货方必须引用同一个，否则 `ACCEPTED` 退化成启发式匹配。网络外对手方用 `EXTERNAL_COUNTERPARTY`，消费者零售不要求签名。

<a id="b10"></a>
### B10 · Append-only trace core，不采用全应用 Event Sourcing
**Baseline.** Canonical records append-only；普通应用状态用事务模型；outbox 驱动 archive、anchor 与 projections；数据库是运营索引而不是唯一历史。

<a id="b11"></a>
### B11 · 不可变版本化 Product Validation Profiles
**Baseline.** Profile 配置字段、单位、vocabulary、evidence reference、consumer allowlist 与 UI metadata，不做通用规则引擎或合规判断来源。

**三条硬约束：** ① 不得把 B3 的地板降级为 optional；② 必须声明标识粒度且与数量规则一致；③ 发布前必须通过 conformance check。扩展字段按「监管筛查需要 → 进 event / 仅举证 → 证据引用 / 否则不收集」三问判定。

<a id="b12"></a>
### B12 · 三类 workload planes
**Baseline.** Participant ingestion、regulator investigation/export 与 public consumer delivery 分离资源与读取策略；农村连接用 offline queue；edge sync lag、processing lag 与 anchor lag 分开度量。

<a id="b13"></a>
### B13 · 写 fail-closed/resumable，读显式降级
**Baseline.** 必要依赖在哪一步失败就停在哪一步，用稳定 identity 幂等续跑；既有 confirmed 数据继续可读，并显示 watermark、staleness 与 dependency health。

<a id="b14"></a>
### B14 · Raw IoT 是 participant-controlled PRIVATE evidence
**Baseline.** Core 只保存 profile-required summary、source-reported exception、reference、provenance 与 commitment。Evidence 状态是客观状态，是否构成风险由 Analytics/监管人员判断；平台托管 raw telemetry 时按 B23 采用零知识托管。

<a id="b15"></a>
### B15 · Regulator 与 Analytics 使用不同身份权限
**Baseline.** Analytics 只读 purpose-minimised confirmed projection，无任意 archive/KMS/private-evidence 权限，也不继承监管人员的法定能力。唯一例外是 B23 的窄通道——所有者已把内容加密给监管 scope，授权来自所有者。

**Evidence request 只是审计记录：** 一条 `AuditRecord(type=EVIDENCE_REQUEST)`，`outcome` 由参与方行动推导、超时为 `NO_RESPONSE`；不建工作流、portal、催办或 SLA，不进 canonical trace。

<a id="b16"></a>
### B16 · Human/Device IAM 在外围，Organisation Governance 在核心
**Baseline.** 企业/IoT vendor 管理账号与设备 fleet；核心只保存 organisation membership、public keys、delegations 与 signed GovernanceRecords。扩权变更在 archive/anchor finality 后生效，紧急撤销可先 fail closed。

**准入强度匹配影响半径：** 批准一个成员等于授予全网读取权，因此需要实体核验 + 现有成员背书 + 双人批准 + 按组织读取审计。**平台自身运维人员是独立的 `PLATFORM_OPERATOR` 主体**，不属任何 organisation，默认无明文读取权，break-glass 需双人批准且进不可变历史。

<a id="b17"></a>
### B17 · Core 记录断言，不裁决真伪
**Baseline.** Core 只做 admission/protocol validation，并原样保留相互冲突的 signed assertions；不判定哪条冲突声明为真，也不产生 anomaly、mass balance、fraud 或 compliance verdict。判定只能由有权主体以签署声明进入历史。

**必须配对的表示义务（non-collapsing）：** lineage、recall、handover 与 audit 的默认视图不得折叠竞争断言，必须多边并存、带 provenance、不排序、不打分、不选代表路径。该义务**相对于 scope**：超出 scope 的内容显示为"存在但不在你的可见范围内"。

**可验证性：** 边是 canonical events 的确定性函数（随 `edgeDerivationVersion` 版本化）。持明文的方可以重算边集并与查询结果比对，所以"漏边/折叠"是**事后可举证的事故**，不是实时保证——没有这条，"不裁决"就只是平台自律。

<a id="b18"></a>
### B18 · Recall 是保守 lineage query，不是物理下架
**Baseline.** 平台查询可能受影响对象、展示授权 notice、记录后续 claims；ERP/WMS/POS 与人员执行封存、下架、退货、销毁。遍历策略归 RecallModule（B25），Core 只提供带 scope / non-collapsing / watermark 的边查询。

成员自行运行的遍历只覆盖其 scope，必须标注 `scope-limited`；权威遍历由全 scope 方在同一 watermark 与同一规则下执行。`confirmedImpact` 与 `recentPendingClaims` 分开展示，并且**对后者跑同一套遍历规则产出 `provisionalImpact`**：标 `provisional`、不合并、不排序为权威范围——否则最近一窗的货在结构性遍历里根本不存在。

<a id="b19"></a>
### B19 · 标识符由参与方分配，QR 不是防伪证明
**Baseline.** 优先使用 GTIN/GLN/SSCC 等标准标识，缺少外部 scheme 时用 network-scoped fallback；QR 只解析 public projection，不证明标签物理真实性。

<a id="b20"></a>
### B20 · NSW/Australian residency 与按类别 retention
**Conditional baseline.** 非公开数据、外部归档与 Consortium KMS 默认位于 Australian regions。Canonical trace 按七年容量/保留假设设计，可由 product/jurisdiction/legal hold 调整；到期删除 payload 与 DEK，保留最小删除审计和非个人 commitment。

**判定、执行、例外三权分立：** 到期依据已发布 policy（台账在全 scope 方另有副本）；平台只发起请求、持有方按同一 policy 复核后执行并签发删除确认；早于 policy 的删除走 dual control。否则平台只要"算错"到期日，就重新拿回了 B1 否掉的删历史能力。

<a id="b21"></a>
### B21 · Regulatory Analytics 是边界内的 peer subsystem
**Baseline.** 它与 Traceability Core 同属系统边界内，但拥有独立运行时域、独立 service identity，以及监管方持有的规则与模型所有权。Findings 默认 regulator-private，监管方可把指定 `ruleId/ruleVersion` 的输出授权为受限 signed `AdvisoryFinding`。`RuleVersion` 由监管方签署，平台不改规则、不扩大适用范围；规则正文只以 `ruleBodyDigest` 进锚定。ML 可选，子系统不可选。

**租户归属由控制平面决定：** 判据不是"能不能登录数据库"，而是"谁掌握控制平面"——掌握者可通过 dump 内存、读宿主存储或替换镜像拿到明文。因此 Analytics 整体运行在监管方账户，**runner 与 registry 不能拆**（执行规则必须读正文）。代价是平台失去远程运维能力。

**跨租户三条流** + 六项契约（幂等、watermark 回显、过期、撤回按追加、双健康信号）。**`RegulationRequirement`** 是监管方签署的独立 artifact，只能绑定已有字段或用同一 primitive 类型新声明；地板 = 模块 manifest ∪ 适用辖区要求。**上链由法律效力决定**：日常 advisory 与调查材料不上链，正式 Assessment/Recall 作为 signed canonical event 自然上链。设计见 [Regulatory Analytics](/systems/regulatory-analytics)。

<a id="b22"></a>
### B22 · 使用显式、可测试的 NSW pilot 数量假设
**Conditional baseline.** 200 初始组织、10k events/day、50 events/s offline burst、5k consumer RPS、logical RPO=0、PostgreSQL RPO 5m、core RTO 4h、regional rebuild 24h；均需测试验证，不是 SLA。

<a id="b23"></a>
### B23 · PRIVATE 不上平台，只留加盐承诺；分享由所有者授予
**Baseline.** `PRIVATE` 内容默认保存在参与方一侧，平台只存 `plaintextCommitment` 与资源引用。可选的平台托管是**零知识**的：只有密文，无解密能力、无 escrow。分享由**所有者**把内容加密给指定接收方，不使用平台计算的 `accessScope`，也不引入事件级受众。

**两个必须记住的推论：** `availabilityStatus` 是三态并集（`OBJECT_PRESENT` / `OWNER_ASSERTED` / `UNKNOWN`），规则是"存在 ≠ 可读""未知 ≠ 不存在"；`ENCRYPTION` 密钥生命周期与签名密钥相反——撤销只阻止再加密，**旧私钥必须保留到最后一份用它加密的密文被删除**。明确不承诺：密钥恢复、平台侧取证、PRIVATE 可用性进 core RPO/RTO、删除的全局证明、元数据保密。

<a id="b24"></a>
### B24 · 平台以组织为身份、访问与租户单元
**Baseline.** 不建用户目录、岗位、审批流程或人员生命周期；角色只保留少量固定值。**每个请求必须显式携带 acting organisation**——一个 subject 可代表多个组织，缺失时拒绝而不是取默认值。

**组织层级 out of scope：** 不建 `parentOrganisationId`；合作社、集团、多站点企业注册为多个 `organisationId` + delegation。层级会污染 scope 计算、KMS epoch、签名归因与召回范围。

<a id="b25"></a>
### B25 · Core 只做机制，业务语义放在语义模块里
**Baseline.** Core 收缩为接收、验证、追加、确认、归档/锚定，以及**只由 EPCIS 标准语义生成**的边；handover 状态、召回遍历、合规重建、分析输入、运营洞察是同进程内的语义模块，经唯一 `QueryPort` 读事实、各自维护可重建投影。这是分层，不是微服务。

**七条不可下沉的不变量：** 身份与幂等；完整性管道；append-only 与 correction；**scope 强制**；**non-collapsing 强制**；watermark 暴露；图的语义下限。模块 manifest 的 `requiresFields` 并集**编译**进 profile 版本后冻结；没有消费者的字段不进地板。

**Insights 只出无归属聚合**（监管问责与召回），禁止点名排名与绩效画像——否则平台就在用自己的口径制造一个没有签署者的判定。设计见 [Semantic Modules](/systems/semantic-modules)。

## 第三层：产品与运营参数（已关闭）

<a id="c1"></a>
### C1 · Public network、anchor window 与迁移方案
**Conditional baseline.** Ethereum 主网 + 不可升级的最小合约 + 30 分钟窗口 + 两 epoch finality；relayer 签名密钥放 KMS；leaf 绑 `chainId + contractAddress` 以支持迁移。产品级细节见[待定事项](/decisions/open-items)。

<a id="c2"></a>
### C2 · PostgreSQL 产品级部署与恢复配置
**Conditional baseline.** Aurora PostgreSQL（Sydney，writer + 1 reader，Multi-AZ）；PITR 35 天、快照跨区复制到 Melbourne、RDS Proxy。RDS 为次选。

<a id="c3"></a>
### C3 · 外部归档与 KMS 的运营主体与产品级恢复
**Conditional baseline.** 归档由治理配置的**持有方集合**承担，门禁取集合内任一方签发的合格 `ArchiveAck`（quorum 1，集合至少两项）。默认集合：监管方 mirror（独立账户）+ 成员 mirror 或商用 WORM。持有副本不等于可读；参考实现为 S3 Object Lock compliance + 受托方 attestor + 多区域 KMS。

## 已舍弃但保留的替代方案

Permissioned Consortium Ledger 仍技术上可行，但当前缺少足够、愿意承担成本且真正独立的 validator operators。项目因此采用 public-chain commitment + external archive + consortium-controlled KMS；不是因为 BFT 本身无效。

> 日志里的 D1–D7 是**原方案的产品 / 数据 / 签名 / 共识 / 生命周期分析与舍弃理由**，属背景材料而非决策，因此不在本页编号；引用时用[完整决策日志的 D 段](/decisions/log#layer-d)。
