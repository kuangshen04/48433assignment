# Agricultural Supply Chain Tracker — 现有报告大纲（讨论稿）

> 来源：`Agricultural_Supply_Chain_Tracker_5k_Reorganized.md`。
> 本文件提取现有报告的结构与论点，供后续调整后回填正文。中文概括保留原章节号、需求编号、关键术语和图号，便于定位。
> 本轮已同步撤去独立监管筛查子系统；保留监管查询、召回调查、普通洞察和可选监管证据镜像。其余假设与设计选择仍待逐项讨论。

## 0. Architecture at a glance — 架构概览

- 系统定位：跨组织、可归责的供应链声明记录；不代替 ERP，也不裁定实物事实。
- 数据基础：组织发布版本化 GS1 EPCIS 事件，支持来源验证、冲突声明和派生溯源关系。
- 当前确认条件：独立 holder 确认归档字节，并且对应 Merkle commitment 达到公链 finality，事件才为 `CONFIRMED`。
- 主要架构：模块化应用、异步归档与投影 workers、隔离 relayer、CDN 公共快照；平台内按权限提供监管查询和导出。
- 核心取舍：独立验证与可恢复性，换取外部 holder 依赖、异步确认和跨组织治理成本。
- 示例：污染批次召回保留多个争议来源，返回“可能受影响”的范围，由人作出业务判断。

## 1. Project context — 项目背景

### 1.1 Problem, objectives and interested parties（rubric 1.1）

- 问题：跨企业标识、记录和批次语义不一致；召回时逐家联系，慢且难以形成可信证据。
- 目标：连接企业已有业务记录，不接管其运营系统。
- 当前业务目标：
  - **O1**：低成本、可离线参与。
  - **O2**：可归责、可检测篡改的历史。
  - **O3**：有证据支持的事故／召回范围。
  - **O4**：准确表达确认状态的消费者视图。
  - **O5**：商业数据按范围可见，私有证据由所有者控制。
  - **O6**：小团队可运营。
  - **O7**：整合设备证据，不建设完整 IoT 平台。
- 主要利益相关者及当前设计回应：
  - **S1 生产者／种植者／包装商**：浏览器录入、离线队列、组织绑定的设备签名。
  - **S2 加工商**：多输入、多输出的 transformation lineage；平台不裁定物料平衡。
  - **S3 分销商／冷链运营商**：双边交接、可归责传感摘要，不上传原始遥测。
  - **S4 零售商**：保守召回遍历；消费者扫描高峰由公共快照承载。
  - **S5 消费者**：QR 查询，区分 `CONFIRMED`、`PENDING`、`NO RECORD`，不能提交声明。
  - **S6 监管者**：固定 watermark 的授权追踪查询及证据导出；没有无限私有数据访问权。
- 其他相关方：治理 **S8**、平台运维 **S9**、归档／密钥 trustees **S10**、审计者／法院 **S11**、设备供应商 **S12**。
- 领域规则：
  - 加工可有多输入、多输出；数量是发布者的声明。
  - 多个加工者声称使用同一输入时，保留各条边及其来源。
  - 召回范围保守纳入争议和临时关系，并标明状态。
- 当前约束与规划条件：
  - **C1**：题目明确要求区块链；同时要求食品安全合规、IoT、多产品线／地区、可视化、农村可访问性。
  - **C2**：采用 NSW 监管范围。
  - **C3**：与企业现有系统互操作。
  - **C4**：农村网络可能间歇中断。
  - **C5–C7**：200 家组织、每天 10,000 个事件、小运营团队、无生产环境访问；原文合并列示这些条件。

### 1.2 Risks, exclusions and architectural relevance（rubric 1.2–1.3）

- 当前风险与对应决策：
  - **R1 无独立联盟验证者** → 公链锚定；接受费用与 finality 依赖。
  - **R2–R3 单一运营者可能改写／移除证据** → 外部 `ArchiveAck`、独立密钥控制、Merkle 证明。
  - **R5 不可变记录泄露个人／商业信息** → canonical event 无自然人标识；私有证据 owner-held；元数据风险仍在。
  - **R4 农村排斥** → PWA／离线录入；不能离线签名的设备稍后签名。
  - **R10 虚假／冲突／串通声明** → 保留来源与竞争声明，交由调查裁定。
