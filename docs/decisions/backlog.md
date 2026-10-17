# 待办清单

本页记录**还没关掉的架构决策与交付工作**。已确定的内容见[决策目录](/decisions/catalog)，理由与取舍见[完整决策日志](/decisions/log)，C1–C3 的参数关闭见[待定事项](/decisions/open-items)。

状态：`未开始` / `进行中` / `已完成`。

## 已完成（2026-10-18）

| 事项 | 结果 |
|---|---|
| B17 重述 | 改为「记录断言 / 签署判定」两分，补上 non-collapsing 表示义务（相对 scope） |
| B21 重述 | Regulatory Analytics 明确为系统边界内的 peer subsystem、监管方独立运行时域，并承担 C4 分解责任 |
| B3 保证范围 | 验证与重建分开：任一成员可验证历史 append-only，重建受 scope 限制；KEK epoch 构成时间边界 |
| B7 补强 | 批次序列必须可验证（running hash chain 或 consistency proof），作为 B3 的技术前提 |
| B23 新增 | PRIVATE 不上平台，只留加盐承诺；可选零知识托管；分享由所有者加密授予，不做事件级受众 |
| B24 新增 | 组织是唯一身份、访问与租户单元；每请求显式绑定 acting organisation；组织层级 out of scope |
| **T1 决策部分** | 数量归类：`quantityList` 进 `CONSORTIUM`，但**与粒度绑定**——`class-lot` 级必填（+ UN/CEFACT `uom`），`instance` 级可用标识计数、重量退化为证据引用。核心字段地板写入 B3；Profile 三条硬约束 + 扩展字段判据写入 B11 |
| **B25 新增** | Core 收缩为机制（含强制 scope / non-collapsing / watermark 的 `QueryPort`）；handover、召回遍历、合规重建、分析输入、洞察改为同进程语义模块；字段地板改由模块 manifest 编译；B9 补配对键义务、B18 明确遍历策略归属、B11 补编译冻结、B21 投影归 AnalyticsInputModule |
| **范围冻结（2026-10-18）** | Analytics 的 C4 取**最小覆盖**（3 container / 4 component / 7 类），并框定 Insights 与 AnalyticsInput 共用的 `DatasetSnapshot` 数据平面；两者合并为 T2+T3，扩展条件写在系统页 |
| **A1 B1 双轨表述** | 日志保留内部表述（"不完全信任运营者"），报告改用对外表述（"跨组织共享历史要求没有单一所有者"）；机制不变，由 B4 的保证边界约束 |
| **A2 B8 放宽副本资格** | v1 外部副本持有者可为成员/监管方 mirror 或独立账户 WORM，不要求专职 archive 服务商；B6 的门禁改为"是否离开平台控制域"，`ArchiveAck` 语义不变；签约操作方转为演进目标 + 三条触发条件 |
| **A3 `RuleVersion` 锚定** | 规则正文留监管域，只把 `RuleVersionManifest`（含 `ruleBodyDigest`）进 archive + Merkle；撤回发新版本、不回溯已签发 finding |
| **B2 `DEVICE_BOUND_SELF_CUSTODY`** | 第 4 档 custody：**组织的设备密钥**（非个人密钥），私钥不可导出、绑定 delegation，归因仍是组织；三条限制（证明不了自然人、设备丢失/共享、**载体是硬边界**）写入 B5 与 iot-edge |
| **B4 evidence request** | 只做 `AuditRecord(type=EVIDENCE_REQUEST)`，`outcome` 由参与方行动推导、超时为 `NO_RESPONSE`；不建工作流/portal/催办/SLA，不进 canonical trace |
| **B1 `actorId` 移出** | canonical trace 与 `SignatureEnvelope` 都不再含自然人标识；归因由 organisation + `keyId` + `custodyMode` + `assuranceLevel` 承担；"谁操作了"只在可变 audit。代价：immutable 层无法回答"哪个员工签的" |
| **B3 配对键** | 确定为 `bizTransaction(type=desadv)`：发货方签发、收货方必须引用同一个；`EXTERNAL_COUNTERPARTY` 可无；同一产品线只用一种 |
| **B5 `availabilityStatus`** | 三态 = 两个独立来源的并集（`OBJECT_PRESENT` / `OWNER_ASSERTED` / `UNKNOWN`），规则是"存在 ≠ 可读""未知 ≠ 不存在" |
| **B6 `ENCRYPTION` 密钥生命周期** | 撤销只阻止再加密、旧私钥保留到对应密文删除、丢失即永久不可解；`recipientKeyRefs` 必须带 `keyId`，与 retention 终态联动 |
| **C1 Analytics 租户归属** | 软件平台构建、**运行在监管方账户**；判据是"谁掌握控制平面"（掌握 ⇒ 可读明文），因此同集群+无 DB key 不算隔离。整个 Analytics 一起搬（拆开会让规则正文外泄）；平台不持运行时凭据、不能远程推送 |
| **C2 `RegulationRequirement`** | 独立 artifact，监管方签署，绑定已有字段或用同一 primitive 类型新声明；地板编译 = 模块 manifest ∪ 适用辖区要求 |
| **C3 Insights 边界** | 主要服务监管问责与召回；允许无归属的跨组织聚合，**禁止点名排名与绩效画像**；不接外部业务数据、不预测、不写回 |
| **C4 跨租户契约** | 三条流 + 六项契约；撤回用同一 `findingId` 重签 `status`；**上链由法律效力决定**——日常 advisory 不上链，正式 Assessment/Recall 作为 canonical event 自然上链 |
| 文档迁移 | `major-decisions-qa.md` 移入本站为[完整决策日志](/decisions/log) |

