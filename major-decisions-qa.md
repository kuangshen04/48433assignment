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

**决定：** 不把完整事件和文件写入公共链。公共链只保存 event commitment 或周期性 Merkle root；完整 canonical EPCIS shared trace 保存在平台控制域之外的独立不可变归档中，大型、高频或仅用于举证的内容继续作为 ProtectedResource 管理。

**边界条件/假设：** 公共链负责不可篡改的时间和完整性证明，不负责业务数据权限、完整 trace 恢复、文件存储或运营查询。

**为什么这样定：** 明文 EPCIS trace 上公链会永久公开供应链关系；完整 ciphertext 上公链又会产生费用、永久保留和未来密钥泄露风险。把 payload 与 proof 分开，可以让联盟内恢复完整 trace，同时只向公共网络暴露最小 commitment。

**否决的方案一：完整明文或密文 EPCIS payload 直接上公链。** 该方案会放大商业泄露、费用、数据驻留、删除和长期密码风险。

**否决的方案二：公链只存 hash，完整 payload 只有平台一份。** 该方案只能在平台愿意提供 payload 时验证防改；平台删除、拒绝服务或退出后无法恢复 trace。

**承受的代价：** 系统需要额外维护独立 immutable archive、归档复制、access-controlled key service、public-chain relayer、finality monitor 和 inclusion proof。

**为什么可以接受：** Archive 的运维职责远小于一个 BFT validator network：它不参与共识、不执行 smart contract，也不需要实时出块。它只需可靠保存、校验和恢复数据，仍能满足平台外可恢复的要求。

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

**决定：** 不完全信任。平台可以运营 SaaS、查询和日常数据处理，但不能成为已确认历史的唯一完整性证明和唯一可恢复副本。

**边界条件/假设：** 平台可能发生内部滥用、管理员账号泄露、基础设施入侵、错误恢复、商业压力或停止运营。系统需要防止平台在事件确认后无痕修改历史，并在平台失效后恢复 canonical trace。

**为什么这样定：** 如果事件 payload、commitment、查询结果和唯一副本都由平台控制，blockchain 只是平台内部的 append-only 实现，参与方仍然必须完全信任平台。

**否决的方案一：完全信任平台数据库和备份。** 无法独立验证历史，也无法应对平台退出。

**否决的方案二：自建多组织 BFT validator network。** 该方案技术上有效，但背景没有给出足够多、真正独立且愿意承担节点、治理与升级成本的组织。

**当前约束：**

- 已 finalise 的 commitment 必须位于平台控制域之外的公共链；
- 完整 canonical trace 必须至少有一个平台控制域之外的 immutable archive；
- canonical payload 写入规定的独立 archive 后，平台签发 receipt，anchor finalise 后提供 inclusion proof；
- 平台不能把自己的 acceptance receipt 当作 public-chain finality；
- 平台仍可能在上链前拒绝或延迟事件，因此 censorship 与 tamper resistance 分开处理。

**承受的代价：** 共识和时间证明依赖外部 public network；数据可用性依赖独立 archive；系统还要维护 relayer、gas、finality 和 chain migration。

**为什么可以接受：** 这些职责比组织和维护自己的 BFT validator consortium 更标准化。平台风险被拆成可分别验证的 integrity、availability 和 ingestion-censorship 问题，而不是假装由一个账本同时解决。

---

## B2. 平台失效后，哪些数据必须仍可恢复？

**决定：** 必须恢复联盟 network profile 中的完整 canonical EPCIS shared trace，包括事件、对象关系和纠错历史。原始证据和企业内部资料不属于强制恢复范围。

**边界条件/假设：** 平台失效后，参与方或审计者至少需要判断产品经历了哪些阶段、数据由谁发布、在哪一环出现矛盾，以及应向哪一方索取证据。

**为什么这样定：** 公链 commitment 只能验证拿到的内容是否匹配，不能从 hash 恢复 payload；只有平台 PostgreSQL 保存完整事件时，平台仍然是唯一数据可用性来源。

**否决的方案一：公链只保存 hash，完整事件只在平台数据库。** 可以检测拿到的 payload 是否被改，但拿不到 payload 时无法恢复任何 trace。

**否决的方案二：共享网络强制保管所有原始 IoT、证书、照片、合同和内部记录。** 会把平台变成通用证据仓库并承担不必要的隐私、保留和法规责任。

**承受的代价：** 需要平台外的 immutable archive、复制和恢复流程；参与方自管的 evidence 仍可能 `Unavailable`、`Expired` 或无法举证。

**为什么可以接受：** Trace core 的体积远小于原始文件和 telemetry，使用对象存储/WORM archive 的成本显著低于运行共识节点，却足以定位问题。原始材料仍由声明方举证，平台可提供可选托管。

