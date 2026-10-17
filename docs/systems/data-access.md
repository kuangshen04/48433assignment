# Data & Access

> 主要决策：[A5–A6](/decisions/catalog#a5)、[B2–B3](/decisions/catalog#b2)、[B10–B12](/decisions/catalog#b10)、[B20](/decisions/catalog#b20)、[B23](/decisions/catalog#b23)

## 三类可见性

| 分类 | 内容示例 | 默认读者 | 平台能否读明文 |
|---|---|---|---|
| `PUBLIC` | consumer allowlisted product/trace projection、signed safety notice | 消费者和公众 | 能（它就是生成者） |
| `CONSORTIUM` | canonical EPCIS trace core、handover/lineage、sensor summary | active consortium participants | 能（运行时被授权解密） |
| `PRIVATE` | raw IoT、报告、合同、调查记录、业务附件 | owner；所有者加密授予的接收方 | **不能**（B23） |

“所有 active consortium participants 可读取 canonical trace core”是试点共享协议的强业务假设，不是密码学必然结果。若利益相关方拒绝该假设，需要重新引入 scoped ABAC、private collections 或 selective disclosure。

## 验证与重建不是同一件事

扁平可见性不等于“任一成员能读全部历史”。按 B3：

| 能力 | 谁可以做 |
|---|---|
| 验证日志 append-only、自己的记录已纳入批次、批次序列无断裂 | 任一成员（inclusion + consistency proof） |
| 重建并验证某条记录 | 持有该事件 scope 的成员 |
| 重建并验证完整历史 | 全 scope 方：监管方、审计者、受托恢复方 |

KEK epoch 同时构成时间边界：新成员默认只拿到当前及之后的 epoch，加入前的历史明文访问需要显式治理授予。**这是对能力声明的收窄，不影响完整性保证**——完整性验证不需要明文。

这也决定了 B7 的一项要求：批次 root 必须构成可验证的 append-only 序列（running hash chain 或 consistency proof），否则“成员可独立验证”只剩单批次 inclusion，不覆盖“没有批次被跳过”。

## ProtectedResource

不能进入共享 trace 的大型或敏感内容使用统一的**平台侧记录**模型。平台只持有记录，不持有内容（B23）：

```text
ProtectedResource (platform-side record)
  ownerOrganisationId
  resourceId / reference
  mediaType
  plaintextCommitment        参与方计算、加盐
  ciphertextDigest           仅零知识托管存在
  storageMode=PARTICIPANT_HOSTED | PLATFORM_HOSTED_ZERO_KNOWLEDGE
  recipientKeyRefs           所有者选择的接收方
  retention policy
  availabilityStatus=OWNER_ASSERTED | OBJECT_PRESENT | UNKNOWN
```

三点必须记住：

1. **没有平台可执行的 `accessScope`。** 平台没有明文，内容级授权无法由它执行；访问权只能由所有者“加密给谁”来表达。
2. **没有结构化 JSONB 存 private detail。** 需要按字段查询的内容必须进 `CONSORTIUM`，没有中间地带。
3. **平台无法验证 commitment 与内容一致。** 它只能证明自己保存的密文未被替换；参与方自管内容在调查时可能无法提供，而“无法提供”本身就是有意义的结论。

分享路径：

```text
owner encrypts to: owner itself / regulator scope / named trading partners
  -> platform stores ciphertext (zero-knowledge) or owner hosts it
  -> CONSORTIUM event 只带 reference + salted commitment
  -> 接收方用自有密钥解密并按 commitment 校验
```

**不承诺：** 密钥恢复、平台侧取证、PRIVATE 内容的可用性进入 core RPO/RTO、删除的全局证明。详见 [B23](/decisions/catalog#b23)。

## Operational 与 canonical 数据

```text
Independent Archive
  authoritative encrypted payload and verification material

PostgreSQL
  current registry + ingestion state + event index
  + outbox + rebuildable projections

CDN/Object snapshots
  versioned PUBLIC consumer views

Regulatory export objects
  short-lived, purpose-bound investigation datasets
```

第一版不采用全应用 Event Sourcing。Canonical events、signatures、ArchiveAck、manifests 和 proofs append-only；用户资料、job state、retry state 和 UI 配置使用普通事务模型。

## Privacy 与数据最小化

Immutable trace 默认排除 employee name、email/phone、home address、credential、consumer identity、scan IP/geolocation 和 investigation notes。组织位置和小农场标识仍可能间接识别自然人，因此详细联系信息留在可更正的 operational registry。

Public-chain commitment 不得直接包含个人字段，也不能公开短小个人字段的可字典匹配 hash。

## Retention terminal

```text
ACTIVE_RETENTION
  |-- LEGAL_HOLD -> keep ciphertext, DEK envelope and dependencies
  `-- RETENTION_EXPIRED
        -> delete archive ciphertext and corresponding DEK envelope
        -> delete rebuildable payload/projection
        -> retain non-personal public commitment
        -> retain signed minimal deletion audit
```

七年是 NSW pilot 的默认 capacity/retention assumption，不是所有食品记录的统一法定最低期。Profile、canonicalisation、key、revocation 和 governance history 至少保留到最后一个依赖 payload 到期。

## Residency

非公开 operational data、independent archive 和 Consortium KMS 默认位于 Australian regions，并至少跨一个 Australian failure domain。海外复制、support access 或 analytics 需要独立 privacy、contractual 和 jurisdiction assessment。
