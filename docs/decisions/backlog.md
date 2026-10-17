# 待办清单

本页记录**还没关掉的架构决策与交付工作**。已确定的内容见[决策目录](/decisions/catalog)，理由与取舍见[完整决策日志](/decisions/log)，C1–C3 的参数关闭见[待定事项](/decisions/open-items)。

状态：`未开始` / `进行中` / `已完成`。

## 已完成（2026-10-18）

第一列是**被改到的决策编号**，不是新编号——同一个决策可能被多轮补充。完整理由见日志对应条目。

| 决策 | 结果 |
|---|---|
| B1 · 双轨表述 | 日志保留内部表述（"不完全信任运营者"），报告改用对外表述（"跨组织共享历史要求没有单一所有者"）；机制不变，由 B4 的保证边界约束 |
| B3 · 保证范围 | 验证与重建分开：任一成员可验证历史 append-only，重建受 scope 限制；KEK epoch 构成时间边界 |
| B3 · 核心字段地板 | `quantityList` 进 `CONSORTIUM` 但**与粒度绑定**——`class-lot` 级必填（+ UN/CEFACT `uom`），`instance` 级可用标识计数、重量退化为证据引用；Profile 三条硬约束 + 扩展字段判据写入 B11 |
| B5 · 第 4 档 custody | `DEVICE_BOUND_SELF_CUSTODY`：**组织的设备密钥**（非个人密钥），私钥不可导出、绑定 delegation，归因仍是组织；三条限制（证明不了自然人、设备丢失/共享、**载体是硬边界**）写入 B5 与 iot-edge |
| B5 · `actorId` 移出 | canonical trace 与 `SignatureEnvelope` 都不再含自然人标识；归因由 organisation + `keyId` + `custodyMode` + `assuranceLevel` 承担；"谁操作了"只在可变 audit。代价：immutable 层无法回答"哪个员工签的" |
| B7 · 批次序列可验证 | running hash chain 或 consistency proof，作为 B3 的技术前提 |
| B8 · 放宽副本资格 | v1 外部副本持有者可为成员/监管方 mirror 或独立账户 WORM，不要求专职 archive 服务商；B6 的门禁改为"是否离开平台控制域"，`ArchiveAck` 语义不变；签约操作方转为演进目标 + 三条触发条件 |
| B9 · 配对键 | 确定为 `bizTransaction(type=desadv)`：发货方签发、收货方必须引用同一个；`EXTERNAL_COUNTERPARTY` 可无；同一产品线只用一种 |
| B15 · evidence request | 只做 `AuditRecord(type=EVIDENCE_REQUEST)`，`outcome` 由参与方行动推导、超时为 `NO_RESPONSE`；不建工作流/portal/催办/SLA，不进 canonical trace |
| B17 · 重述 | 改为「记录断言 / 签署判定」两分，补上 non-collapsing 表示义务（相对 scope） |
| B21 · 重述 | Regulatory Analytics 明确为系统边界内的 peer subsystem、监管方独立运行时域，并承担 C4 分解责任 |
| B21 · C4 最小覆盖 | 取**最小覆盖**（3 container / 4 component / 8 类），并框定 Insights 与 AnalyticsInput 共用的 `DatasetSnapshot` 数据平面；两者合并为同一条数据平面（已出图），扩展条件写在系统页 |
| B21 · `RuleVersion` 锚定 | 规则正文留监管域，只把 `RuleVersionManifest`（含 `ruleBodyDigest`）进 archive + Merkle；撤回发新版本、不回溯已签发 finding |
| B21 · 租户归属 | 软件平台构建、**运行在监管方账户**；判据是"谁掌握控制平面"（掌握 ⇒ 可读明文），因此同集群 + 无 DB key 不算隔离。整个 Analytics 一起搬（拆开会让规则正文外泄）；平台不持运行时凭据、不能远程推送 |
| B21 · `RegulationRequirement` | 独立签署 artifact，只能绑定已有字段或用同一 primitive 类型新声明；地板 = 模块 manifest ∪ 适用辖区要求 |
| B21 · 跨租户契约 | 三条流 + 六项契约；撤回用同一 `findingId` 重签 `status`；**上链由法律效力决定**——日常 advisory 不上链，正式 Assessment/Recall 作为 canonical event 自然上链 |
| B23 · 新增 | PRIVATE 不上平台，只留加盐承诺；可选零知识托管；分享由所有者加密授予，不做事件级受众 |
| B23 · `availabilityStatus` | 三态 = 两个独立来源的并集（`OBJECT_PRESENT` / `OWNER_ASSERTED` / `UNKNOWN`），规则是"存在 ≠ 可读""未知 ≠ 不存在" |
| B23 · `ENCRYPTION` 生命周期 | 撤销只阻止再加密、旧私钥保留到对应密文删除、丢失即永久不可解；`recipientKeyRefs` 必须带 `keyId`，与 retention 终态联动 |
| B24 · 新增 | 组织是唯一身份、访问与租户单元；每请求显式绑定 acting organisation；组织层级 out of scope |
| B25 · 新增 | Core 收缩为机制（含强制 scope / non-collapsing / watermark 的 `QueryPort`）；handover、召回遍历、合规重建、分析输入、洞察改为同进程语义模块；字段地板改由模块 manifest 编译 |
| B25 · Insights 边界 | 主要服务监管问责与召回；允许无归属的跨组织聚合，**禁止点名排名与绩效画像**；不接外部业务数据、不预测、不写回 |
| 文档 | `major-decisions-qa.md` 移入本站为[完整决策日志](/decisions/log) |
| 文档 · C4 图 | Core 与 Analytics 的 container / component / code 图 + 动态视图；图源在 `docs/diagrams/src`，页面见 [Core](/architecture/c4-core)、[Analytics](/architecture/c4-analytics)、[动态](/architecture/c4-dynamic) |

