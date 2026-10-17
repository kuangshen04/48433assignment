# 事件接收与确认

这条流程把 Identity、Traceability Core、KMS、Archive、PostgreSQL 和 Public Chain 的契约串起来。单看某一个系统不能推出 `CONFIRMED` 的完整保证。

## 正常路径

```text
1. Participant creates EPCIS event
2. Resolve effective Product Profile and canonicalisation version
3. Produce canonicalPayloadDigest
4. Organisation/gateway produces SignatureEnvelope
5. Core receives captureRecordId + event + signature
6. Validate idempotency, schema, signature, authority and time evidence
7. Encrypt canonical payload with per-event DEK
8. Wrap DEK using consortium KMS key epoch
9. Store EncryptedArchiveEnvelope in independent WORM archive
10. Receive signed ArchiveAck
11. Issue platform acceptance receipt
12. Allocate deterministic Merkle leaf and batch
13. Relayer submits root to public chain
14. Observe selected finality rule
15. Mark event CONFIRMED and publish eligible projections
```

## 状态机

```text
DRAFT
  -> QUEUED_OFFLINE / SYNCING
  -> RECEIVED
  -> VALIDATED
     |-> REVIEW_REQUIRED
     `-> PENDING_SIGNATURE (managed custody only)
  -> PENDING_ARCHIVE
  -> PENDING_ANCHOR
  -> SUBMITTED_ON_CHAIN
  -> INCLUDED
  -> FINALISED
  -> CONFIRMED
```

`REVIEW_REQUIRED` 不签 acceptance receipt。通常需要当前有效 key 对相同 canonical digest 重新签名，或取得明确负责主体签署的治理/监管例外，才能继续。

## 每个 gate 的保证

| Gate | 新增保证 | 仍未保证 |
|---|---|---|
| Signature verified | 声明由对应 key 产生 | 签署时间可信、业务内容真实 |
| Authority/time accepted | 提交符合当前或受治理迟到策略 | 归档持久性、外部不可改写性 |
| ArchiveAck | 独立 operator 已保存特定 ciphertext/envelope bytes | 已达到 public-chain finality |
| Acceptance receipt | 平台承诺接受并纳入指定 anchor window | commitment 已上链 |
| Chain finality | commitment 达到所选外部 finality | 物理事实真实、参与方未串谋 |
| CONFIRMED projection | 可进入标准 trace/query | Analytics 已完成最新风险分析 |

## Idempotency

重试沿同一 `captureRecordId`、archive object identity、batch intent 和 transaction intent 继续。Worker 每次执行前检查已有外部结果：

- 相同 `captureRecordId`、相同 digest：返回现有状态/receipt；
- 相同 `captureRecordId`、不同 digest：拒绝；
- ArchiveAck 已存在：不重复写 archive；
- Merkle leaf 已分配：不重复分配；
- transaction 已广播/包含：继续观察，不重新构造不同 root。

## 离线路径

Offline draft 在平台收到前不属于共享历史。Self-custody gateway 可以提前签名；managed custody 必须联网后批准。若 key 在接收前被撤销且没有可信撤销前签署证据，事件进入 `REVIEW_REQUIRED`，`eventTime` 不能绕过撤销。

## Safety Notice 例外

Official Recall/Safety Notice 在 authorised signature 与 ArchiveAck 后可以进入 `VERIFIED_PENDING_ANCHOR` 并立即发布，之后补链上 finality。该 publication status 不能被称为普通 canonical event 的 `CONFIRMED`。

## 关联系统

- [Traceability Core](/systems/traceability-core)
- [Identity & Governance](/systems/identity-governance)
- [Trust & Recovery](/systems/trust-recovery)
- [Operations & Deployment](/systems/operations-deployment)
