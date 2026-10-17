# 系统地图

## 一句话架构

本系统是跨组织农业供应链追溯层：参与方发布可归责的 EPCIS source assertions；平台负责接收、查询和投影；平台控制域之外的归档、联盟控制的 KMS 与公共链共同限制平台运营者单方面改写或垄断历史的能力；监管分析在与平台并行的独立运行时域中判断领域风险，但同属一个系统边界，且不改写追溯历史。

## 两个有意选择的成立前提

### B1 不是装饰性 threat model

作业明确要求 blockchain，因此架构必须给它一个普通平台数据库不能独立完成的职责。B1 显式假设参与方不完全信任平台对确认后历史的单方控制，使公共链成为外部 existence/integrity checkpoint。若 archive、KMS、recovery identity 和验证结果最终仍全部由平台单独控制，即使使用公链也只是 `blockchain theatre`。

### B17/B21 不是把领域功能移出核心

Traceability Core 只做 admission/protocol validation 并原样保留断言：它既不掌握产品、地区和监管制度下的权威规则，也无法观察现实，因此连“哪条冲突声明为真”都不判断。判定只能由持钥主体以签署声明进入历史——EPCIS Error Declaration、signed Recall/Safety Notice 或 regulator-signed Assessment。

普通领域启发式、统计分析和 optional ML 由 Regulatory Analytics 执行。该子系统与 Core 同属系统边界内，但拥有独立运行时域和监管方的规则/模型所有权；它同时为平台提供基础审查能力，因此不能被画成边界外的第三方黑盒。代价是 C4 3.2–3.10 必须为它给出 container / component / code 三层视图，并把 Core ↔ Analytics 标为主要信任边界。ML 可选，子系统本身不可选。

投影层的配套义务是 non-collapsing：竞争断言必须并存显示，不选代表路径、不排序、不打分。

## 控制域与系统

```text
System boundary
├── Platform control domain（平台运行时域）
│     Traceability Core
│       ├── Operational PostgreSQL / Projections
│       ├── Public Delivery (CDN) 与 Regulator Portal / Exports
│       ├── Advisory Ingestion
│       └── Merkle Batch / Relayer
│
└── Regulator control domain（监管方运行时域）
      Regulatory Analytics
        Rule & Model Registry / Screening / Finding & Advisory Publisher

      Core --minimised projection--> Analytics
      Core <--signed AdvisoryFinding-- Analytics
      ^ 这条线即主要 trust boundary

Boundary 之外（外部系统与独立基础设施）
  Participant Environment：PWA / ERP / WMS / TMS / IoT Platform / Gateway
  External Archive（平台控制域之外）  <-->  Consortium-controlled KMS
  Public Blockchain（由平台 relayer 提交 Merkle root）
  External IdP / 监管方既有公告渠道
```

## 系统职责总表

| 系统或控制域 | 主要职责 | 明确不负责 |
|---|---|---|
| Participant Environment | 产生业务声明、企业签名、离线排队、私有证据保存 | 全网查询、公共链 finality |
| Traceability Core | EPCIS 接收、结构验证、幂等、生命周期、确认门禁；由 EPCIS 标准语义构建证据图；`QueryPort` 强制 scope / non-collapsing / watermark | 产生任何业务状态、判断物理事实真假、裁决冲突声明哪条为真、库存核算、违法结论 |
| Semantic Modules（同进程） | Handover 状态、召回遍历策略、合规重建、公开投影、分析输入、运营洞察；各自维护可重建投影 | 写入历史（结论须作为签署事件走 capture）、绕过 `QueryPort`、弱化 scope 或 non-collapsing |
| Identity & Governance | 组织资格、public key、delegation、profile/高权限变更历史；组织是唯一身份与租户单元 | 组织内部的员工目录、岗位、审批链；组织层级；设备 fleet IAM；替参与方签名 |
| Evidence (PRIVATE) | 所有者一侧保存内容；平台只持加盐承诺；可选零知识托管 | 解密、检索、比对私有内容；密钥恢复；代为取证 |
| Operational PostgreSQL | 热查询、状态机、outbox、可重建投影 | 作为唯一权威历史或唯一恢复副本 |
| External Archive | 保存可验证的 encrypted archive envelope 并签发 ArchiveAck | 解密业务数据、判断内容真实性 |
| Consortium KMS | 保护 consortium KEK，向获授权 runtime/recovery identity 提供密码操作 | 参与业务审批或替组织签名 |
| Public Blockchain | 保存 Merkle commitment，提供外部 existence/integrity checkpoint | 保存完整 EPCIS、证明 eventTime 或物理事实 |
| Regulatory Analytics（边界内、监管方运行时域） | 运行启发式、统计或可选 ML，输出私有 finding 或获准 advisory；为平台提供基础审查能力 | 改写 trace、继承监管人员全部权限、自动执法、决定哪条冲突声明为真 |
| Public Delivery Plane | 发布版本化消费者 projection，使用 CDN 承担高并发 | 直接读取 archive/KMS 或展示联盟私有数据 |

