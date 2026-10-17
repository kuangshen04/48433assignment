# 系统—决策矩阵

本页给每个决定指定一个主要落点。系统页可以引用多个决定，但不应形成“多个系统都以为对方负责”的灰区。

## 按系统归属

| 系统/主题 | 主要决策 | 支撑或跨系统决策 | 该系统拥有的核心契约 |
|---|---|---|---|
| Scope & Context | A1、A2、A7、A8 | B1、B20 | 追溯层边界、参与方集成方式、首版复杂度 |
| Traceability Core | A3、A6、B6、B9、B10、B11 | A4、B13、B17、B18、B19 | EPCIS 写模型、状态机、handover、correction、lineage |
| Trust & Recovery | A5、B1、B2、B4、B7、B8 | B3、B6、B20、B22、C1、C3 | Archive envelope/Ack、Merkle leaf、KMS 与 recovery |
| Identity & Governance | B5、B16、B24 | B6、B11、B20 | Organisation/key/delegation、签名 assurance、治理生效、acting organisation 绑定 |
| Data & Access | B3、B10、B20、B23 | A5、B2、B12、B14、B15 | PUBLIC/CONSORTIUM/PRIVATE、零知识 ProtectedResource、承诺与分享、retention |
| IoT & Edge | B14 | A8、B12、B16 | Telemetry ownership、summary/evidence、offline queue |
| Regulatory Analytics（系统边界内、监管方运行时域） | B15、B17、B21 | B13、B18、B20 | 最小化输入、signature 绑定的 rule/model 版本、finding、disclosure、freshness |
| Query & Experience | B12、B18、B19 | B9、B10、B13、B21 | Consumer/participant/regulator reads、recall、watermark |
| Operations & Deployment | B13、B22、C1、C2、C3 | A7、B7、B8、B12、B20 | 部署、扩展、故障恢复、reference configuration |

## 跨系统不变量

| 不变量 | 负责建立 | 负责消费/展示 |
|---|---|---|
| `CONFIRMED` 只表示 signed + archived + finalised | Core + Archive/Anchor | 所有 projections、Analytics |
| 判定只能以签署声明进入历史（Error Declaration / signed notice / signed assessment） | Core + Identity/Governance | 所有 projections、Analytics |
| 竞争断言必须并存显示，不得折叠为单一路径（相对 scope） | Traceability Core projections | Query、Recall、Consumer、Analytics |
| 完整性可验证不需要明文，但重建受 scope 限制 | Trust & Recovery / KMS epoch | Core rebuild、Query、Recall |
| Participant time 不是可信签署时间 | Identity/Signature validation | Core、Governance、offline UI |
| Platform DB 不是唯一历史 | Archive/Recovery | Core rebuild、Operations |
| Profile 不产生合规结论 | Profile/Core | IoT、Analytics、UI |
| 没有 finding 不等于没有风险 | Regulatory Analytics | Platform Advisory/UI |
| Recall query 不等于物理下架 | Traceability/Regulator Portal | Participant ERP/WMS/POS |
| QR 不等于防伪证明 | Consumer projection | Consumer UI/Analytics |
| PRIVATE hosting 不改变 ownership | Data Access | IoT、Evidence、Regulator access |
| 平台从不持有 PRIVATE 明文（零知识托管除外，且无 escrow） | Data Access / B23 | Core、Analytics、Regulator access |
| 组织是唯一身份与租户单元，每请求显式绑定 acting organisation | Identity/Governance | Core、KMS、Projections |

## 两个反误读测试

### B1：删除不完全信任前提后，区块链还有独立职责吗？

如果答案只是“多写一份 hash”或“数据库更难修改”，说明没有建立真实的外部验证和控制权分离，属于 blockchain theatre。合格答案必须指出 public commitment、独立 ArchiveAck、非平台 KMS/recovery control 分别限制了平台的哪一种单方能力。

### B17：关闭 ML 后，Regulatory Analytics 是否就没有必要？

如果答案是“是”，说明错误地把 Regulatory Analytics 当成可选 AI 工具。即使完全不用 ML，产品/地区/监管特定的 deterministic heuristics、规则版本、risk finding、controlled disclosure 和 freshness 仍属于这个核心 peer subsystem；平台只消费被监管方授权的基础提醒结果。

### B17：把两条冲突断言合成一条路径显示，是否越权？

是。核心无法判断哪条为真，所以用视图“挑选一条”等于平台在无授权的情况下作出裁决。合格实现必须让竞争边并存、带 provenance，并让 impact 结论可追溯到依赖的断言集合与 watermark。

### B21：把 Regulatory Analytics 画在系统边界外，还能自圆其说吗？

不能。平台的基础审查能力、模型/规则版本、训练数据快照和 human-in-the-loop 都会失去架构位置，合规就只能用“平台不判”回答。代价是必须为它提供 C4 三层视图，并注明它由监管方运营、平台只提供 runtime 与 registry。

## 容易混淆的边界

### Traceability Core vs Regulatory Analytics

Core 判断结构、签名、权限和可重建关系，并负责让冲突可见；Analytics 判断 plausibility、risk 和 compliance relevance，但不决定哪条冲突声明为真。两者同属系统边界内，但运行在各自的控制域。机械派生的 handover status 不算异常判断。

### Identity Governance vs Public Blockchain

Governance 决定谁有现实参与资格；公共链限制确认后历史被静默替换。错误批准恶意成员不会让其获得其他组织的 self-custody key。

### Independent Archive vs PostgreSQL

Archive 保存可验证 canonical bytes；PostgreSQL 提供热状态和索引。Archive 没有完整 query 功能，PostgreSQL 也不能单独兑现 platform-independent recovery。

### Participant Evidence vs Platform-hosted Evidence

托管位置是运营选择，但**平台在任何一种模式下都不持有 PRIVATE 明文**（B23）。`PLATFORM_HOSTED_ZERO_KNOWLEDGE` 只意味着平台代为保存密文，不意味着平台能读、能查、能取证或能恢复：没有 key escrow、没有平台侧调取，也没有进入 core RPO/RTO 的可用性承诺。

### PRIVATE vs CONSORTIUM

没有中间地带。需要按字段查询、需要被联盟重建路径使用的数据必须进 `CONSORTIUM`；不想让联盟读的内容只能留在平台外，用加盐承诺锚定。两者之间不存在"平台可读但成员不可读"的第三档——除非将来启用事件级受众（B3 已说明其代价）。

### 组织 vs 用户

组织是唯一的身份、租户与签名单元；平台不管理组织内部人员。一个 subject 可代表多个组织，所以每个请求必须显式绑定 `actingOrganisationId`，不能从登录身份推断（B24）。
