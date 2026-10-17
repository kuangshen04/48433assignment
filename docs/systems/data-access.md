# Data & Access

> 相关决策：[A5–A6](/decisions/catalog#a5)、[B2–B3](/decisions/catalog#b2)、[B10–B12](/decisions/catalog#b10)、[B20](/decisions/catalog#b20)、[B23](/decisions/catalog#b23)

## 三类可见性

| 分类 | 内容示例 | 默认读者 | 平台能否读明文 |
|---|---|---|---|
| `PUBLIC` | consumer allowlisted product/trace projection、signed safety notice | 消费者和公众 | 能（它就是生成者） |
| `CONSORTIUM` | canonical EPCIS trace core、handover/lineage、sensor summary | active consortium participants | 能（运行时被授权解密） |
| `PRIVATE` | raw IoT、报告、合同、调查记录、业务附件 | owner；所有者加密授予的接收方 | **不能**（B23） |

“所有 active consortium participants 可读取 canonical trace core”是试点共享协议的强业务假设，不是密码学必然结果。若利益相关方拒绝该假设，需要重新引入 scoped ABAC、private collections 或 selective disclosure。

## 验证与重建不是同一件事

扁平可见性不等于“任一成员能读全部历史”。按 B3：

| 能力 | 需要明文 | 谁可以做 |
|---|---|---|
| 验证日志 append-only、自己的记录已纳入批次、批次序列无断裂 | 不需要 | 任一成员（inclusion + consistency proof） |
| 重建并验证某条记录 | 该事件 | 持有该事件 scope 的成员 |
| 重建并验证完整历史 | 全部 | 全 scope 方：监管方、审计者、受托恢复方 |

KEK epoch 同时构成时间边界：新成员默认只拿到当前及之后的 epoch，加入前的历史明文访问需要显式治理授予。**这是对能力声明的收窄，不影响完整性保证**——完整性验证不需要明文。

这也决定了 B7 的一项要求：批次 root 必须构成可验证的 append-only 序列（running hash chain 或 consistency proof），否则“成员可独立验证”只剩单批次 inclusion，不覆盖“没有批次被跳过”。

## 核心字段地板

分类判据（B3）落到具体字段时需要一条地板，否则每个 profile 都能自行决定“哪些字段算结构性”，最终会出现某条产品线无法重建 trace。

**必进 `CONSORTIUM` 的核心字段**（每条都挂到它所服务的决策）：

| 字段 | 服务的决策 |
|---|---|
| event type、`eventTime`、`eventTimeZoneOffset` | A3、B6（顺序与迟到判定） |
| `bizStep`、`disposition` | A3、B9（交接阶段识别） |
| `sourceList`、`destinationList` | B18（一上一下的召回遍历） |
| `bizLocation`（GLN 或 URI） | B3、B18 |
| `readPoint` | 无消费者声明，默认 **optional**（争议与审计证据） |
| 对象标识：`epcList` 或 `quantityList`（含 `epcClass` / `uom`） | A3、B17（lineage 与冲突并存） |
| `profileId` / `profileVersion`、`canonicalisationVersion` | B11、B5（签名绑定） |
| `captureRecordId`、`epcisEventId`、`SignatureEnvelope` | A6、B5、B6 |
| 交接用的 `bizTransactionList` 引用 | B9、B19 |

**数量与粒度绑定，不是全局无条件：**

```text
class/lot 级事件（批次、散装、农产品常态）
  → quantityList 必填，单位用 UN/CEFACT code
  → 理由：B9 部分收货、B21 mass balance 都以"有多少"为前提

instance 级事件（SSCC 整车 / 整托、序列化单品）
  → 数量可由标识计数表达
  → 重量、体积等可退化为证据引用 + 加盐承诺（B23）
  → 这不是"藏数量"，是换了标识粒度
```

**这张表的来源：** 不是手写清单，而是所有 ACTIVE 语义模块 manifest 的 `requiresFields` 并集，编译后冻结进 profile 版本（[B25](/decisions/catalog#b25)、[B11](/decisions/catalog#b11)）。因此“某字段为什么必填”永远能回答到具体模块；没有消费者的字段（如 `readPoint`）默认不进地板。新增模块会收紧地板，属治理变更。

判据本身（哪些字段必须进、为什么不能下放给 profile）见 [B3](/decisions/catalog#b3)。

## ProtectedResource

不能进入共享 trace 的大型或敏感内容使用统一的**平台侧记录**模型。平台只持有记录，不持有内容（B23）：

```text
ProtectedResource (platform-side record)
  resourceId
  captureRecordId / epcisEventId reference
  ownerOrganisationId
  resourceType / mediaType
  plaintextCommitment        参与方计算、加盐；平台无法验证内容
                             加盐用 nonce，**nonce 只由所有者持有、不随事件发布**
  ciphertextDigest           仅零知识托管存在
  storageMode=PARTICIPANT_HOSTED | PLATFORM_HOSTED_ZERO_KNOWLEDGE
  externalLocator            自托管时由所有者提供
  recipientKeyRefs           所有者选择的接收方
  retentionMetadata
  availabilityStatus=OWNER_ASSERTED | OBJECT_PRESENT | UNKNOWN
```

三点必须记住：

1. **没有平台可执行的 `accessScope`。** 平台没有明文，内容级授权无法由它执行；访问权只能由所有者“加密给谁”来表达。
2. **没有结构化 JSONB 存 private detail。** 需要按字段查询的内容必须进 `CONSORTIUM`，没有中间地带。
3. **平台无法验证 commitment 与内容一致。** 它只能证明自己保存的密文未被替换；参与方自管内容在调查时可能无法提供，而“无法提供”本身就是有意义的结论。

**加盐的 nonce 只由所有者持有，不随事件发布。** 低熵内容（是否有机、是否检出某菌、固定模板报告）的承诺可以被字典穷举，加盐就是为了堵住这条路；nonce 一旦随事件进入 `CONSORTIUM`，承诺就退化成可被比对的口径。举证时所有者把内容与 nonce 一并出示，平台才算得出相同的承诺值。

分享路径：

```text
owner encrypts to: owner itself / regulator scope / named trading partners
  -> platform stores ciphertext (zero-knowledge) or owner hosts it
  -> CONSORTIUM event 只带 reference + salted commitment
  -> 接收方用自有密钥解密并按 commitment 校验
```

**不承诺：** 密钥恢复、平台侧取证、PRIVATE 内容的可用性进入 core RPO/RTO、删除的全局证明。详见 [B23](/decisions/catalog#b23)。

### `availabilityStatus` 是两个独立事实的并集

平台既不能读内容，也不能替所有者保证有货，所以"证据是否可用"压不成一个布尔值：

| 状态 | 来源 | 含义 |
|---|---|---|
| `OBJECT_PRESENT` | 平台自动判断（仅零知识托管且对象存在） | 平台确实保管着密文；**不代表能解密** |
| `OWNER_ASSERTED` | 所有者声明 | 所有者声称持有；平台无法核实 |
| `UNKNOWN` | 初值（典型为参与方自托管且未声明） | 平台既无对象也无声明 |

两条使用规则：**`OBJECT_PRESENT ≠ 可读`**、**`UNKNOWN ≠ 不存在`**。调查不能把"平台查不到"写成"对方没提供"，只能表述为"平台侧无法确认"并走 evidence request。它只是运营元数据，不影响任何 canonical event 的有效性、handover 状态或 finding。

### `evidencePresence` 与 `availabilityStatus` 回答两个不同问题

两个枚举都带 "available" 味道，但一个讲**事件里有没有这份证据引用**，一个讲**引用指向的内容现在能不能拿到**。不要混用：

| 枚举 | 层 | 取值 | 谁判定 | 回答的问题 |
|---|---|---|---|---|
| `evidencePresence` | canonical event（profile 视角） | `PRESENT` / `MISSING` / `DELAYED` / `UNAVAILABLE` | Core 机械比对 profile 要求与事件内容 | 这条声明是否按 profile 附上了要求的证据 |
| `availabilityStatus` | `ProtectedResource`（内容视角） | `OWNER_ASSERTED` / `OBJECT_PRESENT` / `UNKNOWN` | 平台自动判断 + 所有者声明 | 内容此刻在不在、平台能不能确认 |

`DELAYED` 只表示"超过 profile 窗口仍无引用"，是时间对比，不是风险结论；`evidencePresence=MISSING` 也不等于对方违规——是否构成风险或违规由 [Regulatory Analytics](/systems/regulatory-analytics) 或监管人员判断。

### `ENCRYPTION` 密钥的生命周期与签名密钥相反

| | `SIGNING` | `ENCRYPTION` |
|---|---|---|
| 撤销后果 | 阻止未来签署；已签事件按 B5 的时间证据规则处理 | 只阻止"再加密给它"，已加密的密文仍可解 |
| 轮换后旧私钥 | 保留以验证历史签名 | **保留到最后一份用它加密的密文被删除** |
| 丢失后果 | 无法再签，走 dual-control recovery | 对应密文永久不可解，无 escrow、无平台侧恢复 |
| 公开方式 | 公钥进注册表供验签 | 公钥进注册表供所有者加密；轮换发布新 `keyId`，旧 `keyId` 保持可查 |

因此 `recipientKeyRefs` 必须带 `keyId`，否则轮换后无法判断该用哪把私钥；销毁旧私钥要与 retention 终态联动。

## Operational 与 canonical 数据

```text
External Archive（平台控制域之外）
  authoritative encrypted payload and verification material

Operational PostgreSQL
  current registry + ingestion state + event index + outbox
  + QueryStore：可重建的明文物化副本（canonical 字段 + 边）
  + rebuildable projections

CDN/Object snapshots
  versioned PUBLIC consumer views

Regulatory export objects
  short-lived, purpose-bound investigation datasets
```

`QueryStore` 是明文的、平台运行时可以读的副本，因此它是这套设计里唯一**必须写下来**的敏感数据集：可重建、不进恢复包、静态加密、按组织审计读取。定义与不变量见 [Traceability Core](/systems/traceability-core)。

第一版不采用全应用 Event Sourcing。Canonical events、signatures、ArchiveAck、manifests 和 proofs append-only；用户资料、job state、retry state 和 UI 配置使用普通事务模型。

## Privacy 与数据最小化

**Canonical trace 不含任何自然人引用。** `actorId` 已移出 signature envelope 与 immutable 历史（B5）：归因由 `signerOrganisationId` + `keyId` + `custodyMode` + `assuranceLevel` 承担，"谁操作了"只存在于可变 operational audit。

Immutable trace 默认排除 employee name、email/phone、home address、credential、consumer identity、scan IP/geolocation 和 investigation notes。组织位置和小农场标识仍可能间接识别自然人，因此详细联系信息留在可更正的 operational registry。

这样自然人维度的更正与删除可以完全在可变层完成，不需要和 WORM 保留期讨价还价。

Public-chain commitment 不得直接包含个人字段，也不能公开短小个人字段的可字典匹配 hash。

## Retention

保留期按数据类定义，不按"统一期限"：

| 数据类 | 保留依据 |
|---|---|
| Confirmed canonical trace | product / jurisdiction retention policy；容量假设 ≥ 7 年 |
| Profile / canonicalisation / key / revocation / governance history | 至少保留到最后一个依赖它的 payload 到期 |
| Platform-hosted PRIVATE evidence / raw IoT | 所有者 + 产品/监管政策 |
| Regulatory export / analytics dataset | 短期、purpose-bound、自动过期；仅调查或 legal hold 可延长 |
| Consumer scan / security logs | 最小采集、短保留、聚合或删除 |

### Retention terminal

```text
ACTIVE_RETENTION
  |-- LEGAL_HOLD -> keep ciphertext, DEK envelope and dependencies
  `-- RETENTION_EXPIRED
        -> delete archive ciphertext and corresponding DEK envelope
        -> delete rebuildable payload/projection
        -> retain non-personal public commitment
        -> retain signed minimal deletion audit
```

七年是 NSW pilot 的默认 capacity/retention assumption，不是所有食品记录的统一法定最低期。到期后系统只能证明"曾存在某 commitment、并按何种 policy 完成删除"，不再能恢复 payload。

**判定、执行、例外是三件事，不能都留在平台手里：**

| 环节 | 谁做 | 为什么 |
|---|---|---|
| 判定到期 | 依据已发布的 retention policy；保留期台账在全 scope 方（监管方/审计方）另存一份 | 否则平台可以"算错"到期日，把删除变成单方权力 |
| 执行删除 | 平台发起请求，**副本持有方按同一 policy 独立复核后执行**并签发 deletion acknowledgement | 删除需要控制域之外的第二个签名，才不是平台自说自话 |
| 例外（早于 policy 删除） | dual control，并写进删除审计 | 这是 B1 唯一真正的例外路径，必须留痕 |

删除审计与治理记录一起锚定，所以"平台偷偷删了历史"会留下外部可查的痕迹——**不是不可删，而是删了会被看见**。

## Residency

非公开 operational data、外部归档和 Consortium KMS 默认位于 Australian regions，并至少跨一个 Australian failure domain。海外复制、support access 或 analytics 需要独立 privacy、contractual 和 jurisdiction assessment。
