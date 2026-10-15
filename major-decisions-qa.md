# 当前重大架构决策 Q&A

> 更新时间：2026-10-16
>
> 用途：记录会改变系统边界、信任模型、数据责任或部署方式的重大决定，并保留每项决定背后的 trade-off。
>
> 依据：case brief、EPCIS 背景、行业平台调研，以及后续架构讨论。背景没有直接给出的内容会明确标记为补充假设。
>
> 阅读方式：第一层是背景直接支持的决定；第二层是已经接受的额外假设；第三层是仍待讨论的选择。

每项决定都会说明必要的边界和理由。只有当真实存在竞争方案、责任转移或显著负面后果时，才进一步记录被否决方案、代价及其可接受性；不为了形式完整而人为制造 trade-off。

# 第一层：背景充分支持的决定

## A1. 系统是完整农业 ERP 吗？

**决定：** 不是。系统是跨组织农业供应链追溯层。ERP、WMS、TMS、MES、农场管理、POS、实验室、认证和监管系统仍在边界之外。

**边界条件/假设：** 项目的核心问题是把不同组织分别产生的声明连接成端到端 trace，而不是统一各企业的内部运营流程。

**为什么这样定：** 跨组织身份、事件语义、谱系、纠错、证据和可信历史是本项目有区分度的能力。生产计划、仓库拣货、运输调度、会计和支付并不会因为进入同一个平台而自动提高追溯可信度。

**否决的方案：完整农业 ERP。** 如果选择该方案，平台需要同时实现农场生产、库存、仓储、运输、零售、合同和财务流程；不同类型企业还会要求完全不同的功能。系统边界会失控，且企业需要替换现有软件才能加入网络。

**承受的代价：** 平台依赖参与方系统或 PWA 提供事件，不能保证企业内部记录完整，也不能替代参与方的业务和法律责任。

**为什么可以接受：** 平台承诺的是跨组织声明可追踪、可归因和可审计，而不是接管每家企业的运营真相。这个责任边界更诚实，也与行业平台的实际接入方式一致。

---

## A2. 所有企业必须使用同一套业务软件吗？

**决定：** 不需要。没有成熟系统的小型组织使用 Web/PWA；已有系统的企业通过 EPCIS/API 或适配器提交相同的 canonical events。

**边界条件/假设：** 参与方数字化水平差异很大，农村用户不能被要求运维完整服务器，而大型企业也不会为了追溯平台放弃现有 ERP/WMS/TMS。

**为什么这样定：** 共享的应当是数据语言、身份规则和追溯网络，不是同一个操作软件。

**否决的方案一：强制使用统一业务套件。** 这会造成迁移阻力、供应商锁定和业务功能膨胀。

**否决的方案二：要求每家公司自行部署完整平台。** 这会把升级、备份、证书、安全补丁和可用性责任转嫁给小型参与方，并产生大量独立故障点。

**承受的代价：** 平台需要维护 PWA 和企业集成两条摄取路径，并处理映射、版本兼容、幂等和不同质量的数据。

**为什么可以接受：** 双轨接入直接服务 rural accessibility 和 enterprise interoperability；这部分复杂度位于系统真正的集成边界，无法通过强迫所有参与者采用同一技术栈合理消除。

---

## A3. 为什么采用 EPCIS？

**决定：** 使用 GS1 EPCIS 概念作为跨组织 canonical event model，并通过联盟批准的 profile 约束本项目实际接受的字段和事件类型。

**边界条件/假设：** 系统需要表达批次、物流单元、时间、地点、业务步骤、聚合、加工、传感器摘要和纠错，但 EPCIS 不负责身份、权限、区块链和联盟治理。

**为什么这样定：** EPCIS 为不同企业提供共同的 what/when/where/why/how 语义，避免每家企业用不同 JSON 和业务词汇描述同一个供应链动作。

**否决的方案：完全自定义事件模型。** 初期看起来更简单，但会把跨企业映射、标识、聚合、Transformation 和纠错语义全部变成项目自定义规则，降低互操作性并增加长期维护成本。

**承受的代价：** EPCIS 本身较复杂，字段多且可扩展；仍需设计 profile、身份、授权、可见性、签名、争议和账本 envelope。