- 排除范围及理由：
  - ERP/WMS 替代、库存结算、支付、正式通知发布、私有文档交换、实物召回执行：超出记录与追踪职责。
  - 海关和认证流程：涉及额外法律／签发机构；证书可作为私有证据引用。
  - 平台原始遥测、消费者提交声明、通用营销／BI：不属于当前 pilot。
  - 国家级攻击者、破产、被攻陷的 onboarding：承认风险，未直接证明控制能力。
- 边界原则：验证声明，不认证事实。

## 2. Requirements analysis — 需求分析

### 2.1 System qualities, scenarios and rejected approaches（rubric 2.1–2.2）

- **SQ-1 完整性／QS-1**：运营者删除批次后仍可检测；链式 Merkle commitments。
- **SQ-2 可归责性／QS-2**：三年后、两次密钥轮换及停权后验证旧签名；保留历史授权与密钥。
- **SQ-3 可用性／QS-3**：归档故障期间召回不能误报 `NO RECORD`；明确降级读取，写入失败关闭并重试。
- **SQ-4 性能／QS-4**：5,000 scans/s；同步遍历最多 10,000 条边；CDN 快照和索引查询副本。
- **SQ-5 恢复／QS-5**：平台账户丢失后，已发回执事件 RPO 0；数据库 RPO ≤5 分钟、RTO ≤4 小时、区域重建 ≤24 小时。
- **SQ-6 可访问性／QS-6**：36 小时离线完成四次录入；2G、WCAG 2.2 AA、200% 文本；持久队列和签名 fallback。
- **SQ-7 隐私／QS-7**：调查者导出召回证据，排除无权限组织记录和私有文档内容；查询／导出实施 scope 和字段 allowlist。
- **SQ-8 互操作／QS-10**：原版本 profile／canonicalisation 可解释、可替换链；采用 EPCIS/CBV 与链无关摘要。
- **SQ-9 可审计性／QS-9**：竞争加工声明在 replay 后仍保留来源；non-collapsing graph、版本化派生、watermark。
- **SQ-10 可运营性**：小团队、一个应用部署单元、托管数据库；避免微服务集群。
- **SQ-11 设备证据／QS-12**：冷藏运输温度超限 40 分钟；签名摘要，原始样本留在源端。
- **SQ-13 洞察／QS-13**：按昨天的 watermark 重现产品线指标；有权限范围的物化投影。
- 当前排除的做法：运营者控制的 WORM 备份、不可变员工身份、同步外部读取、权威图数据库、ML admission。

### 2.2 Data management, scenarios and storage（rubric 2.3–2.4）

- 当前数据要求：
  - **DM-1**：按原始 profile 解释事件。
  - **DM-2**：平台不得读取 PRIVATE 内容。
  - **DM-3**：权威归档与可重建副本分离。
  - **DM-4**：按数据类别保留，支持 legal hold。
  - **DM-5**：canonical records 排除自然人标识。
- 数据字典字段组：
  - 提交／业务信息：`captureRecordId`、`eventTime`、`epcList`、`quantityList`、`quantity`、`uom`。
  - 版本／身份：`profileId`、`profileVersion`、`signerOrganisationId`。
  - 证明／私有引用：`canonicalPayloadDigest`、`plaintextCommitment`、`ArchiveAckDigest`。
  - 查询复现：`dataWatermark`，记录投影／查询所用的固定输入版本。
  - 原表逐组给出格式、长度、说明、来源及关联需求；其余业务字段引用 EPCIS 2.0/CBV。
- 校验和语义：
  - 版本化 profile 约束字段类型、长度和扩展；新产品线不能移除核心追踪字段。
  - 提交幂等 ID 与 EPCIS business event ID 分离。
  - 更正追加，不覆盖签名历史；结构有效不代表声明不冲突。
  - admission 检查授权、必填字段和幂等碰撞，不认证业务事实。
