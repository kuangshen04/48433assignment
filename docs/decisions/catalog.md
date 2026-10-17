# 决策目录

本页是 `major-decisions-qa.md` 的展示索引。完整边界条件、否决方案和 trade-off 仍保留在项目根目录原文件；这里提供稳定编号、状态和当前结论，供系统页引用。

状态含义：

- **Baseline**：背景直接支持或已经接受，后续设计应遵守；
- **Conditional baseline**：依赖显式业务/治理假设，报告必须写明；
- **Open**：边界已确定，但产品、参数或运营主体仍需关闭。

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

**Baseline.** 公共链只保存 commitment/Merkle root；完整 canonical payload 进入独立加密归档；高频或私有证据使用 ProtectedResource。

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

<a id="b2"></a>
### B2 · 平台失效后恢复最小完整 trace

**Conditional baseline.** 恢复范围包括 canonical EPCIS、signatures、profiles、identity/key/governance history 和 chain/archive metadata，不强制恢复所有 raw telemetry 与业务附件。

<a id="b3"></a>
### B3 · PUBLIC / CONSORTIUM / PRIVATE 三层数据模型

**Conditional baseline.** Active consortium participants 共享 canonical trace core；消费者只读 allowlisted public projection；敏感证据是 owner-controlled ProtectedResource。联盟内广泛共享是假设，需利益相关方验证。

<a id="b4"></a>
### B4 · 保证限制在可归责与确认后完整性

**Baseline.** 公共链降低平台单方事后改写风险，但不防业务方串谋提交虚假声明，也不解决上链前入口 censorship；不同签名 custody 模式具有不同 non-impersonation assurance。

<a id="b5"></a>
### B5 · 统一 SignatureEnvelope，保留 custody 差异

**Baseline.** 支持 enterprise self-custody、assisted external custody 和 delegated platform custody。签名真实性、acceptance-time authority 与 trusted signing-time evidence 分开验证；客户端时间不能绕过撤销。

<a id="b6"></a>
### B6 · ArchiveAck + public finality 后才 CONFIRMED

**Baseline.** 普通 event 必须先独立归档，再完成公共链 finality。Official Recall/Safety Notice 可在签名与 ArchiveAck 后以 `VERIFIED_PENDING_ANCHOR` 紧急发布。

<a id="b7"></a>
### B7 · 固定窗口 deterministic Merkle batching

**Baseline.** 平台 relayer 提交 versioned Merkle root；leaf 绑定 event identity、canonical digest、signature digest 和 ArchiveAck digest。首版不要求 secondary relayer。

<a id="b8"></a>
### B8 · 一个强制独立归档 + 联盟控制 KMS

**Conditional baseline.** 至少一个非平台控制的 WORM archive；额外 mirrors 可选。Consortium KEK 使用由联盟/受托方控制账户和 recovery authority 的专业 KMS。

<a id="b9"></a>
### B9 · 联盟内 B2B handover 使用两份独立 claims

**Baseline.** Sender 与 receiver 分别签署；平台只派生 handover status。网络外交易方标为 `EXTERNAL_COUNTERPARTY`，消费者零售不要求消费者签名。

<a id="b10"></a>
### B10 · Append-only trace core，不采用全应用 Event Sourcing

**Baseline.** Canonical records append-only；普通应用状态使用事务模型；outbox 驱动 archive、anchor 和 projections。数据库是运营索引而不是唯一历史。

<a id="b11"></a>
### B11 · 不可变版本化 Product Validation Profiles

**Baseline.** Profile 配置字段、单位、vocabulary、evidence reference、consumer allowlist 和 UI metadata，不成为通用规则引擎或合规判断来源。

<a id="b12"></a>
### B12 · 三类 workload planes

**Baseline.** Participant ingestion、regulator investigation/export 与 public consumer delivery 分离资源和读取策略；农村连接通过 offline queue 处理。

<a id="b13"></a>
### B13 · 写 fail-closed/resumable，读显式降级

**Baseline.** 必要依赖在哪一步失败就停在哪一步，使用稳定 identity 幂等续跑。既有 confirmed 数据尽量继续读取，并显示 watermark、staleness 和 dependency health。

<a id="b14"></a>
### B14 · Raw IoT 是 participant-controlled PRIVATE evidence