**为什么可以接受：** 标准复杂度换来了稳定语义和企业系统集成基础。通过限制网络 profile，而不是实现 EPCIS 的所有能力，可以控制第一版范围。

---

## A4. 区块链能证明物理事实真实吗？

**决定：** 不能。系统只承诺声明的 attribution、authorisation、content integrity、correction history 和 lineage consistency，不声称区块链能证明现实世界事实必然真实。

**边界条件/假设：** 软件不能直接观察货物、温度、实验过程或证书签发过程；它只能处理参与方、设备或证据提供者提交的声明。

**为什么这样定：** 正确签名的声明仍可能是错误、疏忽或欺诈。把密码学有效性描述为物理真实性会制造虚假安全感和错误法律期待。

**否决的方案：把“已上链”宣传为“真实可信”。** 该方案会掩盖 oracle problem，使用户在事故发生时错误依赖平台，并把平台暴露在无法兑现的责任承诺下。

**承受的代价：** 产品承诺听起来没有“区块链保证真相”强；调查仍需要 IoT、实验室、交叉确认、现场审计和参与方举证。

**为什么可以接受：** 这是技术能力的真实边界。系统仍能显著降低事后改写、冒名声明和责任无法定位的风险，而不夸大其能力。

---

## A5. 是否把完整事件、文件和 IoT 原始数据全部上链？

**决定：** 不把所有数据上链。账本保存联盟同意共享、足以恢复最小完整 trace 的 canonical EPCIS core；大型、敏感、高频或仅用于举证的内容留在链下。

**边界条件/假设：** 区块链用于共享历史和独立验证，不是通用文件库、时序数据库或运营查询引擎。

**为什么这样定：** 原始 telemetry、PDF、照片、合同和私有业务详情具有不同的容量、隐私、保留和删除要求，不适合复制到所有 ledger nodes。

**否决的方案：完整数据全部上链。** 该方案会放大商业泄露、数据驻留、删除、更正、节点存储、共识性能和 schema 升级成本，并让每个节点运营方持有不必要的数据。

**承受的代价：** 系统必须维护链上 shared trace 与链下 protected resources 的引用和 commitment；调查时可能遇到外部证据不可用。

**为什么可以接受：** 最小 trace 仍能在平台失效时恢复并定位潜在责任方；原始材料的举证责任可以保留在声明方，平台不必成为所有企业资料的中央保管人。

---

## A6. 已发布的追溯历史如何纠错？

**决定：** 不静默覆盖或删除已确认事件。错误通过 Error Declaration、corrective event 或等价的追加版本表达。

**原因：** 区块链和 EPCIS 纠错模型都不通过直接修改已经确认的历史来表达修正。原地更新还会使既有签名、hash 和账本承诺失效。因此系统追加错误声明和修正事件，并由查询视图显示当前有效解释；原始声明仍保留供审计。

---

## A7. 第一版是否直接采用大量微服务和多种数据库？

**决定：** 不。第一版采用模块化应用和关系数据库作为主要运营基础，并通过 ports/adapters 保留未来拆分能力。

**原因：** 当前没有团队规模、独立发布频率、故障隔离或实测 workload 证明需要微服务和 polyglot persistence。先用模块边界保护职责和依赖方向，可以避免过早引入分布式事务、网络故障和多套运维；以后出现明确的独立扩缩容或发布需求时再提取服务。

---

## A8. IoT 和 AI 在核心业务中分别是什么地位？

**决定：** IoT 是核心证据来源；AI/ML 如果采用，只能是可选、异步和 advisory 的风险分析能力。

**原因：** Case brief 明确要求 IoT 实时采集，因此 canonical event 可以保存必要的 sensor summary、异常和原始数据 commitment，而高频原始数据仍由 IoT 平台或参与方管理。AI 只帮助发现风险，不能决定事件是否有效、参与账本共识或代替食品安全与监管判断；关闭 AI 不影响基本追溯。

# 第二层：已经接受的额外前提

## B1. 参与方是否完全信任平台运营者？

**决定：** 不完全信任。平台运营者不能成为已确认历史的唯一控制者和唯一验证者。

