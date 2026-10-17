---
outline: false
---

# 完整决策日志

> 更新时间：2026-10-17（B17、B21 于 2026-10-18 修订）
>
> 用途：记录会改变系统边界、信任模型、数据责任或部署方式的重大决定，并保留每项决定背后的 trade-off。
>
> 依据：case brief、EPCIS 背景、行业平台调研，以及后续架构讨论。背景没有直接给出的内容会明确标记为补充假设。
>
> 阅读方式：第一层是背景直接支持的决定；第二层是已经接受的额外假设；第三层是仍待讨论的选择。
>
> 2026-10-18 修订说明：B17 改为“记录断言 / 签署判定”两分，并补上 non-collapsing 表示性质；B21 明确 Regulatory Analytics 位于系统边界内但属监管方独立运行时域，因此需要承担 C4 分解责任。受影响的下游表述已在总体结论、一分钟版本、B11、B15、B18、C3 同步，并已落入[决策目录](/decisions/catalog)、[系统地图](/architecture/system-map)与相关系统页。
>
> 2026-10-18 第二次修订：新增 **B23（PRIVATE 零知识模型与证据层分享）** 与 **B24（平台以组织为身份与访问单元）**；B3 的 `PRIVATE` 数据层、ProtectedResource 模型与访问矩阵，以及 B14、B15、B18、B20、B16 中与“平台可读私有证据”相关的表述一并修正。
>
> 2026-10-18 第三次修订：B3 新增「核心字段地板」并把数量归类与标识粒度绑定；B11 新增 Profile 的三条硬约束（含 conformance check）与扩展字段判据，明确 profile 不得把核心字段设为 optional。
>
> 2026-10-18 第四次修订：新增 **B25（Core / Semantic Module 分层与不变量）**，把 handover 状态、召回遍历策略、合规重建、分析输入、洞察统计移出 Core；B3 地板改为由模块 manifest 编译、B9 补配对键义务、B18 明确遍历策略归属、B11 补编译步骤、B21 指明投影由 AnalyticsInputModule 生产。

本页是原始决策日志，保留完整边界条件、否决方案和 trade-off，适合回答“为什么这样决定”。想了解“系统现在到底怎么划分”请从[系统地图](/architecture/system-map)开始；想按编号查结论请用[决策目录](/decisions/catalog)。

## 本页结构