- 数据场景：
  - **DS-1**：七年后召回 → 版本化、可索引 lineage。
  - **DS-2**：冲突 transformation → 保留多条来源边。
  - **DS-3**：实验室报告只保留 commitment 引用；申请和交付在平台外完成。
  - **DS-4**：5,000 scans/s → CDN 投影。
  - **DS-5**：保留期到期但 legal hold → 可审计保留转换。
  - **DS-6**：离线事件在密钥轮换后到达 → review 状态，不只相信事件时间。
- 当前存储决策：托管关系数据库，支持精确数量、关系约束、event/idempotency/outbox 单事务、有限递归查询、权限过滤和 PITR。
- 当前拒绝：文档数据库、将图数据库作为权威事实、全应用 event sourcing、平台可读私有 blob。

### 2.3 Cloud needs, adoption scenarios and service models（rubric 2.5–2.6）

- 云采用理由：浏览器访问、小团队、扫描弹性、外部证据所有权；监管者通过平台执行授权查询和导出。
- 当前服务选择及替代：
  - 应用／workers：托管容器 PaaS；替代自管 IaaS 集群。
  - PostgreSQL：托管 PaaS、writer/reader、PITR；替代自管数据库。
  - 公开读取：CDN＋版本化对象；替代逐次 origin/API 查询。
  - 归档／密钥：独立 trustee 对象存储＋KMS；替代运营者控制备份／KEK。
  - 区块链：付费公链、批量提交；替代无人运营的联盟验证节点。
  - 监管分析：监管账户内 PaaS；替代平台管理的共享租户。
  - 身份：外部 IdP＋企业 registry；替代自建密码／平台签发法律身份。
- 驻留与退出：澳大利亚部署、标准 PostgreSQL、可移植 canonical 格式。

### 2.4 Security, privacy, regulation and device requirements（rubric 2.7–2.8、2.B）

- 当前安全要求：
  - **SP-1**：写入绑定组织、角色及 delegation。
  - **SP-2**：签名与历史授权可验证。
  - **SP-3**：平台不能解密 owner-held 证据。
  - **SP-4**：不可变历史无自然人字段。
  - **SP-5**：高影响治理双人批准。
  - **SP-6**：读取与 break-glass 审计。
  - **SP-8**：记录残余威胁。
- CIA 场景：保密对应 QS-7 的受限证据导出；完整性对应 QS-1/2；可用性对应 QS-3/5。
- 法规范围：Privacy Act／APPs、NSW 隐私义务、NSW Food Act、Food Standards Code；附录 B 映射。
- IoT：源端采集与报警；profile 要求带单位、来源及 commitment 的窗口摘要；设备授权归属组织；无平台原始流／报警路径。
- 监管调查采用追踪查询、证据导出和人工判断；自动监管筛查及 ML 不在本方案范围。

## 3. Architecture views — 架构视图

### 3.1 Context and containers（rubric 3.1–3.4）

- **Figure 1：System Context**。
  - 一个追踪系统：Traceability Core，包含有权限范围的调查、导出与洞察能力。
  - 人员：企业人员、消费者、监管者、治理方。
  - 外部依赖：设备／企业系统、archive、KMS、chain、IdP、企业 registry、监管系统。
  - 监管者通过平台授权查询／导出；归档／密钥／链不只由平台控制。
- **Figure 2：Core Container**。
- 当前容器职责：
  - Portal：录入、交接、受限召回查询／导出、QR 与洞察。
  - Traceability Application：admission、confirmation gate、事件存储、证据图、统一读取。
  - Ingestion/Projection Workers：归档、重试、重建、导出、保留。
  - Batch Builder/Relayer：leaf、manifest、Merkle batch、链提交、finality、proof。
  - Operational PostgreSQL：事务状态、registry、outbox、QueryStore。
  - Public Snapshot Delivery：版本化公共对象＋CDN。
- 交互原则：状态与归档意图原子提交；workers 异步执行；查询不逐次访问 archive/chain；仅 relayer 持链钱包；监管者使用同一 scoped read interface，洞察投影不能改写 canonical 历史。