**边界条件/假设：** 平台可能发生内部滥用、管理员账号泄露、基础设施入侵、错误恢复或受到商业压力。参与方不一定认为平台会主动作恶，但不能把所有历史保证建立在这种信任上。

**为什么这样定：** 如果平台独占数据库、参与方声明权、全部 ledger nodes 和治理密钥，区块链相对于普通 append-only database 或 WORM audit log 的额外价值很弱。

**否决的方案一：完全信任平台。** 该方案最简单，但平台可以控制写入、查询和恢复结果，无法回答为什么需要 blockchain。

**否决的方案二：平台和所有节点在密码学上都不能看到任何业务数据。** 该方案需要事件级加密、复杂密钥分发、private collections 和恢复 escrow，超出当前可实现范围。

**承受的代价：** 需要平台控制域之外的验证和复制能力，并引入联盟成员资格、节点治理、升级和潜在串谋问题。

**为什么可以接受：** 这是让 blockchain 对应真实信任问题所需的最低额外复杂度。当前只要求防止平台单方面静默重写，不声称能够抵抗所有联盟成员共同串谋。

**由此产生的约束：**

- 已确认历史必须在平台控制域之外可验证；
- 账本节点不能只是同一云账号中的名义复制；
- 平台不能同时独占全部节点和治理密钥；
- 平台延迟、遗漏或删除已经接受的数据必须可以被审计；
- 节点运营者、数量、quorum 和反串谋机制仍需继续决定。

---

## B2. 平台失效后，哪些数据必须仍可恢复？

**决定：** 必须恢复联盟 network profile 中的完整 canonical EPCIS shared trace，包括事件、对象关系和纠错历史。原始证据和企业内部资料不属于强制恢复范围。

**边界条件/假设：** 平台失效后，参与方或审计者至少需要判断产品经历了哪些阶段、数据由谁发布、在哪一环出现矛盾，以及应向哪一方索取证据。

**为什么这样定：** 只有 opaque hash 时，平台消失后无法还原物流或谱系；只有平台 PostgreSQL 保存完整事件时，平台仍然是唯一数据可用性来源。

**否决的方案一：账本只保存 hash，完整事件只在平台数据库。** 可以检测拿到的 payload 是否被改，但拿不到 payload 时无法恢复任何 trace。

**否决的方案二：共享网络强制保管所有原始 IoT、证书、照片、合同和内部记录。** 会把平台变成通用证据仓库并承担不必要的隐私、保留和法规责任。

**承受的代价：** Shared ledger 保存的内容多于单纯 commitment，所有节点运营方都能看到联盟 trace core；参与方自管的证据仍可能 `Unavailable`、`Expired` 或无法举证。

**为什么可以接受：** Trace core 的体积远小于原始文件和 telemetry，却足以定位问题。原始材料由作出声明的一方负责保存和提供，平台可以提供可选托管，但不转移其真实性责任。

**强制恢复范围：**

- event ID、type、time、publisher 和 profile version；
- batch、object、pallet 或 logistic-unit identifiers；
- business step、disposition、source/destination；
- aggregation、disaggregation、transformation 和 correction relationships；
- network profile 允许的 sensor/compliance summary；
- protected-resource reference、owner、issuer metadata 和 content commitment。

**默认不强制恢复：** 原始高频 telemetry、完整实验室文件、证书文件、照片、合同、商业单据、内部 ERP/WMS/TMS 明细和私有扩展。

---

## B3. EPCIS 数据和证据采用什么权限模型？

**决定：** 使用固定的 `PUBLIC / CONSORTIUM / PRIVATE` 三层模型；不做字段级动态权限、不做每事件密钥分发，也不建立独立的 private EPCIS event store。

**边界条件/假设：** 参与方不信任平台控制历史完整性，但接受平台和联盟节点作为受合同、安全控制和审计约束的数据处理者。加入联盟意味着同意共享 network EPCIS profile 中的最小 trace facts。

**为什么这样定：** 如果完整 EPCIS event 中每个字段都有不同受众，就需要事件级加密、DEK wrapping、审计 escrow、密钥恢复和复杂查询。固定分类可以用一张权限矩阵解释，并保持平台失效后的可恢复性。