**强制恢复范围：**

- event ID、type、time、publisher 和 profile version；
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
| Archive Operator | 不因运行归档获得消费者身份 | 保存 ciphertext，不因运维自动获得明文权限 | 仅保存平台托管的资源时按审计流程访问 |

### 分类判据

> 没有该数据，联盟是否仍能重建产品经过的组织、阶段和转换关系，并定位潜在责任方？

- 如果不能：进入 `CONSORTIUM` canonical EPCIS profile；
- 如果可以：建模为 participant-owned `ProtectedResource`；
- 如果消费者需要：从 shared trace 生成 `PUBLIC` projection。

如果某字段既不能让联盟成员看到，又是重建最小 trace 必不可少的内容，则当前简化模型不成立；必须修改共享假设或重新引入加密/private collection。

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
- signedAt
- custodyMode
- assuranceLevel
- providerReceipt
```

所有模式使用同一个 `EventSignatureVerifier`：

```text
canonical event digest
→ lookup registered public key
→ verify signature
→ check key validity and revocation
→ check actor/organisation authority
→ check assurance level required by event policy
```

Archive、anchor service 和领域规则依赖标准 envelope，不依赖 AWS、Azure、Turnkey、Fireblocks、Vault 或某个本地 KMS 的专有格式。

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
eventId
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
→ PENDING_SIGNATURE
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
ARCHIVE_RETRY
ANCHOR_RETRY
```

### 各状态的含义

- `DRAFT`：参与方本地意图，可以编辑或删除，不属于共享历史；
- `QUEUED_OFFLINE/SYNCING`：事件仍位于 participant device/gateway 或正在传输，平台尚未接受，不得显示 acceptance receipt；
- `RECEIVED/VALIDATED`：平台已经接收和验证，尚未形成外部证明；
- `PENDING_SIGNATURE`：等待参与方或 signing provider 批准；
- `PENDING_ARCHIVE`：等待 encrypted canonical payload 在独立归档中达到约定复制等级；
- `PENDING_ANCHOR`：archive object 已持久化，等待生成 event commitment 或进入 Merkle batch；
- `SUBMITTED_ON_CHAIN/INCLUDED`：交易已广播或进入区块，但尚未满足最终性规则；
- `FINALISED`：public network 已达到所选 finality；
- `CONFIRMED`：finality、archive location 和 inclusion proof 已关联，正式进入 trace、projection、recall 与 consumer-view 输入。

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

canonical payload 完成签名并写入 independent archive 后，平台签发 acceptance receipt，其中包含 event ID、payload hash、archive reference、received time 和预期 anchor window。Finality 后再提供 chain transaction reference 与 inclusion proof。Receipt 能证明平台已经接受该归档记录并承诺纳入锚定，但不能替代 finality。

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
→ platform-signed acceptance receipt
→ fixed anchor window
→ deterministic batch manifest + Merkle root
→ platform relayer submits root
→ public-chain finality
→ event inclusion proof
```

Batch manifest 至少记录 batch ID、window boundaries、ordered leaf list、hash/canonicalisation algorithm、Merkle root 和 archive reference，并与 event payload 一起独立归档。相同输入必须能够重建相同 root；参与方不需要信任平台提供的查询结果即可验证 inclusion proof。

第一版不设置 independent secondary relayer。平台漏提或延迟提交时，receipt、archive copy 和逾期的 expected anchor window 会留下可审计的不一致，但不会自动绕过平台的 censorship。若实际治理要求在平台失效时仍能继续提交，可在不改变 event、archive 和 proof 格式的前提下增加 archive operator 或 auditor relayer。

**未采用逐事件上链：** 它的 proof 更直接、确认等待通常更短，但每个 event 都产生链上交易，成本、nonce 管理和故障恢复随业务量增长。Merkle batching 把链上职责压缩为定期发布少量 root，更符合“公链只负责不可篡改时间界标”的边界。

**需要接受的代价：** event 在所属窗口关闭并达到链上 finality 前只能保持 pending；manifest 和 inclusion-proof 服务成为必要组件；第一版只能检测平台未按承诺提交，不能保证在平台恶意停摆时自动完成提交。

**为什么可以接受：** 完整 payload 已先进入独立归档，不会因为等待 batch 而只存在于平台数据库中。该作业的核心目标是让事后替换和已接受后漏锚定可被发现，而不是建立一条低延迟支付链。窗口长度可在得到事件量、gas 成本和可接受确认时延后再配置。

---

## B8. Independent Archive 与 Consortium KMS 由谁运营？

**决定：** Independent Archive 采用“一个强制独立副本 + 可选多方 mirror”的开放复制模型；Consortium KEK 托管在由联盟或独立受托方控制的专业 managed KMS 中。二者都不能只存在于平台自己的 cloud account 和管理员权限域内。

### Archive replication baseline

每个 canonical event 在成为 `CONFIRMED` 前，至少获得一个签约的、非平台控制的 WORM archive operator 的持久化 acknowledgement。大型联盟成员、监管方或审计机构可以自愿运行额外只读 mirror，但系统不假设监管方一定愿意承担该职责，也不等待所有自愿 mirror 才确认事件。

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

### 必须诚实保留的依赖

外部 KMS 把信任从平台转移给专业服务与 KMS account governance，并没有消除信任。Archive 全部存在但 KEK 永久丢失时，trace 仍不可恢复。因此 key deletion protection、region/provider outage、rotation、emergency recovery 和管理员交接必须纳入恢复设计；是否增加第二 provider escrow 或 threshold recovery 留到 RPO/RTO 与监管要求明确后决定。

**需要接受的代价：** 平台需要跨控制域调用 archive 与 KMS，处理权限故障和外部服务不可用；至少一个独立 archive operator 与 KMS account owner 需要合同、审计和交接安排。

**为什么可以接受：** 这些参与方只承担标准化存储或密钥托管职责，无需验证业务交易或参与共识。一个强制外部副本提供最低恢复保证，自愿 mirrors 可以逐步增加韧性，同时不会让小型参与方承担基础设施义务。

---

## B9. Shipping 与 Receiving 如何形成双边确认？

**决定：** 所有跨组织实物交接都要求 receiver 最终作出独立签名的 ReceivingEvent，但不要求双方共同签署或修改同一个 event。Sender 的 ShippingEvent 与 receiver 的 ReceivingEvent 分别进入 immutable history；平台通过稳定的 `handoverId` 和 event references 派生业务交接状态。

```text
Sender-signed ShippingEvent
→ independently CONFIRMED claim: "we shipped these objects"

