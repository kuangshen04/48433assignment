# 平台失效与恢复

## 目标场景

平台 application account、PostgreSQL、IAM 和 DNS 不可用，但外部归档、KMS recovery authority 与 public blockchain 仍可由联盟/受托方控制的 Recovery Client 访问。

## 恢复路径

```text
1. Start trustee/consortium-controlled Recovery Client
2. Discover archive catalogue/manifests without platform database
3. Verify ArchiveAck signatures and stored envelope/ciphertext digests
4. Authenticate authorised recovery organisation/regulator
5. Determine the requester's scope（B3：成员仅恢复自身 scope；完整历史需全 scope 身份）
6. Use non-platform KMS recovery identity to unwrap DEKs
7. Decrypt payload and verify canonicalPayloadDigest
8. Verify participant signatures, profile and key history
9. Verify Merkle batches and public-chain inclusion/finality
10. Rebuild governance, registries, event index and projections
11. Recover receipted-but-unanchored intents
12. Resume anchoring and service in priority order
```

## 恢复优先级

1. organisation/key/profile registry；
2. ingestion、idempotency 和 receipt lookup；
3. confirmed trace query 与 regulator access；
4. public projection publication；
5. large exports、historical analytics 和非关键后台任务。

## 必须保留的依赖历史

| 依赖 | 为什么恢复需要它 |
|---|---|
| Product Profiles | 解释和验证 event extensions |
| Canonicalisation definitions | 重算签名与 commitment digest |
| Organisation/public-key history | 验证发布者和历史签名 |
| Revocation/governance history | 判断当时权限与有效状态 |
| Archive envelope specification | 验证和解密对象 |
| Batch/contract/migration metadata | 验证链上 inclusion 与链迁移连续性 |

## 最关键的演练

```text
ArchiveAck and receipt already issued
  + event not yet assigned/finalised on public chain
  + PostgreSQL and platform runtime account lost
```

Recovery Client 必须从 archive catalogue 找到事件，恢复原 receipt、outbox 和 anchor intent，并在不重复 receipt、object 或 leaf 的情况下继续提交。该演练不成功时，receipted trace 的 `logical RPO=0` 不能视为已证明。

## 区域与密钥故障

Archive 与 KMS recovery capability 必须跨 primary Australian failure domain。只复制 ciphertext 而没有可用 KEK/recovery identity，不构成可恢复性。最终 reference deployment 必须验证：

- archive catalogue/export 在区域故障时可用；
- KMS key deletion protection、rotation 和 emergency recovery；
- recovery identity 不依赖平台 account；
- 选定产品能够满足 4h core RTO / 24h regional rebuild target。

## Retention 边界

完整 payload recovery guarantee 只在 active retention 或 legal hold 内成立。Retention expiry 后系统保留 public commitment 与 signed minimal deletion audit，但不再承诺恢复已删除 payload。

## 关联系统

- [Trust & Recovery](/systems/trust-recovery)
- [Data & Access](/systems/data-access)
- [Operations & Deployment](/systems/operations-deployment)
