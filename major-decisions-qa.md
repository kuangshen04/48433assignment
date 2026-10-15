# 当前重大架构决策 Q&A

> 更新时间：2026-10-15  
> 用途：把目前已经形成的架构主线整理成可用于报告、评审和答辩的问答。本文只记录会改变系统边界、信任模型、数据架构或部署方式的重大决定，不展开表结构、字段和云产品等实现细节。  
> 主要依据：`major-architecture-tradeoffs.md`、`system-boundary.md`、`week10-data-architecture.md`，以及“评审架构边界并梳理思路 (2)”和“讨论架构设计 (2)”中的讨论。

# 第一层：背景充分支持、没有明显争议的决定

这一层只保留能够从 case brief、EPCIS 背景和行业平台调研直接得到支持的结论。它们不依赖联盟治理、节点部署、密钥托管、存储拓扑或吞吐量等额外假设。

## A1. 这是完整农业 ERP 吗？

**答：** 不是。系统的核心是跨组织追溯，而不是取代参与方的 ERP、WMS、TMS、MES、农场管理、POS、实验室或认证系统。

平台应处理跨企业共享的追溯事件、证据关联、查询和消费者展示；生产计划、完整库存、仓储作业、运输调度、支付、会计、实际检测和监管审批继续由外部系统负责。

---

## A2. 所有企业必须使用同一套业务软件吗？

**答：** 不需要。所有参与方共享的是追溯数据语言和交互协议，而不是同一套 ERP。

没有成熟系统的小型组织可以通过 Web/PWA 录入；已有系统的企业可以通过 API、EPCIS 或适配器发布追溯事件。这种双轨接入方式同时符合农村可访问性和企业系统集成需求。

这里确认的是“界面接入 + 系统集成并存”，不预先决定企业是否还要部署 Participant Gateway、保管组织私钥或运行账本节点。

---

## A3. 为什么采用 EPCIS？

**答：** EPCIS 适合作为跨企业交换追溯事件的 canonical model，因为它能够统一表达对象、批次、托盘、时间、地点、业务步骤、状态、聚合、加工和传感器信息。

EPCIS 是事件数据和接口标准，不是完整供应链系统，也不替我们决定数据库、区块链、身份、访问控制、签名、双方 endorsement 或治理方式。

---

## A4. 区块链是否能够证明现实世界的数据真实？

**答：** 不能。区块链最多证明某个主体提交过某项内容，以及该内容在确认后有没有被修改；它不能直接观察货物、温度、实验过程或证书签发过程。

因此系统可以承诺 attribution、integrity 和 correction history，但不能把“签名有效”或“已经上链”等同于物理事实必然真实。真实性仍需设备治理、交叉确认、实验室或认证机构、现场审计和争议流程。

---

## A5. 是否应该把完整事件、文件和 IoT 原始数据全部上链？

**答：** 不应该。区块链适合保存证明共享记录来源、顺序和完整性所需的信息，不适合作为完整运营数据库、文件库或高频时序数据库。

完整业务 payload、大型文件、个人信息、商业敏感数据和高频 telemetry 应主要链下保存。这里确认的是“不要全部上链”；具体由平台、参与方、IoT 平台还是受控归档服务保管，以及账本应保存多少最小事实，仍属于待讨论决定。

---

## A6. 已发布的追溯历史如何纠错？

**答：** 不应静默覆盖原始记录。错误通过追加 Error Declaration、修正事件或等价的版本化声明表达，使审计者仍能看到原声明、纠错原因和后续解释。

这一决定只要求跨组织历史可追溯，不代表整个应用的所有状态都必须采用 Event Sourcing。

---

## A7. 第一版是否需要直接采用大量微服务和多种数据库？

**答：** 没有这个必要。模块化应用和关系数据库是更现实的起点；在没有团队规模、独立发布频率、故障隔离或实测负载证据时，不应为了形式上的“云原生”提前引入微服务和 polyglot persistence。

这里确认的是简单且可演进的起点，不提前锁定必须永远只有一个全球 PostgreSQL，也不排除以后按实测需求提取服务或专用存储。

---

## A8. IoT 和 AI 在核心业务中分别是什么地位？

**答：** IoT 接入是 case brief 明确要求的追溯证据来源；AI/ML 不是历史事实的权威来源。

如果采用 AI 风险分析，它应当是可选、异步和 advisory 的能力，不能决定事件是否被接受、不能参与账本共识，也不能代替食品安全或监管判断。关闭 AI 不应破坏基本追溯能力。

---

# 第二层：仍需讨论和重新论证的决定

以下内容是目前方案给出的回答，而不是已经没有争议的事实。讨论时应检查它们依赖的威胁模型、参与方能力、法规、规模和运维前提；讨论结论确定后，再将其中稳定的部分提升到第一层。

