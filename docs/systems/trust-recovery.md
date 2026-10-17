# Trust & Recovery

> 主要决策：[B1–B8](/decisions/catalog#b1)、[B20](/decisions/catalog#b20)、[B22](/decisions/catalog#b22)

## 目标与非目标

目标是让平台运营者无法单方面静默改写、删除或垄断已接受的追溯历史，并让授权主体能够在平台失效后恢复最小完整 trace。

当前保证不包括：

- 证明 source assertion 对应物理事实；
- 防止多个业务参与方共同提交虚假声明；
- 防止获授权的平台 runtime 泄露其可解密的 consortium plaintext；
- 在恶意平台拒绝接收前完全消除 censorship。

## 三层证明与存储

| 层 | 保存什么 | 提供什么保证 |
|---|---|---|
| Independent WORM Archive | encrypted canonical payload、signature、envelope、manifest | 可恢复的确切字节和保留承诺 |
| Public Blockchain | versioned Merkle root/commitment | 外部 existence/integrity checkpoint |
| Operational PostgreSQL | 状态、索引、outbox、projection | 高效运行；可由外部历史重建 |

公共链 inclusion time 只证明 commitment 最迟在该时点存在，不证明业务 `eventTime`。

## Encrypted Archive Envelope

```text
EncryptedArchiveEnvelope
  envelopeVersion
  networkId
  captureRecordId / epcisEventId
  canonicalPayloadDigest
  participantSignatureDigest
  ciphertextDigest
  wrappedDEK
  KMS keyId / keyEpoch
  encryptionAlgorithm / nonce
  canonicalisationVersion / profileVersion
```

事件身份、明文 digest、签名 digest、key epoch 和版本作为 authenticated metadata。Archive Operator 不解密业务内容，只对实际保存的 envelope/ciphertext bytes 签发 `ArchiveAck`。

## ArchiveAck 与公共 commitment

```text
Participant signature
  binds canonicalPayloadDigest

ArchiveAck
  binds archiveObjectId + archiveEnvelopeDigest + ciphertextDigest
  + retentionPolicyId + storedAt + archiveOperatorId

Merkle leaf
  binds event identity + canonicalPayloadDigest
  + participantSignatureDigest + ArchiveAckDigest
```

Recovery Client 必须验证整条关系，不能只检查链上 inclusion proof。

## KMS 权力边界

- 每个事件使用独立 DEK 加密。
- Consortium KEK 由联盟或独立受托方控制的专业 KMS 保护。
- 平台 runtime 可获得必要 wrap/unwrap/decrypt 使用权，但没有 disable/delete/admin 权限。
- Recovery identity 独立于平台 cloud account、IAM、DNS 和数据库。
- Participant signing keys 与 Consortium KEK 是不同用途、策略和生命周期的密钥。

外部 KMS 是信任转移，不是信任消失。KEK 永久丢失时，即使 archive 完整，payload 也无法恢复。

## 恢复包

除 canonical payload 外，还必须保留：

- Product Profile 与 canonicalisation definitions；
- organisation/public-key、delegation 和 revocation history；
- network vocabularies 与 GovernanceRecords；
- archive envelope/manifest specification；
- public-chain contract、batch 和 migration metadata。

只恢复 payload 而不能验证当时身份、schema 和规则，不算完成恢复。

## RPO/RTO 条件

`logical RPO=0` 仅是对已获得可验证 ArchiveAck/receipt、仍在 active retention/legal hold 内事件的设计目标，并依赖：

- archive/KMS 跨 Australian failure domain 的可用性；
- 可独立枚举的 archive catalogue；
- deletion protection 和 recovery identity；
- 成功的 restore drill。

关键验收场景是 ArchiveAck 已签发、尚未进入 Merkle batch 时平台 PostgreSQL 与运行账户全部丢失。系统必须能恢复 receipt/outbox/anchor intent 并继续 anchoring。

完整过程见[平台失效与恢复](/flows/platform-recovery)。