### 3.2 Components and code（rubric 3.5–3.10）

- **Figure 3：Core Components**。
  - Capture API；Idempotency/Outbox Coordinator。
  - Canonicalisation/Profile Validator；Signature/Authority Validator。
  - Submission State Machine；Archive/Anchor Orchestrator。
  - Evidence Graph Builder；Confirmed Event Store；QueryPort。
  - gate 由 orchestrator 管理；workers 执行意图；QueryPort 提供 `edges()`、`traverse()`。
- **Figure 4：Relayer Components**。
  - 意图读取、确定性 leaf 分配、批次构建、链提交、finality 观察、proof 服务、manifest 写入。
- 逻辑实体与职责映射：Submission、Canonical event、Acknowledgement/Leaf/Batch、Derived edge。
- **Figure 5：Core Code View**。
  - 提交、canonical event、签名、profile、receipt。
  - ArchiveEnvelope、ArchiveAck、MerkleLeaf、AnchorBatch。
  - EvidenceEdge、EdgeQuery、EdgeGroup、QueryPort、ProtectedResourceRef。
  - 确认状态、custody mode、edge type 枚举。
- **Figure 6：Physical Data Model**。
  - 九张表：submission、canonical_event、evidence_edge、archive_ack、merkle_leaf、anchor_batch、protected_resource、profile_version、query_event。
- 跨视图论点：每个类有组件／容器归属；外部依赖经 port；逻辑实体映射物理键；SQL 查询副本不成为第二套业务事实。

## 4. Architectural rationale and decisions — 架构理由与决策

### 4.1 Application structure, tactics, SOLID and design smells（rubric 4.1–4.5）

- 总体：单个模块化应用；统一写 gate、统一读入口、追加 canonical claims、可 replay 投影。
- 模式／tactic 与替代：
  - Modular monolith＋内部 layered structure → 替代微服务／broker／sagas。
  - Transactional outbox → 替代 2PC 或 best-effort 双写。
  - CQRS-like read model＋QueryPort → 替代各模块独立权限 SQL／逐跳解密。
  - Append-only events＋state machine → 替代可修改事件行／单一 processed 标志。
  - 每 30 分钟 Merkle batch anchoring → 替代逐事件上链／平台时间戳。
  - Ports/adapters＋版本化 contract → 替代核心直接依赖供应商 SDK。
- SOLID：职责分离 SRP；扩展 custody adapter 支撑 OCP/DIP；统一 envelope 合约支撑 LSP；窄 QueryPort 支撑 ISP。
- 避免 design smells：统一图构建与读取策略、单向依赖、窄组件、供应商包止于 adapter；接受单部署单元的部署风险。

### 4.2 Data authority, models and analytics（rubric 4.6–4.10）

- 当前权威分配：外部加密 archive 是 copy of record；PostgreSQL 是可恢复的明文 consortium 查询副本。
- 三类可见性：PRIVATE owner-held；CONSORTIUM scoped query；PUBLIC 最小投影。
- 数据位置：
  - canonical 密文 → 独立 archive／qualified holder。
  - admission、idempotency、registry、outbox → PostgreSQL＋PITR。
  - QueryStore／lineage → 可 replay 的关系投影。
  - 公共视图／insight marts → 带版本和 watermark 的投影。
- 模型与约束：submission/event 由 capture ID 关联；每事件唯一 leaf；canonical event append-only；非查询 payload 分离；组织 scope 统一执行。
- 更正与冲突：追加更正事件；边派生有版本；同一输入可对应多个竞争声明；固定 watermark 重现召回范围。
- 数据分析选择：不建 warehouse/lake；workers 是 ELT，生成版本化 marts；新产品用 profile 扩展，新地区另作部署／治理决策。

### 4.3 Cloud-native execution and deployment（rubric 4.11–4.15）