## 当前总体定位（待讨论）

本项目不是农业 ERP，也不是要求每家公司部署一整套系统的纯联邦协议；它是一个**由联盟治理、通过共享托管平台交付的跨组织追溯网络**。参与方对自己的源声明负责，平台保存建立谱系所需的规范事件并提供验证和查询，独立管理的联盟账本节点使任何单一方都不能静默改写已经承诺的历史。

---

## 1. 我们到底在建设什么？

**答：** 一个跨组织的农业供应链追溯层，而不是完整 ERP。

平台负责把不同组织分别产生的供应链声明连接成可归因、可验证、不可静默改写并且按权限披露的 provenance history。企业原有的 ERP、WMS、TMS、MES、农场管理、POS、实验室和认证系统仍在系统边界之外。

平台原生提供组织与身份登记、规范事件提交与验证、账本承诺、谱系查询、影响分析、消费者视图和审计能力；它不负责生产计划、完整库存、路线调度、支付、会计、实验室实际检测或监管审批。

**为什么：** 本项目真正困难且有区分度的问题，是在互不完全信任的组织之间建立可信的共享历史。重做所有企业内部业务只会扩大范围，并不会加强跨组织追溯。

**代价：** 平台依赖参与方系统或 PWA 提供事件，无法保证企业内部记录完整，也不能取代企业的法律和业务责任。

---

## 2. 所有参与企业是否必须使用同一套业务系统？

**答：** 不需要。所有参与方共享的是追溯协议、身份规则、事件语义和验证网络，而不是同一个 ERP。

- 没有成熟 IT 系统的小型组织通过平台 PWA 录入和查询事件；
- 有现有系统的企业通过 EPCIS/REST API 发布需要跨组织共享的事件；
- 成熟企业可以在自己的环境中完成 ERP 映射、本地校验、签名和敏感材料管理；
- 只有承担联盟治理职责的部分独立组织需要运行账本节点，不要求每个农场运行节点。

因此默认产品形态是共享托管服务，企业侧 gateway 是增强型接入选项，独立 ledger node 是治理角色，而不是所有参与方的部署义务。

**为什么：** 强制每家公司运维完整服务会产生大量独立故障点，也不符合小农户和 rural accessibility 的背景；但保留企业本地签名和集成能力，可以避免平台成为所有声明的唯一控制者。

---

## 3. 平台保存哪些数据，参与方自己保存哪些数据？

**答：** 划分依据不是笼统的“敏感或不敏感”，而是数据是否属于建立跨组织追溯所必需的共享事实。

平台保存：

- 已接受的 canonical traceability events；
- 组织、身份、地点、设备、公钥、profile 和访问策略；
- 批次、交接、包含关系和派生关系所需的最小事实；
- 外部证据的引用、元数据和内容 commitment；
- 可重建的查询 projection 与运营状态。

参与方或外部提供方保存：

- 完整 ERP/WMS/TMS 等内部记录；
- 原始高频 IoT telemetry；
- 证书、实验室文件和大型附件；
- 不属于跨组织追溯必需内容的商业敏感扩展。

**代价：** 外部材料可能过期、离线或丢失。平台可以验证以后拿到的内容是否与原 commitment 一致，但不能保证材料永远可访问。

---

## 4. “可信”或“不可篡改”在本项目中具体是什么意思？

**答：** 它意味着能够验证声明者、授权、内容完整性、修正历史、冲突和谱系规则，并能发现对已承诺历史的事后修改。

它**不意味着**区块链能够证明现实世界里的货物、温度、检测结果或证书内容必然真实。一个错误甚至恶意的源声明，只要由合法密钥正确签署，在密码学上仍可能是有效的。

更准确的对外表述是：

> 系统使供应链声明可验证、可归因并且不可被单方静默改写；它不声称仅凭软件即可证明物理世界的真实性。

物理真实性仍依赖独立证据、交叉确认、设备治理、检查和争议处理。

---

## 5. 为什么以事件为中心，而不是维护一个可修改的 Batch 状态？

**答：** 已接受的追溯事件构成 append-only authoritative history；批次当前状态、当前保管方、托盘内容、交接状态和召回影响范围都是从事件派生的 projection。

**为什么：** 拆分、混合、加工、装托盘、多次交接和纠错共同形成一个图，而不是一条线性状态。只维护一行可变 Batch 记录会覆盖原始声明，无法展示矛盾，也无法重放和审计。

**代价：** 查询不能只读取一个“最终真相”字段，需要 projection、图遍历、重放和 reconciliation。

---

## 6. 采用什么跨企业事件标准？

**答：** 采用 GS1 EPCIS 2.0 概念作为 canonical event model，并在外层增加本项目的 ledger envelope 和联盟规则。