**否决的方案一：完整 EPCIS 明文对消费者公开。** 会泄露交易关系、精确地点、数量、设备和商业节奏。

**否决的方案二：每事件、每字段密码学隔离。** 会造成密钥和 policy 爆炸、难以查询、难以恢复，也无法简单撤销已经解密的数据。

**否决的方案三：单独维护 private EPCIS layer。** 它与证书、IoT、合同等可选托管资料边界模糊，会产生两套权限和生命周期模型。

**承受的代价：** 所有联盟节点运营方可以看到 shared trace core；不能进入 core 的精确数量、位置或原始证据无法用于全联盟自动验证。平台仍被信任执行日常保密和访问控制。

**为什么可以接受：** 当前目标是恢复路径、识别声明者和定位潜在责任方，而不是让所有成员验证每项商业细节。敏感详情仍可在直接交易方或调查范围内提供，复杂度与收益更匹配。

### 固定数据层

| 分类 | 内容 | 谁可读取 | 保存方式 |
|---|---|---|---|
| `PUBLIC` | 产品、来源地区、主要阶段、公开认证摘要、温控摘要、recall status | Consumer 及其他用户 | 从 shared trace 生成 allowlisted projection |
| `CONSORTIUM` | 联盟批准的 canonical EPCIS trace core | 已认证参与方、Auditor/Regulator、必要运维人员 | Permissioned ledger + application projection |
| `PRIVATE` | 精确商业详情、完整 sensor data、文件、企业私有扩展 | Owner、直接交易方、明确授权的调查者 | Participant-hosted 或可选 platform-hosted `ProtectedResource` |

### ProtectedResource 统一模型

结构化 private detail 与 PDF、照片、证书和原始 telemetry 使用同一个逻辑资源模型：

```text
ProtectedResource
- resourceId
- eventId
- ownerOrganisationId
- resourceType
- schemaOrMediaType
- contentHash
- storageMode: PLATFORM_HOSTED | PARTICIPANT_HOSTED
- externalLocator
- accessScope
- retentionMetadata
- availabilityStatus
```

底层可以分别使用 PostgreSQL JSONB、object storage 或外部 IoT store，但权限、引用、commitment 和 availability 状态由同一个 Protected Resource Service 管理。

### 固定访问矩阵

| 角色 | Public Projection | Shared Trace Core | ProtectedResource |
|---|---:|---:|---:|
| Consumer | 可读 | 不可读 | 不可读，除非另有公开摘要 |
| Consortium Participant | 可读 | 可读 | 仅自有、直接交易相关或明确共享的资源 |
| Auditor/Regulator | 可读 | 可读 | 在批准的 investigation scope 和期限内可读 |
| Platform Operator | 托管 | 托管 | 仅为托管/运维技术访问，并记录审计日志 |
| Ledger Node Operator | 不因运行节点获得消费者身份 | 保存并可验证 | 不保存，也不因运行节点获得访问权 |

### 分类判据

> 没有该数据，联盟是否仍能重建产品经过的组织、阶段和转换关系，并定位潜在责任方？

- 如果不能：进入 `CONSORTIUM` canonical EPCIS profile；
- 如果可以：建模为 participant-owned `ProtectedResource`；
- 如果消费者需要：从 shared trace 生成 `PUBLIC` projection。

如果某字段既不能让联盟成员看到，又是重建最小 trace 必不可少的内容，则当前简化模型不成立；必须修改共享假设或重新引入加密/private collection。

# 第三层：仍需讨论的决定

以下项目保留当前倾向和 trade-off，但尚未提升为架构基线。

## C1. 谁运行 permissioned-ledger nodes，采用什么 quorum？

**当前倾向：** 平台运营者之外，由少数利益和管理控制域相互独立的代表组织运行节点；不要求每个参与方运行节点。

**为什么尚未定案：** 背景没有给出真实行业联盟、节点预算、运营能力或治理章程。节点太少存在串谋和支配风险，太多则增加成本、升级协调和故障概率。

**已否决：** 随意写成“3–5 个独立组织”却不解释其身份和激励；以及由平台在同一云账号代管所有所谓独立节点。这两种做法只是在图上去中心化。