Receiver-signed ReceivingEvent
→ independently CONFIRMED claim: "we received/rejected these objects"

Transfer projection
→ AWAITING_RECEIPT / ACCEPTED / PARTIALLY_ACCEPTED
  / REJECTED / DISPUTED / UNACKNOWLEDGED
```

这里必须区分两个正交状态：

- event lifecycle 的 `CONFIRMED` 表示某一组织的声明已经签名、归档并锚定，不表示另一方同意；
- handover status 表示双方声明能否匹配以及 receiver 是否接受交接。

缺少 ReceivingEvent 不会阻止或删除 ShippingEvent。发货声明可以独立 `CONFIRMED`，但 transfer 保持 `AWAITING_RECEIPT`；超过 profile 定义的期限后变为 `UNACKNOWLEDGED`，不能自动视为接受。这样 receiver 无法通过不响应抹去 sender 的声明，sender 也不能用单方声明制造一条被表示为双方已接受的路径。

ReceivingEvent 不是简单的 approve flag。它必须能够记录实际收到的 identifiers、quantity/unit、time、condition 和差异原因，并引用 `handoverId`、ShippingEvent ID、sender、receiver 与相关 logistic units，以支持分批接收、短缺、损坏、错发和多目的地。无法确定匹配关系时进入 reconciliation/dispute workflow，不静默合并事件。

### 查询和纠错规则

- 普通 accepted-path 或 consumer projection 可以只展示 `ACCEPTED`，或明确标记其他状态；
- recall、food-safety 和 audit 查询必须保守地包含 `AWAITING_RECEIPT`、`PARTIALLY_ACCEPTED`、`DISPUTED` 和 `UNACKNOWLEDGED` edges，避免争议期间漏掉可能已经实际流转的货物；
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

Outbox 与对应的本地状态变更在同一数据库事务中提交，worker 使用 event ID、operation ID 和 state precondition 实现幂等。Archive 和 public chain 无法加入同一个数据库事务，因此由 B6 的显式 lifecycle 和 retry/reconciliation 处理，而不假装存在跨系统 ACID transaction。

第一版可以逻辑区分 command、worker 和 query responsibilities，但不需要为了使用 CQRS 术语部署两套数据库。只有在实测吞吐、独立消费者数量、projection rebuild 时间或故障隔离要求证明必要时，outbox 才发布到独立 broker，特定 read model 才迁移到专用存储。

### 一致性边界

以下操作要求同步事务约束：event ID/idempotency、签名与 organisation authority、合法 lifecycle transition、archive acknowledgement 与 receipt 的绑定、ReceivingEvent 消费唯一性，以及 Merkle leaf allocation。

Consumer view、dashboard、lineage visualisation、handover summary 和 analytics 可以最终一致。Recall/food-safety 查询不得把 projection lag 当作“没有风险”：必须暴露 `data complete through` watermark 和 lag；超过安全阈值时等待追平、回查 confirmed event index，或明确返回 `STALE/INCOMPLETE`。

**未采用完整 Event Sourcing：** EPCIS 是跨组织业务事件标准，不代表用户、权限、配置和作业状态都必须通过 event replay 产生。全量 Event Sourcing 会引入不必要的 replay、schema evolution、event-version compatibility、projection debugging 和个人信息删除冲突。

**需要接受的代价：** PostgreSQL outbox 与 workers 仍然构成异步系统，需要幂等、重试、dead-letter/reconciliation 和 lag monitoring；单一 PostgreSQL 是第一版的共享运营故障域。

**为什么可以接受：** 不可变性由 signed archive 与 public-chain commitment 提供，数据库只承担运营索引和可重建视图。该方案保留未来接入 broker 或专用 read store 的演进路径，却不在缺少 workload 证据时预付完整 CQRS/Event Sourcing 的复杂度。

---

## B11. Product Profile 是否采用可配置 Schema 和版本管理？

**决定：** 采用受治理的 `Versioned Product Validation Profiles`，而不是通用动态 schema、rule engine 或 no-code workflow platform。Profile 负责产品特有的数据约束和简单展示元数据；稳定的 EPCIS core、信任边界和跨事件业务语义继续由领域代码实现。

### 可配置范围

第一版 profile 可以定义：

- required/optional EPCIS extension fields；
- primitive types、formats、enumerations 和合理数值范围；
- permitted units 和 product vocabulary；
- required/optional evidence types；
- 有限的字段内或简单条件校验；
- consumer projection 的显式字段 allowlist；
- 通用表单控件所需的 label、help text 和 display metadata。

以下内容不能由任意 profile 重写：EPCIS event core semantics、Shipping/Receiving handover、correction/append-only rules、canonical digest、signature assurance、archive/anchor lifecycle、organisation authorization、recall traversal 以及复杂 cross-event constraints。

Profile 不引入任意 field-level access policy。Profile 中的 shared trace fields 默认属于 `CONSORTIUM`；消费者只能读取 allowlisted `PUBLIC` projection；不能向联盟公开的文件或数据继续作为 `PRIVATE` ProtectedResource。

### 不可变版本模型

```text
DRAFT
→ PUBLISHED
→ DEPRECATED
→ RETIRED
```

`PUBLISHED` version 不可原地修改。每个 canonical event 固定记录 `profileId`、`profileVersion` 和 `canonicalisationVersion`，并将其绑定到签名 digest。旧事件始终按原 version 解释和验证，不因新版本发布而重新判为无效，也不批量改写已确认历史。

新增 optional field 等兼容变化仍通过新的 version 发布；新增 required field、改变单位语义、删除字段或改变 validation meaning 视为 breaking version，只适用于其 effective policy 下的新事件。跨版本 query projection 可以归一化到稳定核心字段，但必须保留原始 profile/version provenance。

### Validation split

```text
Profile/schema validation
→ fields, types, formats, enumerations, units, simple conditions