EPCIS 负责 what、when、where、why、how，以及 ObjectEvent、AggregationEvent、TransformationEvent 等事件语义。本项目额外负责：

- 组织、用户和设备身份；
- 发布者签名与授权；
- visibility policy；
- profile 与 schema 治理；
- 交接确认和争议；
- 链上承诺与回执；
- 离线同步和消费者投影。

产品差异通过 versioned product profiles 表达。首个完整 profile 是 `Fresh Produce Cold Chain v1`，未来新增乳制品等产品线原则上不需要复制一套服务或数据库。

---

## 7. 批次拆分、合并、装托盘和交接如何区分？

**答：** 核心谱系只使用三类稳定关系：

| 关系 | 含义 | 是否产生新身份 |
|---|---|---|
| `HANDOVER` | 发货方与收货方对同一对象的转移分别作出声明 | 否 |
| `CONTAINS` | 批次或箱被装入托盘、容器 | 否，child identity 保留 |
| `DERIVED_FROM` | 拆分、混合、加工或重新分批产生输出 | 是，输出必须保留完整输入谱系 |

装托盘不是批次合并；保管权转移也不自动改变批次身份或组成。数量必须带单位，并遵守 profile 规定的换算、损耗和 yield 规则。

---

## 8. 一次交接是一条双方共同修改的记录吗？

**答：** 不是。shipping 和 receiving 是两个组织各自签名的独立声明，平台将它们关联后派生 `Pending`、`Accepted`、`Partial`、`Rejected` 或 `Disputed` 等状态。

**为什么：** 发货方不能替收货方证明已经收到，收货方也不能覆盖发货方原先声明的数量。双方不一致时，系统应保留并暴露冲突，而不是悄悄选择一方作为真相。

**代价：** 交接状态是 eventually consistent 的派生结果，业务上需要处理待确认和争议状态。

---

## 9. 错误事件如何修改或删除？

**答：** 已承诺事件不做原地更新或物理删除。纠错通过新的 Error Declaration 和 corrective event 追加表达，projection 可以把旧事件标为 superseded，但原始内容和完整纠错链仍保留供审计。

**为什么：** 原地修改会破坏签名、hash 和账本承诺，也会消除“当时谁说了什么”的证据。

---

## 10. 区块链到底存什么，为什么不把所有数据都上链？

**答：** canonical accepted event 保存在 PostgreSQL；permissioned consortium ledger 只保存最小 event commitment、发布者/版本等必要 envelope 信息和 transaction receipt。大型文件、原始 telemetry 和查询 projection 都不上链。

这里“event 上链”应理解为“以 event 为承诺和验证单位”，不是把完整 event payload 复制到所有节点。

**为什么：** 账本的职责是独立 tamper evidence 和共同治理，不是代替运营数据库。完整数据上链会放大隐私、保留、删除、查询、schema 升级和多组织治理成本。

**代价：** 完整验证需要同时取得 PostgreSQL 中的事件与 ledger commitment；账本暂时不可用时，提交进入明确的 `PendingLedger` 状态，而不是假装已经最终确认。

---

## 11. 为什么还需要联盟账本？普通数据库不够吗？

**答：** PostgreSQL 足以承担应用事务和查询，但它由平台运营方管理，单独使用时无法改变“运营方可以改写全部历史”的信任关系。联盟账本由相互独立的组织管理节点，用来让单方事后改写已承诺历史变得可检测。

平台运营方可以托管应用和部分基础设施，但不能同时独占：

- 所有参与方私钥；
- 所有 ledger/orderer 节点；
- 成员资格和 profile 规则；
- endorsement policy；
- 所有审计和查询结果。

**治理原则：** SaaS 可以中心化运维体验，但可信历史必须由联盟共同治理。

**可选扩展：** 将联盟账本的周期性 Merkle root 锚定到公共链有额外独立性价值，但目前不是核心基线，也不应暴露业务明文。

---

## 12. 为什么只用一个 PostgreSQL，而不是事件库、图数据库和多个服务各一个库？

**答：** 第一版使用一个 managed PostgreSQL application database，以 `registry`、`events`、`projection` 和 `operations` schema 做逻辑隔离。

PostgreSQL 同时提供事务、关系约束、JSON、索引和 recursive CTE，足以支持事件写入、outbox、谱系遍历和可重建 projection。当前没有测量结果证明需要引入更多数据库和一致性边界。

**代价：** PostgreSQL 是共享运营依赖。将来只有在实际 workload 证明谱系查询复杂度或容量超出它的能力时，才引入专用图数据库或独立 read store。

---

## 13. 后端采用微服务吗？

**答：** 第一版不采用完整微服务架构，而是一个有明确模块和 ports/adapters 的 modular Traceability Application。