- [第一层：背景充分支持的决定](#layer-a) — A1–A8
- [第二层：已经接受的额外前提](#layer-b) — B1–B22
- [已舍弃但保留的完整替代方案](#layer-d) — D1–D7
- [第三层：仍需讨论的决定](#layer-c) — C1–C3
- [当前总体结论](#summary)
- [答辩时的一分钟版本](#one-minute)

每项决定都会说明必要的边界和理由。只有当真实存在竞争方案、责任转移或显著负面后果时，才进一步记录被否决方案、代价及其可接受性；不为了形式完整而人为制造 trade-off。

<a id="layer-a"></a>
# 第一层：背景充分支持的决定

## A1. 系统是完整农业 ERP 吗？

**决定：** 不是。系统是跨组织农业供应链追溯层。ERP、WMS、TMS、MES、农场管理、POS、实验室、认证，以及监管机构现有的执法和完整 case-management systems 仍在边界之外；本平台自身包含 regulator-facing access/investigation portal，但不替代外部监管系统。

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

**决定：** 不能。系统只承诺声明的 attribution、authorisation、content integrity、correction history，以及 lineage claims 的 provenance/reconstructability，不承诺跨组织声明彼此一致，也不声称区块链能证明现实世界事实必然真实。

**边界条件/假设：** 软件不能直接观察货物、温度、实验过程或证书签发过程；它只能处理参与方、设备或证据提供者提交的声明。

**为什么这样定：** 正确签名的声明仍可能是错误、疏忽或欺诈。把密码学有效性描述为物理真实性会制造虚假安全感和错误法律期待。

**否决的方案：把“已上链”宣传为“真实可信”。** 该方案会掩盖 oracle problem，使用户在事故发生时错误依赖平台，并把平台暴露在无法兑现的责任承诺下。

**承受的代价：** 产品承诺听起来没有“区块链保证真相”强；调查仍需要 IoT、实验室、交叉确认、现场审计和参与方举证。

**为什么可以接受：** 这是技术能力的真实边界。系统仍能显著降低事后改写、冒名声明和责任无法定位的风险，而不夸大其能力。

---

## A5. 是否把完整事件、文件和 IoT 原始数据全部上链？

**决定：** 不把完整事件和文件写入公共链。公共链只保存 event commitment 或周期性 Merkle root；完整 canonical EPCIS shared trace 保存在平台控制域之外的独立不可变归档中，大型、高频或仅用于举证的内容继续作为 ProtectedResource 管理。

**边界条件/假设：** 公共链负责外部 existence/integrity checkpoint：证明某个 commitment 最迟在链上 inclusion 时已经存在且之后未被替换。它不证明业务 `eventTime`、不负责业务数据权限、完整 trace 恢复、文件存储或运营查询。

**为什么这样定：** 明文 EPCIS trace 上公链会永久公开供应链关系；完整 ciphertext 上公链又会产生费用、永久保留和未来密钥泄露风险。把 payload 与 proof 分开，可以让联盟内恢复完整 trace，同时只向公共网络暴露最小 commitment。

**否决的方案一：完整明文或密文 EPCIS payload 直接上公链。** 该方案会放大商业泄露、费用、数据驻留、删除和长期密码风险。

**否决的方案二：公链只存 hash，完整 payload 只有平台一份。** 该方案只能在平台愿意提供 payload 时验证防改；平台删除、拒绝服务或退出后无法恢复 trace。

**承受的代价：** 系统需要额外维护独立 immutable archive、归档复制、access-controlled key service、public-chain relayer、finality monitor 和 inclusion proof。

**为什么可以接受：** Archive 的运维职责远小于一个 BFT validator network：它不参与共识、不执行 smart contract，也不需要实时出块。它只需可靠保存、校验和恢复数据，仍能满足平台外可恢复的要求。

---

## A6. 已发布的追溯历史如何纠错？

**决定：** 不静默覆盖或删除已确认事件。错误通过 Error Declaration、corrective event 或等价的追加版本表达。

**原因：** 区块链和 EPCIS 纠错模型都不通过直接修改已经确认的历史来表达修正。原地更新还会使既有签名、hash 和账本承诺失效。因此系统追加错误声明和修正事件，并由查询视图显示当前有效解释；原始声明仍保留供审计。

平台必须区分传输/存储身份与 EPCIS 业务身份：

```text
captureRecordId
→ 每次 submission/archive record 唯一
→ 平台 idempotency key

epcisEventId
→ EPCIS business event identifier
→ Error Declaration 是允许重复 non-null eventID 的标准特例

correctiveEventId
→ corrective event 自己的新 EPCIS eventID
→ 由 correctiveEventIDs 引用
```

同一 `captureRecordId` 对应不同 digest 必须拒绝。相同 non-null `epcisEventId` 默认也拒绝重复，但符合 EPCIS Error Declaration 的记录可以与原事件共享 eventID：除 `errorDeclaration` 和 repository-generated `recordTime` 外，其内容必须与原事件相同。Corrective event 使用新的 eventID。Network profile 若不支持这一标准特例，就不能继续声称完整支持 EPCIS Error Declaration。

Normative basis: <https://ref.gs1.org/standards/epcis/2.0.1/#ErrorDeclaration>

---

## A7. 第一版是否直接采用大量微服务和多种数据库？

**决定：** 不。第一版采用模块化应用和关系数据库作为主要运营基础，并通过 ports/adapters 保留未来拆分能力。

**原因：** 当前没有团队规模、独立发布频率、故障隔离或实测 workload 证明需要微服务和 polyglot persistence。先用模块边界保护职责和依赖方向，可以避免过早引入分布式事务、网络故障和多套运维；以后出现明确的独立扩缩容或发布需求时再提取服务。

---

## A8. IoT 和 AI 在核心业务中分别是什么地位？

**决定：** IoT 是核心证据来源；AI/ML 如果采用，只能是可选、异步和 advisory 的风险分析能力。

**原因：** Case brief 明确要求 IoT 实时采集，因此 canonical event 可以保存必要的 sensor summary、异常和原始数据 commitment，而高频原始数据仍由 IoT 平台或参与方管理。AI 只帮助发现风险，不能决定事件是否有效、参与账本共识或代替食品安全与监管判断；关闭 AI 不影响基本追溯。

<a id="layer-b"></a>
# 第二层：已经接受的额外前提

## B1. 参与方是否完全信任平台运营者？

**决定：** 不完全信任。平台可以运营 SaaS、查询和日常数据处理，但不能成为已确认历史的唯一完整性证明和唯一可恢复副本。

**边界条件/假设：** 平台可能发生内部滥用、管理员账号泄露、基础设施入侵、错误恢复、商业压力或停止运营。系统需要防止平台在事件确认后无痕修改历史，并在平台失效后恢复 canonical trace。

**这是题设驱动且有意选择的架构前提。** 作业明确要求采用 blockchain，因此必须给它一个普通平台数据库、审计日志和备份不能独立完成的职责。如果所有参与方都完全信任平台运营者控制 payload、唯一副本、密钥和审计结果，那么 managed PostgreSQL + WORM backup 已经足够，额外写入 blockchain 只会成为 `blockchain theatre`。B1 因而不是背景已经证明的行业事实，而是为题目中的区块链要求建立的显式 scenario：参与方不完全信任平台对确认后历史的单方控制，公共链承担平台控制域之外的 existence/integrity checkpoint。

该“不完全信任”主要针对 history integrity、availability、key control 和 censorship accountability，不代表向平台 runtime 隐藏 `CONSORTIUM` plaintext。平台作为获授权数据处理者具有运行查询/projection 所需的 decrypt 能力；应用或 service role 被攻破仍可能造成 consortium confidentiality breach，需以 least privilege、审计、限流和 breach response 缓解。若要求平台也不可读，需要另行采用 client-side decryption/confidential computing，不属于当前基线。

**为什么这样定：** 如果事件 payload、commitment、查询结果和唯一副本都由平台控制，blockchain 只是平台内部的 append-only 实现，参与方仍然必须完全信任平台。反过来，如果最终部署中的 archive、KMS account、recovery identity 和 chain verification 仍全部由平台单独控制，即使名义上用了公链，也没有兑现 B1，仍属于 blockchain theatre。

**否决的方案一：完全信任平台数据库和备份。** 无法独立验证历史，也无法应对平台退出。

**否决的方案二：自建多组织 BFT validator network。** 该方案技术上有效，但背景没有给出足够多、真正独立且愿意承担节点、治理与升级成本的组织。

**当前约束：**

- 已 finalise 的 commitment 必须位于平台控制域之外的公共链；
- 在 active retention/legal hold 内，完整 canonical trace 必须至少有一个平台控制域之外的 immutable archive；
- canonical payload 获得规定的独立 archive acknowledgement 后，平台签发绑定该 acknowledgement 的 receipt，anchor finalise 后提供 inclusion proof；
- 平台不能把自己的 acceptance receipt 当作 public-chain finality；
- 平台仍可能在上链前拒绝或延迟事件，因此 censorship 与 tamper resistance 分开处理。

**承受的代价：** 外部 existence/integrity checkpoint 依赖 public network；数据可用性依赖独立 archive；系统还要维护 relayer、gas、finality 和 chain migration。

**为什么可以接受：** 这些职责比组织和维护自己的 BFT validator consortium 更标准化。平台风险被拆成可分别验证的 integrity、availability 和 ingestion-censorship 问题，而不是假装由一个账本同时解决。

---

## B2. 平台失效后，哪些数据必须仍可恢复？

**决定：** 在适用 retention period 和 legal hold 内，必须恢复联盟 network profile 中的完整 canonical EPCIS shared trace，包括事件、对象关系和纠错历史。原始证据和企业内部资料不属于强制恢复范围；retention 到期后的保证按 B20 收窄为 commitment 与删除审计可验证，而非 payload 永久可恢复。

**边界条件/假设：** 平台失效后，需要判断产品经历了哪些阶段、由谁发布、在哪一环出现矛盾，以及应向哪一方索取证据。按 B3 的"验证与重建"划分，这由两类主体分担：持有相应 scope 的成员恢复自己的范围；完整联盟历史由全 scope 方（监管方、审计者或受托恢复方）恢复。`logical RPO=0` 衡量的是"存在且可恢复"，不要求每个成员都能恢复全部 payload。

**为什么这样定：** 公链 commitment 只能验证拿到的内容是否匹配，不能从 hash 恢复 payload；只有平台 PostgreSQL 保存完整事件时，平台仍然是唯一数据可用性来源。

**否决的方案一：公链只保存 hash，完整事件只在平台数据库。** 可以检测拿到的 payload 是否被改，但拿不到 payload 时无法恢复任何 trace。

**否决的方案二：共享网络强制保管所有原始 IoT、证书、照片、合同和内部记录。** 会把平台变成通用证据仓库并承担不必要的隐私、保留和法规责任。

**承受的代价：** 需要平台外的 immutable archive、复制和恢复流程；参与方自管的 evidence 仍可能 `Unavailable`、`Expired` 或无法举证。

**为什么可以接受：** Trace core 的体积远小于原始文件和 telemetry，使用对象存储/WORM archive 的成本显著低于运行共识节点，却足以定位问题。原始材料仍由声明方举证，平台可提供可选托管。

**强制恢复范围：**

- captureRecordId、EPCIS eventID/error-declaration relation、type、time、publisher 和 profile version；
- batch、object、pallet 或 logistic-unit identifiers；
- business step、disposition、source/destination；
- aggregation、disaggregation、transformation 和 correction relationships；
- network profile 允许的 sensor/compliance summary；
- protected-resource reference、owner、issuer metadata 和 content commitment。

除 EPCIS trace payload 外，独立恢复包还必须保留验证和解释历史所需的 published Product Profile definitions、canonicalisation definitions、organisation/public-key history、key revocation history、network vocabularies、governance records、archive envelope specification 以及 public-chain contract/migration metadata。只恢复 payload 而无法还原当时的身份、schema 和验证规则，不算完成 trace recovery。

**默认不强制恢复：** 原始高频 telemetry、完整实验室文件、证书文件、照片、合同、商业单据、内部 ERP/WMS/TMS 明细和私有扩展。

### 当前存储分工

```text
Platform PostgreSQL
→ hot operational copy、query、projection

Independent Immutable Trace Archive
→ encrypted canonical EPCIS shared trace
→ platform-independent recovery

Public Blockchain
→ event commitment 或 periodic Merkle root
→ archive manifest hash
```

---

## B3. EPCIS 数据和证据采用什么权限模型？

**决定：** 保留固定的 `PUBLIC / CONSORTIUM / PRIVATE` 三层语义，但公共链只看到 commitment；`CONSORTIUM` payload 加密保存在 independent archive，不把联盟 trace 明文公开到公链。

**边界条件/假设：** 加入联盟意味着同意其他有效联盟成员读取 network EPCIS profile 中的最小 trace facts，但联盟外用户只能看到 public projection 和不可反推 payload 的 commitment。

这是必须由真实参与方通过 consortium agreement 验证的强商业披露假设，而不是技术自动成立的事实。若成员不能接受向所有 active consortium participants 披露 supplier/customer path、location、quantity 或 processing relationships，当前单一 KEK/固定三层模型必须改为 supply-chain-scoped authorisation、private collections 或 selective disclosure，整体复杂度会显著增加。

**为什么这样定：** 固定分类保留清晰的业务权限；per-event DEK 与版本化 consortium KEK 只保护整个 canonical payload，不重新引入字段级权限。

**否决的方案一：完整 EPCIS 明文对消费者公开。** 会泄露交易关系、精确地点、数量、设备和商业节奏。

**否决的方案二：每字段密码学隔离。** 会造成密钥和 policy 爆炸、难以查询和恢复，也无法让已经读取数据的成员“忘记”内容。

**否决的方案三：单独维护 private EPCIS layer。** 它与证书、IoT、合同等可选托管资料边界模糊，会产生两套权限和生命周期模型。

**承受的代价：** 权限治理从 validator membership 转移到 Consortium Key Service；KMS 不可用会影响 archive recovery，key compromise 可能暴露对应 epoch，退出成员已经下载的明文无法撤回。

**为什么可以接受：** KMS、key rotation 和 archive access 是成熟且较窄的基础设施问题，比维护多组织 consensus、orderer、validator upgrade 和 quorum 更容易外包和审计。

### 固定数据层

| 分类 | 内容 | 谁可读取 | 保存方式 |
|---|---|---|---|
| `PUBLIC` | 产品、来源地区、主要阶段、公开认证摘要、温控摘要、recall status | Consumer 及其他用户 | 从 shared trace 生成 allowlisted projection |
| `CONSORTIUM` | 联盟批准的 canonical EPCIS trace core | 已认证参与方、Auditor/Regulator、必要运维人员 | Encrypted immutable archive + application projection |
| `PRIVATE` | 精确商业详情、完整 sensor data、文件、企业私有扩展 | Owner；所有者显式加密授予的接收方 | 默认不上平台，只在 canonical event 留 reference + salted commitment；可选 zero-knowledge 托管（平台不可解密）。见 B23 |

### ProtectedResource 统一模型

结构化 private detail 与 PDF、照片、证书和原始 telemetry 使用同一个逻辑资源模型，**平台侧只有记录、没有内容**（B23）。字段定义见 [Data & Access](/systems/data-access)。

三点与早期设计不同，且这三点是决策而非实现细节：

1. 平台**没有 `accessScope` 可执行**——没有明文，无法做内容级授权；访问权只能由所有者"加密给谁"表达；
2. **没有结构化 JSONB 存 private detail 这条路**——要按字段查询就必须进 `CONSORTIUM`；
3. 平台**不能验证 commitment 与内容一致**，只能证明自己保存的密文未被替换。

### 固定访问矩阵

| 角色 | Public Projection | Shared Trace Core | ProtectedResource |
|---|---:|---:|---:|
| Consumer | 可读 | 不可读 | 不可读，除非另有公开摘要 |
| Consortium Participant | 可读 | 可读 | 仅自有的资源可解；他方资源需所有者加密授予 |
| Auditor/Regulator | 可读 | 可读 | 仅当所有者已把内容加密给监管 scope，或按案件向所有者索取；平台无法代为解密 |
| Platform Operator | 托管 | 托管 | **无明文访问**；零知识托管只能做 blob 级运维，不能解密、不能响应内容调取 |
| Archive Operator | 不因运行归档获得消费者身份 | 保存 ciphertext，不因运维自动获得明文权限 | 若代为存放 PRIVATE 密文，同样不获得明文 |

### 保证范围：验证与重建分开

扁平可见性容易被读成"任一成员可以重建完整联盟历史"。更准确的说法是把两种能力分开：

| 能力 | 需要明文吗 | 谁可以做 |
|---|---|---|
| 验证历史存在且不可重写：自己的记录被包含在某个已 finalise 批次、批次序列无断裂 | 不需要 | 任一成员（inclusion proof + consistency proof） |
| 重建并验证某条记录的内容、签名与语义 | 需要该事件的 canonical payload | 持有该事件 scope 的成员 |
| 重建并验证完整联盟历史 | 需要全部明文 | 全 scope 方：监管方、审计者、受托恢复方 |

即：

> 任一成员可以独立验证历史是一条 append-only 日志、且自己的记录被纳入其中；可以重建并验证自己 scope 内的历史。完整历史的重建与语义验证由全 scope 方执行，其结论对任何拥有相应 scope 的一方可以复核。

这样定的理由是：B1 的保证是**完整性**，而完整性验证不需要明文——成员靠 root 序列、inclusion proof 和 consistency proof 就能证明"我的记录在这条链里，且这条链没有被重写"。扁平可见性额外提供的"我能读别人的全部记录"对防篡改没有贡献，它服务的是恢复能力；而恢复能力可以由全 scope 方承担。

反过来，如果按 trace 收窄重建范围（只让当事人解密自己经手的批次），独立验证能力不变，但"任一成员可自行重建整条链"会退回到受托方一级。因此 v1 仍按扁平运行（scope = 全体 active 成员）；收窄是治理参数，不是架构重写。

**这条降低的是能力声明，不是安全保证。** 受影响的下游表述见 B2（恢复主体）、B7（consistency proof）、B17（non-collapsing 相对 scope）、B18（成员召回范围受限）。

### 分类判据

> 没有该数据，联盟是否仍能重建产品经过的组织、阶段和转换关系，并定位潜在责任方？

- 如果不能：进入 `CONSORTIUM` canonical EPCIS profile；
- 如果可以：建模为 participant-owned `ProtectedResource`；
- 如果消费者需要：从 shared trace 生成 `PUBLIC` projection。

如果某字段既不能让联盟成员看到，又是重建最小 trace 必不可少的内容，则当前简化模型不成立；必须修改共享假设或重新引入加密/private collection。

### 核心字段地板：数量按什么规则定？

判据落到具体字段时需要一条地板，否则每个 profile 都能自行决定"哪些字段算结构性"，最终会出现某条产品线的 trace 无法重建。

**决定：**

- 存在一份**必进 `CONSORTIUM` 的核心字段地板**，profile 不得把它降级为 optional 或重定义语义。完整清单与消费方见 [Data & Access](/systems/data-access)。
- **数量与粒度绑定**：`class-lot` 级必须带 `quantityList` + UN/CEFACT `uom`；`instance` 级可用标识计数，重量等退化为证据引用。具体规则见同一设计页。
- 地板**不是手写清单**，而是所有 ACTIVE 语义模块 manifest 的 `requiresFields` 并集，编译后冻结进 profile 版本（B25、B11）。

**为什么不能完全下放给 profile：** 字段只要进 canonical event 就是 `CONSORTIUM` 可见（B23 已确立没有中间档），所以 profile 能做的只有"放进 event"或"不放"。如果连核心字段也交给 profile 决定，就可能出现"某产品线没有数量、因此不支持部分收货与批量筛查"却仍被当作已实现的能力——这需要显式记录，而不是靠遗漏。

**profile 仍可决定的是**哪些扩展字段、哪些证据要求、哪条公开 allowlist；这些交给 schema 阶段由产品工作组识别，见 B11。

**推论：没有消费者的字段不进地板。** 例如 `readPoint` 目前没有任何模块声明为必需，因此默认 optional，仅作为争议与审计证据存在；`bizLocation` 由 RecallModule 与 ConsumerModule 声明，仍是必填。新增模块会收紧地板，属治理变更（`GovernanceRecord`），不能由开发流程静默完成。

### Consortium archive encryption

每个 canonical EPCIS event 使用独立 DEK 加密，DEK 再由版本化 Consortium KEK 包装：

```text
Canonical EPCIS payload
→ encrypt with Event DEK
→ ciphertext stored in immutable archive

Event DEK
→ wrapped by Consortium KEK
→ keyEpoch recorded in archive envelope
```

Consortium KEK 保存在专业 managed KMS/HSM 中，不把同一个 private key 文件复制给所有成员。承载 KEK 的 cloud/KMS account 必须由联盟或独立受托方控制，而不是平台运营者自己的管理员账号。平台只获得日常加解密所需的最小使用权限，不获得 key policy、disable、deletion 或 recovery 管理权限。

成员通过 organisation identity 获得解密权限；成员变化后启用新 key epoch。Revocation 只能阻止未来获取，不能撤回成员已经下载的明文。使用 AWS、Azure 或其他专业 KMS 降低了密钥存储和运维风险，但真正决定权力边界的是 account ownership、key policy 和 recovery authority，而不是供应商品牌。

Epoch 同时定义了**时间维度上的访问边界**：新加入的成员默认只获得当前及之后的 epoch，不会自动取得加入前的历史明文访问权；历史访问是显式的治理授予，由 B16 的 `GovernanceRecord` 记录。这直接决定了上节"验证与重建"的分界——加入前发生了什么，成员能验证日志连续性，但不一定能重建内容。

`keyId/keyEpoch` 是 archive envelope 的元数据，不进入 canonical payload、不进入签名输入、不进入 Merkle leaf。因此将来若需要第二类受众（例如只对监管方开放的提交），只需新增 key 与治理关系，不必变更 canonicalisation、签名、leaf 或 anchor 格式。

公共链只保存 ciphertext/archive manifest 的 hash 或 Merkle root，不保存 plaintext、DEK 或可直接揭示供应链关系的 metadata。

---

## B4. 系统对节点和参与方串谋提供什么保证？

**决定：** 不再声明本系统自己的 validator L2/L3。已锚定历史的完整性依赖所选成熟 public network 的 consensus 和 finality；本系统只声明平台与业务参与方不能重写已经 finalise 的 commitment。

### 当前保证

在所选 public network 安全且 commitment 已 finalise 的前提下，平台与一个业务参与方不能：

- 修改 archived EPCIS payload 而不导致 public commitment 校验失败；
- 删除或替换已锚定的 archive manifest 而不留下不一致；
- 伪造自行持钥、未参与串谋组织的原始 event signature；
- 让另一份 payload 匹配同一 cryptographic commitment。

它们仍然可以：

- 对自己控制的业务阶段共同提交虚假声明；
- 隐瞒从未提交的现实事件；
- 在 commitment 上链前拒绝、延迟或遗漏事件；
- 拒绝提供 participant-hosted evidence；
- 控制平台 consumer projection，除非用户独立验证 archive/proof；
- 泄露平台可以读取的 private data。

因此当前最简洁的保证仍是：

> 串谋方可以对自己控制的业务阶段共同说谎，但不能修改已经锚定的 payload 而不被发现，也不能替未串谋且自行持钥的组织生成真实签名。

### 公链信任没有消失，只是外部化

系统依赖所选 public network 不发生足以破坏 finality 的 validator/stake majority attack、恶意治理升级或长期停摆。这些风险不由农业联盟自行解决，而通过选择成熟网络、等待正式 finality、保存 chain receipts 和设计 chain migration 处理。

公链不解决上链前 censorship。平台接受事件时需要签发包含 event hash 和 anchor window 的 receipt；anchor finalise 后提供 inclusion proof。Receipt 可以证明平台接受后未按承诺锚定，但只有独立 submission path 才能真正绕过恶意平台入口。

**承受的代价：** 信任从自建 consortium validators 转移到外部 public network，并引入 gas、finality delay、chain governance 和迁移风险。

**为什么可以接受：** 防止平台事后无痕修改是当前最明确的目标。使用已有公共共识比在缺少真实运营者的情况下虚构七个独立 BFT domains 更务实，也更容易清楚说明保证边界。

---

## B5. 参与方签名和托管密钥如何统一接入？

**决定：** 采用分级 custody/assurance，并统一签名结果、验证格式和状态机；不要求企业 self-custody 与托管服务共享相同的私钥调用方式。

三种支持模式是：

```text
ENTERPRISE_SELF_CUSTODY
→ 企业 Gateway/KMS 本地签名

ASSISTED_EXTERNAL_CUSTODY
→ 外部 signing provider 托管或分割密钥
→ 参与方使用 passkey/device approval 授权

DELEGATED_PLATFORM_CUSTODY
→ 平台 KMS 代管并调用签名
→ 保证等级最低
```

### 统一的是 SignatureEnvelope

无论签名来自企业 KMS、外部托管服务、设备密钥还是平台 KMS，提交到追溯系统的结果统一为：

```text
SignatureEnvelope
- signerOrganisationId
- actorId
- keyId
- algorithm
- payloadDigest
- signature
- assertedSignedAt (optional; not trusted by itself)
- signingTimeEvidence (optional)
- custodyMode
- assuranceLevel
- providerReceipt
```

所有模式使用同一个 `EventSignatureVerifier`：

```text
canonical event digest
→ lookup registered public key
→ verify signature
→ check key and actor/organisation authority at acceptance
→ evaluate trusted signing-time evidence for late/offline submissions
→ check assurance level required by event policy
```

Archive、anchor service 和领域规则依赖标准 envelope，不依赖 AWS、Azure、Turnkey、Fireblocks、Vault 或某个本地 KMS 的专有格式。

### 签名真实性与签署时间是两个问题

能用 registered public key 验证 signature，只能证明该私钥产生了签名；participant 填写的 `eventTime`、`assertedSignedAt` 或预先生成的 `captureRecordId` 都不是可信时间证据。平台 `receivedAt` 只能证明最迟收到时间，不能证明离线期间何时签署。

`signingTimeEvidence` 可以是可验证的 external signing-provider receipt、平台在撤销前签发的 challenge/nonce receipt，或企业 gateway 定期归档/锚定的 offline-queue checkpoint。它必须绑定同一 payload digest、keyId 和 signer；纯客户端声明不得提升保证等级。

```text
key/authority valid at platform acceptance
→ normal validation

key expired/revoked before platform acceptance
and trusted evidence proves signing occurred inside the valid interval
→ apply governed late/offline-submission policy

key expired/revoked before platform acceptance
but only participant-asserted eventTime/assertedSignedAt exists
→ REVIEW_REQUIRED; never auto-CONFIRMED
```

已在撤销前完成 archive/anchor 并确认的历史事件，不因之后发生 key compromise 而自动失效；可以将 `suspectedCompromiseFrom` 作为调查范围，正式结论通过新的 signed assessment/correction 记录。

### Self-custody 与托管签名使用不同入口

企业 self-custody 时，平台不调用企业私钥服务：

```text
Enterprise Gateway
→ canonicalise event
→ sign locally
→ submit event + SignatureEnvelope
```

平台只验证结果。因此所有模式共享 `EventSignatureVerifier`，但只有平台协助的托管模式使用：

```text
ManagedSigningPort
- createRequest(context, digest)
- getStatus(requestId)
- getResult(requestId)
- cancel(requestId)
```

托管接口必须是异步 workflow，而不是简单的 `sign(hash)`，因为外部服务可能需要 passkey、手机确认、多人审批或 MPC 后才能返回签名。统一状态至少包括：

```text
PENDING_APPROVAL
APPROVED
REJECTED
EXPIRED
```

Human authentication 与 organisation event signing 是不同边界。大型企业用户通过企业 IdP federation 登录，小型参与方使用 managed customer identity provider；核心系统只消费 authenticated subject claim 并检查其 organisation/role binding，不自行实现企业员工目录、密码或 MFA。Canonical event 只保留 pseudonymous `actorId`、signer organisation 和 signature，不永久保存员工姓名或邮箱。

### 平台需要维护的 provider adapters

Core API 始终允许参与方直接提交 vendor-neutral 的已签名 event，因此大企业接入自己的 KMS 不需要平台维护专用签名 adapter。

如果 PWA 要提供完整托管签名体验，平台需要为选定服务实现 adapter：

```text
ManagedSigningPort
├── DefaultExternalCustodyAdapter
└── PlatformKmsAdapter
```

第一版只集成一个默认 external signing provider，不同时维护多个同类供应商。新增供应商只增加 adapter，不改变事件、验证、archive 或 public-chain commitment 模型。

AWS KMS 等支持 asymmetric signing API 的专业 KMS 可以实现 `ManagedSigningPort`，但“私钥存放在专业 KMS”本身不决定 assurance level：

- key/account 由参与组织控制，平台只收到签名结果时，属于 `ENTERPRISE_SELF_CUSTODY`；
- provider 要求参与方 passkey、设备确认或独立 key share 时，属于 `ASSISTED_EXTERNAL_CUSTODY`；
- 平台服务账号可以单独调用 `Sign` 时，即使私钥从不离开 KMS，仍属于 `DELEGATED_PLATFORM_CUSTODY`。

### Participant signing key 与 Consortium KEK 分离

B5 管理的是“谁声明了 event”的 organisation signing key；B3 管理的是“谁能读取 archive payload”的 Consortium KEK。二者可以使用同一类专业 KMS 和相似的 provider-adapter 技术，但必须使用不同的 keys、用途、policy 和 lifecycle：

```text
ManagedSigningPort
→ asymmetric organisation key
→ produces SignatureEnvelope

ConsortiumKeyEncryptionPort
→ symmetric consortium KEK
→ wraps/unwraps per-event DEK
```

系统不得用 Consortium KEK 签署参与方事件，也不得因为平台有权解密 shared trace 就赋予平台调用参与方 signing key 的权限。

### 所有模式签署相同 canonical digest

Network profile 必须固定并版本化 canonicalisation。签名输入至少绑定：

```text
networkId
profileVersion
captureRecordId
epcisEventId (nullable; may repeat only for valid Error Declaration)
canonicalEpcisPayloadHash
signerOrganisationId
```

这样可以防止签名被挪到其他网络、profile、event 或 organisation 上，也避免不同 provider 因 JSON 序列化不同而生成不可比较的 hash。

### 统一接口不能抹去信任差异

- `ENTERPRISE_SELF_CUSTODY`：平台不能在没有企业私钥的情况下代签，适用完整 L2 non-impersonation guarantee；
- `ASSISTED_EXTERNAL_CUSTODY`：只有 provider policy 确实要求参与方持有的 authenticator 或独立 key share 时，才能接近同等保证；
- `DELEGATED_PLATFORM_CUSTODY`：平台理论上可以代签，只保证事件取得 finality 后不能被平台单方面静默修改。

Event policy 可以要求不同保证等级。例如普通 PWA 录入可接受 delegated custody，而 organisation-key change、实验室证书或高风险 dispute 可以要求 self-custody 或 participant-approved external custody。

**承受的代价：** 平台仍需维护一个默认托管服务 integration、异步 callback、key registry、rotation 和 revocation；不同参与方获得的 attribution guarantee 不完全相同。

**为什么可以接受：** 强迫所有小农场自行管理不可恢复的 PKI 会伤害可访问性，把所有密钥交给平台又会破坏 L2。统一 envelope 加分级 assurance 保留了共同事件模型，同时诚实暴露不同 custody mode 的信任差异。

---

## B6. 事件什么时候进入正式共享历史？

**决定：** 事件只有在 canonical payload 已进入 independent immutable archive，并且对应 commitment 已按所选 public network 的规则达到 finality 后，才成为 `CONFIRMED`。

```text
DRAFT
├── online submit ────────────┐
└── QUEUED_OFFLINE → SYNCING ───┤
                              → RECEIVED
→ VALIDATED
  ├── pre-signed/self-custody ───────────────┐
  └── managed custody → PENDING_SIGNATURE ──┤
                                            → PENDING_ARCHIVE
→ PENDING_ANCHOR
→ SUBMITTED_ON_CHAIN
→ INCLUDED
→ FINALISED
→ CONFIRMED
```

失败或终止状态包括：

```text
REJECTED
SIGNING_REJECTED
EXPIRED
REVIEW_REQUIRED (non-terminal quarantine)
ARCHIVE_RETRY
ANCHOR_RETRY
```

### 各状态的含义

- `DRAFT`：参与方本地意图，可以编辑或删除，不属于共享历史；
- `QUEUED_OFFLINE/SYNCING`：事件仍位于 participant device/gateway 或正在传输，平台尚未接受，不得显示 acceptance receipt；
- `RECEIVED/VALIDATED`：平台已经接收和验证，尚未形成外部证明；repository 在 capture 时生成可信 `recordTime`，忽略客户端提供的 EPCIS `recordTime`，并另存 participant-asserted `eventTime` 与平台 `receivedAt`；
- `REVIEW_REQUIRED`：迟到/离线 submission 使用已撤销或过期 key，且没有足以证明撤销前签署的可信时间证据；该状态不签发 acceptance receipt。只有使用当前有效 key 重新签署同一 canonical digest，或取得有明确责任主体的 signed governance/regulatory exception 后才能继续，否则转为 `REJECTED`；
- `PENDING_SIGNATURE`：仅 managed/assisted custody 路径进入，等待参与方或 signing provider 批准；pre-signed self-custody submission 验证通过后直接进入 `PENDING_ARCHIVE`；
- `PENDING_ARCHIVE`：等待 encrypted canonical payload 获得 qualified independent archive operator 的 signed acknowledgement；
- `PENDING_ANCHOR`：archive object 已持久化，等待生成 event commitment 或进入 Merkle batch；
- `SUBMITTED_ON_CHAIN/INCLUDED`：交易已广播或进入区块，但尚未满足最终性规则；
- `FINALISED`：public network 已达到所选 finality；
- `CONFIRMED`：finality、archive location 和 inclusion proof 已关联，正式进入标准 trace、projection、recall 与 consumer-view 输入。

### 权威关系

```text
Signed canonical EPCIS payload in Independent Archive
→ 可恢复的业务记录

Finalised public-chain commitment
→ payload 未被事后替换的外部证明

PostgreSQL
→ submission 状态、hot query 和 projection

Participant/PWA storage
→ 尚未共享的 draft
```

完整权威记录是 `signed payload + archive copy + finalised commitment + inclusion proof` 的组合，而不是 PostgreSQL 行或单独一个 public-chain hash。

canonical payload 完成签名并获得 independent archive acknowledgement 后，平台签发 acceptance receipt，其中包含 `captureRecordId`、`epcisEventId`、`canonicalPayloadDigest`、`ArchiveAckDigest`、archive reference、received time、预期 anchor window，以及 archive operator identity/signature。Finality 后再提供 chain transaction reference 与 inclusion proof。Receipt 能证明平台和 archive operator 已接受该归档记录并承诺纳入锚定，但不能替代 finality。

食品安全公告是标准 consumer projection gate 的唯一明确例外：authorised regulator/responsible organisation 已签名且取得 archive acknowledgement 的 official Recall/Safety Notice 可以用 `VERIFIED_PENDING_ANCHOR` 状态立即发布，清楚标示尚未获得 chain finality，并在恢复后继续正常 anchoring。普通业务 event、ML finding 和 preliminary advisory 不获得此例外。

Archive 已写入但 public-chain transaction 失败时，事件保持 `PENDING_ANCHOR` 并幂等重试；链上 commitment 已 finalise 但 PostgreSQL 更新失败时，根据 archive manifest 和 chain proof 修复运营数据库，不生成新事件。

Merkle batch manifest 必须随 canonical payload 一样保存在 independent archive，使参与方能够验证某个 event 确实包含在 root 中。普通 projection 默认只使用 `CONFIRMED` events。

**代价：** 公链费用、finality delay、reorganisation、relayer failure 或 archive replication failure 都可能延迟确认。

**为什么可以接受：** 延迟确认比在 payload 未安全保存或 commitment 尚未 finalise 时提前宣布共享历史更安全。现有 confirmed trace 仍可查询，pending events 在依赖恢复后继续处理。

---

## B7. 公共链 commitment 如何提交？

**决定：** 第一版按固定时间窗口对已归档的 canonical events 生成 deterministic Merkle tree，由平台 relayer 统一支付 gas 并将 root 提交到公共链。具体窗口长度和 public network 作为部署参数留到最后决定，不阻塞领域模型和后续架构决策。

```text
Signed canonical event
→ encrypted immutable archive object
→ archive-operator-signed acknowledgement
→ platform-signed acceptance receipt binding the acknowledgement
→ fixed anchor window
→ deterministic batch manifest + Merkle root
→ platform relayer submits root
→ public-chain finality
→ event inclusion proof
```

Batch manifest 至少记录 batch ID、window boundaries、ordered leaf list、hash/canonicalisation algorithm、Merkle root 和 archive reference，并与 event payload 一起独立归档。每个 versioned Merkle leaf 绑定 `networkId + captureRecordId + epcisEventId + canonicalPayloadDigest + participantSignatureDigest + ArchiveAckDigest`；字段顺序、长度编码和 hash algorithm 由 canonicalisation version 固定。相同输入必须能够重建相同 root；参与方不需要信任平台提供的查询结果即可验证 inclusion proof。

第一版不设置 independent secondary relayer。平台漏提或延迟提交时，receipt、archive copy 和逾期的 expected anchor window 会留下可审计的不一致，但不会自动绕过平台的 censorship。若实际治理要求在平台失效时仍能继续提交，可在不改变 event、archive 和 proof 格式的前提下增加 archive operator 或 auditor relayer。

**批次序列必须可验证，而不是只有单批次可验证。** B3 把"成员可独立验证历史未被重写"写成了保证的一半，而彼此独立的 root 只提供 inclusion proof，不能证明"没有批次被跳过、没有批次被重排"。因此 root 必须构成可验证的 append-only 序列：每个 root 承诺其前序 root（running hash chain），或采用支持 consistency proof 的 transparency-log 结构。**这一条是 B3 保证范围的技术前提，不是可选优化。**

**未采用逐事件上链：** 它的 proof 更直接、确认等待通常更短，但每个 event 都产生链上交易，成本、nonce 管理和故障恢复随业务量增长。Merkle batching 把链上职责压缩为定期发布少量 root，更符合“公链只负责外部 existence/integrity checkpoint”的边界；链上 inclusion time 不证明业务 `eventTime`。

**需要接受的代价：** event 在所属窗口关闭并达到链上 finality 前只能保持 pending；manifest 和 inclusion-proof 服务成为必要组件；第一版只能检测平台未按承诺提交，不能保证在平台恶意停摆时自动完成提交。

**为什么可以接受：** 完整 payload 已先进入独立归档，不会因为等待 batch 而只存在于平台数据库中。该作业的核心目标是让事后替换和已接受后漏锚定可被发现，而不是建立一条低延迟支付链。窗口长度可在得到事件量、gas 成本和可接受确认时延后再配置。

---

## B8. Independent Archive 与 Consortium KMS 由谁运营？

**决定：** Independent Archive 采用“一个强制独立副本 + 可选多方 mirror”的开放复制模型；Consortium KEK 托管在由联盟或独立受托方控制的专业 managed KMS 中。二者都不能只存在于平台自己的 cloud account 和管理员权限域内。

### Archive replication baseline

每个 canonical event 在成为 `CONFIRMED` 前，至少获得一个签约的、非平台控制的 WORM archive operator 的持久化 acknowledgement。大型联盟成员、监管方或审计机构可以自愿运行额外只读 mirror，但系统不假设监管方一定愿意承担该职责，也不等待所有自愿 mirror 才确认事件。

归档对象不只是一段无上下文的 ciphertext，而是 versioned `EncryptedArchiveEnvelope`：

```text
EncryptedArchiveEnvelope
- envelopeVersion
- networkId
- captureRecordId / epcisEventId
- canonicalPayloadDigest
- participantSignatureDigest / signature reference
- ciphertextDigest
- wrappedDEK
- keyId / keyEpoch
- encryptionAlgorithm / nonce
- canonicalisationVersion / profileVersion
```

使用 authenticated encryption；事件身份、canonical payload digest、signature digest、key epoch 和版本信息作为 authenticated metadata，防止不改 ciphertext 却替换 envelope context。`canonicalPayloadDigest` 绑定参与方已签署的明文；`ciphertextDigest` 绑定 archive operator 实际保存的字节。

该 acknowledgement 必须可独立验证，而不是平台数据库中的布尔字段：

```text
ArchiveAck
- archiveObjectId
- captureRecordId / epcisEventId
- archiveEnvelopeDigest
- ciphertextDigest
- retentionPolicyId
- storedAt
- archiveOperatorId
- operatorSignature
```

`operatorSignature` 覆盖 archive object identity、envelope digest、ciphertext digest、retention commitment、storedAt 和 operator identity。Acceptance receipt 绑定 `ArchiveAckDigest` 与 `canonicalPayloadDigest`，使参与方可以证明平台是在获得外部持久化确认后才承诺接收。Archive operator 不需要解密或判断业务内容，只证明按约定保存了特定 envelope/ciphertext bytes。

```text
Platform operational copy
→ query and processing; not an independent recovery copy

Required external WORM archive
→ minimum platform-independent recovery guarantee

Optional enterprise/regulator mirrors
→ additional resilience and independent verification
```

Mirror 接收标准化 archive bundle：encrypted canonical payload、wrapped DEK、key epoch、event signature、batch manifest、receipt 和可用后补充的 chain inclusion proof。保存密文副本不自动授予解密权限；archive replication role 与 consortium data-reader role 分开授权。

该模型不要求 mirror 运行 consensus、smart contract 或完整业务应用。它只需验证 content hash、保持 append-only/WORM storage，并能按标准 export/recovery protocol 返回对象，因此成本和治理负担显著低于联盟链 validator。

### KMS control baseline

专业云 KMS 负责密钥材料的保护、密码学操作和审计，但联盟或独立受托方拥有 KMS account、customer-managed KEK、key policy 与 recovery authority。平台服务角色可以获得业务运行所需的 `GenerateDataKey`、wrap/unwrap 或 decrypt 权限，但不能管理、禁用、删除或接管 KEK。

平台作为获授权的数据处理者仍可能读取 `CONSORTIUM` payload；这里解决的是平台不能单方面销毁密钥、垄断恢复或使 archive 永久不可读，而不是向平台隐藏联盟共享数据。如果未来要求平台也不可见明文，需要 client-side decryption 或 confidential-computing 等另一套更复杂的威胁模型。

这也意味着被攻破的平台 runtime/service role 可能在其正常 decrypt 权限范围内批量泄露 consortium plaintext。当前威胁模型不声称防止这一 confidentiality failure；它通过 least privilege、短期 credentials、audit、rate limits 和 incident response 降低风险，但核心保证仍是 platform-independent integrity/recovery。要求平台运行时也不可见将构成新的架构前提。

### Platform-independent recovery path

```text
Trustee/consortium-controlled Recovery Client or Gateway
→ discovers archive manifests without platform database
→ verifies ArchiveAck and the stored envelope/ciphertext digests
→ authenticates an authorised recovery organisation/regulator
→ calls KMS using non-platform recovery identity
→ unwraps DEKs and verifies decrypted canonical payload digest
→ verifies participant signature and public-chain inclusion
→ rebuilds profiles, registries and trace
```

Recovery identity、KMS policy、archive catalogue/export endpoint、profile/key/governance history 和 runbook 不能依赖平台 cloud account、IAM、DNS 或 PostgreSQL。第一版可以由 archive/KMS trustee 运营该 Recovery Gateway；具体签约主体留在 C3，但接口、权限和定期 restore drill 属于基线。没有成功恢复演练时，`logical RPO=0` 只能称目标，不能称已证明能力。

### 必须诚实保留的依赖

外部 KMS 把信任从平台转移给专业服务与 KMS account governance，并没有消除信任。Archive 全部存在但 KEK 永久丢失时，trace 仍不可恢复。因此 key deletion protection、region/provider outage、rotation、emergency recovery、retention expiry 和管理员交接必须纳入恢复设计；是否增加第二 provider escrow 或 threshold recovery 留到 RPO/RTO 与监管要求明确后决定。

**需要接受的代价：** 平台需要跨控制域调用 archive 与 KMS，处理权限故障和外部服务不可用；至少一个独立 archive operator 与 KMS account owner 需要合同、审计和交接安排。

**为什么可以接受：** 这些参与方只承担标准化存储或密钥托管职责，无需验证业务交易或参与共识。一个强制外部副本提供最低恢复保证，自愿 mirrors 可以逐步增加韧性，同时不会让小型参与方承担基础设施义务。

---

## B9. Shipping 与 Receiving 如何形成双边确认？

**决定：** 当实物交接双方都是联盟内已注册组织时，B2B handover 要求 receiver 最终作出独立签名的 receiving claim，但不要求双方共同签署或修改同一个 event。文档中的 `ShippingEvent/ReceivingEvent` 是领域简称；EPCIS 接口使用标准 `ObjectEvent`（或 profile 允许的相应标准 event）配合 `bizStep=shipping/receiving`、source/destination 和 disposition 表达。双方 claims 分别进入 immutable history。

**谁派生 handover 状态：** 按 B25，Core 只存两份 claim 与它们的配对引用，不产生交接状态；**状态由 HandoverModule 派生**，作为可重建投影存在，并由该模块的 manifest 声明它需要的 `requiresPairingKey`。

**配对键必须稳定。** 如果发货方和收货方各自引用自己的单据编号，两个 URI 配不上，`ACCEPTED` 就退化成"标识符 + 时间窗 + 双方组织"的启发式匹配，`PARTIALLY_ACCEPTED` 在实践中不可靠。因此 profile 必须指定唯一的配对键类型，并由**收货方在其 receiving claim 中引用发货方签发的那个键**（候选实现：`bizTransaction` 的 desadv，见待办 T13）。若无法配对，进入 reconciliation/dispute，不静默合并。

```text
Sender-signed ShippingEvent
→ independently CONFIRMED claim: "we shipped these objects"

Receiver-signed ReceivingEvent
→ independently CONFIRMED claim: "we received/rejected these objects"

Transfer projection
→ AWAITING_RECEIPT / ACCEPTED / PARTIALLY_ACCEPTED
  / REJECTED / DISPUTED / UNACKNOWLEDGED
  / EXTERNAL_COUNTERPARTY
```

这里必须区分两个正交状态：

- event lifecycle 的 `CONFIRMED` 表示某一组织的声明已经签名、归档并锚定，不表示另一方同意；
- handover status 表示双方声明能否匹配以及 receiver 是否接受交接。

缺少 ReceivingEvent 不会阻止或删除 ShippingEvent。发货声明可以独立 `CONFIRMED`，但 transfer 保持 `AWAITING_RECEIPT`；超过 profile 定义的期限后变为 `UNACKNOWLEDGED`，不能自动视为接受。这样 receiver 无法通过不响应抹去 sender 的声明，sender 也不能用单方声明制造一条被表示为双方已接受的路径。

对方不是联盟注册组织时，不伪造无法获得的 receiver signature：联盟成员仍可发布单方 shipping/receiving source claim，handover 标为 `EXTERNAL_COUNTERPARTY`，并保留可用的外部单据/evidence reference。面向最终消费者的零售使用 retail-selling 等 EPCIS 表达，不要求消费者签名。这些边界声明可以进入历史，但不得显示为双边已接受。

ReceivingEvent 不是简单的 approve flag。它必须能够记录实际收到的 identifiers、quantity/unit、time、condition 和差异原因，并引用 `handoverId`、ShippingEvent ID、sender、receiver 与相关 logistic units，以支持分批接收、短缺、损坏、错发和多目的地。无法确定匹配关系时进入 reconciliation/dispute workflow，不静默合并事件。

### 查询和纠错规则

- 普通 accepted-path 或 consumer projection 可以只展示 `ACCEPTED`，或明确标记其他状态；
- recall、food-safety 和 audit 查询必须保守地包含 `AWAITING_RECEIPT`、`PARTIALLY_ACCEPTED`、`DISPUTED`、`UNACKNOWLEDGED` 和 `EXTERNAL_COUNTERPARTY` edges，避免争议期间或网络边界漏掉可能已经实际流转的货物；
- 已确认的 ShippingEvent 和 ReceivingEvent 不原地修改；数量、关联或状态错误通过引用原事件的 correction event 修正；
- carrier、sensor 或 inspection events 可以增加证据，但双边确认仍只证明双方作出了相互关联的声明，不能证明物理事实真实，也不能防止双方串谋。

**需要接受的代价：** 系统需要 handover correlation、partial receipt、timeout、reconciliation 和 dispute projection；未及时确认会产生长期非终态 edge，查询必须显示保证等级而不能简单隐藏。

**为什么可以接受：** 两份独立声明保留了不一致本身这一关键证据，也避免由接收方离线或拒绝配合而阻止发货方记录历史。复杂性集中在可重建的 transfer projection，而不是让任意一方修改另一方已经签署的事实声明。

---

## B10. 是否采用完整 Event Sourcing 和异步 CQRS？

**决定：** 不采用全应用 Event Sourcing，也不在第一版引入独立 message broker、event store、read database 或 graph database。系统采用 `append-only trace core + ordinary transactional application + transactional outbox + targeted rebuildable projections`；第一版的 operational state、outbox 与 projections 位于同一个 managed PostgreSQL 中。

### 数据职责

不可原地覆盖、只能追加或通过 correction event 修正的内容包括：

- canonical EPCIS events；
- ShippingEvent、ReceivingEvent 与 correction events；
- participant signatures；
- archive receipts、batch manifests 和 chain inclusion proofs。

用户、组织当前资料、membership、API credentials、signing request、relayer job、重试状态、UI 配置等使用普通事务模型。需要审计的配置可以版本化，但不要求从全量 domain events 回放整个应用。

可从 canonical events 重建的 projections 包括 lineage、handover status、batch location、consumer view、recall graph 和 activity summaries。Projection 可以更新、删除后重建或更换存储技术，不构成权威历史。

### 第一版异步机制

```text
PostgreSQL transaction
├── signed event index / lifecycle transition
└── durable outbox job

Idempotent workers
├── write independent archive
├── issue acceptance receipt
├── allocate Merkle batch / submit anchor
└── update targeted projections
```

Outbox 与对应的本地状态变更在同一数据库事务中提交，worker 使用 `captureRecordId`、operation ID 和 state precondition 实现幂等；EPCIS `eventID` 另按 A6 的 Error Declaration 特例验证。Archive 和 public chain 无法加入同一个数据库事务，因此由 B6 的显式 lifecycle 和 retry/reconciliation 处理，而不假装存在跨系统 ACID transaction。

第一版可以逻辑区分 command、worker 和 query responsibilities，但不需要为了使用 CQRS 术语部署两套数据库。只有在实测吞吐、独立消费者数量、projection rebuild 时间或故障隔离要求证明必要时，outbox 才发布到独立 broker，特定 read model 才迁移到专用存储。

### 一致性边界

以下操作要求同步事务约束：`captureRecordId`/idempotency、签名与 organisation authority、合法 lifecycle transition、ArchiveAck 与 receipt 的绑定、每条 receiving claim 自身的唯一 capture identity，以及 Merkle leaf allocation。一个 handover 可以因 partial、split 或 correction 产生多条 receiving claims，不能误设为“每个 handover 只能消费一条 ReceivingEvent”。

Consumer view、dashboard、lineage visualisation、handover summary 和 analytics 可以最终一致。Recall/food-safety 查询不得把 projection lag 当作“没有风险”：必须暴露 `data complete through` watermark 和 lag；超过安全阈值时等待追平、回查 eligible source index（confirmed trace，加上 B18 authorised safety-notice fast path），或明确返回 `STALE/INCOMPLETE`。

**未采用完整 Event Sourcing：** EPCIS 是跨组织业务事件标准，不代表用户、权限、配置和作业状态都必须通过 event replay 产生。全量 Event Sourcing 会引入不必要的 replay、schema evolution、event-version compatibility、projection debugging 和个人信息删除冲突。

**需要接受的代价：** PostgreSQL outbox 与 workers 仍然构成异步系统，需要幂等、重试、dead-letter/reconciliation 和 lag monitoring；单一 PostgreSQL 是第一版的共享运营故障域。

**为什么可以接受：** 不可变性由 signed archive 与 public-chain commitment 提供，数据库只承担运营索引和可重建视图。该方案保留未来接入 broker 或专用 read store 的演进路径，却不在缺少 workload 证据时预付完整 CQRS/Event Sourcing 的复杂度。

---

## B11. Product Profile 是否采用可配置 Schema 和版本管理？

**决定：** 采用受治理的 `Versioned Product Validation Profiles`，而不是通用动态 schema、rule engine 或 no-code workflow platform。Profile 负责产品特有的数据约束和简单展示元数据；稳定的 EPCIS core、信任边界和跨事件业务语义继续由领域代码实现。

### 可配置范围

第一版 profile 可以定义：

- 标识粒度（`class-lot` 或 `instance`），但受 B3 的数量规则约束；
- required/optional EPCIS extension fields；
- primitive types、formats 和 enumerations；
- permitted units（统一到 UN/CEFACT code）和 product vocabulary；
- required/optional evidence-reference types；
- consumer projection 的显式字段 allowlist；
- 通用表单控件所需的 label、help text 和 display metadata。

以下内容不能由任意 profile 重写：EPCIS event core semantics、Shipping/Receiving handover、correction/append-only rules、canonical digest、signature assurance、archive/anchor lifecycle、organisation authorization 和 recall traversal。**Profile 也不得把 B3 的核心字段地板设为 optional 或重定义标识粒度**。Yield、mass balance、fraud heuristics、cross-event plausibility 和 compliance conclusions 不放入 profile，也不转移到核心领域代码，而由 Regulatory Analytics 子系统处理（B21）。

Profile 不引入任意 field-level access policy。Profile 中的 shared trace fields 默认属于 `CONSORTIUM`；消费者只能读取 allowlisted `PUBLIC` projection；不能向联盟公开的文件或数据继续作为 `PRIVATE` ProtectedResource，也不进 event。

### Profile 的三条硬约束

| # | 约束 | 为什么 |
|---|---|---|
| 1 | 不得把 B3 的核心字段地板降级为 optional，也不得重定义其语义 | 否则某条产品线的 trace 会无法重建，而架构仍声称能重建 |
| 2 | 必须显式声明**标识粒度**（`class-lot` 或 `instance`），且与 B3 的数量规则一致：`class-lot` 必须有 `quantityList` 与 `uom` | 数量是否进 event 取决于粒度，不能让"漏写数量"变成隐式的粒度切换 |
| 3 | 必须通过 profile conformance check 才能发布 | 把"profile 不能弱化追溯"变成会挡住发布门禁，而不是一句原则 |

**地板清单由模块 manifest 编译而来（B25），不是手写维护。** 发布 profile 时执行两步：① 把所有 ACTIVE 语义模块的 `requiresFields` 并集编译成该版本的地板；② 用地板做 conformance check。地板一旦发布即冻结，后续模块新增字段必须发新 profile 版本并走治理，否则历史事件会按新规则被重新解释——这违反 B2 的恢复要求。

conformance check 的完整失败条件清单属于设计内容，见 [Traceability Core → Product Profile](/systems/traceability-core)。

### 扩展字段的判据（给 schema 作者用）

产品工作组不需要自己判断"这个字段算不算结构性"，只需要按顺序回答三问：

```text
1. 监管方已声明某类 rule 需要它做筛查？
   → 必须进 event（并接受全联盟可见），
     或明确记录"该产品线不支持这类筛查"，不能假装筛查还在
2. 只用于举证、追溯附件或人工核查？
   → 证据引用 + 加盐承诺（B23），不进 event
3. 两者都不是？
   → 不要收集
```

第 1 条的代价必须被看见：**进 event 就等于全联盟可见**。因此"不支持 mass balance 筛查"是一个合法的产品选择，但它要被写进 profile 的能力声明，而不是靠字段缺失隐式发生。

### 不可变版本模型

```text
DRAFT
→ PUBLISHED
→ DEPRECATED
→ RETIRED
```

`PUBLISHED` version 不可原地修改。每个 canonical event 固定记录 `profileId`、`profileVersion` 和 `canonicalisationVersion`，并将其绑定到签名 digest。旧事件始终按原 version 解释和验证，不因新版本发布而重新判为无效，也不批量改写已确认历史。

新增 optional field 等兼容变化仍通过新的 version 发布；新增 required field、改变单位语义、删除字段或改变 validation meaning 视为 breaking version，只适用于其 effective policy 下的新事件。跨版本 query projection 可以归一化到稳定核心字段，但必须保留原始 profile/version provenance。

迟到/离线事件必须显式引用 profile version，但不能只靠 participant-asserted `eventTime` 回选已退役版本或恢复已失效权限。引用版本在可信 signing-time evidence 所在时间内有效时，按 governed late-submission policy 处理；没有该证据时，按接收时的当前策略校验，必要时进入 `REVIEW_REQUIRED`，不因回填时间自动放行。

### Validation split

```text
Profile/schema validation
→ fields, types, formats, enumerations, units,
  required evidence-reference shape

Core protocol/domain processing
→ identity, authority, signature, canonicalisation,
  idempotency, lifecycle, handover correlation,
  append-only correction structure and recall traversal
```

通用 UI 可以根据 profile 生成 string、number、date、enumeration 和 unit fields；需要特殊交互、复杂计算或新业务 lifecycle 的产品必须提供经过评审的代码扩展，不能承诺所有产品永远只靠 JSON 配置上线。

最小 profile artifact 包含 `profileId`、`version`、`status`、`effectiveFrom`、`baseEpcisVersion`、`validationSchema`、`valueLists`、`evidenceRequirements` 和 `consumerProjectionAllowlist`。Profile 的发布、弃用和 breaking-change approval 属于联盟治理操作。

**需要接受的代价：** 系统必须长期保留旧 profile、测试跨版本 projection、管理 vocabulary/unit 演进，并防止 schema validation 与领域代码产生冲突。动态字段的查询索引和复杂 UI 仍可能需要专门实现。

**为什么可以接受：** 多数“新增字段、枚举、单位和证据引用要求”的产品差异可以低成本扩展，而会改变交接、转换或召回数据结构的差异仍通过显式代码接受审查。业务合理性与合规判断保留给监管分析。这个边界提供实际可扩展性，同时避免把项目变成通用规则平台。

---

## B12. 性能与网络延迟采用什么 workload model？

**决定：** 性能设计围绕三种负载形态隔离，而不是假设所有接口都需要相同的高 TPS 架构：参与方写入总体低频但可能离线后突发同步；监管/内部查询低频但单次数据量大；消费者查询单次很小但并发和突发流量高。三者可以由同一个模块化应用产生数据，但不共享相同的在线查询路径和资源池。

```text
Participant write plane
→ reliable ingestion, idempotency, offline queue, outbox

Regulator/internal investigation plane
→ bounded interactive query + asynchronous bulk export

Public consumer plane
→ versioned public projection + object/cache/CDN delivery
```

### Public consumer plane

消费者请求不得直接遍历 canonical events、调用 Consortium KMS 或读取 archive/internal tables。只有 `CONFIRMED` events 进入 Public Projection Builder，生成按 trace/product ID 定位的 versioned public snapshots，并通过 object storage/cache/CDN、WAF 和 rate limiting 对互联网提供。

Correction event 生成新的 projection version，再更新 current-version pointer 和 cache；不在缓存中无痕覆盖历史版本。消费者并发主要由 CDN/edge cache 和可水平扩容的 stateless API 承担，不要求因此拆分整个后台为微服务。

### Regulator/internal investigation plane

小型调查查询使用 cursor pagination、bounded traversal 和结果大小限制。跨大量 batches/events 的请求创建 audited asynchronous export job，在明确的 confirmed-event watermark 上生成一致快照，以 stream 方式写入受保护的临时 export object，再提供短期授权下载。

大型导出使用独立 worker pool、并发配额、statement timeout 和资源限制，不能以长时间同步 HTTP query 占用 ingestion 或 public-query 资源。第一版可以读取同一 PostgreSQL；实际压力增加后，优先引入 read replica 或专用 export projection。

### Rural/offline participant plane

农村网络问题使用 offline-first submission 处理，而不是无限 HTTP retry。PWA 使用受保护的本地存储保存 draft、client-generated `captureRecordId`、可选 EPCIS eventID、待提交 payload、必要 profile/vocabulary、dependency 和 sync status；成熟参与方可以由 local gateway 提供 durable queue。

必须区分三种延迟：

```text
Edge sync lag
= participant creates event → platform RECEIVED

Platform processing lag
= RECEIVED → independent archive acknowledgement / receipt

Anchor lag
= archived event → Merkle batch public-chain finality
```

农村连接主要影响 edge sync lag。`LOCAL_DRAFT`、`QUEUED_OFFLINE` 和 `SYNCING` 不属于平台已接受的共享历史，也不能生成 acceptance receipt。平台恢复连接后使用稳定 `captureRecordId`、idempotency key 和 causal references 去重并处理依赖；participant `eventTime` 与 repository-generated `recordTime`、平台 `receivedAt` 分开记录，不能信任设备时钟决定全局顺序。

离线能力遵守 B5 的 custody boundary：enterprise self-custody gateway 可以离线签名后排队；需要 external/device approval 或 platform custody 的 PWA event 只能离线保存 draft，联网并重新认证后完成签名。离线缓存不应长期保存整个 consortium trace，尤其不能在共享设备上复制不必要的敏感数据。

### Storage and scaling path

第一版以一个 managed PostgreSQL 保存 operational state、event index、outbox 和 projections；完整 payload 同时受 independent archive 保护。扩展顺序是 query/index tuning、connection pooling、vertical scaling、consumer CDN/cache、read replicas，再根据实测的表大小、projection rebuild 时间和 lineage/export workload 决定 partitioning、broker 或专用 read store，而不是预先部署全部组件。

当前 workload assumptions 是：正常写入频率较低但必须承受离线设备恢复后的 burst；内部交互读取低并发但 export 可能覆盖大量事件；消费者读取具有高并发和活动/召回导致的突发峰值；设备可能离线数小时至数天；平台 processing lag 预计为秒级到几十秒，public-chain confirmation 为分钟级并由最后选择的 anchor window 决定。这些是可验证的设计假设，不声称是客户提供的事实。

Projection 必须发布 `data complete through` watermark 和 lag。Consumer UI 可以容忍短暂 eventual consistency；recall/food-safety 查询超过安全 lag threshold 时必须等待追平、回查 eligible source index，或明确返回 `STALE/INCOMPLETE`，不能把缺失结果解释为没有风险。Official Safety Notice 依 B18 fast path 单独标注 assurance，不与 confirmed trace watermark 混淆。

**需要接受的代价：** 系统需要维护离线同步协议、public projection publication、cache invalidation、export jobs、workload resource limits 和 projection-lag monitoring，即使第一版仍是模块化单体和单一 PostgreSQL。

**为什么可以接受：** 复杂度针对背景中真实不同的访问模式，而不是虚构统一的极端 TPS。Public plane 隔离保护内部系统，异步 export 防止大查询拖垮写入，offline queue 则直接处理农村连接这一明确需求，同时保留基于实测指标逐步扩容的路径。

---

## B13. 依赖故障时读写路径如何降级？

**决定：** `Write path is fail-closed and resumable; read path remains available for previously confirmed data, with explicit freshness and degradation indicators.` 新事件通过持久化单向状态机推进，在哪个必要依赖失败就停在哪一步；依赖恢复后使用相同 identifiers 幂等续跑，不跳过安全门槛，也不回滚已经完成的外部事实。

```text
Signing provider unavailable
→ PENDING_SIGNATURE

Consortium KMS or all qualified archives unavailable
→ PENDING_ARCHIVE
→ no acceptance receipt

Public chain or relayer unavailable
→ PENDING_ANCHOR / SUBMITTED_ON_CHAIN
→ receipt may exist, but not CONFIRMED
→ authorised official safety notice may be displayed as VERIFIED_PENDING_ANCHOR

Transaction included but finality not reached
→ INCLUDED

Projection worker unavailable
→ canonical event may remain CONFIRMED
→ affected projection becomes STALE and retries independently

Regulatory Analytics unavailable or behind
→ trace ingestion/query and manual investigation continue
→ risk assessment becomes DELAYED / UNAVAILABLE
→ absence of a current finding must not be shown as "no risk"
```

### 三类失败结果

1. **Transient dependency failure：** 保持当前 pending state，通过 durable outbox、backoff 和 reconciliation 重试。已写 archive、已分配 batch 或已广播 transaction 不执行补偿删除。
2. **Permanent validation/business failure：** 无效签名、无权限、非法 profile/schema 或明确拒签进入 `REJECTED`、`SIGNING_REJECTED` 或 `EXPIRED`，不无限重试。
3. **Read-model failure：** 不改变 canonical event 的确认状态，只使相应 projection 落后；修复后从 confirmed event index/archive rebuild。

所有 retry 使用稳定的 `captureRecordId`、archive object ID、operation ID、batch ID 和 transaction intent。Worker 必须先检查当前 state 与已有外部结果，再执行下一步，以防重复归档、重复 leaf allocation、重复 receipt 或重复链上提交。

### Read degradation boundary

已有 consumer snapshots 继续由 cache/CDN 提供，已有 confirmed trace 和未受影响的 operational projections 继续读取。每个异步 read model 暴露 `data complete through` watermark、lag 和 health；普通 UI 可以显示 stale indicator，recall/food-safety 查询超过安全阈值时必须等待、回查 eligible source index，或返回 `STALE/INCOMPLETE`。

“读继续”不代表所有依赖故障时所有数据都可读。KMS 不可用时，public projection 和已经合法物化的视图可以继续，但需要即时解密 archive payload 的查询会暂时不可用；PostgreSQL/平台整体失效时，CDN 可以继续提供已有 public snapshot，完整 consortium trace 则通过独立 recovery procedure 恢复，而不是承诺零中断切换。

Regulatory Analytics 独立发布 `analysisInputWatermark`、`lastSuccessfulEvaluationAt`、`activeRuleSetVersion` 和 `analysisHealth=CURRENT/DELAYED/UNAVAILABLE`。只有对应 rule set 已成功运行到指定 watermark，且 finding 尚未过期时，界面才能表达“截至该范围没有产生提示”。Analytics 滞后或不可用时，UI/API 必须表达 `Trace data available — risk assessment delayed/unavailable`；不得将规则未运行解释为没有风险。当前分析仍只使用达到 B21 input gate 的 confirmed projection，其 freshness/SLO 显式包含事件等待 anchor/finality 的时间；第一版不增加 provisional analytics path。

### Backpressure and receipts

平台可以在 archive 暂时故障时有界保存 `RECEIVED/PENDING_ARCHIVE` submissions，但在获得至少一个 qualified independent archive acknowledgement 前不得签发 acceptance receipt。Pending queue 达到容量或最大等待时间后，停止接收并返回 retryable failure，由 participant offline queue 保留原 event。

Public chain 故障时 payload 已在独立 archive 中，因此可以签发 receipt 并积累 `PENDING_ANCHOR` backlog；系统必须监控 oldest pending age 和 backlog size，但不能因超时自动提升为 `CONFIRMED`。B18 official safety notice 可以按 `VERIFIED_PENDING_ANCHOR` 展示，但该 publication status 不改变 canonical event finality。

**需要接受的代价：** 所有异步步骤都需要明确 state、idempotency、retry policy、dead-letter/reconciliation、backpressure 和可观测性；用户界面必须同时表达 submission progress 与 read freshness。

**为什么可以接受：** 该模型优先保护已确认历史的可用性，同时避免依赖故障时降低签名、归档或 finality 标准。故障恢复是从最后一个可靠 checkpoint 继续，而不是用跨 KMS、archive、database 和 public chain 的虚假分布式事务换取表面上的同步成功。

---

## B14. 原始 IoT 数据由参与方还是平台控制？

**决定：** 原始 IoT telemetry 默认属于 participant-controlled `PRIVATE ProtectedResource`。平台管理进入共享历史的 profile-required sensor summary、source-reported alarm/exception、provenance、raw-resource reference 和 content commitment；“一体化接入”不代表原始 telemetry 归平台所有或默认向联盟公开。

### IoT data classification

| Data | Classification | Default control |
|---|---|---|
| 高频 raw readings、完整轨迹 | `PRIVATE` | 设备所属参与方或其 IoT provider |
| Device credential、firmware、运维日志 | `PRIVATE` | 参与方或 IoT provider |
| Raw bundle reference、content hash、time range | `CONSORTIUM` | canonical EPCIS sensor evidence metadata |
| Min/max/mean、excursion duration、异常 flag | `CONSORTIUM` | profile-required sensor summary |
| Device identity、calibration status/reference | `CONSORTIUM` when required | network profile |
| 消费者可理解的合规声明 | `PUBLIC` | allowlisted confirmed projection |

独立 archive 保存 shared summary、provenance、reference 和 hash，但不强制复制全部高频 readings。参与方后续提供 raw bundle 时，系统以已确认的 content commitment 验证内容是否与当时承诺一致；无法提供时标记 `UNAVAILABLE`，由发布方承担举证后果。

### Hosting does not change ownership or classification

```text
PARTICIPANT_HOSTED
→ raw telemetry remains in participant/IoT-provider store
→ canonical event stores reference + commitment

PLATFORM_HOSTED
→ platform stores raw telemetry as an optional managed service
→ still participant-owned PRIVATE ProtectedResource
```

小型参与方可以使用平台提供的一体化 device binding、telemetry ingestion、private storage、summary generation 和 EPCIS submission；大型参与方可以继续使用自己的 IoT platform。平台托管只改变 storage/operator **，且按 B23 采用零知识托管——平台只有密文，没有解密能力**；它当然也不能把 raw telemetry 公开给其他成员、消费者或用于 ML training。

### Evidence responsibility

IoT provider/device signature 可以证明 bundle 的技术来源，但 canonical EPCIS publication 仍需要 organisation 或其注册 gateway/machine actor 承担声明责任。企业 gateway 可以按获批 policy 自动签名，无需人工批准每一条 reading。

IoT vendor/参与方负责完整 device fleet identity、certificate provisioning、firmware、connectivity 和 calibration operations。追溯平台只注册向本系统上传数据的 integration principal、organisation delegation、allowed scopes、public-key/credential reference 与 validity；不为每个低成本 sensor 建立平台账号。Device-level signature 是可选 provenance，不能替代 organisation 对 canonical publication 的责任。

缺少 sensor evidence 不得使已经发生的 shipping/receiving 从 trace 中消失。Product Profile 只定义 required sensor evidence、字段、单位、结构和引用格式；Traceability Core 客观记录 `PRESENT`、`MISSING`、`DELAYED` 或 `UNAVAILABLE` 以及 participant source-reported exceptions。“缺失证据构成风险/违规”属于 Regulatory Analytics 或监管人员的判断，Profile 和 Core 不产生 compliance warning，也不自动阻止合规结论。设备签名、校准、防拆和 content hash 提高 assurance，但不能证明传感器实际安装位置或测量的物理真实性。

**需要接受的代价：** 平台和审计方不能随时直接查询所有 raw telemetry；调查时可能需要 participant access grant，且参与方可能无法提供材料。Platform-hosted 模式还需要 tenant isolation、retention、deletion 和 access-audit controls。

**为什么可以接受：** 高频 telemetry 的容量、商业敏感性和设备多样性远高于共享 trace core。统一 ProtectedResource 模型保留了调查验证能力，也避免把追溯平台扩张为强制的通用 IoT device-management 和 time-series storage platform。

---

## B15. 监管方与 Regulatory Analytics/ML 是否拥有相同权限？

**决定：** 不拥有相同权限。Regulator organisation/authorised officer 是具有法定或联盟治理职责的正式主体；Regulatory Analytics service（包括 deterministic heuristics、statistics 和 optional ML）是目的受限的辅助工具和独立 service identity。Analytics service 不继承监管方人员的全部权限，也不能以“由监管方运营”为理由获得任意 archive、KMS 或 `PRIVATE` data access。

该子系统位于系统边界内，但属于监管方独立运行时域（B21）：边界内不代表平台可以获得它的规则、模型或 finding 数据，也不代表监管方可以借它取得平台侧的运行权限。两侧的接口只有 B21 的 analytics projection 导出与 signed `AdvisoryFinding` 返回。

### Permission matrix

| Capability | Regulator / authorised officer | Regulatory Analytics/ML service |
|---|---|---|
| Read `PUBLIC` data | Yes | Only when included in its dataset |
| Read confirmed `CONSORTIUM` trace | Yes, through regulator role | Only purpose-minimised analytics projection |
| Read complete canonical archive | Through authorised regulator query/recovery path when required | No direct archive/KMS access |
| Read participant `PRIVATE` evidence | Only if the owner already encrypted it to the regulator scope, or via a case-specific request to the owner（平台无法代为解密，见 B23） | No in routine screening |
| Request evidence or exercise legal authority | Yes | No; may only recommend investigation |
| Create internal risk alert | Yes | Yes, regulator-private by default; separately approved findings may be disclosed as advisory |
| Sign Inspection/Assessment event | Yes, using regulator organisation key | No |
| Change handover/event validity | No direct mutation; may publish a new signed regulatory statement | No |
| Approve consumer safety notice | Authorised regulator process | No |
| Reuse data for model training | Only under separate approved purpose and policy | Not implied by screening access |

即使 ML runtime 部署在监管机构自己的 cloud account 中，也使用与 regulator human/gateway 分开的 credential、role 和 audit trail。外部 ML provider 只是 regulator 的受约束 data processor，权限不得高于 ML service identity，也不得自行留存、训练或复用数据。

### Routine screening data path

```text
Confirmed CONSORTIUM trace
→ Regulatory Analytics Projection
→ purpose- and field-minimised export with watermark
→ Regulatory Analytics/ML Service
→ regulator-private RiskAlert
```

Regulatory Analytics Projection 可以包含 confirmed event relationships、handover claims、sensor summaries、missing/delayed evidence status、correction history 和必要 organisation/location identifiers。它不包含 raw IoT telemetry、合同、完整实验室文件、device credentials、signing material 或其他 participant-private resources。

Analytics service **不能任意追取** ProtectedResource；唯一例外是 B23 的窄通道：所有者提交时已把内容加密给监管 scope，Analytics 可用自有密钥解密并对照 commitment 校验。授权来自所有者，不是来自平台或 Analytics 的权限扩张。

按 B25，这条投影由 **AnalyticsInputModule** 生产：它把"最小化到哪些字段、按什么 watermark、如何按目的打包"写在自己的 manifest 里，Core 只提供经 `QueryPort` 过滤后的 edge group。这样新增一类筛查数据是改 manifest + 发新 profile，而不是改 Core。

Export 记录 dataset/schema version、confirmed-data watermark、purpose、recipient service identity、retention/expiry 和 audit ID。Model output 记录 `alertId`、`modelId/modelVersion`、`runId`、关联 event IDs、reason codes、risk score、data watermark 和生成时间。

### Investigation and formal decision path

```text
ML RiskAlert
→ regulator reviews
→ optional case-specific RegulatoryEvidenceRequest
→ authorised officer accesses selected PRIVATE resources
→ human/legal assessment
→ regulator-signed Inspection/Assessment event
→ normal archive and anchoring lifecycle
```

对 `PRIVATE` evidence 的访问必须绑定 case ID、resource IDs、purpose、authorised identity、legal/governance basis、effective/expiry time 和 access audit。该访问权属于监管调查主体，不自动下放给日常批量筛查模型。

Analytics alert 默认属于 regulator-owned `PRIVATE` data，不能直接进入 consumer projection、改变 event validity、触发法律结论或公开企业风险标签。监管方可以按 B21 为特定 rule/finding 指定受限 disclosure scope，使平台向相关组织转达 preliminary advisory；该转达仍不是正式监管结论。只有经授权人员复核并以 regulator organisation key 签署的 Inspection/Assessment event 才进入 canonical trace；是否形成 `PUBLIC` safety notice 还需要独立的监管发布流程。

**需要接受的代价：** 平台需要单独的 regulatory analytics projection、service identity、export audit 和 risk-alert store；监管人员调查 private evidence 时走另一条 case-specific authorization path，不能简单复用 ML 的批量数据接口。

**为什么可以接受：** ML 需要足够数据发现异常，但不需要监管机构的全部法定权力。身份和数据路径分离降低了大规模 private-data 暴露、外部模型供应商滥用、误报自动执法以及模型输出泄露企业声誉信息的风险，同时保留监管方依法调查和签署正式结论的能力。

---

## B16. Human、Machine 与 Organisation Identity 的管理边界是什么？

**决定：** 核心系统不建设完整 Human IAM 或 IoT device-fleet IAM。Human identities 由企业 IdP 或 managed customer identity provider 认证；IoT/device identities 由参与方或 IoT provider 管理。追溯核心只管理 `Organisation Registry`、`Organisation Key Registry`、进入本系统的 scoped delegations，以及不可覆盖的 governance-change history。

组织是唯一的身份、访问和租户单元；平台不管理组织内部的用户、岗位与审批流程，也不维护组织层级。每个请求必须显式携带 acting organisation。完整边界见 B24。

```text
External/participant Human IAM
→ authenticated subject claim
→ platform organisation/role authorisation

Participant/IoT-provider Device IAM
→ registered gateway/integration principal
→ scoped sensor-data submission

Core traceability identity
→ organisation membership + public keys + delegations
→ accountable canonical event publication
```

### Minimal core registries

```text
Organisation Registry
- organisationId
- legal/business identifiers
- organisationType
- membershipStatus

Organisation Key Registry
- keyId / publicKey
- keyPurpose: SIGNING | ENCRYPTION   ← ENCRYPTION 供 B23 的内容加密接收方使用
- custodyMode
- validFrom / validTo
- revocationStatus

Delegation Registry
- subjectOrIntegrationPrincipalId
- organisationId
- allowedScopes
- validFrom / validTo
- status

Governance Record History
- membership/key/profile change
- approvers/signatures
- effectiveAt/reason
- previousRecordHash
```

Human subject binding 支持 organisation-local roles，例如 OrgAdmin、EventPublisher、EvidenceManager 和 Viewer，但 employee onboarding/offboarding、HR structure、password 和 MFA lifecycle 由 identity provider 管理。Machine delegation 只允许已注册 gateway/provider 代表指定 organisation 发布限定 event types、locations 或 devices，不能因为能上传 sensor data 就获得 shipping、transformation 或 regulator 权限。

### Membership governance is limited trust

现实组织身份不能由 public chain 自动判断，因此保留一个 `Membership Governance Function`，而不是假设一个全能、完全可信的 Membership Authority。平台执行 application、材料收集、technical checks 和 tenant provisioning；联盟秘书处、行业机构或被授权 membership officer 核实现实组织身份并签署 activation/suspension/exit record。

```text
Membership governance
→ establishes who may participate and under which role

Organisation signature
→ attributes each business statement

Public-chain commitment
→ prevents silent replacement of confirmed records
```

普通 participant onboarding 可以由一个独立 authorised membership officer 批准；regulator role、lost-key recovery、KMS recovery、profile publication、archive-operator change 和 chain migration 等高影响操作使用独立 dual control。这里的审批是低频治理流程，不是新的 BFT network，也不要求所有联盟成员逐项投票。

Membership/key/profile changes 使用签名的 `GovernanceRecord`，进入 independent archive 和 Merkle anchoring；PostgreSQL current registry 是可重建 projection。平台不能仅修改数据库就无痕激活虚假组织、授予 regulator role 或替换历史 public key。

### Governance effective gate

普通 organisation activation、key rotation/recovery、regulator-role grant、Product Profile publication 和其他扩权变更只有在 GovernanceRecord 完成签名、获得 independent ArchiveAck 并达到 public-chain finality 后才进入 current registry 的 `EFFECTIVE` projection。依赖该新身份、key 或 profile 的 business event 在此之前不得取得 receipt/CONFIRMED。

```text
PROPOSED
→ APPROVED_AND_SIGNED
→ ARCHIVED
→ ANCHORED_AND_FINALISED
→ EFFECTIVE
```

Emergency suspension/revocation 是唯一方向相反的例外：为 fail closed，可以在 authorised dual-control command 验证后立即阻止新的 submission/decrypt grant，并以 `EMERGENCY_PENDING_ANCHOR` 标记；随后必须归档、锚定和审计。若后续治理记录失败或被撤回，使用新的 signed governance record 恢复，不静默删除 emergency history。

事件签名分别验证 cryptographic authenticity、acceptance-time authority 和 signing-time evidence，不按 participant-asserted `eventTime`、`assertedSignedAt` 或 `captureRecordId` 直接判断撤销前有效。接收时已过期/撤销的 key 只有在可验证时间证据将同一 digest 的签署定位到有效区间内时，才能进入 governed late/offline-submission path；否则进入 `REVIEW_REQUIRED`，不自动确认。Key compromise 可以声明 `suspectedCompromiseFrom` 并触发调查，但不能在没有正式 assessment 的情况下自动使已确认的历史签名失效。详细时间证据契约见 B5。

### Membership and key lifecycle

```text
APPLICANT → ACTIVE → SUSPENDED → ACTIVE / EXITED / REVOKED
```

`SUSPENDED/EXITED/REVOKED` organisation 不能发布新 canonical events 或获得新的 consortium access/key epoch，但过去的 membership、public keys 和 signed events 保留供验证。正常 key rotation 由当前 organisation key 授权；旧 key 丢失时走独立 dual-control recovery。Key compromise 触发 suspension、new-key issuance 和受影响事件调查，不物理删除旧签名，也不自动断言泄露前全部事件无效。

退出成员不再获得新 KEK epoch 或在线 consortium access，但密码学上无法撤回其已经下载的 plaintext。是否在争议或法律要求下恢复特定旧资料，走审计的 regulator/governance access path。

**为什么仍需要 public blockchain：** Membership governance 只被有限信任去判断现实参与资格，不被授权代表成员签事件、删除 archive 或重写历史。即使它错误批准恶意成员，该成员也只能用自己的可追责身份发布声明；它不能伪造其他 self-custody organisation 的签名或修改过去的 finalised commitments。如果平台和 membership governance 被假设为可以完全控制且完全可信，区块链才确实没有必要，但这不是 B1 的威胁模型。

**需要接受的代价：** 平台需要 federation/managed-IAM adapters、organisation/key/delegation registries 和治理审批记录；onboarding、lost-key recovery 和高权限变更不会即时完成。

**为什么可以接受：** 核心只保留跨组织追责所必需的身份事实，不复制企业 IAM 或 IoT device-management 能力。有限治理解决现实身份入口，签名解决声明归属，public commitment 解决确认后的不可篡改，三者职责不重叠。

---

## B17. 核心平台是否判断 Transformation、Aggregation 或数量关系异常？

**决定：** Traceability Core 不判定现实真伪，只记录断言。核心平台只验证 event 的 schema/profile shape、signature、organisation authority、canonicalisation、idempotency 和 envelope/lifecycle validity。只要一项声明在技术和权限上有效，就保留发布方签署的原始 claim；平台不生成官方 anomaly、fraud、mass-balance 或 compliance status，也不因跨事件关系看起来不合理而拒绝归档和锚定。

**这是领域知识与规则权威的架构前提，不是为了减少实现工作。** 平台运营者不知道不同产品、地区和监管制度下什么数量、时序、温度、加工损耗或关系组合才算合理，也无权自行发明这些规则。把普通领域启发式校验和高级 statistical/ML analysis 一起放入 Regulatory Analytics，可让监管方配置、版本化和审计规则，并对规则结论负责。这里 optional 的只是 ML 技术；deterministic regulatory heuristics、rule evaluation、freshness 和 controlled disclosure 使 Regulatory Analytics 成为与 Traceability Core 对等的核心业务子系统，而不只是供监管人员“查东西”的外围报表工具。

### 记录断言与签署判定是两个不同职责

即使同一序列化对象被两项 transformation 分别声称消耗，核心也无法判断哪一项为真：这不是实现不足，而是可观测性边界。EPCIS 本身就允许不同组织分别作出互相不兼容的声明，并不规定谁正确（见 `epcis-model-notes.md` §11），因此核心若选其一或判其错，等于在无授权的情况下代替现实作出裁决。

由此得到本系统的判定规则：

> 平台记录断言；判定只能由有权主体以签署声明的方式进入历史。

判定进入历史的通道目前只有三条：A6 的 EPCIS `ErrorDeclaration`、B18 的 signed Recall/Safety Notice、B15/B21 的 regulator-signed Inspection/Assessment。三者都要求一个具名的、持钥的权威主体。由平台自行推断并写入历史的“错误”或“违规”结论一律不允许，因为平台既没有观察现实的能力，也没有裁决权。

### Admission validation（阻断性校验）

核心可以拒绝：无法解析的 EPCIS/profile payload、缺失 schema-required fields、非法数据类型或 vocabulary、无法 canonicalise 的内容、无效 signature、无权 publisher、同一 `captureRecordId` 对应不同 digest、违反 A6 Error Declaration 特例的重复 EPCIS eventID、损坏的 signature/archive envelope，以及非法 lifecycle transition。

核心不判断：input 是否被重复消耗、output/yield 是否合理、损耗是否异常、时间地点是否可疑、同一对象是否被多个 transformation 声称、aggregation 是否冲突、关系是否形成业务上可疑的 cycle，或某组织 correction 是否过于频繁。EPCIS schema 明确禁止的结构仍不接收，但平台不添加超出 schema 的业务合理性门槛。

### 两类“校验”必须分开

```text
Admission validation（阻断）
→ schema/profile shape、signature、authority、canonicalisation、
  idempotency、envelope/lifecycle validity

In-domain structural representability（不阻断）
→ 某对象被多个 transformation 声称消耗、存在竞争 parent、
  引用了网络内未知标识、lineage 关系在时间上成环
→ 只决定投影如何呈现，不决定事件是否有效
```

第二类不是业务合理性判断，而是关于**已提交断言集合**的、无需领域知识的事实：它可以计算、可以复现、不含价值判断。它不得成为拒收条件、不得生成 verdict 状态、不得阻塞归档与锚定，但必须被如实呈现（见下节）。把这两类混在一起，会要么让核心越权裁决，要么让平台对自相矛盾的历史保持沉默。

### Preserve conflicting claims

互相冲突或不完整的 signed events 仍分别进入 canonical history，并保留 publisher、event time、record/received time、profile version 和 signature。平台不选择“哪一条是真的”，也不使用 first-writer-wins 让先提交者阻止其他组织留下相反声明。

Lineage/query projection 必须容忍 unknown references、多条竞争关系和 graph cycles，使用 visited set、depth/result limit 和 provenance-per-edge 防止无限遍历。它必须如实显示“没有更早的网络内事件”或多条声明，但不创建 `UNRESOLVED_INPUT`、`MASS_BALANCE_WARNING` 等官方业务判断状态。

### 默认视图不得折叠竞争断言

“不创建判断状态”和“必须暴露断言冲突”并不矛盾：前者是 platform verdict，禁止；后者是关于已提交断言集合的 provenance fact，必须可见。

在 B3 的 scope 模型下，这条性质是**相对 scope** 的：竞争断言必须在调用者可读范围内并存显示，不得因为部分内容超出 scope 就把它呈现为单一路径。超出 scope 的内容应显示为"存在该记录但不在你的可见范围内"，而不是被静默丢弃或合并。

对同一对象的全部已确认断言，lineage、recall impact、handover 和 audit 的**默认视图不得折叠为一条路径**，也不得为竞争边排序、打分或选择“代表路径”（平台不产生置信度）。每条边至少保留 B18 定义的 provenance 字段。

Recall/food-safety 查询尤其不能折叠：任何“受影响 / 未受影响”的结论都必须能追溯到它所依赖的断言集合和 watermark；当依赖集合包含竞争边时，结果必须显示该竞争关系，而不是取其一。Consumer projection 受 `PUBLIC` allowlist 约束，但同样不得在存在竞争断言时呈现为单一路径；具体披露措辞可与消费者视图的合规审查一并确定。

这条要求也是“transparency”这一业务目标在查询层的落点：如果只有监管方能看到历史自相矛盾，参与者与消费者就没有获得透明性。

Shipping/Receiving 的 `ACCEPTED/PARTIALLY_ACCEPTED/DISPUTED` 是对两份明确声明的机械关联结果，而不是异常检测；同理，correction relationship 和 recall traversal 是结构处理，不代表平台认定声明真实。这也是 non-collapsing 的一个特例：handover status 可以机械派生，但派生依据必须能回到原始的两份声明。

### No authoritative material-balance model

平台不维护 authoritative inventory、remaining quantity、expected yield、consumed balance、fraud score 或 MaterialBalanceProjection。TransformationEvent 只记录 publisher 声称的 inputs、outputs、quantities、transformation ID 和 process context；AggregationEvent 只记录 publisher 声称的 parent/child relationship。ERP/MES 继续负责库存、配方、生产核算和内部控制。

Product Profile 只定义字段结构、required references、vocabulary、units、consumer allowlist 和 UI metadata，不配置 yield tolerance、mass-balance、fraud heuristics 或 automatic compliance conclusion。

### Analysis belongs outside the Traceability Core, but inside the system boundary

```text
Confirmed source assertions
→ Regulatory Analytics Projection
→ regulator-owned deterministic rules / statistics / optional ML
→ regulator-private alert
→ human investigation
→ optional regulator-signed Assessment/Inspection event
```

监管方可以自行配置 duplicate-consumption、mass-balance、timing/location、correction-frequency、sensor-excursion 和 supplier-risk rules。它们遵守 B15 的最小化数据权限，输出默认 regulator-private；监管方可以把一部分基础 rule/version 的输出授权为 `SUBJECT_ORGANISATION` 或 `CONSORTIUM_ADVISORY`，由平台据此提供基础提醒。第一版的“授权给平台”是返回带 rule version、watermark、expiry、scope 和 regulator signature 的 `AdvisoryFinding`，不是把可执行监管代码复制进 Traceability Core，也不授予平台自行修改规则的权力。只有监管人员复核并签署的正式结论才进入 canonical trace。

**需要接受的代价：** 没有启用监管分析时，核心系统会保存甚至展示明显矛盾的 source assertions。`CONFIRMED` 只能解释为“已签名、归档并锚定”，不能被 UI 或报告表达为“平台已验证业务真实、数量合理或合规”。Recall traversal 也必须保守处理所有相关 claims，而不能依赖一个平台判定的唯一正确路径。

**为什么可以接受：** 区块链和 EPCIS 在本系统中提供 attribution、trace reconstruction 和 post-confirmation integrity，而不是通用欺诈检测。把产品、地区和监管机构特有的启发式规则留在 Regulatory Analytics 子系统（B21：系统边界内、监管方运行时域），可以避免 Traceability Core 变成由平台擅自维护的规则权威，也避免错误规则阻止冲突证据进入历史；受控披露又让平台仍能使用监管方批准的基础结果提供及时提醒。

---

## B18. Recall 在本系统中是查询还是实际下架流程？

**决定：** Recall 的核心范围是对共享 `CONSORTIUM` lineage projection 进行保守、可复现的影响范围查询，以及展示 authorised organisation/regulator 提交的 signed recall status；不是由平台执行 POS 禁售、仓库封存、门店下架、退货、运输、销毁或退款。

```text
Regulator/responsible organisation decides recall externally
→ submits signed recall notice or recalled EPCIS statement
→ RecallModule（B25）按声明的边类型与时间范围做保守遍历
→ consortium/public recall projection
→ participant ERP/WMS/POS and staff execute physical actions
→ optional subsequent EPCIS action claims
```

按 B25，**遍历策略归 RecallModule，不归 Core**：Core 只提供带 scope、non-collapsing 和 watermark 的边查询；哪些边类型要跟、时间范围怎么截取、哪些 handover 状态必须保守纳入，写在模块 manifest 里，由监管方与联盟治理共同评审。这样新增一类证据（例如新的关联事件类型）不需要改 Core。

参与方可以随后提交 recalled、quarantined、returned、destroying/decommissioning 等事件，记录其声称采取的行动；平台不远程控制外部库存系统，也不把通知送达解释为物理下架完成。

### No new access model

Recall impact query 只遍历所有 active consortium members 原本可读的 canonical trace fields，因此不引入单独权限层。Raw IoT、完整 laboratory reports、contracts 和 investigation notes 仍是 `PRIVATE`，且按 B23 默认不在平台上：调查需要时，或由所有者把内容加密给监管 scope，或由平台向所有者转达索取请求——平台无法代为解密。

查询本身可以由普通联盟成员运行；但发布正式 recall status、改变 consumer projection 或签署监管结论仍要求 responsible-organisation 或 regulator authority。按 B3，成员自行运行的遍历只覆盖其 scope，结果必须标注 `scope-limited`，不能作为权威影响范围；权威的保守遍历由全 scope 方执行，两者使用同一 watermark 和同一遍历规则。Regulatory Analytics/ML alert 不能自动成为 recall。

### Conservative lineage traversal

```text
Transformation: input → all claimed outputs
Aggregation: child ↔ time-applicable parent/container
Shipping/Receiving: object → all claimed destinations/custodians
Association: not automatically treated as product-impact propagation
```

平台不判断哪条冲突路径真实，也不决定某种加工是否消除污染。查询返回所有可能相关的 source assertions 和 edge provenance，结果语义是 `possibly affected based on available claims`，不是平台认证的污染结论。结果按 B17 的 non-collapsing 规则呈现：竞争边并存显示，不选代表路径，也不为边打分。产品/风险特有的停止规则、cross-contamination 和 process-effectiveness 判断属于监管分析或人工调查。

Aggregation/custody relations 具有时间范围；重复使用的 pallet、container 或 location 不能形成永久影响关系。Lineage edge projection 至少保留 `fromObjectId`、`toObjectId`、`edgeType`、`sourceEventId`、publisher、event time、effective interval、confirmation status 和 handover status。

### Reproducibility and pending data

标准 recall result 固定一个 confirmed-data watermark，确保同一查询可以复现：

```text
confirmedImpact
→ derived only from CONFIRMED source assertions at watermark W

recentPendingClaims
→ RECEIPTED / PENDING_ANCHOR claims shown separately
→ never silently mixed into confirmed result
```

新事件、迟到事件或 correction 到达后可以在新 watermark 上重新运行并生成新 export/version，不能无提示覆盖先前范围。Disputed、partially accepted 和 unacknowledged handover relationships 仍属于 confirmed claims 时，应被保守遍历并带状态返回。

### Safety publication fast path

Authorised regulator/responsible organisation 的 official Recall/Safety Notice 与普通 trace event 的 finality gate 分开处理。Notice 在 organisation/regulator signature 验证通过并取得 independent ArchiveAck 后即可用 `VERIFIED_PENDING_ANCHOR` 状态进入 consumer/regulator view，不等待 15–60 分钟 anchor window 或 public-chain recovery；UI 必须显示 issuer、issuedAt、archive verification 和 pending-anchor status。

```text
SIGNED_OFFICIAL_NOTICE
→ ARCHIVED / VERIFIED_PENDING_ANCHOR
→ immediate safety publication
→ ANCHORED_AND_FINALISED
→ VERIFIED_CONFIRMED
```

该例外只解决紧急信息传播，不把 notice 当成链上已 finalise。普通 business event、heuristic/ML finding 和 preliminary advisory 仍按原生命周期处理。NSW Food Authority/FSANZ 的官方公告渠道继续是独立外部来源；平台展示不能成为现实 recall 执行的唯一渠道。

### Query implementation boundary

第一版使用 PostgreSQL 中可重建的 lineage-edge projection 和 cycle-safe recursive traversal。查询必须使用 visited set、depth/result limits、cursor pagination、timeout 和 provenance-per-edge；超过同步结果阈值时复用 B12 的 asynchronous export path。Graph database 只在实测 traversal/rebuild 指标证明需要后引入。

正式 recall notice 可以作为 authorised party 提交的 signed record 和 consumer-projection input 处理，不需要独立 case-management/workflow engine。通知可通过 portal、webhook 或外部 email/SMS provider 辅助，但监管机构现有公告渠道和参与方 operational systems 仍负责现实执行。

**需要接受的代价：** 保守遍历可能返回过多候选对象，并且不能保证实际污染或下架完成；网络外来源、缺失事件和冲突声明会限制结果完整性。大型 traversal 可能只能异步导出。

**为什么可以接受：** 该边界直接支持追溯和食品安全调查，同时保持系统不是 ERP/WMS/POS 或监管 case-management platform。访问控制复用既有 `CONSORTIUM/PRIVATE` 模型，复杂度集中在时间关系、冲突声明、可复现 watermark 和大图查询，而不是建立另一套业务权限和工作流。

---

## B19. 产品、物流标识和消费者 QR 由谁分配，平台是否负责防伪？

**决定：** 参与方继续分配和管理其标准 product/logistics identifiers；平台为没有外部 scheme 的小型参与方提供可选 network-scoped identifiers。平台只验证 syntax、namespace authority、stable resolution、event attribution 和 idempotency，不验证 external code 的现实所有权、标签物理粘贴或产品真实性。QR 是 public-projection resolver，不是 anti-counterfeit proof。

优先复用 GTIN、GTIN+lot、SGTIN、SSCC、GLN、GRAI/GIAI 和 GS1 Digital Link 等现有标识。大型参与方继续使用其 ERP/WMS/serialisation 系统；平台不建立替代 GS1 的全局编码机构。没有标准标识的参与方使用由 `networkId + issuerOrganisationId + objectType + localId` 组成或等价表达的 network-scoped URI，确保联盟内部命名空间不冲突。

平台可以检查 identifier scheme、格式/check digit、组织 namespace、profile 允许的 scheme、canonical representation 和同一 `captureRecordId` 的 digest consistency；EPCIS eventID 遵守 A6 的 Error Declaration 特例。Organisation signature 表示发布方为“该 identifier 对应此对象/事件”的声明负责。平台不额外证明组织在现实中拥有某个 GTIN，也不证明 label、package 和 physical product 正确对应。

网络中从未出现过的 input/reference 不因未知而被拒绝或赋予官方 anomaly status。平台保留 publisher 对该 identifier 的签名引用；监管方或参与方以后可请求 invoice、supplier record 或其他 private evidence。Trace 的起点和缺失上游可以从 graph 中直接观察，不由核心系统推断欺诈。

Consumer QR 只编码稳定 resolver/Digital Link，解析到 versioned `PUBLIC` projection；不得包含 Consortium payload、private-resource locator、DEK 或访问 credential。平台可以为小参与方提供 QR 生成/打印便利，大企业继续使用自己的 labeling/RFID infrastructure；该便利不构成平台真实性背书。

二维码可以被复制或换贴，因此扫描只能说明该 identifier 存在一份由相关组织发布并确认后未被替换的记录，不能证明眼前物品就是记录对应的真实对象。一次性 code、secure NFC、防拆标签和 scan-pattern detection 是可选防伪扩展，不属于当前核心保证。

Consumer scan logs 是 platform-private operational/analytics data，不进入 canonical trace；必须限制 retention、位置收集和再利用。Duplicate/impossible scan patterns 可以由 Regulatory Analytics 生成 private alert，但核心不自动标记 counterfeit 或改变 trace。

**需要接受的代价：** 平台无法阻止复制二维码、冒用外部编号或标签贴错实物；缺少 GS1 标识的 network-scoped ID 在联盟外互操作性较弱。

**为什么可以接受：** 当前系统的保证是 attribution、stable trace reference 和 post-confirmation integrity，而不是物理防伪。复用外部标准保持企业互操作性，为小参与方提供 scoped fallback 保持可访问性，同时把现实 ownership/authenticity 审查留给责任组织和监管方。

---

## B20. NSW trial 的 privacy、retention 和 data residency 基线是什么？

**决定：** NSW 作为首个 trial jurisdiction。Primary application/PostgreSQL、participant/private evidence、independent archive 和 Consortium KMS 默认部署在 Australian regions；至少一个恢复副本位于不同 Australian failure domain。Public chain 只保存不直接识别个人的 commitment/Merkle root，`PUBLIC` consumer projection 可以通过全球 CDN 分发。

选择 Australian residency 是降低 APP 8/cross-border、regulator procurement 和 incident-coordination 风险的架构政策，不声称澳大利亚法律绝对禁止所有海外处理。海外复制、support access 或 analytics 默认关闭；未来启用时必须单独完成 privacy、contractual 和 jurisdiction assessment。

### Applicable responsibility baseline

平台和参与企业在适用时按 Australian Privacy Principles 处理个人信息；为避免按企业规模反复分叉，系统把 APP-style minimisation、purpose limitation、security、access/correction 和 deletion/de-identification 作为所有 tenants 的统一最低标准。NSW public-sector regulator 对其取得的数据还按 PPIP/IPPs、NSW Mandatory Notification of Data Breach 和 NSW government cloud/procurement policy 管理。

该划分不替代法律意见。Platform operator、participant、consortium governance 和 regulator 对 shared/private data 的法律 controller/processor 角色需要在 production agreement 中确认；architecture 只明确技术控制与审计责任。

### Keep natural-person data out of immutable history

Canonical `CONSORTIUM` trace 默认只保存 organisation/business location、product/lot/logistic-unit IDs、pseudonymous actor reference、event relationships、sensor summary、evidence reference 和 commitment。Employee name、personal email/phone、home address、authentication credential、consumer identity、scan IP/geolocation 和 regulator investigation notes 不得进入 immutable trace schema。

Small-farm business identifiers/location 仍可能间接识别个人，因此详细 contact data 保存在受控、可更正的 operational organisation registry。Pseudonymous `actorId` 也按可能重新识别个人的数据保护；consortium/public views 不需要展开真实员工身份。

### Retention is data-class and policy based

```text
Confirmed canonical trace
→ product/jurisdiction retention policy
→ capacity planning assumption: at least seven years

Profile/key/governance/canonicalisation history
→ retained at least as long as dependent trace

Platform-hosted PRIVATE evidence / raw IoT
→ owner + product/regulatory policy

Regulatory export / analytics dataset
→ short-lived, purpose-bound, automatic expiry
→ extend only for recorded investigation/legal hold

Consumer scan/security logs
→ minimum collection and short retention
→ aggregate/de-identify or delete
```

“至少七年”是 storage capacity 和 trial policy assumption，不是对所有 NSW food records 的法定最低期限声明。实际 retention policy 由 data class、product profile、jurisdiction 和 legal hold 共同决定，发布前需由联盟/法律与监管代表批准。

### Deletion and immutability

在 active retention period 内，confirmed organisation-level business trace 不接受物理删除，错误通过 correction event 处理。Retention 到期不是静默改写历史，而是进入显式终态：

```text
ACTIVE_RETENTION
├── LEGAL_HOLD → 保留 ciphertext、wrapped DEK 和验证依赖
└── RETENTION_EXPIRED
    → 删除 archive ciphertext 和对应 DEK envelope/object
    → 删除可重建 operational payload/projection
    → 保留 non-personal public-chain commitment
    → 保留 signed minimal deletion audit
```

七年是 NSW pilot canonical trace 的默认 retention/capacity assumption；product/jurisdiction policy 可以设置更长期限，legal hold 暂停到期删除。平台外完整 payload recovery guarantee 只在 active retention/legal hold 内成立；到期后只能证明曾存在某 commitment 以及按何种 policy 完成删除，不能再恢复 payload。

Profile、canonicalisation、organisation/public-key、revocation 和 governance history 至少保留到最后一个依赖它们的 canonical payload 到期。删除操作由 authorised retention worker 请求，Archive operator 执行并签署 deletion acknowledgement；该 minimal deletion record 进入后续 Merkle anchoring。平台不能单方面提前删除 WORM object。

Mutable user/account/contact data 支持 access、correction、deletion 或 de-identification；private evidence 到期后可以删除，并把引用状态更新为 `EXPIRED/DELETED/UNAVAILABLE`，但不回写或伪造仍在 retention 内的原 canonical event。按 B23，平台能删的只是自己名下的密文对象；所有者自己的副本不在范围内，删除也无法证明内容在其他位置已消失。Legal hold 必须记录 authority、case、scope、effective/expiry time 和 audit trail。

Public-chain commitment 永久存在，因此 commitment input 不得包含 plaintext personal identifier，也不能把短小个人字段直接当作可被字典匹配的公开 hash。减少不可变 PII 的主要手段是 schema allowlist 和 ingestion-time data minimisation，而不是承诺以后从 WORM/public chain 中擦除。

### Consumer and analytics privacy

Consumer lookup 默认不要求登录，不收集精确 geolocation，不建立个人 scan history；IP/user-agent 只用于短期 security/rate-limiting，并在期限后删除或聚合。Duplicate-scan analytics 使用最小化或去标识数据，不能转为消费者画像。

Regulatory exports 和 analytics inputs 必须记录 purpose、recipient service identity、schema/dataset version、confirmed watermark、expiry 和 legal-hold status。ML/rule outputs 默认 regulator-private；只有监管方明确签署 disclosure policy 的 findings 才能作为 B21 preliminary advisory 提供给指定 audience。数据访问权不隐含训练、长期留存或其他目的再利用权。

### Breach responsibility

Platform、participant 和 regulator 分别保留适用于自身控制数据的数据泄露 detection、containment、assessment、audit 和 notification 流程。跨主体合同必须定义通知时限和协作责任；区块链 commitment 只能帮助检测历史篡改，不能满足 privacy breach response。

**需要接受的代价：** Australian-only non-public deployment 限制供应商/region 选择并增加跨控制域灾备成本；严格排除 PII 需要 schema review、log minimisation 和 evidence-retention automation；七年容量规划高于部分数据的实际法律保留期。

**为什么可以接受：** NSW trial 获得清楚、可审计且较低跨境风险的初始边界。将长期 immutable trace 限制为组织级供应链事实，使 correction/anchoring 与个人数据删除原则能够共存；按数据类别配置 retention 又避免虚构一个适用于所有产品和记录的统一法定期限。

### Official basis used for the trial assumption

- OAIC Australian Privacy Principles: <https://www.oaic.gov.au/privacy/australian-privacy-principles/read-the-australian-privacy-principles>
- NSW IPC Information Protection Principles: <https://www.ipc.nsw.gov.au/resources/fact-sheet-information-protection-principles-ipps>
- NSW Mandatory Notification of Data Breach guidance: <https://www.ipc.nsw.gov.au/resources/guideline-guidelines-assessment-data-breaches-under-part-6a-ppip-act>
- NSW Government Cloud Policy: <https://digital.nsw.gov.au/policy/cloud-policy>
- NSW Food Authority recall guidance: <https://www.foodauthority.nsw.gov.au/help/recalls>
- FSANZ food traceability guidance: <https://www.foodstandards.gov.au/business/food-safety/food-traceability>

---

## B21. Regulatory Analytics 是否只供监管方使用，还是也向平台提供辅助能力？

**决定：** Regulatory Analytics 与 Traceability Core 是本系统的两个 peer core subsystems，**都在系统边界之内**。Regulatory Analytics 拥有独立运行时域、独立 service identity，以及由监管方持有的规则和模型所有权，但它不是本架构之外的黑盒：它必须为平台自身提供基础审查能力（baseline review service）。普通领域启发式规则、统计分析和 optional ML 都在这一子系统内运行；结果默认 regulator-private，但监管方可以通过明确的 disclosure policy，把选定基础 rule/version 的输出作为 signed preliminary advisory 提供给平台用于基础提醒。平台只负责验证、路由和展示获准结果，不继承监管系统的完整数据、模型或法定权限。

```text
Confirmed CONSORTIUM Projection
→ Regulatory Analytics Module
   ├─ regulator-only rules/models → private findings
   └─ approved advisory rules → signed AdvisoryFinding
                                     ↓
Platform Advisory Ingestion → permitted participant reminders
```

### 一个架构，两个控制域

```text
System boundary（本架构）
├── Traceability Core（平台运行时域）
│   ├── ingestion / validation / signature / archive / anchor
│   ├── lineage / handover / recall / consumer projection
│   └── regulator portal 与 investigation access
└── Regulatory Analytics（监管方运行时域）
    ├── rule / model registry（监管方签署并持有）
    ├── screening / evaluation
    └── finding store / advisory publisher

Trust boundary = Traceability Core ↔ Regulatory Analytics
```

**为什么在边界内，而不是画成外部系统：**

1. 平台需要的基础审查能力（缺证据、跨断言冲突、handover 异常、recall 辅助范围）由这一子系统提供。若把它画在系统边界之外，本架构就只保证证据完整性而不提供任何审查能力，“compliance with food safety regulations” 只能靠“我们不判”来回答。
2. 只有作为边界内子系统，ML 的模型版本、训练数据快照与 watermark、评估与漂移、human-in-the-loop、finding 的披露控制才有可描述的架构位置；画在边界外，这些内容不属于本架构。
3. Traceability Core ↔ Regulatory Analytics 是本威胁模型中最需要专门标注的信任边界（B15 的权限分离、B18 的 case-specific evidence request gate）；其余边界（参与方/API 入口、独立 archive、公链 relayer、KMS）属于常规外部接口，按 4.18 的正常方式标注即可，不承担区分治理域的作用。

**术语澄清：** “peer core subsystem” 指**整体系统**中与 Traceability Core 对等的两个子系统，不代表 Regulatory Analytics 是平台运营者拥有的另一个 container，也不代表平台对它的规则有所有权。它的运行时、数据边界和治理权属于监管方；平台只实现并运维其 runtime、registry 接口、export 入口和 advisory 接收端。B15 的权限分离、B8 的 KMS 边界不变。

### Analytics 子系统的 C4 分解责任

因为它位于系统边界内，3.2–3.10 必须覆盖它。规模控制在下表量级，超出会伤及“避免 feature concentration / dense structure”：

| C4 层 | 最少需要出现 | 对应视图 |
|---|---|---|
| Container | Analytics Input/Export Gate（watermark 校验、数据集打包）、Rule & Model Registry、Screening Scheduler + Runner pool、Finding & Advisory Store、Disclosure & Advisory Publisher；ML 侧 Training Snapshot、Model Evaluation/Registry、Human Review Queue | 3.2–3.4 |
| Component | 每 container 2–3 个：Watermark Verifier、Dataset Packager、Rule Version Loader、Rule Validator、Finding Evaluator、Dedup/Expiry、Audience Resolver、Advisory Signer | 3.5–3.7 |
| Code | `Rule`、`RuleVersion`、`ScreeningRun`、`DatasetSnapshot`、`Finding`、`AdvisoryFinding`、`DisclosurePolicy`、`ModelVersion`、`ReviewDecision` | 3.8–3.10 |

**规则所有权必须在图上可见。** `RuleVersion` 由监管方密钥签署后进入 Registry，平台只提供 runtime 与 registry，不 author、不改规则、不扩大适用范围。这与“平台跑账本、但由组织签交易”是同一个模式，用来回答“平台团队实现了规则引擎，是否等于平台在定义规则”。

**关闭 Analytics 只影响审查能力，不影响追溯。** 内部化之后这是**系统内**的降级路径，而不是外部依赖故障：ingestion、trace query、consumer view 和监管人员手工调查继续运行，risk assessment 标记为 `DELAYED/UNAVAILABLE`，过期 finding 停止当前态展示（B13、B17）。这同时是可用性战术的正面例证：异步解耦 + 可选依赖 + advisory 不参与写入路径。

### 合规能力的三层分工

把 Analytics 放在边界内之后，brief 的 “Compliance with food safety regulations” 由三层能力共同回答，而不是“平台不判”：

| 层 | 机制 | 权威来源 | 是否阻断写入 |
|---|---|---|---|
| 准入层 | regulation profile 的 mandatory evidence requirements（B11）、EPCIS 结构与 vocabulary | 联盟治理发布的 profile | 是 |
| 筛查层 | deterministic rules / statistics / optional ML → `AdvisoryFinding` | 监管方持有并签署的 `RuleVersion` | 否 |
| 结论层 | Inspection/Assessment、Recall/Safety Notice | 监管方或责任组织的组织密钥 | 否（追加记录） |

三层共同的前提是 Traceability Core 提供可核验、不可静默改写的证据链（A5、A6、B6）；判定权始终留在第二层（规则 owner）和第三层（签署者），平台不自行添加业务门槛（B17）。

### Rule/finding disclosure policy

每个监管 rule 和输出 finding 明确指定：

```text
REGULATOR_ONLY
→ regulator officers only

SUBJECT_ORGANISATION
→ disclose only to the organisation/object owner concerned

CONSORTIUM_ADVISORY
→ disclose to explicitly related consortium audiences

PUBLIC
→ not permitted for automatic analytics output;
  requires a separate human-signed publication
```

高 correction frequency、跨组织 fraud score 或调查线索默认 `REGULATOR_ONLY`；sensor summary 超出监管建议范围可以由监管方批准为 `SUBJECT_ORGANISATION` preliminary reminder；正式 recall、违法结论或 public safety statement 必须经过 authorised officer 人工复核和签署。

### Advisory contract

```text
AdvisoryFinding
- findingId
- sourceRegulatorId
- ruleId / ruleVersion
- affectedOrganisationIds
- affectedObject/event references
- severity / reasonCodes
- humanReadableMessage
- dataWatermark
- generatedAt / expiresAt
- disclosureScope
- regulatorSignature
```

Platform Advisory Ingestion 验证 regulator identity、signature、rule/finding version、expiry 和 disclosure scope，再将结果路由给允许的组织或角色。平台不能扩大 audience、重新解释 severity、查看 regulator-only context，或把 advisory 与平台自己的判断混合。

AdvisoryFinding 不进入 canonical trace，不影响 event validation、handover status、membership、consumer projection 或 recall status。它只能生成 preliminary reminder、建议查看 evidence 或联系监管方。如果一项规则要成为强制 submission/schema requirement，必须经独立治理流程发布新的 Product Profile/Regulatory Policy 和 effective date，不能通过隐藏 analytics rule 改变 write path。

因此“监管方授权基础规则给平台”在第一版中的准确含义是：监管方授权特定 `ruleId/ruleVersion` 的 finding 可按指定 scope、watermark 和 expiry 被平台用于提醒；规则仍在监管控制域执行，平台不能修改或扩大适用范围。若未来确实需要低延迟本地执行，再单独评估 signed declarative rule package 和 sandbox，不能把它悄悄并入 Core validation。

当前基线不把 industry association 视为 Regulatory `AdvisoryFinding` 签发主体。行业机构可以通过联盟治理提议 Product Profile、vocabulary 或行业指导，但只有按 GovernanceRecord 流程发布后才影响平台。若未来允许行业机构直接发布提示，必须新建与 Regulatory Advisory 明确分开的 authority type、适用成员范围和 UI 语义，不通过泛化 `sourceRegulatorId` 默认扩权。

### Analytics freshness and failure semantics

Regulatory Analytics 必须对平台提供 `analysisInputWatermark`、`lastSuccessfulEvaluationAt`、`activeRuleSetVersion` 和 `analysisHealth`。`AdvisoryFinding.dataWatermark` 表示该 finding 使用的 confirmed input scope，`expiresAt` 限制它的当前有效性；两者不能被平台的当前 trace watermark 替代。

Analytics 不可用或滞后时，Traceability Core 继续 ingestion、trace/recall query 和 regulator manual investigation，但平台必须标记 risk assessment `DELAYED/UNAVAILABLE`，并对过期 finding 停止当前态展示。“无当前 finding”只能表示“对已成功评估到的 watermark 未产生提示”，不是食品安全保证。

### Separate notification sources

```text
Platform Operational Notification
→ stuck lifecycle, key/profile expiry, archive/anchor failure,
  handover deadline, projection lag
→ generated by platform from explicit state/deadline

Regulatory Advisory
→ regulator-approved heuristic/statistical/ML finding
→ generated and disclosure-controlled by regulator

Formal Regulatory Assessment
→ human-reviewed and organisation-signed canonical statement
```

UI、API 和 audit log 必须显示来源与保证等级，不能把三者都呈现成“监管违规”。Notification delivery failure 不回滚原 event 或 finding，平台只重试并记录 delivery status。

### Execution boundary

第一版由平台导出最小化 Regulatory Analytics Projection，监管环境执行 rules/models，再返回获准 AdvisoryFindings。监管方不能向平台上传任意 executable code。未来若低延迟场景确有需要，可以另行评估 signed declarative rule package 和 sandbox，但不作为当前基线。

Regulator Portal/Access Module 仍是核心平台的一等业务入口，负责 trace investigation、recall impact query、evidence access、exports 和 signed regulatory statement submission；Regulatory Analytics 与 Traceability Core 同属系统边界内，但拥有监管方独立运行时域和规则/模型所有权（见上）。关闭 Analytics 不影响 ingestion、trace query、consumer view 或监管人员手工调查。

**需要接受的代价：** 系统需要 AdvisoryFinding schema、regulator signature verification、audience routing、expiry/revocation 和 delivery audit；同一问题可能同时存在 private finding、participant advisory 和后续 formal assessment，UI 必须避免混淆。

**为什么可以接受：** 监管方保留规则和披露决定权，平台参与方又能及时获得获准的初步提醒。Peer integration 避免平台自行复制监管逻辑或看到全部调查结果，也避免把 optional analytics 变成 canonical write path 的可用性依赖。

---

## B22. NSW pilot 使用什么量化 workload 与恢复假设？

**决定：** 背景没有给出真实规模和 SLA，因此报告采用一组显式、内部一致且可测试的 NSW pilot architecture assumptions。它们不是客户事实或生产合同承诺，必须在 production deployment 前通过 load、failure-recovery、security 和 rural-usability testing 验证。

| Measure | NSW pilot assumption |
|---|---:|
| Initial participating organisations | 200 |
| Designed organisation growth | 1,000 |
| Internal users | 2,000 |
| Average canonical events | 10,000/day |
| Offline recovery burst | 50 events/s for 15 minutes |
| Consumer request peak at CDN | 5,000 requests/s |
| CDN cache-hit target | at least 95% |
| Public origin/API peak after cache | approximately 250 requests/s |
| Maximum synchronous lineage traversal | 10,000 edges |
| Large regulatory export | up to 1,000,000 events/job, asynchronous |
| Normal projection lag | at most 30 seconds |
| Safety-query stale threshold | 5 minutes |
| Designed rural offline window | up to 72 hours |
| Archive receipt latency after signed, connected submission | p95 at most 5 seconds under healthy dependencies; excludes human signing approval |
| Public-chain anchor/finality target | 15–60 minutes; exact value deferred to C1 |
| Canonical trace capacity horizon | at least 7 years |
| Receipted/CONFIRMED canonical trace logical RPO | 0 |
| PostgreSQL operational RPO | at most 5 minutes |
| Core platform RTO | at most 4 hours |
| Full Australian regional rebuild RTO | at most 24 hours |

10,000 events/day over seven years is approximately 25.6 million canonical events before growth and headroom。该数量仍适合以 managed PostgreSQL 保存 indexed operational metadata/projections，并把完整 payload 放在 object/WORM archive；consumer 5,000 requests/s 不进入 PostgreSQL/KMS 路径，而由 versioned snapshots 和 CDN 承担。

Offline burst 明显高于日均写入，用于验证多个 rural gateways 恢复连接时的 idempotency、backpressure 和 outbox processing。50 events/s 持续 15 分钟约为 45,000 submissions；平台不要求全部在一个数据库事务中完成，而按 stable `captureRecordId` 分批处理。

同步 lineage traversal 超过 10,000 edges，或预计结果接近 response/time limits 时，自动转 asynchronous export。一次最多约一百万 events 的监管 export 使用固定 watermark、streaming、独立 worker quota 和 temporary protected object，不形成长时间同步 database transaction。

Projection 正常 lag 目标为 30 秒；达到五分钟 safety threshold 时，recall/food-safety query 等待追平、回查 eligible source index 或返回 `STALE/INCOMPLETE`。这里的五分钟衡量“某记录达到其可发布 gate 后到 projection 可见”的延迟，不包含普通 event 的 15–60 分钟 anchor/finality 等待。Official Recall/Safety Notice 按 B18 的 `VERIFIED_PENDING_ANCHOR` fast path 计入 safety projection；Dashboard/consumer view 显示相应 watermark 和 assurance status，不把缺失结果当成“没有风险”。

Logical RPO=0 是设计目标，仅适用于已经获得可验证 independent ArchiveAck 并签发 receipt，或已经 `CONFIRMED` 的 canonical event，并以 archive/KMS durability、retention 尚未到期和成功 restore drill 为前提。`LOCAL_DRAFT/QUEUED_OFFLINE/SYNCING` 由 participant device/gateway 负责；PostgreSQL 中可重建 operational state 使用五分钟 RPO 目标。Core RTO 四小时优先恢复 ingestion、trace query 和 regulatory access；大型 exports/analytics 可以在完整区域重建的二十四小时目标内后恢复。

Logical RPO=0 的必测场景是：event 已取得 independent ArchiveAck 并向参与方签发 receipt，但尚未进入 Merkle batch 时平台 PostgreSQL 和运行账户全部丢失。Recovery Client 必须能从 independent archive catalogue 发现该对象，重建 receipt/outbox/anchor intent，在不重复签发 receipt 和不重复分配 leaf 的前提下继续 anchoring。该演练未成功前，receipted trace 的 logical RPO=0 仍只是目标。

### Scaling triggers

第一版先使用 connection pooling、query/index tuning、vertical scaling、CDN 和 workload quotas。若连续 load test/production window 中出现以下任一情况，则进行相应演进，而不是按日历提前拆分：

- consumer origin 超过约 250 requests/s 或 cache hit 低于 95%：先修正 cache key/TTL/publication strategy，再扩 stateless origin；
- regulator export 或 read workload 使 ingestion/receipt SLO 失败：增加 PostgreSQL read replica 或专用 export projection；
- event/index volume、vacuum/backup 或 projection rebuild 无法满足四小时 core RTO：引入 time/organisation partitioning；
- 10,000-edge traversal 经索引和查询优化后仍无法满足交互时延，或大图查询变为常态：评估专用 graph/read projection；
- outbox backlog 无法在允许的 projection lag 内消化：先水平扩 worker，再评估独立 broker。

**需要接受的代价：** 数字不是实测事实，可能导致初始容量偏大或偏小；报告和测试计划必须清楚标注 assumption、measurement method 和 revision trigger，不能把它们包装成客户 SLA。

**为什么可以接受：** 可量化假设使 PostgreSQL、CDN、outbox、archive、offline queue 和 async export 的设计能够被验证，同时保留基于实际证据调整的空间。相比虚构极端 TPS 或完全不写容量，它更符合试点阶段的现实决策方式。

---

## B23. PRIVATE 数据保存在哪里、如何分享？

**决定：** `PRIVATE` 默认**不在平台上**。平台侧只保存 canonical event 里的 commitment（加盐摘要）和资源引用（owner、类型、commitment、可选 blob 位置、保留策略）；内容的实际保存与举证责任属于发布方。平台可以提供**可选的零知识托管**：只保存参与方加密后的密文，平台自身没有解密能力，也没有 key escrow。

**边界条件/假设：** 参与方有能力（或通过 IoT provider、农业软件供应商）保管自己的证据。平台不承担通用证据仓库、通用 IoT 时序库或内容取证的角色。

**为什么这样定：**

- 平台看不到内容，就不需要为它设计字段级权限、租户隔离、KMS 策略和争议裁定；
- 举证义务本来就在发布方（A4/B19），把内容收进平台反而让责任变模糊；
- commitment 进入锚定历史后，"参与方事后替换证据"从免责声明变成**可被检测**（见"承诺的可执行性"）。

### 平台侧只留记录

平台侧保存的是 `ProtectedResource` **记录**，不是内容：`captureRecordId` / `epcisEventId` 引用、`ownerOrganisationId`、`mediaType`、`plaintextCommitment`、可选 `ciphertextDigest`、`storageMode`、`externalLocator`、`recipientKeyRefs`、`retentionMetadata`、`availabilityStatus`。字段定义与三种 `availabilityStatus` 的语义见 [Data & Access](/systems/data-access)。

与早期模型的两点差别（这两点是决策，不只是实现）：

1. **不再有由平台执行的 `accessScope`。** 平台没有明文，无法执行内容级授权；访问权只能由所有者通过"加密给谁"来表达。
2. **没有"结构化 private detail 存 PostgreSQL JSONB"这条路。** 一旦平台需要按结构化字段查询，它就必须是 `CONSORTIUM`，没有中间地带。

### 承诺的可执行性（这是收益，不是限制）

- commitment 随 canonical event 一起锚定 → 参与方**事后无法替换证据而不被发现**。
- 低熵内容（是否有机、是否检出某菌、固定模板报告）会被字典穷举，所以 commitment 必须加盐：`commitment = H(content ‖ nonce)`，nonce 由参与方持有，只在举证时与内容一并出示。
- 平台在提交时**无法验证** commitment 对应任何真实材料。这正是"举证义务在参与方"的准确含义：调查时拿不出可匹配材料，该承诺即为未支持。
- Retention 到期后，锚定的 commitment 仍在，但没有 nonce 无法反推内容——"永久 commitment"与"数据删除"因此可以共存。

### 所有者选择的内容接收方（不做事件级受众）

需要"只有监管方看得到"的证据时，不需要给事件加第三类受众，而是让**所有者**把内容加密给额外接收方：

```text
owner encrypts evidence to:
  - owner itself（找回用）
  - optional: regulator encryption key
  - optional: named trading partners
→ platform stores ciphertext (zero-knowledge) or owner hosts it
→ CONSORTIUM event 只带 reference + salted commitment
→ regulator / Analytics 用自有密钥解密，并用 commitment 校验
```

与"事件级受众"的关键区别：**接收方由所有者决定，不是平台计算的 scope。** 因此平台不需要新增策略权威角色、不需要第二套 KEK、也不需要在写入时推导"谁有权看什么"。

配套条件：

- `Organisation Key Registry` 必须区分密钥用途：`SIGNING | ENCRYPTION`；
- B15 需要一条窄例外：Analytics 可以取用**所有者已加密给监管 scope** 的资源；这不是任意追取 ProtectedResource；
- 同一内容可有多个接收方，平台无法审计"谁真的解开了"，只能审计"谁被授权持有 key"。

### 不承诺清单

| 项 | 不承诺 |
|---|---|
| 密钥恢复 | 无 escrow、无平台侧恢复。参与方丢失私钥即内容永久不可用，平台无法协助举证 |
| 取证 | 平台不能响应针对内容的调取要求，只能转达给所有者；监管方的法定取数权对所有者和平台的作用不同 |
| 可用性 | 零知识托管按 best effort 或商用对象存储的可用性承诺，**不进入 core RTO/RPO**；`logical RPO=0` 不覆盖 PRIVATE 内容 |
| 删除 | 平台删的是密文对象；所有者自己的副本不在范围内，平台侧删除无法证明内容在其他地方也已消失 |
| 元数据 | 平台仍可见"谁、何时、多大、关联哪个 event、下载频率"。需要最小化与保留期，不能被"零知识"掩盖 |
| 完整性 | 平台不能验证 commitment 与内容一致；它只能证明自己保存的密文未被替换（`ciphertextDigest`） |

**承受的代价：** 平台失去对私有证据的检索、比对和自动取证能力；调查依赖参与方配合；零知识托管仍带元数据泄漏面。

**为什么可以接受：** 这类数据（原始 telemetry、化验报告、合同、照片）的容量、商业敏感性和法域差异远高于共享 trace。把它们收进平台会把架构从"追溯层"扩张成"通用证据仓库 + IoT 时序库"，并引入整套字段级权限与租户隔离问题。把内容留在所有者一侧、用承诺锚定，可以在不扩张边界的前提下保住可验证性。

---

## B24. 平台如何管理“用户”？

**决定：** 平台不以自然人为管理单元，以**组织**为唯一的身份、访问和租户单元。平台不建设用户目录、岗位、审批流程或人员生命周期；组织内部谁在何时可以做什么，由组织自行决定并向平台声明为 delegation 断言。

**边界条件/假设：** 一个 subject 可以同时代表多个组织（顾问、集团员工、合作社职员）；组织之间不存在平台维护的层级关系（合作社不是其成员农场的父组织）。

**为什么这样定：**

- 平台要保证的是"这条声明由哪个组织负责"，不是"哪个员工点了一下"（B5/B16）；
- 员工入离职、岗位调整、审批链属于企业 HR/IAM 职责，复制进追溯平台只会产生第二份会过期的真相；
- 把组织当唯一单元后，租户边界、签名归因、archive/KMS epoch 和治理记录共用同一个 key。

### 四个注册表与请求绑定

平台侧只维护四样东西：`Organisation Registry`、`Organisation Key Registry`（区分 `SIGNING` / `ENCRYPTION` 用途）、`Delegation Registry`、`Governance Record History`；角色保留少量固定值，不建模组织内部架构。字段定义与请求绑定流程见 [Identity & Governance](/systems/identity-governance)。

以下两条是决策，不能下沉为实现细节：

1. **每请求必须显式绑定 acting organisation。** 一个 subject 可代表多个组织，缺失绑定时**拒绝**，不能默认取第一个或最近使用的组织——否则归因与可见范围取决于会话历史。
2. **平台可以给一个很简易的用户界面，但它是 delegation 注册表的编辑器，不是权威用户目录。** 组织更换 HR 系统时平台不感知，也不需要同步。

### 明确不管的部分

| 不归平台管 | 归谁 |
|---|---|
| 员工名册、入离职、岗位、汇报线 | 组织自己的 HR/IAM |
| 组织内部审批链、双人复核 | 组织自己的流程；平台只验证最终签名 |
| 密码、MFA、会话 | 外部 IdP |
| 合作社与成员农场的关系 | 参与方之间的商业安排：写成多个 `organisationId` + delegation，不建组织层级 |
| 多站点企业的站点结构 | 同上；站点可写成不同 `bizLocation`，但仍属同一 organisation |

平台可以提供一个**很简易的用户界面**（查看/编辑本组织的 delegation 列表），但那个界面是 delegation 注册表的编辑器，不是权威用户目录；组织更换 HR 系统时平台不感知，也不需要同步。

### 组织层级显式 out of scope

不建 `parentOrganisationId`。一旦层级存在，`CONSORTIUM` 可见范围、scope 计算、KMS epoch 和签名归因都要沿层级继承，复杂度和治理成本立刻上升；而农业场景中的层级关系（合作社、集团、代工、代销）差异太大，平台无法给出通用语义。

**触发条件：** 若出现"父组织以自身名义代为提交成员事件"的需求，用 delegation 表达（父组织作为 agent，签名仍归实际申报主体），而不是引入层级。若确实需要层级，作为新的架构前提重新评估。

**承受的代价：** 合作社/集团要在平台上注册多个组织，onboarding 成本上升；参与方内部权限变更需走 delegation 更新，不会随 HR 系统自动生效。

**为什么可以接受：** 组织数量增加是一次性 onboarding 成本，而组织层级会污染每一个下游决策（scope、epoch、归因、召回范围）。宁可多注册几个组织。

---

## B25. Traceability Core 与业务语义如何分工？

**决定：** 把 Core 收缩为**机制**——接收、验证、追加、确认、归档/锚定，以及只由 EPCIS 标准语义导出的证据图。业务语义（handover 状态、召回遍历策略、合规重建、分析输入、运营洞察）作为**同进程内的语义模块**，通过唯一的 `QueryPort` 读取事实，各自维护可重建投影。**Core 不认识任何模块。**

**这是分层，不是微服务。** 模块同进程、同一 PostgreSQL、经 port 调用；不引入 broker、独立数据库或独立部署。与 A7/B10 一致：只有出现独立发布或扩缩容需求时才拆分。

### 三层的分界

| 层 | 内容 | 归属 |
|---|---|---|
| 完整性机制 | capture、canonicalisation、签名与 authority、幂等、lifecycle、archive/anchor 编排、`CONFIRMED` 门禁、correction 结构 | Core，不可下沉 |
| 事实与图 | canonical event、对象身份、**只由 EPCIS 标准语义生成**的边（identity、transformation input/output、aggregation parent/child、association、correction link、handover reference） | Core |
| 业务语义 | handover 状态、召回遍历策略、合规映射、mass-balance 口径、公开投影、洞察统计 | 语义模块 |

一句话分界：

> **Core 保证"这条事实是什么、你能否看见、你是否看全"；Service 决定"它意味着什么"。**

前半句是 A5/B5/B6/B17/B23 已经承诺的东西，不能外包；后半句是业务词汇与策略，本就应当可替换。

### 不可下沉的不变量

以下七条必须由 Core 强制，任何模块都不得自行实现或绕过：

1. **身份与幂等**：`captureRecordId` / `epcisEventId` 的唯一性与 Error Declaration 特例（A6）；
2. **完整性管道**：canonicalisation、签名验证、authority、archive ack、finality 门禁（A5、B5–B8）；
3. **append-only 与 correction 结构**（A6、B17）；
4. **scope 强制**：`QueryPort` 按调用者 scope 过滤，而不是由模块自觉遵守（B3）；
5. **non-collapsing 强制**：竞争断言成组返回，不排序、不打分、不选代表路径（B17）；
6. **watermark 与完整性暴露**：每次查询都带 `dataCompleteThrough`（B12、B13）；
7. **图的语义下限**：边只能来自 EPCIS 标准语义，不允许模块向图里注入自定义边。

### 读取入口与模块清单放在设计页

`QueryPort` 的方法签名、`EdgeGroup` 语义、`ModuleManifest` 字段定义和第一版六个模块（Handover / Recall / Compliance / Consumer / AnalyticsInput / Insights）的读写与降级表，属于设计内容，见 [Semantic Modules](/systems/semantic-modules)。

留在本决策里的只有三条硬规则：

1. **模块只读 canonical facts。** 任何"结论"（召回通知、监管评估、纠错声明）仍然作为签署事件走**同一条 capture 路径**——只有一个写路径，B5/B6 不受影响。
2. **模块能力可以降级，但不能影响 Core 的确认、归档与锚定。** 降级必须可显示，不能静默丢掉。
3. **`requiresFields` 的并集是编译产物，不是运行时 union。** 编译进 profile 版本后冻结，因为 B2 的恢复要求"还原当时的 schema 与验证规则"，地板不能随模块上线而漂移。

### 字段地板从哪来

```text
所有 ACTIVE 模块 manifest 的 requiresFields 并集
  → 编译
  → 冻结进 profile 版本（B11）
  → conformance check 用冻结后的清单校验
```

推论：**没有消费者的字段不进地板。** 例如 `readPoint` 目前没有任何模块声明为必需，因此默认 optional，仅作为争议与审计证据存在；`bizLocation` 由 RecallModule 与 ConsumerModule 声明，仍是必填。

新增模块会收紧地板，属治理变更，必须走 `GovernanceRecord`（B16），不能由开发流程静默完成。

### 两个必须避免的误读

1. **"既然是模块，就可以随便加。"** 不行。模块上线会改变 profile 地板与治理范围，是治理动作，不是重构。
2. **"Core 不含业务，所以没有业务保证。"** 不对。Core 保证的是**可验证性、可见范围、是否看全**——这正是 B17/B23/B3 的全部内容；业务含义由模块承担，且每个模块的能力边界必须对用户可见。

**承受的代价：** 组件图变宽（Core 内部组件减少，多出约六个模块）；模块之间需要 watermark 对齐，否则 recall 与 handover 可能基于不同快照；需要一套 manifest 编译与冻结流程（与 T1 的 conformance check 合并）；port 边界一旦画错（把标准语义下沉或把完整性上移）会引发返工。

**为什么可以接受：** 依赖方向单向——模块依赖 `QueryPort`，Core 不认识模块，属于 stable dependency；能力降级而非全局失败，与 B13 的读侧降级一致；只有一个写路径，B5/B6/B7 的完整性保证不受影响。

<a id="layer-d"></a>
# 已舍弃但保留的完整替代方案：Permissioned Consortium Ledger

该方案技术上成立，也与早期数据模型高度一致。它被舍弃的原因是现实治理和成本前提不足，而不是因为 BFT 或 permissioned ledger 本身无效。

## D1. 原方案的产品和部署模型

```text
Participant Environment
- ERP/WMS/TMS
- optional Participant Gateway
- organisation signing key
- participant-owned evidence

Shared SaaS Application Plane
- PWA / portals / API
- modular Traceability Application
- PostgreSQL / projection / broker

Permissioned Consortium Ledger Plane
- independently controlled validators/orderers
- complete canonical EPCIS shared trace core
- common membership and governance policies
```

普通农场和中小企业不运行节点。节点只由平台运营者、生产者代表组织、物流/分销代表、零售代表、行业机构或独立审计主体等治理成员运行。日常技术运维可以外包，但云账号、validator key 和 governance approval 必须保持独立控制。

## D2. 原方案的数据和权限模型

- `PUBLIC`：消费者 allowlisted projection；
- `CONSORTIUM`：联盟 profile 中的完整 EPCIS shared trace core，以明文复制给 channel/ledger members；
- `PRIVATE`：精确商业详情、文件和原始 telemetry，作为 participant-owned ProtectedResource；
- PostgreSQL：hot operational copy 和可重建 projections；
- Permissioned ledger：平台外可恢复的 canonical history 和 finality。

加入联盟意味着接受所有 node operators 能看到 shared trace core。无法向所有联盟成员披露的字段不得进入 network EPCIS profile。

## D3. 原方案的签名与共识边界

Participant signature、ledger consensus 和 governance approval 是三个不同门槛：

- Participant signature 证明哪个组织作出声明；
- BFT consensus 决定交易顺序和 finality；
- Governance policy 决定 membership、profile、validator 和规则变更。

即使 validators 达到 quorum，也不能生成未串谋且自行持钥组织的原始签名；但治理多数可能尝试修改 identity mapping 或降低 endorsement requirement，因此旧 policy 和 identity history 仍需保留。

## D4. 原方案的 L2/L3 保证

原目标是有限 L2：平台运营者与一个 participant/validator domain 串谋时，仍不能修改已 finalise 事件、冒充未串谋自持钥组织，或单方面改变治理。

经典 BFT 关系通常为：

```text
n >= 3f + 1
```

如果要正式容忍两个 Byzantine validator domains，通常需要至少七个真正独立的验证域。超过 `f` 后 safety 不再有形式保证；达到 commit quorum 后，串谋节点可能不依赖诚实节点确认替代历史；达到 governance threshold 后，还可能修改成员和规则。

原方案不承诺完整 L3。达到联盟 consensus/governance quorum 的成员串谋时，封闭联盟无法同时保证正确性和 liveness；外部 checkpoint 最多使既有历史重写可检测，不能阻止串谋方共同提交虚假现实声明。

## D5. 原方案的确认生命周期

```text
DRAFT
→ RECEIVED
→ VALIDATED
→ PENDING_SIGNATURE
→ PENDING_LEDGER
→ CONFIRMED
```

只有有效 transaction 获得 BFT finality 后才成为 `CONFIRMED`。Quorum 不足时保持 `PENDING_LEDGER`，不降级为平台单方确认。Ledger 是 confirmed consortium history，PostgreSQL 是 submission 状态和查询 projection。

## D6. 原方案为何舍弃

1. **缺少真实节点运营者。** 背景没有给出一个已经存在的行业联盟，也没有证据证明足够多组织愿意承担 validator、CA、HSM、升级、监控和 incident response。
2. **完整 L2 的独立域成本过高。** 若目标为 `f=2`，经典 BFT 需要至少七个独立控制域；七个容器或同一服务商代管的七个节点并不构成七个故障域。
3. **治理问题无法由节点数量解决。** Membership、profile、key rotation、validator replacement 和 emergency upgrade 都需要长期章程、预算和投票机制。
4. **少数节点方案的保证容易被夸大。** 三至五个节点可能降低单方控制，但不能诚实宣称完整抵抗平台与另一个 validator 同时 Byzantine。
5. **主要目标只是防止事后无痕修改。** 使用成熟公链提供外部 commitment，并用独立 archive 提供数据可用性，可以更直接地解决已确认的 integrity/availability 问题。

## D7. 从原方案保留的设计

切换到 public-chain commitment 后仍保留：

- participant event signatures 与分级 custody；
- canonical EPCIS shared trace；
- `PUBLIC / CONSORTIUM / PRIVATE` 分类；
- participant-owned ProtectedResource；
- 平台外恢复完整 trace；
- append-only correction；
- acceptance receipt、幂等 `captureRecordId`、EPCIS Error Declaration 特例和明确 finality；
- PostgreSQL hot query 与可重建 projection；
- 不声称区块链证明物理事实真实。

新的方案只是把原方案中三个耦合职责拆开：

```text
Public Blockchain
→ integrity and external existence checkpoint

Independent Immutable Archive
→ full canonical trace availability

Consortium Key Service
→ consortium-only access
```

<a id="layer-c"></a>
# 第三层：仍需讨论的决定

以下项目保留当前倾向和 trade-off，但尚未提升为架构基线。

## C1. Public-chain anchoring 采用什么网络和时间窗口？

**已确认的边界：** canonical EPCIS payload 不上链；采用固定时间窗口的 deterministic Merkle batching，由平台 relayer 统一支付 gas 和提交 root。第一版不要求 independent secondary relayer。

**为什么部分参数尚未定案：** 网络选择与窗口长度不会改变 event、archive、receipt、manifest 或 proof 的逻辑边界。它们主要取决于实际事件量、gas 成本、finality 特性、生态稳定性和业务可接受的确认时延，因此可以在部署设计阶段比较后确定。

**已否决：** 完整 EPCIS plaintext/ciphertext 默认上公链；以及由平台数据库保存唯一 payload、公链只留无法恢复内容的 opaque hash。

**需要接受的代价：** 系统依赖外部网络的 gas、finality、validator/stake security、治理升级和长期可用性；平台需要 relayer、transaction monitor、proof service 和 chain migration procedure。

**最后再回答：** 选择哪一个 public network；窗口是分钟级还是小时级；commitment contract 是否 immutable；如何迁移到新链并保持 anchor continuity；允许多长的 anchor/finality delay。

---

## C2. PostgreSQL 的部署地区、恢复目标和拆分阈值是什么？

**已确认的边界：** 第一版使用一个 managed PostgreSQL application database，通过 `registry`、`events`、`projection` 和 `operations` schema 做逻辑隔离；independent trace archive、public chain 和 participant artifact stores 保持外部边界。PostgreSQL 不是 canonical history 的唯一恢复来源。NSW trial 的 primary deployment 位于 Australian region（优先 NSW/Sydney），所有非公开 operational data 默认不出境。

NSW pilot 采用 B22 假设：10,000 canonical events/day、50 events/s offline-sync burst、PostgreSQL operational RPO 不超过五分钟、core platform RTO 不超过四小时、完整 Australian regional rebuild 不超过二十四小时。扩容由 SLO、rebuild time 和实测 workload 触发，不预先引入多数据库。

**为什么尚未完全定案：** PostgreSQL 足以提供事务、约束、JSON 和递归遍历，但背景也要求多产品线和地区，未来可能出现数据驻留或跨区域写入限制。

**已否决：** 第一版同时引入事务数据库、event store、graph database 和独立 read store，因为没有 workload 证据支持这些一致性边界。

**需要接受的代价：** PostgreSQL 是共享运营依赖，存在共同故障域；复杂谱系或跨区域部署达到一定规模后可能需要分区或专用存储。

**待回答：** 最终 cloud service 的 backup/PITR 配置与成本验证；load/recovery tests 是否证明 B22 targets 可达。Read replica、partition、graph/read store 的初始触发条件已经由 B22 定义，但 production threshold 可按测试结果修订。

---

## C3. 独立控制域的恢复目标和具体运营安排是什么？

**已确认的边界：** 区分 Participant Environment、Shared SaaS Application Plane、Regulator-Operated Analytics Environment、Independent Trace Archive、Consortium-controlled Key Service 和 External Public Blockchain。其中 Shared SaaS Application Plane 与 Regulator-Operated Analytics Environment 同属系统边界内（B21），但运行时、数据边界和治理权分离；至少一个 WORM archive replica 必须位于平台控制域之外；额外企业/监管 mirrors 是可选的。Consortium KEK 使用专业 managed KMS，但其 account、policy 与 recovery authority 由联盟或独立受托方控制。

NSW trial 的 mandatory archive 和 Consortium KMS 位于 Australian regions；恢复副本至少跨 Australian failure domain。Public chain 可以是 global network，因为链上只保存不直接识别个人的 commitment/Merkle root。

已经获得可验证 independent ArchiveAck/receipt 且仍处于 active retention/legal hold 的 canonical trace 采用 logical RPO=0 target；core service RTO 为四小时，完整 regional rebuild RTO 为二十四小时。该目标仍依赖选定 archive/KMS product、account governance、KMS recovery identity 和恢复演练证明能够达到。

故障语义也已经确定：write path 在失败步骤 fail closed 并可幂等续跑；既有 confirmed data 尽可能继续读取并暴露 freshness/degradation；ArchiveAck 之前不签 receipt，public-chain finality 之前不进入 `CONFIRMED`。B18 authorised official Recall/Safety Notice 可以 `VERIFIED_PENDING_ANCHOR` 快速发布，但不得冒充链上 finality。

**为什么部分内容尚未定案：** 权力边界、Australian residency、retention terminal state 和 target RPO/RTO 已经确定，但背景没有给出愿意签约的 archive operator、联盟治理实体或具体产品，不能虚构组织和供应商，也不能在恢复测试前把 targets 写成已实现 SLA。

**已否决：** 仅罗列云服务品牌而不说明谁控制账号、密钥和恢复；也否决要求每个小型参与方部署完整基础设施。

**需要接受的代价：** 跨控制域部署增加网络、安全、监控、升级和故障协调成本。

**待回答：** 强制 archive operator 和 KMS account owner 的具体组织；Australian replica/failure-domain 选择；archive/KMS 产品级 failover 与 restore procedure 能否满足 B22 RPO/RTO；KEK deletion protection、rotation 和 emergency recovery；是否需要第二 provider escrow；relayer wallet 和 gas budget；Participant Gateway 是否进入第一版。

### C1–C3 在最终报告中的关闭条件

Q&A 阶段可以保留产品选型待定，但最终 deployment/infrastructure view 不能全部保留为 TBD。提交前至少选定一套可实施的 reference deployment：具体 public network 与 anchor window、Australian cloud region/managed PostgreSQL 配置、WORM archive 产品及账户归属、KMS/recovery identity/跨故障域配置，以及对应恢复路径和验证方法。这是开发团队可执行的参考方案，不声称产品已签约或生产 SLA 已获得证明。

<a id="summary"></a>
# 当前总体结论

当前已经确定的最短表述是：

> 本系统是跨组织农业供应链追溯层，而不是农业 ERP。参与方通过 PWA 或既有系统发布联盟 profile 约束的 EPCIS events。消费者只读取公开 projection；联盟成员共享足以重建路径和定位潜在责任方的 canonical EPCIS trace core；商业详情和原始证据保存在参与方一侧，平台只持有加盐承诺，或提供平台不可解密的零知识托管。平台以组织为身份与访问单元，不管理组织内部用户。系统不声称区块链证明物理事实真实，但要求平台运营者不能单方面静默重写或垄断已经确认的历史。

其中有两个不能在报告压缩时省略的成立前提。第一，B1 是为了让题目明确要求的 blockchain 承担真实的外部完整性职责；如果参与方完全信任平台，数据库加 WORM backup 已足够，区块链会退化为 theatre。第二，B17/B21 不是取消领域校验，而是把“记录断言”和“签署判定”分开：Traceability Core 只记录断言，判定只能由有权主体以签署声明进入历史；普通领域启发式与高级分析在**系统边界内**的 Regulatory Analytics 子系统中执行，该系统与 Traceability Core 对等但拥有独立运行时与治理域，规则和模型所有权属于监管方。投影层不得把竞争断言折叠成单一路径。只有 ML 算法本身是可选的。

Canonical shared trace 使用 per-event DEK 加密，并在确认前取得至少一个平台控制域之外 WORM archive operator 的 signed ArchiveAck；大型成员和监管方可以自愿维护额外 encrypted mirrors。公共链只保存 event commitment 或 Merkle root，提供平台不能改写的 external existence/integrity checkpoint。平台 PostgreSQL 负责 hot query 和 projection；由联盟或独立受托方控制 account 的专业 KMS 保护 Consortium KEK，平台有运行所需的 decrypt 使用权但没有密钥管理权，因此本方案不声称防止被攻破的平台 runtime 泄露 consortium plaintext。

联盟内注册组织之间的 B2B 实物交接由 sender-signed shipping claim 与 receiver-signed receiving claim 两份独立声明组成，在 EPCIS 中映射为标准 events 加 shipping/receiving bizStep；二者分别确认，平台只派生 handover status。网络外对手方使用明确标注的单方 boundary claim，消费者零售不要求消费者签名。缺少接收确认不会抹去发货声明，争议、未确认和 `EXTERNAL_COUNTERPARTY` edges 仍进入 recall/audit 查询并明确标记保证等级。

应用不采用全量 Event Sourcing。不可变 trace core 保持 append-only；普通应用状态使用事务模型；archive、anchor 和针对性 projections 由 PostgreSQL transactional outbox 驱动。第一版不需要独立 broker 或多套读写数据库，projection lag 必须通过 watermark 暴露，安全查询不得把过期视图解释为完整结果。

产品扩展采用不可变、版本化并由联盟治理的 Product Validation Profiles。Profile 只配置字段、枚举、单位、证据引用、consumer allowlist 和 UI metadata；它不承载 yield、mass-balance、fraud heuristic 或 compliance conclusion，也不承诺用配置取代所有产品代码扩展。

性能设计分为 participant ingestion、regulator/internal investigation 和 public consumer 三个 workload planes。低频写入通过离线队列、幂等和 outbox 保证可靠；大范围监管读取使用带 watermark 的异步 export；消费者只访问 versioned public projections，并由 cache/CDN 承担高并发。农村网络造成的 edge sync lag 与平台 processing lag、public-chain anchor lag 分开度量。

依赖故障时，写路径停留在最后一个持久化状态并幂等续跑，不绕过签名、archive acknowledgement 或 public-chain finality；读路径继续提供已有 confirmed data，并通过 watermark、stale status 和安全查询的 fail-closed 行为诚实表达降级。

原始 IoT telemetry 默认作为 participant-controlled PRIVATE ProtectedResource，由参与方自管或选择平台托管；canonical trace 只保存 profile-required sensor summary、source-reported alarm/exception、provenance、reference 和 content commitment。一体化设备接入不改变数据分类和举证责任。

监管机构与其 Analytics/ML 工具使用不同身份和权限。监管方可以读取 confirmed consortium trace，并在具体案件中依据记录的法律或治理授权访问选定 private evidence、签署正式监管事件；Analytics 只读取最小化 projection，输出默认 regulator-private。监管方可以把选定 findings 作为 signed preliminary advisories 提供给平台转达，但 Analytics 不能访问任意 private resource、作出正式监管决定或直接写入 canonical trace。

Human 和 IoT fleet identity 由外部/参与方 IAM 管理；核心只保存 organisation membership、organisation public keys、scoped user/machine delegations 和 signed governance history。Membership governance 只判断现实参与资格，高影响变更采用独立 dual control；它不能替成员签署事件或改写 public-chain finality，因此不取代区块链的完整性职责。

核心只验证 EPCIS source assertion 的 schema、signature、authority、canonicalisation 和 idempotency，不判断 transformation、aggregation、quantity、timing 或 lineage 是否符合业务常识；但它必须如实呈现已提交断言之间的冲突——lineage/recall 的默认视图不得折叠为单一路径，也不为竞争边排序或选择代表路径。启发式规则、统计分析或可选 ML 在系统边界内的 Regulatory Analytics 子系统中运行，该子系统属于监管方独立运行时域并持有规则与模型所有权；输出默认 regulator-private，经签名 disclosure policy 才能作为平台可转达的 preliminary advisory，且在 authorised officer 人工签署前不构成正式结论。合规能力由三层共同承担：准入层的 regulation profile 强制证据要求、筛查层的 advisory finding、结论层的签署事件。

Recall 是对 shared consortium lineage projection 的保守、带 watermark 的查询，并可展示 authorised party 提交的 signed recall status。Official Recall/Safety Notice 在 signature + ArchiveAck 后可作为 `VERIFIED_PENDING_ANCHOR` 紧急发布，随后补 chain finality；平台不执行实际下架、封存、退货或销毁。Confirmed impact 与 recent pending claims 分开展示，private evidence 只在后续调查时单独授权。

参与方负责分配标准 product/logistics identifiers，平台只为缺少外部 scheme 的参与方提供 network-scoped fallback，并验证 syntax、namespace、resolution 和 attribution。Consumer QR 只解析 public projection，不证明标签物理真实性或提供防伪保证。

NSW 是首个 trial jurisdiction。非公开 operational data、independent archive 和 Consortium KMS 默认位于 Australian regions；immutable trace 排除自然人直接标识，canonical payload 默认保留至少七年并可由 product/jurisdiction policy 或 legal hold 延长。Retention 到期后删除 archive ciphertext/DEK envelope 和可重建 payload，只永久保留非个人 public-chain commitment 与 signed minimal deletion audit。Mutable personal data 支持 correction/deletion/de-identification。

NSW pilot 的 reference workload 为 200 个初始组织、2,000 名内部用户和日均 10,000 canonical events；农村恢复峰值按 50 events/s、消费者 CDN 峰值按 5,000 requests/s 设计。Active-retention 内已取得可验证 ArchiveAck 的 trace 以 logical RPO=0 为目标，PostgreSQL RPO 五分钟，core RTO 四小时，regional rebuild 二十四小时；这些都是待测试验证的 architecture assumptions，而不是生产 SLA。

仍待定的是 public network、anchor window、具体 archive/KMS 签约主体、产品级 restore validation、key recovery 和 chain migration，而不是 archive 权力边界、retention terminal、anchoring 粒度或自建 validator 数量。

<a id="one-minute"></a>
# 答辩时的一分钟版本

> We are building a cross-organisation agricultural traceability layer rather than an ERP. Because the assignment explicitly requires blockchain, we make platform-operator distrust an explicit scenario: otherwise a managed database and WORM backup would be sufficient and blockchain would be theatre. Before confirmation, the encrypted canonical trace receives a signed acknowledgement from an independently controlled WORM archive, the consortium key is administered outside the platform account, and a public blockchain stores periodic Merkle roots so post-confirmation replacement is externally detectable. The Traceability Core records assertions and never adjudicates reality: verdicts enter history only as signed declarations, and lineage or recall views must keep competing claims side by side instead of collapsing them into one path. Deterministic heuristics, statistics and optional ML run in a Regulatory Analytics peer subsystem that sits inside the system boundary but in the regulator's own runtime and governance domain; it owns the rules and models, can authorise selected signed findings for platform reminders, and never decides which claim is true. Consumers receive an allowlisted public projection, detailed evidence remains participant-owned, and an independent recovery path can rebuild retained trace data without the platform database. Neither blockchain nor analytics is presented as proof of physical truth.