Domain validators in code
→ identity, authority, handover, correction,
  transformation, recall and cross-event invariants
```

通用 UI 可以根据 profile 生成 string、number、date、enumeration 和 unit fields；需要特殊交互、复杂计算或新业务 lifecycle 的产品必须提供经过评审的代码扩展，不能承诺所有产品永远只靠 JSON 配置上线。

最小 profile artifact 包含 `profileId`、`version`、`status`、`effectiveFrom`、`baseEpcisVersion`、`validationSchema`、`valueLists`、`evidenceRequirements` 和 `consumerProjectionAllowlist`。Profile 的发布、弃用和 breaking-change approval 属于联盟治理操作。

**需要接受的代价：** 系统必须长期保留旧 profile、测试跨版本 projection、管理 vocabulary/unit 演进，并防止 schema validation 与领域代码产生冲突。动态字段的查询索引和复杂 UI 仍可能需要专门实现。

**为什么可以接受：** 多数“新增字段、枚举、单位和证据要求”的产品差异可以低成本扩展，而会改变交接、转换或召回语义的差异仍通过显式代码接受审查。这个边界提供实际可扩展性，同时避免把项目变成通用规则平台。

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

农村网络问题使用 offline-first submission 处理，而不是无限 HTTP retry。PWA 使用受保护的本地存储保存 draft、client-generated event ID、待提交 payload、必要 profile/vocabulary、dependency 和 sync status；成熟参与方可以由 local gateway 提供 durable queue。

必须区分三种延迟：

```text
Edge sync lag
= participant creates event → platform RECEIVED

Platform processing lag
= RECEIVED → independent archive acknowledgement / receipt

