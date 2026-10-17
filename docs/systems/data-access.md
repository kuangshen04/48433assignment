# Data & Access

> 主要决策：[A5–A6](/decisions/catalog#a5)、[B2–B3](/decisions/catalog#b2)、[B10–B12](/decisions/catalog#b10)、[B20](/decisions/catalog#b20)

## 三类可见性

| 分类 | 内容示例 | 默认读者 |
|---|---|---|
| `PUBLIC` | consumer allowlisted product/trace projection、signed safety notice | 消费者和公众 |
| `CONSORTIUM` | canonical EPCIS trace core、handover/lineage、sensor summary | active consortium participants |
| `PRIVATE` | raw IoT、报告、合同、调查记录、业务附件 | owner；案件授权后监管方 |

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

不能进入共享 trace 的大型或敏感内容使用统一 ProtectedResource 模型：

```text
ProtectedResource
  ownerOrganisationId
  classification=PRIVATE
  storageMode=PARTICIPANT_HOSTED | PLATFORM_HOSTED
  contentCommitment
  reference / mediaType / retention policy
  access grants and audit
```

平台托管只改变 storage/operator，不改变所有权和分类。参与方自管证据可能在调查时不可用；content hash 只能在材料实际提供时验证其是否匹配当时承诺。

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