- **Figure 7：Logical Deployment；Figure 8：Reference Deployment**。
- Cloud-native 原则：托管执行、声明式基础设施、工作负载隔离、无状态副本、异步 workers 按 backlog 扩缩容。
- 应用与 workers 使用同一 image、不同执行角色；CDN 独立扩展；数据库托管；不部署自管 Kubernetes。
- 当前三个管理域：平台、独立 archive/KMS trustee、可选监管证据镜像域；镜像仅承担额外 holder 职责，不执行监管筛查。
- Reference deployment：
  - Sydney 主区、Melbourne 恢复副本。
  - AWS 托管容器、Aurora PostgreSQL writer/reader、PITR、对象存储、CloudFront。
  - 隔离 outbound relayer；链钱包由 KMS 保护。
  - Ethereum mainnet；不可升级锚定合约；批次顺序及 previous-root linkage；等待 consensus finality。
  - 不采用 active-active writes、自营验证节点、独立 warehouse。
- Qualified holder 条件：独立管理、保留／枚举 envelope、对落盘字节签名。
- 当前 quorum：一个 qualified acknowledgement 即可，额外镜像增强韧性；holder 故障阻塞新回执；24 小时重建仍为演练目标。

### 4.4 Dynamic evidence flows and trust boundaries（rubric 4.16–4.20）

- **Figure 9：Event Acceptance 动态图**。
  1. 提交事件、组织签名和幂等 ID。
  2. 校验 profile／历史授权，原子提交状态及归档意图。
  3. worker 获取 wrapped DEK，加密归档并获得 `ArchiveAck`。
  4. 发 acceptance receipt，分配 leaf／加入 batch。
  5. relayer 提交链式 root，观察 finality，提供 inclusion proof。
  6. 标为 `CONFIRMED`，更新公共快照；故障只等待／重试，不自动提升状态。
- **Figure 10：Recall Investigation 动态图**。
  - 调查者（零售商或监管者）提交批次与组织／角色；应用授权并固定 watermark。
  - 查询本地 QueryStore、lineage 和证明记录；有界遍历上下游，检查可用签名、摘要及 inclusion proof。
  - 返回潜在受影响批次及来源，区分 confirmed／provisional，标明验证状态和覆盖限制。
  - 导出时重新检查权限与字段 allowlist，记录访问者、范围、watermark 和导出引用。
  - 导出记录与验证材料，供调查者独立对照公链承诺；不包含 owner-held 文档正文。
  - 正式通知、私有文档交付及实物召回使用既有外部流程；查询不依赖同步 archive／chain 调用。
- 信任边界／数据流：参与者→admission；平台→KMS/holder；relayer→chain；worker→CDN；调查者按权限读取／导出。
- STRIDE：
  - Spoofing → 企业身份、delegation、历史授权。
  - Tampering → 签名、append-only、链式 root、证明。
  - Repudiation → 签名 envelope、历史密钥、holder receipt。
  - Information disclosure → owner-held 加密、QueryPort scope。
  - DoS → 配额、有界队列、背压、重试、holder 集合。
  - Elevation of privilege → 无常驻 staff 权限、双批准 break-glass、隔离 relayer。
- 残余风险：真实声明可能虚假；平台可读 consortium 明文；串通、访问元数据、对方破产、密钥被攻陷。

### 4.5 IoT integration and insight views（rubric 4.B）

- IoT：源端设备／系统采集和报警；adapter 提交窗口、单位、min/max/mean、超限时长、delegation 和原始样本 commitment。
- 不上传原始流、不要求平台报警；减少存储并适应间歇连接。
- Insight 复用同一物化 lineage，标明组织、版本、watermark，不抹去争议与 provisional 状态。
- 门户提供录入、交接、调查、洞察入口；详细屏幕设计延后，但保留离线、无障碍和状态区别要求。

## 5. Evaluation and feasible alternatives — 评价与替代方案

### 5.1 Business-objective assessment（rubric 5.1–5.2）