**需要接受的代价：** 任何平台外可恢复和不可单方改写的保证，都要求某些外部主体承担存储、验证和治理成本。架构不能消除该成本，只能明确由谁承担。

**待回答：** 是否明确假设存在行业联盟或独立行业机构；节点由生产者组织、物流/分销组织、零售组织、审计机构还是专业托管方运行；系统只抵抗单方篡改，还是还要抵抗部分节点串谋；公共链 anchoring 是否仅作为反串谋加强措施。

---

## C2. 参与方如何签名和管理密钥？

**当前倾向：** 采用分级 assurance：成熟企业在自己的 Gateway/KMS 中签名；小型组织可以选择 tenant-isolated delegated signing，不要求每个农场自行运维组织级 PKI。

**为什么尚未定案：** 每事件签名增强 attribution，但农村共享设备、手机丢失、员工变动、证书撤销和恢复会显著增加使用风险。

**已否决：** 平台无条件掌握所有组织私钥，因为平台可冒充参与方；也不宜强制所有小型参与者自行保管不可恢复私钥，否则丢失和共享账号会让系统不可用。

**需要接受的代价：** 分级模式意味着不同参与者具有不同信任保证；托管签名必须明确标记为 delegated trust，不能与企业本地签名描述为同一保证等级。

**待回答：** 哪些事件必须组织签名，哪些只需要经过强认证的提交；托管密钥如何恢复和撤销；device signature、organisation endorsement 和 ledger consensus 如何区分。

---

## C3. 是否采用完整 Event Sourcing 和异步 CQRS？

**当前倾向：** 跨组织 trace events 保持 append-only；普通用户、权限、配置和运营状态使用常规事务模型。是否引入 broker 和异步 projection 由一致性和 workload 场景决定。

**为什么尚未定案：** EPCIS 是事件共享模型，不等于整个应用必须 Event Sourcing。异步 projection 能加速谱系和消费者查询，但会引入 stale read、replay、schema migration 和恢复复杂度。

**已否决：** 把所有应用状态都建模成事件；也否决普通查询直接遍历 blockchain，因为共识账本不适合作为低延迟、按受众裁剪的查询引擎。

**需要接受的代价：** 如果先同步查询 PostgreSQL，未来高负载时可能需要重构；如果现在采用异步 projection，食品召回视图可能短暂落后，必须暴露 watermark 和 stale/unavailable 状态。

**待回答：** 哪些查询必须同步强一致，哪些允许 eventual consistency；是否只有 ledger dual-write 使用 outbox，还是所有 read models 都通过 broker 更新。

---

## C4. Shipping 与 receiving 是否必须形成双边交接状态机？

**当前倾向：** Shipping 和 receiving 保持两个组织的独立声明；平台关联后可以派生 Pending、Accepted、Partial、Rejected 或 Disputed，但是否强制双边确认由 product/transaction profile 决定。

**为什么尚未定案：** 独立声明能防止一方覆盖另一方，但现实流程可能存在代理接收、分批收货、永不确认或多个目的地。将同一状态机强加给所有供应链可能导致大量永久 Pending 和绕过行为。

**已否决：** 一条由任意一方修改的 transfer row，因为无法保留双方不一致；也不应默认每一次物流都必须由双方共同签署同一交易。

**需要接受的代价：** 独立事件带来 reconciliation 和争议处理；profile-specific 规则比一个全局流程更难测试。

**待回答：** 哪些业务步骤需要 receiver confirmation；未确认事件是否仍进入 trace；争议状态对消费者和 recall 查询有什么影响。

---

## C5. 第一版是否固定为一个 PostgreSQL？

**当前倾向：** 一个 managed PostgreSQL application database，通过 `registry`、`events`、`projection` 和 `operations` schema 做逻辑隔离；permissioned ledger 和 participant artifact stores 保持外部边界。

**为什么尚未完全定案：** PostgreSQL 足以提供事务、约束、JSON 和递归遍历，但背景也要求多产品线和地区，未来可能出现数据驻留或跨区域写入限制。

**已否决：** 第一版同时引入事务数据库、event store、graph database 和独立 read store，因为没有 workload 证据支持这些一致性边界。