身份与 registry、事件提交、policy、ledger adapter、projection 和 query 在逻辑上分离，但先共享部署和数据库。外部 ledger、artifact provider 和 message broker 仍保持真正的系统边界。

**为什么：** 当前没有团队规模、独立发布频率或负载证据足以抵消分布式事务、网络故障和运维复杂度。

**演进原则：** 先用模块边界保护可修改性；只有某个能力出现明确的独立扩缩容、隔离或发布需求时才提取服务。

---

## 14. 写入和查询为什么要分开？查询是否直接遍历区块链？

**答：** 写路径负责规范化、身份和签名验证、profile/business-rule 验证、幂等落库、账本提交及 outbox；查询路径读取 PostgreSQL 中异步构建、可丢弃并可重建的 projection。

普通 trace、consumer view 和 recall impact query 不直接遍历账本。需要完整性证明时，再用原始事件与 ledger receipt 交叉验证。

**为什么：** 共识基础设施适合证明承诺，不适合承担低延迟、按权限裁剪的业务查询。projection 还能为 consumer、participant 和 auditor 生成不同的 allowlisted view。

**代价：** projection 是 eventually consistent 的；API 必须暴露 projection timestamp/sequence，在重建或落后时明确报告 stale/unavailable，而不是返回看似完整的错误结果。

---

## 15. 最优先的质量属性是什么？

**答：** Trustworthiness 是首要架构驱动，包括 attribution、authorisation、tamper detection、visible conflict、correction history、lineage validity、evidence verification 和 governance independence。

并发性能不是当前最难的问题，也没有足够业务数据支持虚构高 TPS 或极端 p95 指标。公共查询的容量可以在测量后通过 projection、cache 和 cloud scaling 处理。

这不表示性能不重要，而是：

> 先解决无法用普通扩容补救的跨组织信任问题，再根据实测 workload 做容量规划。

---

## 16. Rural accessibility、IoT 和 AI 如何处理？

**答：**

- Rural accessibility：PWA 支持离线 draft/durable queue，恢复网络后以稳定 event ID 幂等重试；本地草稿不是共享历史，只有完成服务端验证和账本承诺后才成为已确认事实。
- IoT：属于核心 evidence integration。平台保存签名摘要、时间范围、设备身份、异常和原始数据引用，不吞入所有高频 telemetry。
- AI/ML：是可选、异步、advisory 的风险分析能力，只读取授权 projection，输出带模型版本的派生结果。

AI 不能决定事件是否被接受、不能参与 ledger consensus，也不能成为监管或历史真相。关闭 AI 不得影响事件提交、完整性验证或谱系查询。

---

## 17. 云部署中的权力边界是什么？

**答：** 应区分三个平面：

1. **Participant-controlled environment**：ERP/WMS/TMS、可选 gateway、本地签名密钥和 artifact store；
2. **Shared SaaS application plane**：PWA/portal、API、modular application、PostgreSQL、broker/worker 和 query projections；
3. **Consortium ledger plane**：由不同利益相关组织独立管理的 ledger nodes 和共同治理规则。

小型组织可以使用托管 PWA；成熟组织可以在自己的环境中签名和集成；关键联盟成员而非每个参与者负责运行独立节点。

云厂商和具体 managed service 尚未选定，因为当前重要的是 trust boundary、故障域、密钥和治理权的分离，而不是服务品牌。

---

## 目前仍开放、但不会推翻主线的问题

以下事项仍需在报告后续章节或实现阶段确定：

- 具体的 permissioned-ledger 产品与最终 endorsement policy；
- 最小 ledger envelope 的精确字段；
- 云厂商、区域拓扑和具体 managed services；
- 小型组织托管签名密钥时的 delegated-trust 流程；
- Participant Gateway 是否进入第一版部署，还是仅作为企业集成扩展；
- jurisdiction-specific retention 和 deletion/anonymisation 参数；
- 根据真实 workload 确定 SLA、分区阈值、索引和缓存；
- 是否加入公共链周期性 anchoring；
- 可选 AI/ML 风险分析是否纳入最终交付。

这些是实现和治理参数，不应重新打开以下已定主线：追溯层而非 ERP、事件历史、最小链上承诺、一个 PostgreSQL、外部 artifact ownership、modular application，以及 trustworthiness 优先。

---

## 答辩时最简短的版本

如果评审只允许一分钟，可以回答：

> We are building a consortium-governed traceability network, not an agricultural ERP. Participants keep their operational systems and remain responsible for signed source assertions. The shared platform stores the canonical events needed for cross-organisation lineage, while sensitive raw evidence remains externally owned. Events are append-only in PostgreSQL, and only minimal commitments are replicated to independently administered consortium-ledger nodes. Query projections are rebuildable and audience-specific. This design makes history attributable and non-silently-rewriteable without claiming that blockchain proves physical truth.