- O1：离线参与有条件成立；部分设备联网后才能签名。
- O2：签名＋独立 ack＋Merkle finality 提供强设计；仍有虚假／串通和治理风险。
- O3：保守、带 watermark 的 lineage 支撑召回；完整性依赖企业记录覆盖率。
- O4：CDN 状态与来源信息支撑消费者查询；新确认事件有缓存传播延迟。
- O5：owner-held PRIVATE＋scoped consortium 读取；仍有元数据和运行时明文。
- O6：单部署、托管服务、批量锚定可行；外部 archive holder 仍需运营者。
- O7：IoT 摘要与 commitment 有条件成立；源端设备和保留能力不一致。
- 多产品线／地区／insights：部分支持；地区扩展和前端可视化仍需实现。

### 5.2 ATAM: sensitivities, risks and trade-offs（rubric 5.3）

- 采用 ATAM 的理由：评估证据记录系统，而非物理过程控制。
- 优先驱动：运营方丢失后的完整性、跨轮换签名、归档故障召回、扫描性能、离线录入、受限证据导出。
- 敏感点：
  - 锚定窗口：成本 ↔ 确认延迟。
  - holder liveness：回执吞吐 ↔ 独立性。
  - 遍历上限：召回完整性 ↔ 延迟。
  - 可见范围：监管权限 ↔ 商业保密。
- 风险：holder／chain 故障、单 relayer 凭证、admission 治理不足、恢复时间未验证。
- 接受的取舍：finality 前临时可见、元数据泄露、小团队单部署。
- 评价限制：无 benchmark／恢复演练；是可建设提案，不是运行实测结果。
- 验证优先级：签名／授权 replay、平台丢失后 archive 枚举、依赖故障注入、冲突召回负载、低端离线设备。

### 5.3 Alternative architectures（rubric 5.4）

- **A1 Permissioned BFT consortium ledger**：共同治理、较快确认；当前认为缺少独立节点运营者及持续运维安排；行业共同投入后可重选。
- **A2 Layer-2 anchoring**：可能降低交易成本；新增 sequencer、settlement/finality、长期依赖；主网费用／延迟超过阈值时考虑。
- **A3 Microservices/event bus**：独立发布／扩展；增加 broker、分布式状态及团队成本；负载或团队分化后考虑。
- **非区块链条件替代 TSA＋transparency log**：第三方共签可能更便宜；违背当前强制区块链要求，仅在 C1 放宽时可选。
- 当前结论：偏好无需预先形成验证者联盟的独立证据验证方案。

## Appendix A — Glossary

- **A.1 标准／领域术语**：GS1、EPCIS、CBV、lot/batch、aggregation/transformation、cold chain、provenance/lineage。
- **A.2 系统术语**：attributable claim、confirmation gate、holder/trustee、DEK/KEK、ArchiveAck、Merkle proof、WORM、watermark、non-collapsing、QueryPort/QueryStore。
- **A.3 图例／符号**：C4 元素、同步／异步箭头、交互编号、PK/FK、crow’s foot。
- **A.4 缩写**：APPs、ATAM、BFT、CBV、CDN、CQRS、DEK/KEK、HSM、IAM、KMS、NFR、PITR、PWA、RPO/RTO、SOLID、STRIDE、TSA、WCAG。

## Appendix B — Regulation

- NSW Food Act／Food Standards Code → 保守召回证据、受控导出，不自动裁定事实。
- Privacy Act／APPs／NSW privacy law → 最小化不可变身份、scoped reads、owner-held 证据、可更正路径。
- Records retention／legal hold → 分类规则、状态转换日志、多方删除、锚定审计证据。

---

## 编辑记录

- 2026-10-28：撤去独立监管筛查子系统及其目标、需求、数据契约、接口与评价项；移除三张专属分析图，保留图重排为 Figure 1–10。
- 保留监管角色、查询／导出、普通 insights，以及可选监管证据镜像；未调整区块链和 archive 的核心信任条件。
- 本轮变更已同步正文及活动 PUML；旧监管分析图源移入 `docs/diagrams/retired/regulatory-analytics/`。后续继续按大纲讨论其他假设。

- 2026-10-28：简化 recall 为授权查询、记录验证、影响范围计算与受限导出；移除通知发布／锚定以及私有文档请求／加密交付流程，同步正文与 Figure 10 及概览图。