---

## 第一批：会改变容器图，必须先做

这几条决定 container / component 清单，晚做会返工。

| 编号 | 事项 | 动作 | 影响 |
|---|---|---|---|
| T1 | **Profile conformance check 与模板**（决策已于 2026-10-18 完成，剩下工程化） | 把 B11 的失败条件做成 profile 发布前的校验组件，并提供 profile 模板（粒度声明 + 核心字段 + allowlist + evidence requirements） | 3.5–3.7；也是「profile 不能弱化追溯」的可执行证据 |
| T2+T3 | **数据平面最小覆盖设计**（两者合并） | **已完成范围框定**：Insights 与 AnalyticsInput 共用一条 `DatasetSnapshot` 路径，见 [Semantic Modules](/systems/semantic-modules)；Analytics 侧只做 3 container / 4 component / 7 类，见 [Regulatory Analytics](/systems/regulatory-analytics)。剩余：把它画进 container 与 component 图 | 4.6–4.9、3.2–3.7；4.B 主要靠 IoT 叙事，不依赖这里做深 |
| T4 | **运营数据的租户隔离** | registry / job / outbox / export 的 `organisationId` 谓词 + RLS 兜底；export 绑定 tenant 或 case scope；运维访问 break-glass | 2.7 / 4.18（B23 只解决了内容，没解决运维数据） |

**T2/T3 的扩展条件**（当前不触发，写在系统页里）：4.B 需要 ML 深度才够分、出现第二个监管域、或 deterministic rules 的容量/时延被实测证明不足。三条都不成立就维持最小覆盖。

## 第二批：把已有材料写成论证

不需要新设计，主要是改写与补表。