**需要接受的代价：** PostgreSQL 是共享运营依赖，存在共同故障域；复杂谱系或跨区域部署达到一定规模后可能需要分区或专用存储。

**待回答：** 第一个部署区域、数据驻留假设、备份与恢复目标，以及何种实测阈值触发 graph/read store 或区域拆分。

---

## C6. Product Profile 能承担多少产品线差异？

**当前倾向：** 稳定 EPCIS core 加 versioned product profiles 是主要扩展机制，但不承诺所有新产品都只需配置、永远无需代码和数据模型变化。

**为什么尚未定案：** Profile 可以约束字段、单位、证据和业务词汇，但不同产品还可能改变召回、加工、温控、生物安全、保留期和 UI 工作流。

**已否决：** 为每个产品线复制一套服务和数据库；也否决“新增任何产品只需要一个 JSON schema”的过度承诺。

**需要接受的代价：** Profile engine 和版本兼容本身增加复杂度；某些产品仍可能需要经过评审的代码扩展。

**待回答：** 哪些规则可配置，哪些必须由领域代码实现；profile 的批准、弃用和兼容流程由谁治理。

---

## C7. Trustworthiness 与 scalability 如何排序？

**当前倾向：** Trustworthiness 决定核心信任边界，但 scalability 仍必须通过可测场景验证；不能用“不是主要问题”跳过 case brief 的多产品和多地区要求。

**为什么尚未定案：** 没有真实吞吐量和用户数量，虚构极端 TPS 没有意义；但完全没有容量和时延场景也无法证明云和查询设计合理。

**已否决：** 用没有来源的高 TPS/p95 数字驱动微服务；也否决只讨论可信性、不说明 ingestion、consumer query 和 lineage traversal 能承受什么规模。

**需要接受的代价：** 架构报告需要声明一组可复核的 workload assumptions，并承认它们不是客户提供的事实。

**待回答：** 参与组织、每日事件、消费者查询峰值、最大 lineage edges、允许的 projection lag 和恢复目标采用什么假设。

---

## C8. 云部署如何表达权力边界？

**当前倾向：** 区分 Participant Environment、Shared SaaS Application Plane 和 Consortium Ledger Plane；云厂商与具体 managed services 后定。

**为什么尚未定案：** 部署图必须反映真实独立控制域。把所有节点、密钥、数据库和治理组件部署在平台同一账号，会否定 B1 的不完全信任假设。

**已否决：** 仅罗列云服务品牌而不说明谁控制账号、密钥和恢复；也否决要求每个小型参与方部署完整基础设施。

**需要接受的代价：** 跨控制域部署增加网络、安全、监控、升级和故障协调成本。

**待回答：** 哪些组件由平台托管，哪些由独立组织或专业托管方控制；Participant Gateway 是否进入第一版；ledger node 和备份是否跨云账号或区域。

# 当前总体结论

当前已经确定的最短表述是：

> 本系统是跨组织农业供应链追溯层，而不是农业 ERP。参与方通过 PWA 或既有系统发布联盟 profile 约束的 EPCIS events。消费者只读取公开 projection；联盟成员共享足以重建路径和定位潜在责任方的 canonical EPCIS trace core；商业详情和原始证据作为 participant-owned ProtectedResources，由参与方保存或选择平台托管。系统不声称区块链证明物理事实真实，但要求平台运营者不能单方面静默重写或垄断已经确认的历史。

仍然阻止方案最终定型的核心问题是：谁在平台控制域之外运行 ledger nodes、承担复制和治理成本，以及系统需要抵抗到什么程度的节点串谋。

# 答辩时的一分钟版本

> We are building a cross-organisation agricultural traceability layer rather than an ERP. Small participants may use the platform PWA, while mature organisations integrate through EPCIS or APIs. A permissioned shared record retains the consortium-approved EPCIS trace core needed to reconstruct lineage and identify the party from whom further evidence is required. Consumers receive an allowlisted public projection, while commercially sensitive details and source evidence remain participant-owned protected resources that may optionally be hosted by the platform. This deliberately trades fine-grained cryptographic isolation for a clear and feasible permission model. The ledger makes unilateral post-confirmation rewriting by the platform detectable, but it does not prove that source claims are physically true.