Anchor lag
= archived event → Merkle batch public-chain finality
```

农村连接主要影响 edge sync lag。`LOCAL_DRAFT`、`QUEUED_OFFLINE` 和 `SYNCING` 不属于平台已接受的共享历史，也不能生成 acceptance receipt。平台恢复连接后使用稳定 event ID、idempotency key 和 causal references 去重并处理依赖；participant `eventTime` 与平台 `receivedAt` 分开记录，不能信任设备时钟决定全局顺序。

离线能力遵守 B5 的 custody boundary：enterprise self-custody gateway 可以离线签名后排队；需要 external/device approval 或 platform custody 的 PWA event 只能离线保存 draft，联网并重新认证后完成签名。离线缓存不应长期保存整个 consortium trace，尤其不能在共享设备上复制不必要的敏感数据。

### Storage and scaling path

第一版以一个 managed PostgreSQL 保存 operational state、event index、outbox 和 projections；完整 payload 同时受 independent archive 保护。扩展顺序是 query/index tuning、connection pooling、vertical scaling、consumer CDN/cache、read replicas，再根据实测的表大小、projection rebuild 时间和 lineage/export workload 决定 partitioning、broker 或专用 read store，而不是预先部署全部组件。

当前 workload assumptions 是：正常写入频率较低但必须承受离线设备恢复后的 burst；内部交互读取低并发但 export 可能覆盖大量事件；消费者读取具有高并发和活动/召回导致的突发峰值；设备可能离线数小时至数天；平台 processing lag 预计为秒级到几十秒，public-chain confirmation 为分钟级并由最后选择的 anchor window 决定。这些是可验证的设计假设，不声称是客户提供的事实。

Projection 必须发布 `data complete through` watermark 和 lag。Consumer UI 可以容忍短暂 eventual consistency；recall/food-safety 查询超过安全 lag threshold 时必须等待追平、回查 confirmed event index，或明确返回 `STALE/INCOMPLETE`，不能把缺失结果解释为没有风险。

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

Transaction included but finality not reached
→ INCLUDED

Projection worker unavailable
→ canonical event may remain CONFIRMED
→ affected projection becomes STALE and retries independently
```

### 三类失败结果

1. **Transient dependency failure：** 保持当前 pending state，通过 durable outbox、backoff 和 reconciliation 重试。已写 archive、已分配 batch 或已广播 transaction 不执行补偿删除。
2. **Permanent validation/business failure：** 无效签名、无权限、非法 profile/schema 或明确拒签进入 `REJECTED`、`SIGNING_REJECTED` 或 `EXPIRED`，不无限重试。
3. **Read-model failure：** 不改变 canonical event 的确认状态，只使相应 projection 落后；修复后从 confirmed event index/archive rebuild。

所有 retry 使用稳定的 event ID、archive object ID、operation ID、batch ID 和 transaction intent。Worker 必须先检查当前 state 与已有外部结果，再执行下一步，以防重复归档、重复 leaf allocation、重复 receipt 或重复链上提交。

### Read degradation boundary

已有 consumer snapshots 继续由 cache/CDN 提供，已有 confirmed trace 和未受影响的 operational projections 继续读取。每个异步 read model 暴露 `data complete through` watermark、lag 和 health；普通 UI 可以显示 stale indicator，recall/food-safety 查询超过安全阈值时必须等待、回查 confirmed event index，或返回 `STALE/INCOMPLETE`。

“读继续”不代表所有依赖故障时所有数据都可读。KMS 不可用时，public projection 和已经合法物化的视图可以继续，但需要即时解密 archive payload 的查询会暂时不可用；PostgreSQL/平台整体失效时，CDN 可以继续提供已有 public snapshot，完整 consortium trace 则通过独立 recovery procedure 恢复，而不是承诺零中断切换。

### Backpressure and receipts

平台可以在 archive 暂时故障时有界保存 `RECEIVED/PENDING_ARCHIVE` submissions，但在获得至少一个 qualified independent archive acknowledgement 前不得签发 acceptance receipt。Pending queue 达到容量或最大等待时间后，停止接收并返回 retryable failure，由 participant offline queue 保留原 event。

Public chain 故障时 payload 已在独立 archive 中，因此可以签发 receipt 并积累 `PENDING_ANCHOR` backlog；系统必须监控 oldest pending age 和 backlog size，但不能因超时自动提升为 `CONFIRMED`。

**需要接受的代价：** 所有异步步骤都需要明确 state、idempotency、retry policy、dead-letter/reconciliation、backpressure 和可观测性；用户界面必须同时表达 submission progress 与 read freshness。

**为什么可以接受：** 该模型优先保护已确认历史的可用性，同时避免依赖故障时降低签名、归档或 finality 标准。故障恢复是从最后一个可靠 checkpoint 继续，而不是用跨 KMS、archive、database 和 public chain 的虚假分布式事务换取表面上的同步成功。