**Baseline.** Core 保存 profile-required summary、source-reported exception、reference、provenance 和 commitment。Evidence status 是客观状态，是否构成风险由 Analytics/监管人员判断。

<a id="b15"></a>
### B15 · Regulator 与 Analytics 使用不同身份权限

**Baseline.** Analytics 只读 purpose-minimised confirmed projection，无任意 archive/KMS/private-evidence 权限，不能继承监管人员法定能力。

<a id="b16"></a>
### B16 · Human/Device IAM 在外围，Organisation Governance 在核心

**Baseline.** 企业/IoT vendor 管理账号与设备 fleet；核心保存 organisation membership、public keys、delegations 和 signed GovernanceRecords。扩权变更在 archive/anchor finality 后生效，紧急撤销可先 fail closed。

<a id="b17"></a>
### B17 · Core 不判断跨事件业务异常

**Baseline.** 冲突、数量、mass balance、timing/location 和 fraud heuristic 属于 regulator-controlled analytics；Core 保留相互冲突的 signed source assertions。

**为什么是项目成立前提：** 平台不知道不同产品、地区和监管制度下的权威领域规则，也无权自行发明。普通 deterministic heuristics 与高级 statistics/optional ML 因而统一放在 Regulatory Analytics 中，由监管方配置、版本化、审计并承担规则责任。Optional 的是 ML 技术，不是该核心业务子系统。

<a id="b18"></a>
### B18 · Recall 是保守 lineage query，不是物理下架

**Baseline.** 平台查询可能受影响对象、展示授权 notice 和记录后续 claims；ERP/WMS/POS 与人员执行封存、下架、退货和销毁。

<a id="b19"></a>
### B19 · 标识符由参与方分配，QR 不是防伪证明

**Baseline.** 优先使用 GTIN/GLN/SSCC 等标准标识，缺少外部 scheme 时使用 network-scoped fallback。QR 解析 public projection，不证明标签物理真实性。

<a id="b20"></a>
### B20 · NSW/Australian residency 与按类别 retention

**Conditional baseline.** 非公开数据、archive 和 KMS 默认位于 Australian regions。Canonical trace 默认按七年 capacity/retention assumption 设计，可由 product/jurisdiction/legal hold 调整；到期后删除 payload/DEK 并保留最小删除审计和非个人 commitment。

<a id="b21"></a>
### B21 · Regulatory Analytics 是 peer subsystem

**Baseline.** Findings 默认 regulator-private；监管方可把指定基础 `ruleId/ruleVersion` 的输出授权为受限 signed AdvisoryFinding，由平台用于基础提醒。规则仍在监管控制域执行，平台不取得修改或扩大规则的权力。Analytics 有独立 watermark/health，规则未运行不能展示为“无风险”。行业协会当前不是 Regulatory Advisory issuer。

<a id="b22"></a>
### B22 · 使用显式、可测试的 NSW pilot 数量假设

**Conditional baseline.** 200 初始组织、10k events/day、50 events/s offline burst、5k consumer RPS、logical RPO=0 target、PostgreSQL RPO 5m、core RTO 4h、regional rebuild 24h；均需测试验证。

## 第三层：仍需关闭的决定

<a id="c1"></a>
### C1 · Public network、anchor window 与迁移方案

**Open.** Payload/leaf/manifest 逻辑已定；仍需选择具体网络、15–60 分钟内的窗口/finality、contract mutability、gas/relayer 和 chain migration continuity。

<a id="c2"></a>
### C2 · PostgreSQL 产品级部署与恢复配置

**Open.** Australian primary region、单一 managed PostgreSQL 起步和 RPO/RTO target 已定；仍需给出具体 service、PITR/backup、成本和 load/recovery evidence。

<a id="c3"></a>
### C3 · Archive/KMS 运营主体与产品级恢复

**Open.** 独立控制域和跨 Australian failure domain 已定；仍需选定 operator/account owner、产品、recovery identity、key deletion protection、restore runbook、relayer wallet 和 Participant Gateway 首版范围。

## 已舍弃但保留的替代方案

Permissioned Consortium Ledger 仍是技术上可行的替代方案，但当前缺少足够、愿意承担成本且真正独立的 validator operators。项目因此采用 public-chain commitment + independent archive + consortium-controlled KMS；不是因为 BFT 本身无效。