## 核心信任边界

### 平台运营者不是完全可信方

架构主要限制平台对完整性、可恢复性、密钥控制和接受后审查的单方权力。这个边界是题设所要求 blockchain 的实际用途，而不是泛化地声称“区块链更安全”。平台 runtime 仍然被授权读取 `CONSORTIUM` 明文，因此当前模型不声称在 runtime 被攻破时仍能保持联盟数据机密性。

### 组织声明不等于物理事实

签名、ArchiveAck 和公共链 finality 可以证明“谁发布了什么、保存了什么、之后是否被替换”，不能证明货物真的存在、传感器真的安装在声明位置，或参与方没有串谋。

### 记录断言不等于作出判断

Core 的职责边界可以压缩成一句规则：**平台记录断言，判定只能由有权主体以签署声明进入历史。** 同一个序列化对象被两项 transformation 分别声称消耗时，核心既无观察现实的能力，也无裁决权，因此它保留双方，而不是挑一个或标一个 verdict。投影层必须让这种冲突可见（竞争边并存、带 provenance、不排序、不选代表路径）；隐藏冲突或用单一路径呈现，等于用界面替平台作了裁决。

### 能验证到什么程度（验证 ≠ 重建）

“任一成员可独立验证”这句话必须拆开，否则会被读成“任一成员能读全部历史”：**验证**历史是 append-only、自己的记录已被纳入、批次序列无断裂，不需要明文；**重建并验证内容**需要明文，范围由 scope 决定；**完整历史**的重建只有全 scope 方（监管方、审计者、受托恢复方）能做。三者的准确划分与 KEK epoch 的时间边界见 [Data & Access](/systems/data-access)。

关键在于：B1 的保证是**完整性**，而完整性验证不需要明文。扁平可见性额外提供的“我能读别人的全部记录”对防篡改没有贡献，它服务的是恢复能力；而恢复能力可以由全 scope 方承担。因此 v1 的 scope 取“全体 active 成员”，收窄只是治理参数，不是架构重写。

### Regulatory Analytics 是边界内的 peer subsystem

Traceability Core 保存可归责的 source assertions；Regulatory Analytics 维护监管方拥有的 deterministic heuristics、statistics 和 optional ML，并解释领域风险。监管方可以授权指定 rule/version 的 signed findings 给平台形成基础提醒。

两者同属系统边界内，但 Analytics 处在监管方的独立运行时域，规则和模型归监管方所有：`RuleVersion` 由监管方密钥签署，平台只提供 runtime 与 registry，不 author、不改规则、不扩大适用范围。正因为它在边界内并为平台提供基础审查能力，C4 的 container / component / code 三层都必须覆盖它；关闭它时的行为属于系统内降级，而非外部依赖故障——追溯写入、查询、召回遍历或监管人员手工调查继续，但必须显式显示分析结果过期或不可用。

## 主要数据类别

| 数据类别 | 默认位置 | 默认访问 | 平台能否读明文 |
|---|---|---|---|
| Canonical EPCIS trace | 外部归档（加密）；PostgreSQL 索引/投影 | `CONSORTIUM` | 能（运行时被授权） |
| Consumer projection | 版本化对象/CDN | `PUBLIC` | 能（它就是生成者） |
| Raw IoT、报告、合同等证据 | 参与方一侧；可选零知识托管（只有密文） | `PRIVATE` | **不能**（B23） |
| Membership/profile/key history | 外部归档并锚定；数据库 current projection | 受治理访问 | 能 |
| Analytics dataset/findings | Regulatory Analytics runtime（监管方运行时域，边界内） | 目的受限；默认 regulator-private | 不在平台侧 |
| Public-chain commitment | 外部公共链 | 公开，但不得含可字典匹配的个人字段 | 不适用 |

## 继续阅读

- 核心写模型：[Traceability Core](/systems/traceability-core)
- 信任保证：[Trust & Recovery](/systems/trust-recovery)
- 端到端确认：[事件接收与确认](/flows/event-acceptance)
- 决策归属：[系统—决策矩阵](/decisions/system-matrix)