---

## 第一批：会改变容器图，必须先做

这几条决定 container / component 清单，晚做会返工。

| 编号 | 事项 | 动作 | 影响 |
|---|---|---|---|
| T1 | **Profile conformance check 与模板**（决策已于 2026-10-18 完成，剩下工程化） | 把 B11 的失败条件做成 profile 发布前的校验组件，并提供 profile 模板（粒度声明 + 核心字段 + allowlist + evidence requirements） | 3.5–3.7；也是「profile 不能弱化追溯」的可执行证据 |
| T4 | **运营数据的租户隔离** | registry / job / outbox / export 的 `organisationId` 谓词 + RLS 兜底；export 绑定 tenant 或 case scope；运维访问 break-glass | 2.7 / 4.18（B23 只解决了内容，没解决运维数据） |

**T2/T3 的扩展条件**（当前不触发，写在系统页里）：4.B 需要 ML 深度才够分、出现第二个监管域、或 deterministic rules 的容量/时延被实测证明不足。三条都不成立就维持最小覆盖。

## 第二批：把已有材料写成论证

不需要新设计，主要是改写与补表。T5 / T6 / T7 / T8 的**决策部分都已定**，剩下的只是把理由和数字写进报告正文。

| 编号 | 事项 | 动作 | 影响 |
|---|---|---|---|
| T5 | **B1 框定改写** | 从「不信任平台运营者」改为「多方不可抵赖 + 第三方可验证」；机制完全不变（决策见上表 B1 双轨表述） | 1.1 / 1.2 的说服链 |
| T6 | **B8 可行性 fallback** | 给出 v1 基线（平台存储 + 跨管理域副本）与演进触发；说明 `ArchiveAck` 需要会签名的持有方，而不是一个存储桶 | 1.1 risk、4.14 deployment |
| T7 | **合规义务映射表** | 「法规义务 → profile 强制字段 / EPCIS 关系 → 缺失时状态」3–5 行；不越过 B17（只证明字段存在且可追溯） | brief 第 5 条、2.7 |
| T8 | **IoT 时延三层** | 实时采集（边缘）/ 准实时可用（receipted）/ 最终可验证（CONFIRMED）；明确冷链超温响应归参与方本地，平台侧告警是 post-confirmation | brief 第 3 条、A8 |
| T10 | **第二个替代方案** | 「不上公链」对照：中心化 WORM + 外部时间戳 / 透明日志；三方案在成本、信任结构、合规风险上比较 | 5.4（+2 分） |
| T14 | **四角色 UI 职责表** | farmer / distributor / retailer / consumer 的录入与查询职责（现在只有三个读取平面） | 3.9–3.10 |
| T15 | **多区域论证** | 产品线靠 profile、区域靠单区试点 + 分区触发，写成完整回答 | 2.x、4.14 |
| T16 | **B3 扁平论证改写** | 「强商业披露假设」改成正面论证（验证/重建 + B23 已提供材料） | 2.7、5.3 |