| 编号 | 事项 | 动作 | 影响 |
|---|---|---|---|
| T5 | **B1 框定改写** | 从「不信任平台运营者」改为「多方不可抵赖 + 第三方可验证」；机制完全不变 | 1.1 / 1.2 的说服链 |
| T6 | **B8 可行性 fallback** | 给出 v1 基线（平台存储 + 跨管理域副本）与演进触发；说明 `ArchiveAck` 需要会签名的服务方，而不是一个存储桶 | 1.1 risk、4.14 deployment |
| T7 | **合规义务映射表** | 「法规义务 → profile 强制字段 / EPCIS 关系 → 缺失时状态」3–5 行；不越过 B17（只证明字段存在且可追溯） | brief 第 5 条、2.7 |
| T8 | **IoT 时延三层** | 实时采集（边缘）/ 准实时可用（receipted）/ 最终可验证（CONFIRMED）；明确冷链超温响应归参与方本地，平台侧告警是 post-confirmation | brief 第 3 条、A8 |
| T9 | **`RuleVersion` 治理** | 规则如何发布与发现、是否进 archive / Merkle batch、撤回时已发出的 AdvisoryFinding 怎么处理 | B21 的完整闭环 |
| T10 | **第二个替代方案** | 「不上公链」对照：中心化 WORM + 外部时间戳 / 透明日志；三方案在成本、信任结构、合规风险上比较 | 5.4（+2 分） |

## 第三批：小修与新债

不改变容器，只改文字和一两张表，可以一次过。

| 编号 | 事项 | 动作 |
|---|---|---|
| T11 | `actorId` 移出 canonical trace | EPCIS 没有 who 维度；归因由 organisation + signature 承担，actor 留在可变 audit |
| T12 | `DEVICE_BOUND_SELF_CUSTODY` | B5 补第 4 档：PWA 本地 passkey/WebCrypto 签名，让离线能产生真实签名事件；同步改 iot-edge 的「只能存 draft」 |
| T13 | `handoverId` 改为 `bizTransaction` | 用 `bizTransactionList`（desadv / receiving advice）承载，提升 EPCIS/CBV 一致性 |
| T14 | 四角色 UI 职责表 | farmer / distributor / retailer / consumer 的录入与查询职责（现在只有三个读取平面） |
| T15 | 多区域论证 | 产品线靠 profile、区域靠单区试点 + 分区触发，写成完整回答 |
| T16 | B3 扁平论证改写 | 「强商业披露假设」改成正面论证（验证/重建 + B23 已提供材料） |
| T17 | 加密密钥生命周期 | `ENCRYPTION` 用途密钥的发布、轮换、旧私钥保留（否则历史证据变不可读） |
| T18 | Evidence request 流转 | `REQUESTED → GRANTED / DECLINED / EXPIRED` 状态、超时、审计；平台只转达不取证 |
| T19 | `availabilityStatus` 语义 | `OWNER_ASSERTED / OBJECT_PRESENT / UNKNOWN` 谁设置、UI 怎么表达、调查里算不算不配合 |

## 报告阶段：不需要新决策，但必须做

| 编号 | 事项 | 说明 |
|---|---|---|
| R1 | Dynamic diagram 选型 | 建议用 event capture → archive → anchor → confirm 作主场景；18 个状态折叠成 5 段 |
| R2 | SOLID / 设计味道映射 | A7 的 ports/adapters、B5 的单一 `EventSignatureVerifier`、B11 的 profile 与 core 分层已是现成证据（4.4 / 4.5） |
| R3 | ATAM / HAZOP | 日志里的「承受的代价」「否决的方案」直接就是风险与 trade-off 素材（5.3） |
| R4 | C1–C3 reference deployment | 云部署策略按要求暂缓，但提交前必须选定一套可实施的配置，否则 4.14 / 4.15 没有内容 |
| R5 | Glossary | 所有图例、符号、缩写、关键术语进附录，**不超过三页**（硬性要求） |
| R6 | 字数预算与裁剪 | ≤5000 词；D1–D7 保留、B8/B16/B20 的细节压缩或移出正文 |
| R7 | 提交检查 | Contribution Table 全员签署（未签为零分）；Turnitin 时间 |

## 建议顺序

1. **T1 → T2 → T3 → T4**：一口气做完，因为它们共同决定容器图。
2. **T5 → T10**：论证类，材料都在日志里，写成文即可。
3. **T11 → T19**：批量小修。
4. **R1 → R7**：进入写报告阶段。