---

## B14. 原始 IoT 数据由参与方还是平台控制？

**决定：** 原始 IoT telemetry 默认属于 participant-controlled `PRIVATE ProtectedResource`。平台管理进入共享历史的 profile-required sensor summary、异常、provenance、raw-resource reference 和 content commitment；“一体化接入”不代表原始 telemetry 归平台所有或默认向联盟公开。

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

小型参与方可以使用平台提供的一体化 device binding、telemetry ingestion、private storage、summary generation 和 EPCIS submission；大型参与方可以继续使用自己的 IoT platform。平台托管只改变 storage/operator，不授予平台将 raw telemetry 公开给其他成员、消费者或用于 ML training 的权利。

### Evidence responsibility

IoT provider/device signature 可以证明 bundle 的技术来源，但 canonical EPCIS publication 仍需要 organisation 或其注册 gateway/machine actor 承担声明责任。企业 gateway 可以按获批 policy 自动签名，无需人工批准每一条 reading。

IoT vendor/参与方负责完整 device fleet identity、certificate provisioning、firmware、connectivity 和 calibration operations。追溯平台只注册向本系统上传数据的 integration principal、organisation delegation、allowed scopes、public-key/credential reference 与 validity；不为每个低成本 sensor 建立平台账号。Device-level signature 是可选 provenance，不能替代 organisation 对 canonical publication 的责任。

缺少 sensor evidence 不得使已经发生的 shipping/receiving 从 trace 中消失。业务事件仍可记录，但 evidence status 显示为 `MISSING`、`DELAYED` 或 `UNAVAILABLE`，product profile 可以产生 compliance warning 或阻止某个合规结论。设备签名、校准、防拆和 content hash 提高 assurance，但不能证明传感器实际安装位置或测量的物理真实性。

**需要接受的代价：** 平台和审计方不能随时直接查询所有 raw telemetry；调查时可能需要 participant access grant，且参与方可能无法提供材料。Platform-hosted 模式还需要 tenant isolation、retention、deletion 和 access-audit controls。

**为什么可以接受：** 高频 telemetry 的容量、商业敏感性和设备多样性远高于共享 trace core。统一 ProtectedResource 模型保留了调查验证能力，也避免把追溯平台扩张为强制的通用 IoT device-management 和 time-series storage platform。

---

## B15. 监管方与监管 ML 是否拥有相同权限？

**决定：** 不拥有相同权限。Regulator organisation/authorised officer 是具有法定或联盟治理职责的正式主体；Regulatory ML service 是目的受限的辅助工具和独立 service identity。ML 不继承监管方人员的全部权限，也不能以“由监管方运营”为理由获得任意 archive、KMS 或 `PRIVATE` data access。

### Permission matrix