## 已知限制：报告里写成限制，不展开设计

这些是外部冷读评审指出、我们确认为真的问题，但**不改变架构骨架**，也不在报告正文里展开——写成"已知限制与后续工作"一段即可。报告里不要假装它们不存在，评阅人问起来要有答案。

| 编号 | 限制 | 现在的处理 |
|---|---|---|
| L1 | 召回遍历是图上的传递闭包，而扩展顺序里 graph projection 的触发条件写成了"图查询成为常态"——但召回本身就是图查询 | 把触发条件改为"遍历时延超预算"；首版用递归 CTE + 深度/边数预算 |
| L2 | `REVIEW_REQUIRED` 没有队列所有者与超时，且不进入召回可见集合 | 指定 owner + 超时转 `REJECTED`；UI 必须显示"存在待复核事件" |
| L3 | QR resolver 的 QPS 不在容量模型里；CDN 快照新鲜度与"立即通知"的合并规则未定义 | 明确 resolver 是否可缓存；召回时 bypass cache 或强制 revalidate |
| L4 | Insights 的"无归属聚合"没有 k 阈值，3 家组织时可用减法反推 | 加最小单元与抑制规则 |
| L5 | 字段地板只会收紧，没有退役路径（模块 `RETIRED` 后字段仍必填） | 需要一条"字段退役"治理流程，否则小农场事件会越来越重 |
| L6 | `PARTIALLY_ACCEPTED` 要跨单位比数量，但单位换算的归属没定义 | 落在 HandoverModule，并明确"换算不等于判定" |
| L7 | PRIVATE 证据没有可解性证明：所有者回传打不开的 blob 时，平台无法区分失职与技术事故 | 记录为限制；若日后需要，加 challenge-decrypt 之类的可解性检验 |
| L8 | 归档副本只在写入时确认一次（`ArchiveAck` 是一次性事件），没有周期性再证明 | 用定期 restore drill 与 catalogue 对账替代；不新增协议 |
| L9 | 读取审计的采样率与保留期未定（成本 vs 可归因） | 导出与跨组织读取全记，交互式查询按请求聚合 |

## 报告阶段：不需要新决策，但必须做

| 编号 | 事项 | 说明 |
|---|---|---|
| R1 | Dynamic diagram 选型 | **已完成**：[C4 视图 · 动态](/architecture/c4-dynamic)。主场景 capture → archive → anchor → confirm，18 个状态折成 5 段；用 sequence 形式（协作图会摊成 2500px 横幅，竖版页面读不出字） |
| R2 | SOLID / 设计味道映射 | A7 的 ports/adapters、B5 的单一 `EventSignatureVerifier`、B11 的 profile 与 core 分层已是现成证据（4.4 / 4.5） |
| R3 | ATAM / HAZOP | 日志里的「承受的代价」「否决的方案」直接就是风险与 trade-off 素材（5.3） |
| R4 | C1–C3 reference deployment | 云部署策略按要求暂缓，但提交前必须选定一套可实施的配置，否则 4.14 / 4.15 没有内容 |
| R5 | Glossary | 所有图例、符号、缩写、关键术语进附录，**不超过三页**（硬性要求） |
| R6 | 字数预算与裁剪 | ≤5000 词；D1–D7 保留、B8/B16/B20 的细节压缩或移出正文 |
| R7 | 提交检查 | Contribution Table 全员签署（未签为零分）；Turnitin 时间 |

## 建议顺序

1. **T1 → T4**：先把容器图的两处空白补完（conformance 组件、运维数据隔离）。
2. **T5 → T10 → T14 → T16**：论证类，材料都在日志里，写成文即可。
3. **R1 → R7**：进入写报告阶段。