| Capability | Regulator / authorised officer | Regulatory ML screening service |
|---|---|---|
| Read `PUBLIC` data | Yes | Only when included in its dataset |
| Read confirmed `CONSORTIUM` trace | Yes, through regulator role | Only purpose-minimised analytics projection |
| Read complete canonical archive | Through authorised regulator query/recovery path when required | No direct archive/KMS access |
| Read participant `PRIVATE` evidence | Only for a specific case with recorded legal/governance basis | No in routine screening |
| Request evidence or exercise legal authority | Yes | No; may only recommend investigation |
| Create internal risk alert | Yes | Yes, regulator-private advisory output |
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
→ Regulatory ML Service
→ regulator-private RiskAlert
```

Regulatory Analytics Projection 可以包含 confirmed event relationships、handover discrepancies、sensor summaries、missing/delayed evidence status、correction history 和必要 organisation/location identifiers。它不包含 raw IoT telemetry、合同、完整实验室文件、device credentials、signing material 或其他 participant-private resources。ML 无权通过 reference 自动追取对应 ProtectedResource。

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

ML alert 默认属于 regulator-owned `PRIVATE` data，不能直接进入 consumer projection、改变 event validity、触发法律结论或公开企业风险标签。只有经授权人员复核并以 regulator organisation key 签署的 Inspection/Assessment event 才进入 canonical trace；是否形成 `PUBLIC` safety notice 还需要独立的监管发布流程。

**需要接受的代价：** 平台需要单独的 regulatory analytics projection、service identity、export audit 和 risk-alert store；监管人员调查 private evidence 时走另一条 case-specific authorization path，不能简单复用 ML 的批量数据接口。

**为什么可以接受：** ML 需要足够数据发现异常，但不需要监管机构的全部法定权力。身份和数据路径分离降低了大规模 private-data 暴露、外部模型供应商滥用、误报自动执法以及模型输出泄露企业声誉信息的风险，同时保留监管方依法调查和签署正式结论的能力。

---

## B16. Human、Machine 与 Organisation Identity 的管理边界是什么？

**决定：** 核心系统不建设完整 Human IAM 或 IoT device-fleet IAM。Human identities 由企业 IdP 或 managed customer identity provider 认证；IoT/device identities 由参与方或 IoT provider 管理。追溯核心只管理 `Organisation Registry`、`Organisation Key Registry`、进入本系统的 scoped delegations，以及不可覆盖的 governance-change history。

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

### Membership and key lifecycle

```text
APPLICANT → ACTIVE → SUSPENDED → ACTIVE / EXITED / REVOKED
```

`SUSPENDED/EXITED/REVOKED` organisation 不能发布新 canonical events 或获得新的 consortium access/key epoch，但过去的 membership、public keys 和 signed events 保留供验证。正常 key rotation 由当前 organisation key 授权；旧 key 丢失时走独立 dual-control recovery。Key compromise 触发 suspension、new-key issuance 和受影响事件调查，不物理删除旧签名，也不自动断言泄露前全部事件无效。

退出成员不再获得新 KEK epoch 或在线 consortium access，但密码学上无法撤回其已经下载的 plaintext。是否在争议或法律要求下恢复特定旧资料，走审计的 regulator/governance access path。

**为什么仍需要 public blockchain：** Membership governance 只被有限信任去判断现实参与资格，不被授权代表成员签事件、删除 archive 或重写历史。即使它错误批准恶意成员，该成员也只能用自己的可追责身份发布声明；它不能伪造其他 self-custody organisation 的签名或修改过去的 finalised commitments。如果平台和 membership governance 被假设为可以完全控制且完全可信，区块链才确实没有必要，但这不是 B1 的威胁模型。

**需要接受的代价：** 平台需要 federation/managed-IAM adapters、organisation/key/delegation registries 和治理审批记录；onboarding、lost-key recovery 和高权限变更不会即时完成。

**为什么可以接受：** 核心只保留跨组织追责所必需的身份事实，不复制企业 IAM 或 IoT device-management 能力。有限治理解决现实身份入口，签名解决声明归属，public commitment 解决确认后的不可篡改，三者职责不重叠。

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
- acceptance receipt、幂等 event ID 和明确 finality；
- PostgreSQL hot query 与可重建 projection；
- 不声称区块链证明物理事实真实。

新的方案只是把原方案中三个耦合职责拆开：

```text
Public Blockchain
→ integrity and timestamp proof

Independent Immutable Archive
→ full canonical trace availability

Consortium Key Service
→ consortium-only access
```

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

**已确认的边界：** 第一版使用一个 managed PostgreSQL application database，通过 `registry`、`events`、`projection` 和 `operations` schema 做逻辑隔离；independent trace archive、public chain 和 participant artifact stores 保持外部边界。PostgreSQL 不是 canonical history 的唯一恢复来源。

**为什么尚未完全定案：** PostgreSQL 足以提供事务、约束、JSON 和递归遍历，但背景也要求多产品线和地区，未来可能出现数据驻留或跨区域写入限制。

**已否决：** 第一版同时引入事务数据库、event store、graph database 和独立 read store，因为没有 workload 证据支持这些一致性边界。

**需要接受的代价：** PostgreSQL 是共享运营依赖，存在共同故障域；复杂谱系或跨区域部署达到一定规模后可能需要分区或专用存储。

**待回答：** 第一个部署区域、数据驻留假设、备份与恢复目标，以及何种实测阈值触发 graph/read store 或区域拆分。

---

## C3. 独立控制域的恢复目标和具体运营安排是什么？

**已确认的边界：** 区分 Participant Environment、Shared SaaS Application Plane、Independent Trace Archive、Consortium-controlled Key Service 和 External Public Blockchain。至少一个 WORM archive replica 必须位于平台控制域之外；额外企业/监管 mirrors 是可选的。Consortium KEK 使用专业 managed KMS，但其 account、policy 与 recovery authority 由联盟或独立受托方控制。

故障语义也已经确定：write path 在失败步骤 fail closed 并可幂等续跑；既有 confirmed data 尽可能继续读取并暴露 freshness/degradation；archive acknowledgement 之前不签 receipt，public-chain finality 之前不进入 `CONFIRMED`。

**为什么部分内容尚未定案：** 权力边界已经确定，但背景没有给出愿意签约的 archive operator、联盟治理实体、部署地区、保留期限或恢复 SLA，不能虚构具体组织和供应商。

**已否决：** 仅罗列云服务品牌而不说明谁控制账号、密钥和恢复；也否决要求每个小型参与方部署完整基础设施。

**需要接受的代价：** 跨控制域部署增加网络、安全、监控、升级和故障协调成本。

**待回答：** 强制 archive operator 和 KMS account owner 的具体组织；archive retention、replica geography、RPO/RTO；KEK deletion protection、rotation 和 emergency recovery；是否需要第二 provider escrow；relayer wallet 和 gas budget；Participant Gateway 是否进入第一版。

# 当前总体结论

当前已经确定的最短表述是：

> 本系统是跨组织农业供应链追溯层，而不是农业 ERP。参与方通过 PWA 或既有系统发布联盟 profile 约束的 EPCIS events。消费者只读取公开 projection；联盟成员共享足以重建路径和定位潜在责任方的 canonical EPCIS trace core；商业详情和原始证据作为 participant-owned ProtectedResources，由参与方保存或选择平台托管。系统不声称区块链证明物理事实真实，但要求平台运营者不能单方面静默重写或垄断已经确认的历史。

Canonical shared trace 使用 per-event DEK 加密，并在确认前写入至少一个平台控制域之外的 WORM archive；大型成员和监管方可以自愿维护额外 encrypted mirrors。公共链只保存 event commitment 或 Merkle root，提供平台不能改写的外部完整性证明。平台 PostgreSQL 负责 hot query 和 projection；由联盟或独立受托方控制 account 的专业 KMS 保护 Consortium KEK，平台只有有限使用权而没有密钥管理权。

跨组织实物交接由 sender-signed ShippingEvent 与 receiver-signed ReceivingEvent 两份独立声明组成；二者分别确认，平台只派生 handover status。缺少接收确认不会抹去发货声明，争议和未确认 edges 仍进入 recall/audit 查询并明确标记保证等级。

应用不采用全量 Event Sourcing。不可变 trace core 保持 append-only；普通应用状态使用事务模型；archive、anchor 和针对性 projections 由 PostgreSQL transactional outbox 驱动。第一版不需要独立 broker 或多套读写数据库，projection lag 必须通过 watermark 暴露，安全查询不得把过期视图解释为完整结果。

产品扩展采用不可变、版本化并由联盟治理的 Product Validation Profiles。Profile 只配置字段、枚举、单位、简单校验、证据要求和 consumer allowlist；交接、纠错、转换、授权、签名和召回等跨事件语义保留在领域代码中，不承诺用配置取代所有产品代码扩展。

性能设计分为 participant ingestion、regulator/internal investigation 和 public consumer 三个 workload planes。低频写入通过离线队列、幂等和 outbox 保证可靠；大范围监管读取使用带 watermark 的异步 export；消费者只访问 versioned public projections，并由 cache/CDN 承担高并发。农村网络造成的 edge sync lag 与平台 processing lag、public-chain anchor lag 分开度量。

依赖故障时，写路径停留在最后一个持久化状态并幂等续跑，不绕过签名、archive acknowledgement 或 public-chain finality；读路径继续提供已有 confirmed data，并通过 watermark、stale status 和安全查询的 fail-closed 行为诚实表达降级。

原始 IoT telemetry 默认作为 participant-controlled PRIVATE ProtectedResource，由参与方自管或选择平台托管；canonical trace 只保存 profile-required sensor summary、异常、provenance、reference 和 content commitment。一体化设备接入不改变数据分类和举证责任。

监管机构与其 ML 工具使用不同身份和权限。监管方可以读取 confirmed consortium trace，并在具体案件中依据记录的法律或治理授权访问选定 private evidence、签署正式监管事件；ML 只读取最小化的 regulatory analytics projection，输出 regulator-private advisory alerts，不能访问任意 private resource、作出监管决定或直接写入 canonical trace。

Human 和 IoT fleet identity 由外部/参与方 IAM 管理；核心只保存 organisation membership、organisation public keys、scoped user/machine delegations 和 signed governance history。Membership governance 只判断现实参与资格，高影响变更采用独立 dual control；它不能替成员签署事件或改写 public-chain finality，因此不取代区块链的完整性职责。

仍待定的是 public network、anchor window、具体 archive/KMS 签约主体、RPO/RTO、key recovery 和 chain migration，而不是 archive 权力边界、anchoring 粒度或自建 validator 数量。

# 答辩时的一分钟版本

> We are building a cross-organisation agricultural traceability layer rather than an ERP. Small participants may use the platform PWA, while mature organisations integrate through EPCIS or APIs. Before confirmation, the encrypted canonical trace is persisted in at least one independently controlled WORM archive; large members and regulators may maintain additional optional mirrors. The consortium encryption key is held by a professionally managed KMS account controlled by the consortium or an independent trustee, while the platform receives usage but not administrative authority. A public blockchain stores periodic Merkle roots, making post-confirmation replacement detectable without exposing supply-chain data. Consumers receive an allowlisted public projection, while detailed evidence remains participant-owned and may optionally be hosted by the platform. This design does not claim that blockchain proves the physical truth of source assertions.
